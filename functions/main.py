"""
Firebase Cloud Functions for MessageAI

This module contains serverless functions that run in response to Firebase events.
Currently implements:
- Push notification delivery when new messages are created
- Translation API for real-time message translation
- Display name propagation when users update their profile
"""

from firebase_functions import firestore_fn, https_fn, options
from firebase_functions.params import SecretParam
from firebase_admin import initialize_app, firestore, messaging
from google.cloud import translate_v2 as translate
from google.cloud import secretmanager
import google.cloud.firestore
from typing import Any
import time
import os
from openai import OpenAI

# Initialize Firebase Admin SDK
app = initialize_app()

# Define secret parameters
OPENAI_API_KEY = SecretParam('OPENAI_API_KEY')

# Initialize Translation API client
# Note: Uses Application Default Credentials by default (recommended for Cloud Functions)
# If TRANSLATION_API_KEY_SECRET env var is set, will fetch API key from Secret Manager
translate_client = None

def get_translate_client():
    """
    Get Translation API client, initializing it if needed.
    Supports both Application Default Credentials and Secret Manager.
    """
    global translate_client
    if translate_client is None:
        secret_name = os.environ.get("TRANSLATION_API_KEY_SECRET")
        if secret_name:
            # Use Secret Manager to get API key
            try:
                client = secretmanager.SecretManagerServiceClient()
                project_id = os.environ.get("GCP_PROJECT") or os.environ.get("GCLOUD_PROJECT")
                secret_path = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
                response = client.access_secret_version(request={"name": secret_path})
                api_key = response.payload.data.decode("UTF-8")
                translate_client = translate.Client(api_key=api_key)
                print(f"Translation client initialized with Secret Manager: {secret_name}")
            except Exception as e:
                print(f"Failed to load API key from Secret Manager: {e}")
                # Fall back to Application Default Credentials
                translate_client = translate.Client()
                print("Translation client initialized with Application Default Credentials")
        else:
            # Use Application Default Credentials (recommended for Cloud Functions)
            translate_client = translate.Client()
            print("Translation client initialized with Application Default Credentials")

    return translate_client


def get_openai_client(api_key: str):
    """
    Get OpenAI client with the provided API key.
    """
    return OpenAI(api_key=api_key)


# Cost control: Limit concurrent function instances
options.set_global_options(max_instances=10)

# Supported languages for translation (10 required languages)
SUPPORTED_LANGUAGES = {
    "en": "English",
    "es": "Spanish",
    "fr": "French",
    "de": "German",
    "zh": "Chinese",
    "ja": "Japanese",
    "ar": "Arabic",
    "pt": "Portuguese",
    "ru": "Russian",
    "hi": "Hindi",
}

# Formality levels for message adjustment
FORMALITY_LEVELS = ["casual", "neutral", "formal"]


@https_fn.on_call(secrets=[OPENAI_API_KEY])
def adjust_formality(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Adjusts the formality level of a message using GPT-4o-mini.

    Args:
        req.data should contain:
            - text (str): The text to adjust
            - target_formality (str): Target formality level ('casual', 'neutral', 'formal')
            - language (str, optional): Language code (e.g., 'en', 'es'). Defaults to 'en'
            - current_formality (str, optional): Current formality level for context

    Returns:
        dict: {
            'adjustedText': str,
            'targetFormality': str,
            'detectedFormality': str,
            'language': str,
            'cached': bool,
            'rateLimit': {
                'limit': int,
                'remaining': int,
                'resetInSeconds': int
            }
        }

    Raises:
        https_fn.HttpsError: If validation fails or adjustment errors occur
    """
    # Extract and validate request data
    data = req.data

    if not isinstance(data, dict):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Request data must be a dictionary"
        )

    text = data.get("text")
    target_formality = data.get("target_formality")
    language = data.get("language", "en")
    current_formality = data.get("current_formality", "neutral")

    # Validate required fields
    if not text or not isinstance(text, str):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'text' field is required and must be a string"
        )

    if len(text.strip()) == 0:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'text' cannot be empty"
        )

    if not target_formality or not isinstance(target_formality, str):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'target_formality' field is required and must be a string"
        )

    # Validate formality levels
    if target_formality not in FORMALITY_LEVELS:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"Target formality '{target_formality}' is not supported. "
                   f"Supported levels: {', '.join(FORMALITY_LEVELS)}"
        )

    if current_formality not in FORMALITY_LEVELS:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"Current formality '{current_formality}' is not supported. "
                   f"Supported levels: {', '.join(FORMALITY_LEVELS)}"
        )

    # Log formality adjustment request
    print(f"Formality adjustment request: '{text[:50]}...' from '{current_formality}' to '{target_formality}' (lang: {language})")

    try:
        start_time = time.time()

        # Step 0: Check rate limit (100 requests per hour per user)
        db = firestore.client()

        # Get user ID from request context (authenticated user)
        user_id = req.auth.uid if req.auth else "anonymous"

        # Calculate current hour window (truncate timestamp to hour)
        current_hour = int(time.time() // 3600)  # Unix timestamp divided by 3600 seconds
        rate_limit_key = f"{user_id}_{current_hour}"

        # Check rate limit
        rate_limit_ref = db.collection("formality_rate_limits").document(rate_limit_key)
        rate_limit_doc = rate_limit_ref.get()

        request_count = 0
        if rate_limit_doc.exists:
            rate_limit_data = rate_limit_doc.to_dict()
            request_count = rate_limit_data.get("count", 0)

        # Rate limit: 100 requests per hour per user
        RATE_LIMIT = 100
        if request_count >= RATE_LIMIT:
            # Calculate when the limit resets (next hour)
            next_hour = (current_hour + 1) * 3600
            reset_seconds = next_hour - time.time()

            print(f"Rate limit exceeded for user {user_id}: {request_count}/{RATE_LIMIT}")

            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.RESOURCE_EXHAUSTED,
                message=f"Formality adjustment rate limit exceeded. Limit: {RATE_LIMIT} requests per hour. "
                       f"Try again in {int(reset_seconds/60)} minutes."
            )

        # Increment request count
        rate_limit_ref.set({
            "userId": user_id,
            "hourWindow": current_hour,
            "count": request_count + 1,
            "lastRequest": time.time(),
        })

        remaining_requests = RATE_LIMIT - (request_count + 1)
        print(f"Rate limit check passed: {request_count + 1}/{RATE_LIMIT} requests (user: {user_id})")

        # Step 1: Check cache first (reduces API costs)
        cache_collection = db.collection("formality_cache")

        # Create cache key from text + current + target + language
        cache_key = f"{text}_{current_formality}_{target_formality}_{language}"
        cache_ref = cache_collection.document(cache_key)
        cache_doc = cache_ref.get()

        # Check if cache entry exists and is not expired (24-hour TTL)
        if cache_doc.exists:
            cache_data = cache_doc.to_dict()
            timestamp = cache_data.get("timestamp")

            if timestamp:
                # Check if cache is still valid (24 hours = 86400 seconds)
                age_seconds = time.time() - timestamp
                if age_seconds < 86400:  # 24 hours
                    # Cache hit!
                    elapsed_time = time.time() - start_time
                    print(f"Cache HIT in {elapsed_time:.3f}s (age: {age_seconds/3600:.1f}h)")

                    return {
                        "adjustedText": cache_data["adjustedText"],
                        "targetFormality": cache_data["targetFormality"],
                        "detectedFormality": cache_data.get("detectedFormality", current_formality),
                        "language": cache_data["language"],
                        "cached": True,
                        "cacheAge": age_seconds,
                        "rateLimit": {
                            "limit": RATE_LIMIT,
                            "remaining": remaining_requests,
                            "resetInSeconds": int((current_hour + 1) * 3600 - time.time()),
                        },
                    }

        # Step 2: Cache miss - call OpenAI API
        print("Cache MISS - calling OpenAI API")

        # Get OpenAI client
        client = get_openai_client(OPENAI_API_KEY.value)

        # Construct the prompt for GPT-4o-mini
        system_prompt = (
            "You are a language expert specializing in adjusting message formality. "
            "Rewrite messages to match the target formality level while preserving meaning "
            "and cultural appropriateness. Return ONLY the rewritten message without any "
            "explanations, quotes, or additional text."
        )

        user_prompt = f"""Rewrite this message to match the target formality level while preserving meaning and cultural appropriateness.

Current formality: {current_formality}
Target formality: {target_formality}
Language: {language}

Rules:
- Casual: Contractions OK, slang OK, friendly tone
- Neutral: Standard language, no slang, balanced
- Formal: No contractions, respectful, professional

Message: "{text}"

Return ONLY the rewritten message."""

        # Call OpenAI API (GPT-4o-mini)
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.7,
            max_tokens=500,
        )

        elapsed_time = time.time() - start_time

        # Extract adjusted text
        adjusted_text = response.choices[0].message.content.strip()

        # Remove quotes if the model added them
        if adjusted_text.startswith('"') and adjusted_text.endswith('"'):
            adjusted_text = adjusted_text[1:-1]
        if adjusted_text.startswith("'") and adjusted_text.endswith("'"):
            adjusted_text = adjusted_text[1:-1]

        # Step 3: Store in cache for future requests
        cache_ref.set({
            "originalText": text,
            "currentFormality": current_formality,
            "targetFormality": target_formality,
            "adjustedText": adjusted_text,
            "detectedFormality": current_formality,
            "language": language,
            "timestamp": time.time(),
        })

        print(f"Formality adjustment successful in {elapsed_time:.2f}s: "
              f"{current_formality} -> {target_formality}")

        return {
            "adjustedText": adjusted_text,
            "targetFormality": target_formality,
            "detectedFormality": current_formality,
            "language": language,
            "cached": False,
            "rateLimit": {
                "limit": RATE_LIMIT,
                "remaining": remaining_requests,
                "resetInSeconds": int((current_hour + 1) * 3600 - time.time()),
            },
        }

    except Exception as e:
        print(f"Formality adjustment error: {e}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Formality adjustment failed: {str(e)}"
        )


@https_fn.on_call(secrets=[OPENAI_API_KEY])
def explain_idioms(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Explains idioms, slang, and colloquialisms in a message using GPT-4o-mini.

    Args:
        req.data should contain:
            - text (str): The text to analyze
            - source_language (str): Source language code (e.g., 'en', 'es')
            - target_language (str): Target language code for equivalent expressions

    Returns:
        dict: {
            'idioms': [
                {
                    'phrase': str,
                    'meaning': str,
                    'culturalNote': str,
                    'equivalentIn': {language_code: equivalent_phrase}
                }
            ]
        }

    Raises:
        https_fn.HttpsError: If validation fails or explanation errors occur
    """
    # Extract and validate request data
    data = req.data

    if not isinstance(data, dict):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Request data must be a dictionary"
        )

    text = data.get("text")
    source_language = data.get("source_language", "en")
    target_language = data.get("target_language", "en")

    # Validate required fields
    if not text or not isinstance(text, str):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'text' field is required and must be a string"
        )

    if len(text.strip()) == 0:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'text' cannot be empty"
        )

    # Log idiom explanation request
    print(f"Idiom explanation request: '{text[:50]}...' (source: {source_language}, target: {target_language})")

    try:
        start_time = time.time()

        # Get OpenAI client
        client = get_openai_client(OPENAI_API_KEY.value)

        # Construct the prompt for GPT-4o-mini
        system_prompt = (
            "You are a language expert specializing in idioms, slang, and colloquialisms. "
            "Analyze messages to identify and explain idiomatic expressions, slang terms, "
            "and colloquialisms. Provide cultural context and equivalent expressions in other "
            "languages. Always return valid JSON."
        )

        user_prompt = f"""Analyze this message for idioms, slang, or colloquialisms and provide explanations.

Source language: {source_language}
Target language: {target_language}
Message: "{text}"

Return JSON in this exact format:
{{
  "idioms": [
    {{
      "phrase": "the exact phrase from the message",
      "meaning": "clear explanation of what it means",
      "culturalNote": "cultural context or origin",
      "equivalentIn": {{"es": "equivalent in Spanish", "fr": "equivalent in French"}}
    }}
  ]
}}

If no idioms/slang found, return {{"idioms": []}}.
Only return the JSON, no additional text."""

        # Call OpenAI API (GPT-4o-mini)
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.3,  # Lower temperature for more consistent JSON
            max_tokens=1000,
            response_format={"type": "json_object"}  # Ensure JSON response
        )

        elapsed_time = time.time() - start_time

        # Extract and parse response
        response_text = response.choices[0].message.content.strip()

        # Parse JSON response
        import json
        try:
            result = json.loads(response_text)
        except json.JSONDecodeError as e:
            print(f"Failed to parse JSON response: {e}")
            print(f"Response was: {response_text}")
            # Return empty result if parsing fails
            result = {"idioms": []}

        print(f"Idiom explanation successful in {elapsed_time:.2f}s: found {len(result.get('idioms', []))} idiom(s)")

        return result

    except Exception as e:
        print(f"Idiom explanation error: {e}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Idiom explanation failed: {str(e)}"
        )


@https_fn.on_call(secrets=[OPENAI_API_KEY])
def analyze_cultural_context(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Analyzes a message for cultural nuances, idioms, or formality using GPT-4o-mini.

    Args:
        req.data should contain:
            - text (str): The text to analyze
            - language (str): Language code (e.g., 'en', 'es')

    Returns:
        dict: {
            'culturalHint': str | None  # null if no cultural context needed
        }

    Raises:
        https_fn.HttpsError: If validation fails or analysis errors occur
    """
    # Extract and validate request data
    data = req.data

    if not isinstance(data, dict):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Request data must be a dictionary"
        )

    text = data.get("text")
    language = data.get("language", "en")

    # Validate required fields
    if not text or not isinstance(text, str):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'text' field is required and must be a string"
        )

    if len(text.strip()) == 0:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'text' cannot be empty"
        )

    # Log cultural context request
    print(f"Cultural context analysis request: '{text[:50]}...' (lang: {language})")

    try:
        start_time = time.time()

        # Step 1: Check cache first (30-day TTL for cost reduction)
        db = firestore.client()
        cache_collection = db.collection("cultural_context_cache")

        # Create cache key from text + language
        cache_key = f"{text}_{language}"
        cache_ref = cache_collection.document(cache_key)
        cache_doc = cache_ref.get()

        # Check if cache entry exists and is not expired (30 days = 2592000 seconds)
        if cache_doc.exists:
            cache_data = cache_doc.to_dict()
            timestamp = cache_data.get("timestamp")

            if timestamp:
                # Check if cache is still valid (30 days)
                age_seconds = time.time() - timestamp
                if age_seconds < 2592000:  # 30 days
                    # Cache hit!
                    elapsed_time = time.time() - start_time
                    print(f"Cultural context cache HIT in {elapsed_time:.3f}s (age: {age_seconds/86400:.1f} days)")

                    return {
                        "culturalHint": cache_data.get("culturalHint"),
                        "cached": True,
                        "cacheAge": age_seconds,
                    }

        # Step 2: Cache miss - call OpenAI API
        print("Cultural context cache MISS - calling OpenAI API")

        # Get OpenAI client
        client = get_openai_client(OPENAI_API_KEY.value)

        # Construct the prompt for GPT-4o-mini
        system_prompt = (
            "Analyze this message for cultural nuances, idioms, or formality that might not be obvious to non-native speakers. "
            "Focus on: Cultural greetings or expressions, Formal vs informal language use, Idioms or colloquialisms, Cultural references. "
            "Keep explanations under 50 words. If the message is straightforward with no cultural context needed, return null."
        )

        user_prompt = f"""Analyze this message for cultural context:

Language: {language}
Message: "{text}"

If the message contains cultural nuances, idioms, formal greetings, or references that might not be obvious to non-native speakers, provide a brief explanation (under 50 words).

If the message is straightforward and doesn't require cultural explanation, respond with exactly: null

Return only the explanation or null, no additional formatting."""

        # Call OpenAI API (GPT-4o-mini)
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.3,  # Lower temperature for consistent analysis
            max_tokens=100,   # Keep explanations short
        )

        elapsed_time = time.time() - start_time

        # Extract cultural hint
        cultural_hint_raw = response.choices[0].message.content.strip()

        # Parse response - handle "null" or actual explanation
        cultural_hint = None
        if cultural_hint_raw.lower() != "null":
            cultural_hint = cultural_hint_raw

        # Step 3: Store in cache for future requests (30-day TTL)
        cache_ref.set({
            "text": text,
            "language": language,
            "culturalHint": cultural_hint,
            "timestamp": time.time(),
        })

        print(f"Cultural context analysis successful in {elapsed_time:.2f}s: "
              f"{'Found context' if cultural_hint else 'No context needed'}")

        return {
            "culturalHint": cultural_hint,
            "cached": False,
        }

    except Exception as e:
        print(f"Cultural context analysis error: {e}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Cultural context analysis failed: {str(e)}"
        )


@https_fn.on_call()
def translate_message(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Translates a message from one language to another using Google Cloud Translation API.

    Args:
        req.data should contain:
            - text (str): The text to translate
            - source_language (str): Source language code (e.g., 'en', 'es')
            - target_language (str): Target language code (e.g., 'en', 'es')

    Returns:
        dict: {
            'translatedText': str,
            'sourceLanguage': str,
            'targetLanguage': str,
            'detectedLanguage': str (if source was auto-detected)
        }

    Raises:
        https_fn.HttpsError: If validation fails or translation errors occur
    """
    # Extract and validate request data
    data = req.data

    if not isinstance(data, dict):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Request data must be a dictionary"
        )

    text = data.get("text")
    source_language = data.get("source_language", "")  # Empty string = auto-detect
    target_language = data.get("target_language")

    # Validate required fields
    if not text or not isinstance(text, str):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'text' field is required and must be a string"
        )

    if not target_language or not isinstance(target_language, str):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'target_language' field is required and must be a string"
        )

    # Validate target language is supported
    if target_language not in SUPPORTED_LANGUAGES:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"Target language '{target_language}' is not supported. "
                   f"Supported languages: {', '.join(SUPPORTED_LANGUAGES.keys())}"
        )

    # Validate source language if provided
    if source_language and source_language not in SUPPORTED_LANGUAGES:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"Source language '{source_language}' is not supported. "
                   f"Supported languages: {', '.join(SUPPORTED_LANGUAGES.keys())}"
        )

    # Log translation request
    print(f"Translation request: '{text[:50]}...' from '{source_language or 'auto'}' to '{target_language}'")

    try:
        start_time = time.time()

        # Step 0: Check rate limit (100 requests per hour per user)
        db = firestore.client()

        # Get user ID from request context (authenticated user)
        user_id = req.auth.uid if req.auth else "anonymous"

        # Calculate current hour window (truncate timestamp to hour)
        current_hour = int(time.time() // 3600)  # Unix timestamp divided by 3600 seconds
        rate_limit_key = f"{user_id}_{current_hour}"

        # Check rate limit
        rate_limit_ref = db.collection("translation_rate_limits").document(rate_limit_key)
        rate_limit_doc = rate_limit_ref.get()

        request_count = 0
        if rate_limit_doc.exists:
            rate_limit_data = rate_limit_doc.to_dict()
            request_count = rate_limit_data.get("count", 0)

        # Rate limit: 100 requests per hour per user
        RATE_LIMIT = 100
        if request_count >= RATE_LIMIT:
            # Calculate when the limit resets (next hour)
            next_hour = (current_hour + 1) * 3600
            reset_seconds = next_hour - time.time()

            print(f"Rate limit exceeded for user {user_id}: {request_count}/{RATE_LIMIT}")

            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.RESOURCE_EXHAUSTED,
                message=f"Translation rate limit exceeded. Limit: {RATE_LIMIT} requests per hour. "
                       f"Try again in {int(reset_seconds/60)} minutes."
            )

        # Increment request count
        rate_limit_ref.set({
            "userId": user_id,
            "hourWindow": current_hour,
            "count": request_count + 1,
            "lastRequest": time.time(),
        })

        remaining_requests = RATE_LIMIT - (request_count + 1)
        print(f"Rate limit check passed: {request_count + 1}/{RATE_LIMIT} requests (user: {user_id})")

        # Step 1: Check cache first (reduces API costs by 70%)
        db = firestore.client()
        cache_collection = db.collection("translation_cache")

        # Create cache key from text + source + target
        cache_key = f"{text}_{source_language or 'auto'}_{target_language}"
        cache_ref = cache_collection.document(cache_key)
        cache_doc = cache_ref.get()

        # Check if cache entry exists and is not expired (24-hour TTL)
        if cache_doc.exists:
            cache_data = cache_doc.to_dict()
            timestamp = cache_data.get("timestamp")

            if timestamp:
                # Check if cache is still valid (24 hours = 86400 seconds)
                age_seconds = time.time() - timestamp
                if age_seconds < 86400:  # 24 hours
                    # Cache hit!
                    elapsed_time = time.time() - start_time
                    print(f"Cache HIT in {elapsed_time:.3f}s (age: {age_seconds/3600:.1f}h)")

                    return {
                        "translatedText": cache_data["translatedText"],
                        "sourceLanguage": cache_data["sourceLanguage"],
                        "targetLanguage": cache_data["targetLanguage"],
                        "detectedLanguage": cache_data["detectedLanguage"],
                        "cached": True,
                        "cacheAge": age_seconds,
                        "rateLimit": {
                            "limit": RATE_LIMIT,
                            "remaining": remaining_requests,
                            "resetInSeconds": int((current_hour + 1) * 3600 - time.time()),
                        },
                    }

        # Step 2: Cache miss - call Translation API
        print("Cache MISS - calling Translation API")

        # Get Translation API client (supports Secret Manager or Application Default Credentials)
        client = get_translate_client()

        # Call Google Cloud Translation API
        result = client.translate(
            text,
            target_language=target_language,
            source_language=source_language if source_language else None,
            format_="text"
        )

        elapsed_time = time.time() - start_time

        # Extract results
        translated_text = result["translatedText"]
        detected_language = result.get("detectedSourceLanguage", source_language)

        # Step 3: Store in cache for future requests
        cache_ref.set({
            "sourceText": text,
            "sourceLanguage": source_language or detected_language,
            "targetLanguage": target_language,
            "translatedText": translated_text,
            "detectedLanguage": detected_language,
            "timestamp": time.time(),
        })

        print(f"Translation successful in {elapsed_time:.2f}s: "
              f"detected={detected_language}, target={target_language}")

        return {
            "translatedText": translated_text,
            "sourceLanguage": source_language or detected_language,
            "targetLanguage": target_language,
            "detectedLanguage": detected_language,
            "cached": False,
            "rateLimit": {
                "limit": RATE_LIMIT,
                "remaining": remaining_requests,
                "resetInSeconds": int((current_hour + 1) * 3600 - time.time()),
            },
        }

    except Exception as e:
        print(f"Translation error: {e}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Translation failed: {str(e)}"
        )


@https_fn.on_request()
def clean_translation_cache(req: https_fn.Request) -> https_fn.Response:
    """
    Scheduled function to clean up expired cache and rate limit entries.

    Removes:
    - Translation cache entries older than 24 hours
    - Formality cache entries older than 24 hours
    - Translation rate limit entries older than 2 hours
    - Formality rate limit entries older than 2 hours

    Should be triggered via Cloud Scheduler (e.g., daily at 2 AM).

    Can also be called manually:
        curl https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/clean_translation_cache

    Returns:
        JSON with cleanup stats: { translationCacheDeleted, formalityCacheDeleted,
                                   translationRateLimitDeleted, formalityRateLimitDeleted, errors }
    """
    try:
        db = firestore.client()

        # === Clean translation cache (24-hour TTL) ===
        cache_collection = db.collection("translation_cache")
        cache_cutoff_time = time.time() - 86400  # 24 hours ago

        expired_cache_query = cache_collection.where("timestamp", "<", cache_cutoff_time)
        expired_cache_docs = expired_cache_query.stream()

        cache_deleted = 0
        error_count = 0

        # Delete expired cache entries in batches
        batch = db.batch()
        batch_count = 0

        for doc in expired_cache_docs:
            try:
                batch.delete(doc.reference)
                batch_count += 1
                cache_deleted += 1

                # Firestore batches can only contain 500 operations
                if batch_count >= 500:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0
            except Exception as e:
                error_count += 1
                print(f"Error deleting cache entry {doc.id}: {e}")

        # Commit remaining cache deletions
        if batch_count > 0:
            batch.commit()
            batch_count = 0

        print(f"Cache cleanup: deleted {cache_deleted} entries")

        # === Clean rate limit entries (2-hour retention) ===
        rate_limit_collection = db.collection("translation_rate_limits")

        # Delete rate limit entries older than 2 hours (well past their hour window)
        rate_limit_cutoff_time = time.time() - 7200  # 2 hours ago

        expired_rate_limit_query = rate_limit_collection.where("lastRequest", "<", rate_limit_cutoff_time)
        expired_rate_limit_docs = expired_rate_limit_query.stream()

        rate_limit_deleted = 0
        batch = db.batch()

        for doc in expired_rate_limit_docs:
            try:
                batch.delete(doc.reference)
                batch_count += 1
                rate_limit_deleted += 1

                if batch_count >= 500:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0
            except Exception as e:
                error_count += 1
                print(f"Error deleting rate limit entry {doc.id}: {e}")

        # Commit remaining rate limit deletions
        if batch_count > 0:
            batch.commit()

        print(f"Translation rate limit cleanup: deleted {rate_limit_deleted} entries")

        # === Clean formality cache (24-hour TTL) ===
        formality_cache_collection = db.collection("formality_cache")
        formality_cache_cutoff_time = time.time() - 86400  # 24 hours ago

        expired_formality_cache_query = formality_cache_collection.where("timestamp", "<", formality_cache_cutoff_time)
        expired_formality_cache_docs = expired_formality_cache_query.stream()

        formality_cache_deleted = 0
        batch = db.batch()
        batch_count = 0

        for doc in expired_formality_cache_docs:
            try:
                batch.delete(doc.reference)
                batch_count += 1
                formality_cache_deleted += 1

                if batch_count >= 500:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0
            except Exception as e:
                error_count += 1
                print(f"Error deleting formality cache entry {doc.id}: {e}")

        # Commit remaining formality cache deletions
        if batch_count > 0:
            batch.commit()
            batch_count = 0

        print(f"Formality cache cleanup: deleted {formality_cache_deleted} entries")

        # === Clean formality rate limit entries (2-hour retention) ===
        formality_rate_limit_collection = db.collection("formality_rate_limits")
        formality_rate_limit_cutoff_time = time.time() - 7200  # 2 hours ago

        expired_formality_rate_limit_query = formality_rate_limit_collection.where("lastRequest", "<", formality_rate_limit_cutoff_time)
        expired_formality_rate_limit_docs = expired_formality_rate_limit_query.stream()

        formality_rate_limit_deleted = 0
        batch = db.batch()

        for doc in expired_formality_rate_limit_docs:
            try:
                batch.delete(doc.reference)
                batch_count += 1
                formality_rate_limit_deleted += 1

                if batch_count >= 500:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0
            except Exception as e:
                error_count += 1
                print(f"Error deleting formality rate limit entry {doc.id}: {e}")

        # Commit remaining formality rate limit deletions
        if batch_count > 0:
            batch.commit()

        print(f"Formality rate limit cleanup: deleted {formality_rate_limit_deleted} entries")

        # === Clean cultural context cache (30-day TTL) ===
        cultural_cache_collection = db.collection("cultural_context_cache")
        cultural_cache_cutoff_time = time.time() - 2592000  # 30 days ago

        expired_cultural_cache_query = cultural_cache_collection.where("timestamp", "<", cultural_cache_cutoff_time)
        expired_cultural_cache_docs = expired_cultural_cache_query.stream()

        cultural_cache_deleted = 0
        batch = db.batch()
        batch_count = 0

        for doc in expired_cultural_cache_docs:
            try:
                batch.delete(doc.reference)
                batch_count += 1
                cultural_cache_deleted += 1

                if batch_count >= 500:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0
            except Exception as e:
                error_count += 1
                print(f"Error deleting cultural context cache entry {doc.id}: {e}")

        # Commit remaining cultural context cache deletions
        if batch_count > 0:
            batch.commit()

        print(f"Cultural context cache cleanup: deleted {cultural_cache_deleted} entries")
        print(f"Total cleanup complete: translationCache={cache_deleted}, formalityCache={formality_cache_deleted}, "
              f"culturalContextCache={cultural_cache_deleted}, "
              f"translationRateLimit={rate_limit_deleted}, formalityRateLimit={formality_rate_limit_deleted}, "
              f"errors={error_count}")

        return https_fn.Response(
            response=f'{{"translationCacheDeleted": {cache_deleted}, "formalityCacheDeleted": {formality_cache_deleted}, '
                    f'"culturalContextCacheDeleted": {cultural_cache_deleted}, '
                    f'"translationRateLimitDeleted": {rate_limit_deleted}, "formalityRateLimitDeleted": {formality_rate_limit_deleted}, '
                    f'"errors": {error_count}}}',
            status=200,
            headers={"Content-Type": "application/json"}
        )

    except Exception as e:
        print(f"Cleanup failed: {e}")
        return https_fn.Response(
            response=f'{{"error": "{str(e)}"}}',
            status=500,
            headers={"Content-Type": "application/json"}
        )


def _send_notification_for_message(
    event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None],
    conversation_collection: str,
) -> None:
    """
    Internal helper to send push notifications for messages.

    Args:
        event: Firestore event with message data
        conversation_collection: Either "conversations" or "group-conversations"
    """
    if event.data is None:
        print("No data in event, skipping notification")
        return

    # Extract message data
    message_data = event.data.to_dict()
    if message_data is None:
        print("Could not convert message to dict, skipping notification")
        return

    sender_id = message_data.get("senderId")
    sender_name = message_data.get("senderName", "Someone")
    message_text = message_data.get("text", "")
    conversation_id = event.params["conversationId"]
    message_id = event.params["messageId"]

    # Determine if this is a group message based on collection
    is_group = conversation_collection == "group-conversations"
    message_type = "group" if is_group else "direct"

    print(f"New {message_type} message from {sender_name} in {conversation_id}")

    # Get conversation to find participants
    db = firestore.client()
    conversation_ref = db.collection(conversation_collection).document(conversation_id)
    conversation = conversation_ref.get()

    if not conversation.exists:
        print(f"Conversation {conversation_id} not found in {conversation_collection}")
        return

    conversation_data = conversation.to_dict()
    if conversation_data is None:
        print("Could not convert conversation to dict")
        return

    participants = conversation_data.get("participants", [])
    if not participants:
        print("No participants found in conversation")
        return

    # Extract participant IDs
    participant_ids = [p.get("uid") for p in participants if p.get("uid")]

    # Get group name for group messages
    group_name = conversation_data.get("name", "Group") if is_group else None

    print(f"Sending notifications to {len(participant_ids) - 1} participants (excluding sender)")

    # Send notification to each participant (except sender)
    notification_count = 0
    for participant_id in participant_ids:
        if participant_id == sender_id:
            continue  # Don't notify the sender

        # Get user's FCM tokens
        user_ref = db.collection("users").document(participant_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            print(f"User {participant_id} not found")
            continue

        user_data = user_doc.to_dict()
        if user_data is None:
            continue

        fcm_tokens = user_data.get("fcmTokens", [])
        if not fcm_tokens:
            print(f"No FCM tokens for user {participant_id}")
            continue

        # Customize notification title for groups
        notification_title = f"{sender_name} in {group_name}" if is_group else sender_name

        # Send notification to each token
        for token in fcm_tokens:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=notification_title,
                        body=message_text[:100],  # Truncate long messages
                    ),
                    data={
                        "conversationId": conversation_id,
                        "senderId": sender_id,
                        "messageId": message_id,
                        "type": "group_message" if is_group else "direct_message",
                        "isGroup": "true" if is_group else "false",
                    },
                    token=token,
                    android=messaging.AndroidConfig(
                        priority="high",
                        notification=messaging.AndroidNotification(
                            color="#2196F3",
                            sound="default",
                            channel_id="messages",
                        ),
                    ),
                    apns=messaging.APNSConfig(
                        payload=messaging.APNSPayload(
                            aps=messaging.Aps(
                                sound="default",
                                badge=1,
                                content_available=True,
                            ),
                        ),
                    ),
                )

                response = messaging.send(message)
                notification_count += 1
                print(f"Sent notification to {participant_id}: {response}")

            except Exception as e:
                print(f"Failed to send notification to {participant_id}: {e}")
                # Continue to next token even if one fails

    print(f"Notification batch complete: {notification_count} notifications sent")


@firestore_fn.on_document_created(
    document="conversations/{conversationId}/messages/{messageId}"
)
def send_message_notification(
    event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None],
) -> None:
    """
    Sends push notifications when a new direct message is created.

    Triggered by: New document in conversations/{conversationId}/messages/
    Action: Sends FCM notification to all conversation participants except sender
    """
    _send_notification_for_message(event, "conversations")


@firestore_fn.on_document_created(
    document="group-conversations/{conversationId}/messages/{messageId}"
)
def send_group_message_notification(
    event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None],
) -> None:
    """
    Sends push notifications when a new group message is created.

    Triggered by: New document in group-conversations/{conversationId}/messages/
    Action: Sends FCM notification to all group participants except sender

    Group notifications include the group name in the title:
    "John in Team Discussion" instead of just "John"
    """
    _send_notification_for_message(event, "group-conversations")
