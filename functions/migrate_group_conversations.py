#!/usr/bin/env python3
"""
Firestore Migration Script: Move group-conversations to conversations collection

This script migrates all documents from the 'group-conversations' collection
to the unified 'conversations' collection, including all messages and status
subcollections.

Usage:
    python3 migrate_group_conversations.py [--dry-run] [--delete-old]

Arguments:
    --dry-run: Preview what would be migrated without making changes
    --delete-old: Delete old group-conversations collection after migration
"""

import argparse
import sys
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.base_query import FieldFilter


def initialize_firebase() -> firestore.Client:
    """Initialize Firebase Admin SDK and return Firestore client."""
    if not firebase_admin._apps:
        # Initialize with default credentials (ADC or service account)
        firebase_admin.initialize_app()
    return firestore.client()


def migrate_conversations(
    db: firestore.Client,
    dry_run: bool = False,
    delete_old: bool = False,
) -> dict[str, int]:
    """
    Migrate all group conversations to the unified conversations collection.

    Args:
        db: Firestore client
        dry_run: If True, only preview changes without writing
        delete_old: If True, delete old collection after migration

    Returns:
        Dictionary with migration statistics
    """
    stats = {
        "conversations_migrated": 0,
        "messages_migrated": 0,
        "status_docs_migrated": 0,
        "errors": 0,
    }

    # Get all documents from group-conversations
    group_conversations_ref = db.collection("group-conversations")
    group_conversations = group_conversations_ref.stream()

    print("Starting migration from 'group-conversations' to 'conversations'...")
    print(f"Dry run: {dry_run}")
    print(f"Delete old collection: {delete_old}")
    print("-" * 60)

    for group_conv_doc in group_conversations:
        conversation_id = group_conv_doc.id
        conversation_data = group_conv_doc.to_dict()

        print(f"\n📄 Processing conversation: {conversation_id}")
        print(f"   Type: {conversation_data.get('type', 'unknown')}")
        print(f"   Group name: {conversation_data.get('groupName', 'N/A')}")
        print(
            f"   Participants: {len(conversation_data.get('participantIds', []))}",
        )

        try:
            # Check if conversation already exists in target collection
            target_ref = db.collection("conversations").document(conversation_id)
            target_doc = target_ref.get()

            if target_doc.exists:
                print(f"   ⚠️  Already exists in 'conversations', skipping...")
                continue

            if not dry_run:
                # Copy conversation document
                target_ref.set(conversation_data)
                print(f"   ✅ Copied conversation document")
            else:
                print(f"   [DRY RUN] Would copy conversation document")

            stats["conversations_migrated"] += 1

            # Migrate messages subcollection
            messages_ref = group_conv_doc.reference.collection("messages")
            messages = messages_ref.stream()

            for message_doc in messages:
                message_id = message_doc.id
                message_data = message_doc.to_dict()

                if not dry_run:
                    # Copy message document
                    target_message_ref = (
                        target_ref.collection("messages").document(message_id)
                    )
                    target_message_ref.set(message_data)
                else:
                    print(f"      [DRY RUN] Would copy message: {message_id}")

                stats["messages_migrated"] += 1

                # Migrate status subcollection for this message
                status_ref = message_doc.reference.collection("status")
                status_docs = status_ref.stream()

                for status_doc in status_docs:
                    status_id = status_doc.id
                    status_data = status_doc.to_dict()

                    if not dry_run:
                        # Copy status document
                        target_status_ref = (
                            target_ref.collection("messages")
                            .document(message_id)
                            .collection("status")
                            .document(status_id)
                        )
                        target_status_ref.set(status_data)
                    else:
                        print(
                            f"         [DRY RUN] Would copy status doc: {status_id}",
                        )

                    stats["status_docs_migrated"] += 1

            print(
                f"   ✅ Migrated {stats['messages_migrated']} messages with status docs",
            )

            # Delete old conversation if requested
            if delete_old and not dry_run:
                print(f"   🗑️  Deleting old conversation from group-conversations...")
                # Delete all status docs
                for message_doc in messages_ref.stream():
                    status_ref = message_doc.reference.collection("status")
                    for status_doc in status_ref.stream():
                        status_doc.reference.delete()
                    message_doc.reference.delete()
                # Delete conversation doc
                group_conv_doc.reference.delete()
                print(f"   ✅ Deleted old conversation")

        except Exception as e:
            print(f"   ❌ Error migrating conversation {conversation_id}: {e}")
            stats["errors"] += 1

    return stats


def main() -> None:
    """Main entry point for migration script."""
    parser = argparse.ArgumentParser(
        description="Migrate group-conversations to conversations collection",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without writing to Firestore",
    )
    parser.add_argument(
        "--delete-old",
        action="store_true",
        help="Delete old group-conversations collection after migration",
    )

    args = parser.parse_args()

    # Initialize Firestore
    try:
        db = initialize_firebase()
        print("✅ Connected to Firestore")
    except Exception as e:
        print(f"❌ Failed to connect to Firestore: {e}")
        sys.exit(1)

    # Run migration
    stats = migrate_conversations(
        db,
        dry_run=args.dry_run,
        delete_old=args.delete_old,
    )

    # Print summary
    print("\n" + "=" * 60)
    print("MIGRATION SUMMARY")
    print("=" * 60)
    print(f"Conversations migrated: {stats['conversations_migrated']}")
    print(f"Messages migrated: {stats['messages_migrated']}")
    print(f"Status documents migrated: {stats['status_docs_migrated']}")
    print(f"Errors: {stats['errors']}")

    if args.dry_run:
        print("\n⚠️  This was a DRY RUN - no changes were made to Firestore")
        print("Run without --dry-run to perform the actual migration")
    else:
        print("\n✅ Migration completed successfully!")

    if stats["errors"] > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
