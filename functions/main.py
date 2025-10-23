"""
Firebase Cloud Functions for MessageAI

This module contains serverless functions that run in response to Firebase events.
Currently implements:
- Push notification delivery when new messages are created
- Translation API for real-time message translation
- Display name propagation when users update their profile
"""

from firebase_functions import firestore_fn, https_fn, options
from firebase_admin import initialize_app, firestore, messaging
from google.cloud import translate_v2 as translate
from google.cloud import secretmanager
import google.cloud.firestore
from typing import Any
import time
import os

# Initialize Firebase Admin SDK
app = initialize_app()

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
    Scheduled function to clean up expired translation cache and rate limit entries.

    Removes:
    - Cache entries older than 24 hours
    - Rate limit entries older than 2 hours (past their hour window)

    Should be triggered via Cloud Scheduler (e.g., daily at 2 AM).

    Can also be called manually:
        curl https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/clean_translation_cache

    Returns:
        JSON with cleanup stats: { cacheDeleted, rateLimitDeleted, errors }
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

        print(f"Rate limit cleanup: deleted {rate_limit_deleted} entries")
        print(f"Total cleanup complete: cache={cache_deleted}, rateLimit={rate_limit_deleted}, errors={error_count}")

        return https_fn.Response(
            response=f'{{"cacheDeleted": {cache_deleted}, "rateLimitDeleted": {rate_limit_deleted}, "errors": {error_count}}}',
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


@firestore_fn.on_document_updated(document="users/{userId}")
def propagate_display_name_changes(
    event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot | None]],
) -> None:
    """
    Propagates user display name changes to all their messages.

    Triggered by: User document update in users/{userId}
    Action: If displayName changed, update senderName in all messages from this user

    This ensures other users see the updated display name immediately for all
    past and future messages. Implements proper multi-user cache invalidation.
    """
    if event.data is None:
        return

    # Get before and after snapshots
    before_data = event.data.before.to_dict() if event.data.before else None
    after_data = event.data.after.to_dict() if event.data.after else None

    if not before_data or not after_data:
        return

    # Check if displayName changed
    old_name = before_data.get("displayName", "")
    new_name = after_data.get("displayName", "")

    if old_name == new_name:
        return  # No change, skip processing

    user_id = event.params["userId"]
    print(f"📝 Display name changed for user {user_id}: '{old_name}' -> '{new_name}'")

    # Get Firestore client
    db = firestore.client()

    # Batch write for efficiency (max 500 operations per batch)
    batch = db.batch()
    batch_count = 0
    total_updated = 0

    try:
        # Update messages in direct conversations
        conversations_ref = db.collection("conversations")
        for conversation_doc in conversations_ref.stream():
            messages_ref = conversation_doc.reference.collection("messages")
            query = messages_ref.where("senderId", "==", user_id)

            for message_doc in query.stream():
                batch.update(message_doc.reference, {"senderName": new_name})
                batch_count += 1
                total_updated += 1

                # Commit batch if it reaches 500 operations
                if batch_count >= 500:
                    batch.commit()
                    print(f"✅ Committed batch of 500 updates (total: {total_updated})")
                    batch = db.batch()  # Start new batch
                    batch_count = 0

        # Update messages in group conversations
        group_conversations_ref = db.collection("group-conversations")
        for conversation_doc in group_conversations_ref.stream():
            messages_ref = conversation_doc.reference.collection("messages")
            query = messages_ref.where("senderId", "==", user_id)

            for message_doc in query.stream():
                batch.update(message_doc.reference, {"senderName": new_name})
                batch_count += 1
                total_updated += 1

                # Commit batch if it reaches 500 operations
                if batch_count >= 500:
                    batch.commit()
                    print(f"✅ Committed batch of 500 updates (total: {total_updated})")
                    batch = db.batch()  # Start new batch
                    batch_count = 0

        # Update lastMessageSenderName in conversations where this user sent the last message
        query = conversations_ref.where("lastMessageSenderId", "==", user_id)
        for conv_doc in query.stream():
            batch.update(conv_doc.reference, {"lastMessageSenderName": new_name})
            batch_count += 1
            total_updated += 1

            if batch_count >= 500:
                batch.commit()
                print(f"✅ Committed batch of 500 updates (total: {total_updated})")
                batch = db.batch()
                batch_count = 0

        # Update lastMessageSenderName in group conversations
        query = group_conversations_ref.where("lastMessageSenderId", "==", user_id)
        for conv_doc in query.stream():
            batch.update(conv_doc.reference, {"lastMessageSenderName": new_name})
            batch_count += 1
            total_updated += 1

            if batch_count >= 500:
                batch.commit()
                print(f"✅ Committed batch of 500 updates (total: {total_updated})")
                batch = db.batch()
                batch_count = 0

        # Commit remaining updates
        if batch_count > 0:
            batch.commit()
            print(f"✅ Committed final batch of {batch_count} updates")

        print(f"✨ Successfully updated {total_updated} documents with new display name")

    except Exception as e:
        print(f"❌ Error propagating display name: {e}")
        # Don't raise - this shouldn't block the user profile update
