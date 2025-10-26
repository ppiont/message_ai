/// Remote data source for messages stored in Firestore
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/features/messaging/data/models/message_model.dart';

/// Abstract interface for remote message data operations.
abstract class MessageRemoteDataSource {
  /// Creates a new message in a conversation
  Future<MessageModel> createMessage(
    String conversationId,
    MessageModel message,
  );

  /// Retrieves a message by ID from a conversation
  Future<MessageModel> getMessageById(String conversationId, String messageId);

  /// Retrieves messages for a conversation with pagination
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int limit = 50,
    DateTime? before,
  });

  /// Updates an existing message
  Future<MessageModel> updateMessage(
    String conversationId,
    MessageModel message,
  );

  /// Deletes a message (or marks as deleted)
  Future<void> deleteMessage(String conversationId, String messageId);

  /// Watches messages in a conversation in real-time
  Stream<List<MessageModel>> watchMessages({
    required String conversationId,
    int limit = 50,
  });

  /// Marks a message as delivered for a specific user
  Future<void> markAsDelivered(
    String conversationId,
    String messageId,
    String userId,
  );

  /// Marks a message as read for a specific user
  Future<void> markAsRead(
    String conversationId,
    String messageId,
    String userId,
  );

  /// Gets status records for a message from Firestore subcollections
  ///
  /// Returns a list of status records (userId, status, timestamp) for all users
  /// who have interacted with the message. Used by senders to see delivery/read status.
  Future<List<Map<String, dynamic>>> getMessageStatus(
    String conversationId,
    String messageId,
  );

  /// Watches status changes for a message in real-time
  ///
  /// Returns a stream of status records that updates whenever recipients mark
  /// messages as delivered/read. Used by senders for instant status updates.
  Stream<List<Map<String, dynamic>>> watchMessageStatus(
    String conversationId,
    String messageId,
  );

  /// Watches all status changes for a conversation in real-time
  ///
  /// Returns a stream of ALL status records for all messages in the conversation.
  /// Uses collectionGroup query with conversationId filter for efficient real-time updates.
  /// Updates whenever any recipient marks any message as delivered/read in this conversation.
  Stream<List<Map<String, dynamic>>> watchConversationStatus(
    String conversationId,
  );
}

/// Implementation of [MessageRemoteDataSource] using Firebase Firestore.
class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  MessageRemoteDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;
  final FirebaseFirestore _firestore;

  static const String _conversationsCollection = 'conversations';
  static const String _messagesSubcollection = 'messages';

  /// Helper to get messages collection reference for a conversation.
  CollectionReference<Map<String, dynamic>> _messagesRef(
    String conversationId,
  ) => _firestore
      .collection(_conversationsCollection)
      .doc(conversationId)
      .collection(_messagesSubcollection);

  @override
  Future<MessageModel> createMessage(
    String conversationId,
    MessageModel message,
  ) async {
    try {
      final messagesRef = _messagesRef(conversationId);
      final docRef = messagesRef.doc(message.id);

      // Check if message already exists
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        throw RecordAlreadyExistsException(
          recordType: 'Message',
          recordId: message.id,
        );
      }

      // Create the message document
      await docRef.set(message.toJson());

      // Return the created message
      return message;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(
        message: 'Failed to create message',
        originalError: e,
      );
    }
  }

  @override
  Future<MessageModel> getMessageById(
    String conversationId,
    String messageId,
  ) async {
    try {
      final messagesRef = _messagesRef(conversationId);
      final docSnapshot = await messagesRef.doc(messageId).get();

      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'Message',
          recordId: messageId,
        );
      }

      return MessageModel.fromJson(docSnapshot.data()!);
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(
        message: 'Failed to get message',
        originalError: e,
      );
    }
  }

  @override
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      final messagesRef = _messagesRef(conversationId);
      var query = messagesRef
          .orderBy('timestamp', descending: true)
          .limit(limit);

      // Add pagination if before timestamp is provided
      if (before != null) {
        query = query.where('timestamp', isLessThan: before);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(
        message: 'Failed to get messages',
        originalError: e,
      );
    }
  }

  @override
  Future<MessageModel> updateMessage(
    String conversationId,
    MessageModel message,
  ) async {
    try {
      final messagesRef = _messagesRef(conversationId);
      final docRef = messagesRef.doc(message.id);

      // Check if message exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'Message',
          recordId: message.id,
        );
      }

      // Update the message document
      await docRef.update(message.toJson());

      // Return the updated message
      return message;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(
        message: 'Failed to update message',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      // For a chat app, we might prefer soft delete (marking as deleted)
      // For now, we'll do hard delete for simplicity in MVP
      final messagesRef = _messagesRef(conversationId);
      await messagesRef.doc(messageId).delete();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(
        message: 'Failed to delete message',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<MessageModel>> watchMessages({
    required String conversationId,
    int limit = 50,
  }) {
    try {
      final messagesRef = _messagesRef(conversationId);
      return messagesRef
          .orderBy(
            'timestamp',
            descending: false,
          ) // Oldest first (standard chat order)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => MessageModel.fromJson(doc.data()))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(
        message: 'Failed to watch messages',
        originalError: e,
      );
    }
  }

  @override
  Future<void> markAsDelivered(
    String conversationId,
    String messageId,
    String userId,
  ) async {
    try {
      final messagesRef = _messagesRef(conversationId);

      // Check current status first - don't downgrade from 'read' to 'delivered'
      final statusDoc = await messagesRef
          .doc(messageId)
          .collection('status')
          .doc(userId)
          .get();

      final currentStatus = statusDoc.data()?['status'] as String?;

      // Only mark as delivered if:
      // 1. No status exists yet (first time)
      // 2. Current status is 'sent' (upgrade to delivered)
      // Never downgrade from 'read' to 'delivered'
      if (currentStatus == null || currentStatus == 'sent') {
        await messagesRef.doc(messageId).collection('status').doc(userId).set({
          'status': 'delivered',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': userId,
          'conversationId': conversationId, // For collectionGroup filtering
          'messageId': messageId, // For collectionGroup filtering
        });
      }
      // If already 'read', do nothing (don't downgrade)
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(
        message: 'Failed to mark message as delivered',
        originalError: e,
      );
    }
  }

  @override
  Future<void> markAsRead(
    String conversationId,
    String messageId,
    String userId,
  ) async {
    try {
      final messagesRef = _messagesRef(conversationId);

      // Use subcollection structure for efficient status tracking:
      // messages/{messageId}/status/{userId}
      await messagesRef.doc(messageId).collection('status').doc(userId).set({
        'status': 'read',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'conversationId': conversationId, // For collectionGroup filtering
        'messageId': messageId, // For collectionGroup filtering
      }); // No merge needed for read - it's the final state
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(
        message: 'Failed to mark message as read',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMessageStatus(
    String conversationId,
    String messageId,
  ) async {
    try {
      final messagesRef = _messagesRef(conversationId);

      // Query the status subcollection for all users
      final statusSnapshot = await messagesRef
          .doc(messageId)
          .collection('status')
          .get();

      // Convert to list of maps
      return statusSnapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(
        message: 'Failed to get message status',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMessageStatus(
    String conversationId,
    String messageId,
  ) {
    try {
      final messagesRef = _messagesRef(conversationId);
      return messagesRef
          .doc(messageId)
          .collection('status')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(
        message: 'Failed to watch message status',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchConversationStatus(
    String conversationId,
  ) {
    try {
      // Use collectionGroup to watch ALL status subcollections
      // Filter by conversationId to scope to this conversation only
      return _firestore
          .collectionGroup('status')
          .where('conversationId', isEqualTo: conversationId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw UnknownException(
        message: 'Failed to watch conversation status',
        originalError: e,
      );
    }
  }

  /// Map Firestore exceptions to app exceptions
  AppException _mapFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const UnauthorizedException(
          message: 'You do not have permission to access this resource',
        );
      case 'not-found':
        return const RecordNotFoundException(recordType: 'Document');
      case 'already-exists':
        return const RecordAlreadyExistsException(recordType: 'Document');
      case 'resource-exhausted':
        return const RateLimitExceededException();
      case 'failed-precondition':
        return const ConstraintViolationException(
          message: 'Operation failed due to constraint violation',
        );
      case 'aborted':
        return const ServerException(
          message: 'Operation was aborted. Please try again',
        );
      case 'out-of-range':
        return const ValidationException(
          message: 'Invalid range for operation',
          fieldErrors: {},
        );
      case 'unimplemented':
        return const NotImplementedException(
          message: 'This operation is not implemented',
        );
      case 'unavailable':
        return const NoInternetException();
      case 'deadline-exceeded':
        return const NetworkTimeoutException();
      default:
        return ServerException(message: 'Firestore error: ${e.message}');
    }
  }
}
