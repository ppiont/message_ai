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
from google.auth import default
from google.auth.transport.requests import Request
import json

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


def generate_vertex_ai_embedding(text: str) -> list[float]:
    """
    Generate text embedding using Vertex AI REST API.

    Uses text-multilingual-embedding-002 model which produces 768-dimensional vectors.
    This model supports 100+ languages and is optimized for semantic search/retrieval.

    This approach uses the REST API instead of the heavy google-cloud-aiplatform SDK
    to avoid dependency conflicts and reduce Cloud Build times.

    Args:
        text: The text to generate an embedding for

    Returns:
        List of 768 floats representing the embedding vector

    Raises:
        Exception: If the API call fails
    """
    import requests

    # Get Application Default Credentials
    credentials, project = default()

    # Refresh credentials if needed
    if not credentials.valid:
        credentials.refresh(Request())

    # Vertex AI endpoint
    project_id = project or os.environ.get('GCP_PROJECT') or os.environ.get('GCLOUD_PROJECT')
    location = 'us-central1'
    model = 'text-multilingual-embedding-002'
    url = f'https://{location}-aiplatform.googleapis.com/v1/projects/{project_id}/locations/{location}/publishers/google/models/{model}:predict'

    # Request payload
    # task_type: RETRIEVAL_DOCUMENT optimizes embeddings for semantic search
    payload = {
        'instances': [
            {
                'content': text,
                'task_type': 'RETRIEVAL_DOCUMENT'
            }
        ]
    }

    # Make the API call
    headers = {
        'Authorization': f'Bearer {credentials.token}',
        'Content-Type': 'application/json'
    }

    response = requests.post(url, headers=headers, json=payload)
    response.raise_for_status()

    # Parse response
    result = response.json()
    embedding = result['predictions'][0]['embeddings']['values']

    return embedding


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


# Note: Group conversations are also in 'conversations' collection (single collection architecture)
# Both direct and group messages trigger the same function above


# ========== Automatic Embedding Generation ==========


@firestore_fn.on_document_created(
    document="conversations/{conversationId}/messages/{messageId}"
)
def generate_message_embedding(
    event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None],
) -> None:
    """
    Automatically generates embeddings for direct conversation messages.

    This trigger fires when a new message is created in a direct conversation.
    It uses Vertex AI's textembedding-gecko model to generate a 768-dimensional
    embedding vector and writes it back to the message document.

    Benefits:
    - Zero phone involvement (server-side only)
    - Async/non-blocking (doesn't slow down message send)
    - Cheaper than OpenAI ($1 vs $20 per 1M messages)
    - Automatic indexing by Firestore vector search

    Triggered by: New document in conversations/{conversationId}/messages/
    Action: Generate 768D embedding using Vertex AI and update document

    Note: Works for both direct and group conversations (single collection architecture)
    """
    _generate_embedding_for_message(event)


def _generate_embedding_for_message(
    event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None],
) -> None:
    """
    Shared logic for generating embeddings for messages.

    This function:
    1. Extracts the message text from the document
    2. Validates it's long enough (>= 5 chars)
    3. Generates embedding using Vertex AI textembedding-gecko
    4. Updates the message document with the embedding

    Args:
        event: Firestore document creation event

    Note: Errors are logged but don't throw to avoid retry loops
    """
    try:
        if event.data is None:
            print("Warning: Event data is None, skipping embedding generation")
            return

        message_data = event.data.to_dict()
        if message_data is None:
            print("Warning: Message data is None, skipping embedding generation")
            return

        text = message_data.get('text', '')
        message_id = event.data.id

        # Skip if text is too short
        if len(text.strip()) < 5:
            print(f"Skipping embedding for message {message_id}: text too short ({len(text)} chars)")
            return

        # Skip if embedding already exists (shouldn't happen, but defensive)
        if 'embedding' in message_data and message_data['embedding']:
            print(f"Skipping embedding for message {message_id}: embedding already exists")
            return

        print(f"Generating embedding for message {message_id}: '{text[:50]}...'")
        start_time = time.time()

        # Generate embedding using Vertex AI textembedding-gecko (via REST API)
        # This model produces 768-dimensional vectors
        embedding_vector = generate_vertex_ai_embedding(text)

        # Update message document with embedding
        event.data.reference.update({'embedding': embedding_vector})

        elapsed_ms = (time.time() - start_time) * 1000
        print(f"Successfully generated 768D embedding for message {message_id} in {elapsed_ms:.0f}ms")

    except Exception as e:
        # Log error but don't throw to avoid retry loops
        print(f"Error generating embedding for message: {e}")
        import traceback
        traceback.print_exc()


# ========== Smart Replies ==========


@https_fn.on_call(secrets=[OPENAI_API_KEY])
def generate_smart_replies_complete(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Unified smart reply generation with complete RAG pipeline server-side.

    This function implements the entire Smart Replies RAG pipeline in one call:
    1. Generates embedding for incoming message using Vertex AI (768D)
    2. Performs vector search using Firestore find_nearest()
    3. Fetches user communication style from Firestore
    4. Generates 3 reply suggestions with GPT-4o-mini

    This replaces the old multi-step client-side orchestration with a single
    server-side function call, reducing latency and complexity.

    Args:
        req.data should contain:
            - conversationId (str): The conversation context
            - incomingMessageText (str): The message to generate replies for
            - userId (str): The user ID for fetching communication style

    Returns:
        dict: {
            'suggestions': [
                {'text': str, 'intent': str},  # positive
                {'text': str, 'intent': str},  # neutral
                {'text': str, 'intent': str},  # question
            ],
            'cached': bool,
            'latency': float  # Total latency in milliseconds
        }

    Raises:
        https_fn.HttpsError: If validation fails or generation errors occur

    Performance: Target <2 seconds response time (embedding + search + LLM)
    Cost: ~$0.001 embedding + ~$0.0001 GPT-4o-mini = ~$0.0011 per request
    """
    start_time = time.time()

    # Validate authentication
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="User must be authenticated to generate smart replies"
        )

    # Extract and validate request data
    data = req.data

    if not isinstance(data, dict):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Request data must be a dictionary"
        )

    conversation_id = data.get("conversationId")
    incoming_message_text = data.get("incomingMessageText")
    user_id = data.get("userId")

    # Validate required fields
    if not conversation_id or not isinstance(conversation_id, str):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'conversationId' field is required and must be a string"
        )

    if not incoming_message_text or not isinstance(incoming_message_text, str):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'incomingMessageText' field is required and must be a string"
        )

    if not user_id or not isinstance(user_id, str):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'userId' field is required and must be a string"
        )

    # Log smart reply request
    print(f"Smart reply complete request: '{incoming_message_text[:50]}...' in conversation {conversation_id}")

    try:
        db = firestore.client()

        # Step 0: Rate limiting (50 requests per hour per user)
        current_hour = int(time.time() // 3600)
        rate_limit_key = f"{user_id}_{current_hour}"
        rate_limit_ref = db.collection("smart_reply_rate_limits").document(rate_limit_key)
        rate_limit_doc = rate_limit_ref.get()

        request_count = 0
        if rate_limit_doc.exists:
            rate_limit_data = rate_limit_doc.to_dict()
            request_count = rate_limit_data.get("count", 0)

        RATE_LIMIT = 50
        if request_count >= RATE_LIMIT:
            next_hour = (current_hour + 1) * 3600
            reset_seconds = next_hour - time.time()
            print(f"Rate limit exceeded for user {user_id}: {request_count}/{RATE_LIMIT}")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.RESOURCE_EXHAUSTED,
                message=f"Smart reply rate limit exceeded. Limit: {RATE_LIMIT} requests per hour. "
                       f"Try again in {int(reset_seconds/60)} minutes."
            )

        # Increment request count
        rate_limit_ref.set({
            "userId": user_id,
            "hourWindow": current_hour,
            "count": request_count + 1,
            "lastRequest": time.time(),
        })

        print(f"Rate limit check passed: {request_count + 1}/{RATE_LIMIT} requests")

        # Step 1: Check cache first (7-day TTL)
        import hashlib
        import json

        # Create cache key from incoming message text and conversation ID
        cache_key_data = f"{conversation_id}_{incoming_message_text}_{user_id}"
        cache_key_hash = hashlib.sha256(cache_key_data.encode('utf-8')).hexdigest()
        cache_collection = db.collection("smart_reply_cache")
        cache_ref = cache_collection.document(cache_key_hash)
        cache_doc = cache_ref.get()

        # Check if cache entry exists and is not expired (7 days = 604800 seconds)
        if cache_doc.exists:
            cache_data = cache_doc.to_dict()
            timestamp = cache_data.get("timestamp")

            if timestamp:
                age_seconds = time.time() - timestamp
                if age_seconds < 604800:  # 7 days
                    elapsed_time = (time.time() - start_time) * 1000
                    print(f"Smart reply cache HIT in {elapsed_time:.0f}ms (age: {age_seconds/86400:.1f} days)")
                    return {
                        "suggestions": cache_data["suggestions"],
                        "cached": True,
                        "latency": elapsed_time,
                    }

        # Step 2: Cache miss - run full RAG pipeline
        print("Smart reply cache MISS - running full RAG pipeline")

        # Step 2a: Generate embedding for incoming message using Vertex AI (via REST API)
        embedding_start = time.time()
        query_embedding = generate_vertex_ai_embedding(incoming_message_text)
        embedding_ms = (time.time() - embedding_start) * 1000
        print(f"Generated 768D embedding in {embedding_ms:.0f}ms")

        # Step 2b: Perform vector search using find_nearest()
        # Single collection architecture - all conversations in 'conversations' collection
        search_start = time.time()
        messages_ref = db.collection('conversations').document(conversation_id).collection('messages')

        # Perform vector search (find_nearest requires firestore-admin SDK)
        from google.cloud.firestore_v1.base_vector_query import DistanceMeasure

        vector_query = messages_ref.find_nearest(
            vector_field='embedding',
            query_vector=query_embedding,
            distance_measure=DistanceMeasure.COSINE,
            limit=10  # Get top 10 most relevant messages
        )

        search_results = vector_query.stream()
        relevant_messages = []
        for doc in search_results:
            msg_data = doc.to_dict()
            relevant_messages.append({
                'text': msg_data.get('text', ''),
                'senderId': msg_data.get('senderId', ''),
                'timestamp': msg_data.get('timestamp', ''),
            })

        search_ms = (time.time() - search_start) * 1000
        print(f"Vector search completed in {search_ms:.0f}ms, found {len(relevant_messages)} results")

        # Step 2c: Fetch user communication style from Firestore
        style_start = time.time()
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()

        # Default style if user doc doesn't exist
        user_style = {
            'styleDescription': 'neutral, conversational',
            'averageMessageLength': '50',
            'emojiUsageRate': '10%',
            'casualityScore': '0.5',
        }

        if user_doc.exists:
            user_data = user_doc.to_dict()
            communication_style = user_data.get('communicationStyle', {})
            if communication_style:
                user_style = {
                    'styleDescription': communication_style.get('styleDescription', user_style['styleDescription']),
                    'averageMessageLength': str(communication_style.get('averageMessageLength', 50)),
                    'emojiUsageRate': f"{int(communication_style.get('emojiUsageRate', 0.1) * 100)}%",
                    'casualityScore': str(communication_style.get('casualityScore', 0.5)),
                }

        style_ms = (time.time() - style_start) * 1000
        print(f"Fetched user style in {style_ms:.0f}ms")

        # Step 2d: Generate smart replies with GPT-4o-mini
        llm_start = time.time()

        # Build context messages string
        context_str = ""
        if relevant_messages:
            context_messages = []
            for msg in relevant_messages[:5]:  # Limit to top 5 for prompt size
                sender_id = msg.get("senderId", "Unknown")
                text = msg.get("text", "")
                context_messages.append(f"User {sender_id[-4:]}: {text}")
            context_str = "\n".join(context_messages)
        else:
            context_str = "(No recent context available)"

        # Build user style string
        style_description = user_style.get("styleDescription", "neutral, conversational")
        avg_length = user_style.get("averageMessageLength", "50")
        emoji_rate = user_style.get("emojiUsageRate", "10%")
        casualty = user_style.get("casualityScore", "0.5")

        # Construct the prompt for GPT-4o-mini
        system_prompt = (
            "You are an AI assistant that generates smart reply suggestions. "
            "Create 3 brief reply suggestions (<50 chars each) that match the user's communication style. "
            "Each reply should have a different intent: positive (affirmative/friendly), "
            "neutral (balanced/informational), and question (follow-up/clarification). "
            "Always return valid JSON in the exact format specified."
        )

        user_prompt = f"""Generate 3 smart reply suggestions for this incoming message.

Incoming message: "{incoming_message_text}"

Recent conversation context:
{context_str}

User's communication style:
- Description: {style_description}
- Average message length: {avg_length} chars
- Emoji usage rate: {emoji_rate}
- Casualty score: {casualty} (0=formal, 1=casual)

Requirements:
- Each reply must be <50 characters
- Match the user's style (emoji usage, casualty, message length)
- Provide 3 different intents: positive, neutral, question
- Be contextually relevant to the incoming message
- Sound natural and conversational

Return JSON in this exact format:
{{
  "suggestions": [
    {{"text": "positive reply here", "intent": "positive"}},
    {{"text": "neutral reply here", "intent": "neutral"}},
    {{"text": "question reply here", "intent": "question"}}
  ]
}}

Only return the JSON, no additional text."""

        # Get OpenAI client
        client = get_openai_client(OPENAI_API_KEY.value)

        # Call OpenAI API (GPT-4o-mini)
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.7,
            max_tokens=300,
            response_format={"type": "json_object"}
        )

        llm_ms = (time.time() - llm_start) * 1000
        print(f"GPT-4o-mini completed in {llm_ms:.0f}ms")

        # Extract and parse response
        response_text = response.choices[0].message.content.strip()

        # Parse JSON response
        try:
            result = json.loads(response_text)
            suggestions = result.get("suggestions", [])

            # Validate suggestions
            if not suggestions or len(suggestions) != 3:
                raise ValueError(f"Expected 3 suggestions, got {len(suggestions)}")

            # Validate each suggestion
            for suggestion in suggestions:
                if "text" not in suggestion or "intent" not in suggestion:
                    raise ValueError("Each suggestion must have 'text' and 'intent' fields")
                if suggestion["intent"] not in ["positive", "neutral", "question"]:
                    raise ValueError(f"Invalid intent: {suggestion['intent']}")

        except (json.JSONDecodeError, ValueError) as e:
            print(f"Failed to parse or validate JSON response: {e}")
            print(f"Response was: {response_text}")

            # Return fallback suggestions
            suggestions = [
                {"text": "Thanks!", "intent": "positive"},
                {"text": "Got it", "intent": "neutral"},
                {"text": "Can you clarify?", "intent": "question"}
            ]

        # Step 3: Store in cache for future requests (7-day TTL)
        cache_ref.set({
            "conversationId": conversation_id,
            "incomingMessageText": incoming_message_text,
            "userId": user_id,
            "suggestions": suggestions,
            "timestamp": time.time(),
        })

        total_latency = (time.time() - start_time) * 1000
        print(f"Smart reply complete successful in {total_latency:.0f}ms total "
              f"(embed: {embedding_ms:.0f}ms, search: {search_ms:.0f}ms, "
              f"style: {style_ms:.0f}ms, llm: {llm_ms:.0f}ms)")

        return {
            "suggestions": suggestions,
            "cached": False,
            "latency": total_latency,
        }

    except Exception as e:
        print(f"Smart reply complete error: {e}")
        import traceback
        traceback.print_exc()
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Smart reply generation failed: {str(e)}"
        )


@https_fn.on_call()
def search_messages_semantic(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Performs semantic search on messages using Firestore vector search.

    Optimized for speed with aggressive caching and smart defaults.
    Target latency: <100ms (cached) or <500ms (fresh query)

    Args:
        req.data should contain:
            - conversationId (str): The conversation to search within
            - queryEmbedding (list): 1536-dimensional embedding vector
            - limit (int, optional): Max results (default: 5, optimized for speed)

    Returns:
        dict: {
            'messages': List of semantically similar messages,
            'count': Number of results,
            'cached': Whether results were cached,
            'latency': Query execution time in milliseconds
        }

    Performance optimizations:
    - 5-minute result caching (aggressive for demo smoothness)
    - Firestore vector search (server-side cosine similarity)
    - Smaller result set (5 instead of 10) for faster response
    - Minimal payload (exclude embeddings from response)
    """
    start_time = time.time()

    # Extract and validate request data
    data = req.data

    if not isinstance(data, dict):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Request data must be a dictionary"
        )

    conversation_id = data.get("conversationId")
    query_embedding = data.get("queryEmbedding")
    limit = data.get("limit", 5)  # Default 5 for speed

    # Validate required fields
    if not conversation_id or not isinstance(conversation_id, str):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'conversationId' field is required and must be a string"
        )

    if not query_embedding or not isinstance(query_embedding, list):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'queryEmbedding' field is required and must be a list"
        )

    if len(query_embedding) != 1536:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"'queryEmbedding' must be 1536 dimensions, got {len(query_embedding)}"
        )

    if not isinstance(limit, int) or limit < 1 or limit > 100:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="'limit' must be an integer between 1 and 100"
        )

    print(f"Semantic search: conversation={conversation_id}, limit={limit}")

    try:
        # Step 1: Check cache (5-minute TTL for demo smoothness)
        import hashlib
        import json

        db = firestore.client()

        # Create cache key from hash of inputs
        cache_input = {
            "conversationId": conversation_id,
            "queryEmbedding": query_embedding,
            "limit": limit,
        }
        cache_key_hash = hashlib.sha256(
            json.dumps(cache_input, sort_keys=True).encode('utf-8')
        ).hexdigest()

        cache_collection = db.collection("semantic_search_cache")
        cache_ref = cache_collection.document(cache_key_hash)
        cache_doc = cache_ref.get()

        # Check if cache entry exists and is not expired (5 minutes = 300 seconds)
        if cache_doc.exists:
            cache_data = cache_doc.to_dict()
            timestamp = cache_data.get("timestamp")

            if timestamp:
                age_seconds = time.time() - timestamp
                if age_seconds < 300:  # 5 minutes
                    elapsed_ms = (time.time() - start_time) * 1000
                    print(f"Semantic search cache HIT ({elapsed_ms:.1f}ms, age: {age_seconds:.1f}s)")

                    return {
                        "messages": cache_data["messages"],
                        "count": len(cache_data["messages"]),
                        "cached": True,
                        "latency": elapsed_ms,
                    }

        # Step 2: Cache miss - perform Firestore vector search
        print("Semantic search cache MISS - querying Firestore")

        # Import vector search dependencies
        from google.cloud.firestore_v1.vector import Vector
        from google.cloud.firestore_v1.base_vector_query import DistanceMeasure

        # Get messages collection for this conversation
        messages_ref = db.collection_group("messages")

        # Perform k-NN vector search with Firestore
        vector_query = messages_ref.find_nearest(
            vector_field="embedding",
            query_vector=Vector(query_embedding),
            distance_measure=DistanceMeasure.COSINE,
            limit=limit * 2,  # Get more candidates for filtering
        ).where("conversationId", "==", conversation_id)

        # Execute query
        results = vector_query.get()

        # Convert to list and format (exclude embeddings to reduce payload)
        messages = []
        for doc in results:
            try:
                message_data = doc.to_dict()

                # Format for response (remove embedding to reduce payload size)
                formatted_message = {
                    "id": doc.id,
                    "text": message_data.get("text", ""),
                    "senderId": message_data.get("senderId", ""),
                    "timestamp": message_data.get("timestamp"),
                    "detectedLanguage": message_data.get("detectedLanguage"),
                    "translations": message_data.get("translations"),
                    # embedding excluded for performance
                }

                messages.append(formatted_message)

                # Stop once we have enough results
                if len(messages) >= limit:
                    break

            except Exception as e:
                print(f"Error processing message {doc.id}: {e}")
                continue

        elapsed_ms = (time.time() - start_time) * 1000
        print(f"Semantic search found {len(messages)} messages in {elapsed_ms:.1f}ms")

        # Step 3: Cache the results for 5 minutes
        cache_ref.set({
            "conversationId": conversation_id,
            "messages": messages,
            "timestamp": time.time(),
            "limit": limit,
        })

        return {
            "messages": messages,
            "count": len(messages),
            "cached": False,
            "latency": elapsed_ms,
        }

    except Exception as e:
        print(f"Semantic search error: {e}")
        import traceback
        traceback.print_exc()

        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Semantic search failed: {str(e)}"
        )


@https_fn.on_call(secrets=[OPENAI_API_KEY])
def analyze_message_context(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Analyzes a message for cultural context, formality, and idioms using GPT-4o-mini.

    This unified function replaces both analyze_cultural_context and explain_idioms,
    providing comprehensive cultural analysis in a single API call.

    Args:
        req.data should contain:
            - text (str): The text to analyze
            - language (str): Language code (e.g., 'en', 'es')

    Returns:
        dict: {
            'culturalHint': str | None,      # Brief 1-sentence summary
            'formality': str | None,         # 'very formal', 'formal', 'neutral', 'casual', 'very casual'
            'culturalNote': str | None,      # Detailed cultural explanation
            'idioms': [                      # List of idioms found
                {
                    'phrase': str,
                    'meaning': str,
                    'culturalNote': str,
                    'equivalentIn': {language_code: equivalent_phrase}
                }
            ],
            'cached': bool
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

    # Log message context request
    print(f"Message context analysis request: '{text[:50]}...' (lang: {language})")

    try:
        start_time = time.time()

        # Step 1: Check cache first (30-day TTL for cost reduction)
        db = firestore.client()
        cache_collection = db.collection("message_context_cache")

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
                    print(f"Message context cache HIT in {elapsed_time:.3f}s (age: {age_seconds/86400:.1f} days)")

                    return {
                        "culturalHint": cache_data.get("culturalHint"),
                        "formality": cache_data.get("formality"),
                        "culturalNote": cache_data.get("culturalNote"),
                        "idioms": cache_data.get("idioms", []),
                        "cached": True,
                        "cacheAge": age_seconds,
                    }

        # Step 2: Cache miss - call OpenAI API
        print("Message context cache MISS - calling OpenAI API")

        # Get OpenAI client
        client = get_openai_client(OPENAI_API_KEY.value)

        # Construct the unified prompt for GPT-4o-mini
        system_prompt = (
            "You are a language expert specializing in cultural analysis, formality detection, "
            "and idiomatic expressions. Analyze messages comprehensively for cultural nuances, "
            "formality level, and idioms/slang. Always return valid JSON."
        )

        user_prompt = f"""Analyze this message for cultural context, formality, and idioms.

Language: {language}
Message: "{text}"

Provide a comprehensive analysis in JSON format:
1. culturalHint: Brief 1-sentence summary of key cultural aspects (or null if none)
2. formality: Assess formality level - choose from: "very formal", "formal", "neutral", "casual", "very casual" (or null if unclear)
3. culturalNote: Detailed explanation of cultural nuances, greetings, customs, or references that might not be obvious to non-native speakers (or null if none)
4. idioms: Array of idioms, slang, or colloquialisms found in the message

For each idiom, provide:
- phrase: exact phrase from the message
- meaning: clear explanation of what it means
- culturalNote: cultural context or origin
- equivalentIn: equivalent expressions in 6-8 major languages (en, es, fr, de, zh, ja, ar, pt)

Return JSON in this exact format:
{{
  "culturalHint": "brief summary or null",
  "formality": "very formal|formal|neutral|casual|very casual or null",
  "culturalNote": "detailed explanation or null",
  "idioms": [
    {{
      "phrase": "exact phrase",
      "meaning": "explanation",
      "culturalNote": "cultural context",
      "equivalentIn": {{"es": "equivalent in Spanish", "fr": "equivalent in French", ...}}
    }}
  ]
}}

If the message is straightforward with no cultural context, return all fields as null except idioms as empty array.
Only return the JSON, no additional text."""

        # Call OpenAI API (GPT-4o-mini)
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.3,  # Lower temperature for consistent analysis
            max_tokens=1000,   # Allow for detailed analysis
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
            result = {
                "culturalHint": None,
                "formality": None,
                "culturalNote": None,
                "idioms": []
            }

        # Extract fields with defaults
        cultural_hint = result.get("culturalHint")
        formality = result.get("formality")
        cultural_note = result.get("culturalNote")
        idioms = result.get("idioms", [])

        # Step 3: Store in cache for future requests (30-day TTL)
        cache_ref.set({
            "text": text,
            "language": language,
            "culturalHint": cultural_hint,
            "formality": formality,
            "culturalNote": cultural_note,
            "idioms": idioms,
            "timestamp": time.time(),
        })

        print(f"Message context analysis successful in {elapsed_time:.2f}s: "
              f"formality={formality}, idioms={len(idioms)}, "
              f"{'has cultural context' if cultural_hint else 'no cultural context'}")

        return {
            "culturalHint": cultural_hint,
            "formality": formality,
            "culturalNote": cultural_note,
            "idioms": idioms,
            "cached": False,
        }

    except Exception as e:
        print(f"Message context analysis error: {e}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Message context analysis failed: {str(e)}"
        )
