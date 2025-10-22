"""
Firebase Cloud Functions for MessageAI

This module contains serverless functions that run in response to Firebase events.
Currently implements push notification delivery when new messages are created.
"""

from firebase_functions import firestore_fn, options
from firebase_admin import initialize_app, firestore, messaging
import google.cloud.firestore

# Initialize Firebase Admin SDK
app = initialize_app()

# Cost control: Limit concurrent function instances
options.set_global_options(max_instances=10)


@firestore_fn.on_document_created(
    document="conversations/{conversationId}/messages/{messageId}"
)
def send_message_notification(
    event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None],
) -> None:
    """
    Sends push notifications when a new message is created.

    Triggered by: New document in conversations/{conversationId}/messages/
    Action: Sends FCM notification to all conversation participants except sender

    Flow:
    1. Extract message data from created document
    2. Get conversation participants
    3. Look up FCM tokens for each participant (except sender)
    4. Send notification to each token
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

    print(f"New message from {sender_name} in conversation {conversation_id}")

    # Get conversation to find participants
    db = firestore.client()
    conversation_ref = db.collection("conversations").document(conversation_id)
    conversation = conversation_ref.get()

    if not conversation.exists:
        # Try group-conversations collection
        conversation_ref = db.collection("group-conversations").document(
            conversation_id
        )
        conversation = conversation_ref.get()

        if not conversation.exists:
            print(f"Conversation {conversation_id} not found")
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

    # Send notification to each participant (except sender)
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

        # Send notification to each token
        for token in fcm_tokens:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=sender_name,
                        body=message_text[:100],  # Truncate long messages
                    ),
                    data={
                        "conversationId": conversation_id,
                        "senderId": sender_id,
                        "type": "new_message",
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
                print(f"Sent notification to {participant_id}: {response}")

            except Exception as e:
                print(f"Failed to send notification to {participant_id}: {e}")
                # Continue to next token even if one fails


@firestore_fn.on_document_created(
    document="group-conversations/{conversationId}/messages/{messageId}"
)
def send_group_message_notification(
    event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None],
) -> None:
    """
    Sends push notifications for group messages.

    Same logic as send_message_notification but for group-conversations collection.
    """
    # Reuse the same logic - just different collection path
    send_message_notification(event)
