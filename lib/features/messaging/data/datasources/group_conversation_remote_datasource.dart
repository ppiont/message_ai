/// Remote data source for group conversations stored in Firestore
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/features/messaging/data/models/conversation_model.dart';

/// Abstract interface for remote group conversation data operations.
abstract class GroupConversationRemoteDataSource {
  /// Creates a new group conversation
  Future<ConversationModel> createGroup(ConversationModel group);

  /// Retrieves a group conversation by ID
  Future<ConversationModel> getGroupById(String groupId);

  /// Retrieves group conversations for a specific user
  Future<List<ConversationModel>> getGroupsForUser(
    String userId, {
    int limit = 50,
    DateTime? before,
  });

  /// Updates an existing group conversation
  Future<ConversationModel> updateGroup(ConversationModel group);

  /// Deletes a group conversation
  Future<void> deleteGroup(String groupId);

  /// Watches group conversations for a user in real-time
  Stream<List<ConversationModel>> watchGroupsForUser(
    String userId, {
    int limit = 50,
  });

  /// Adds a member to a group
  Future<void> addMember(
    String groupId,
    String userId,
    String userName,
    String preferredLanguage,
  );

  /// Removes a member from a group
  Future<void> removeMember(String groupId, String userId);

  /// Updates group information (name, image, description)
  Future<void> updateGroupInfo({
    required String groupId,
    String? groupName,
    String? groupImage,
  });

  /// Promotes a member to admin
  Future<void> promoteToAdmin(String groupId, String userId);

  /// Demotes an admin to regular member
  Future<void> demoteFromAdmin(String groupId, String userId);

  /// Updates the last message in a group
  Future<void> updateLastMessage(
    String groupId,
    String messageText,
    String senderId,
    DateTime timestamp,
  );

  /// Updates unread count for a user in a group
  Future<void> updateUnreadCount(String groupId, String userId, int count);
}

/// Implementation of [GroupConversationRemoteDataSource] using Firebase Firestore.
class GroupConversationRemoteDataSourceImpl
    implements GroupConversationRemoteDataSource {

  GroupConversationRemoteDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;
  final FirebaseFirestore _firestore;

  static const String _groupsCollection = 'group-conversations';

  CollectionReference<Map<String, dynamic>> get _groupsRef =>
      _firestore.collection(_groupsCollection);

  @override
  Future<ConversationModel> createGroup(ConversationModel group) async {
    try {
      final docRef = _groupsRef.doc(group.documentId);

      // Check if group already exists
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        throw RecordAlreadyExistsException(
          recordType: 'GroupConversation',
          recordId: group.documentId,
        );
      }

      // Validate group fields
      if (group.type != 'group') {
        throw const ValidationException(message: 'Conversation type must be "group"');
      }

      if (group.participantIds.length < 2) {
        throw const ValidationException(
          message: 'Group must have at least 2 participants',
        );
      }

      if (group.groupName == null || group.groupName!.isEmpty) {
        throw const ValidationException(message: 'Group name is required');
      }

      if (group.adminIds == null || group.adminIds!.isEmpty) {
        throw const ValidationException(
          message: 'Group must have at least one admin',
        );
      }

      // Create the group document
      await docRef.set(group.toJson());

      // Return the created group
      return group;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to create group',
        originalError: e,
      );
    }
  }

  @override
  Future<ConversationModel> getGroupById(String groupId) async {
    try {
      final docSnapshot = await _groupsRef.doc(groupId).get();

      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: groupId,
        );
      }

      final data = docSnapshot.data();
      if (data == null) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: groupId,
        );
      }

      return ConversationModel.fromJson(data);
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to retrieve group',
        originalError: e,
      );
    }
  }

  @override
  Future<List<ConversationModel>> getGroupsForUser(
    String userId, {
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      var query = _groupsRef
          .where('participantIds', arrayContains: userId)
          .orderBy('lastUpdatedAt', descending: true)
          .limit(limit);

      if (before != null) {
        query = query.where(
          'lastUpdatedAt',
          isLessThan: Timestamp.fromDate(before),
        );
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ConversationModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to retrieve groups for user',
        originalError: e,
      );
    }
  }

  @override
  Future<ConversationModel> updateGroup(ConversationModel group) async {
    try {
      final docRef = _groupsRef.doc(group.documentId);

      // Check if group exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: group.documentId,
        );
      }

      // Update the group document
      await docRef.update(group.toJson());

      // Return the updated group
      return group;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to update group',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      final docRef = _groupsRef.doc(groupId);

      // Check if group exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: groupId,
        );
      }

      // Delete the group document
      await docRef.delete();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to delete group',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<ConversationModel>> watchGroupsForUser(
    String userId, {
    int limit = 50,
  }) {
    try {
      return _groupsRef
          .where('participantIds', arrayContains: userId)
          .orderBy('lastUpdatedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
                .map((doc) => ConversationModel.fromJson(doc.data()))
                .toList());
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to watch groups for user',
        originalError: e,
      );
    }
  }

  @override
  Future<void> addMember(
    String groupId,
    String userId,
    String userName,
    String preferredLanguage,
  ) async {
    try {
      final docRef = _groupsRef.doc(groupId);

      // Check if group exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: groupId,
        );
      }

      // Add member to participants array
      await docRef.update({
        'participantIds': FieldValue.arrayUnion([userId]),
        'participants': FieldValue.arrayUnion([
          {
            'uid': userId,
            'name': userName,
            'preferredLanguage': preferredLanguage,
          },
        ]),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to add member to group',
        originalError: e,
      );
    }
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    try {
      final docRef = _groupsRef.doc(groupId);

      // Check if group exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: groupId,
        );
      }

      final data = docSnapshot.data();
      if (data == null) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: groupId,
        );
      }

      // Get current participants
      final participants = data['participants'] as List<dynamic>? ?? [];
      // ignore: avoid_dynamic_calls
      final updatedParticipants = participants
          .where((p) => p['uid'] != userId)
          .toList();

      // Remove member from participants array
      await docRef.update({
        'participantIds': FieldValue.arrayRemove([userId]),
        'participants': updatedParticipants,
        'adminIds': FieldValue.arrayRemove([
          userId,
        ]), // Also remove from admins if present
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to remove member from group',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateGroupInfo({
    required String groupId,
    String? groupName,
    String? groupImage,
  }) async {
    try {
      final docRef = _groupsRef.doc(groupId);

      // Check if group exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: groupId,
        );
      }

      // Build update map
      final updates = <String, dynamic>{
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (groupName != null) {
        updates['groupName'] = groupName;
      }

      if (groupImage != null) {
        updates['groupImage'] = groupImage;
      }

      // Update group info
      await docRef.update(updates);
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to update group info',
        originalError: e,
      );
    }
  }

  @override
  Future<void> promoteToAdmin(String groupId, String userId) async {
    try {
      final docRef = _groupsRef.doc(groupId);

      // Check if group exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: groupId,
        );
      }

      // Add user to admins array
      await docRef.update({
        'adminIds': FieldValue.arrayUnion([userId]),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to promote member to admin',
        originalError: e,
      );
    }
  }

  @override
  Future<void> demoteFromAdmin(String groupId, String userId) async {
    try {
      final docRef = _groupsRef.doc(groupId);

      // Check if group exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: groupId,
        );
      }

      // Remove user from admins array
      await docRef.update({
        'adminIds': FieldValue.arrayRemove([userId]),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to demote admin',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateLastMessage(
    String groupId,
    String messageText,
    String senderId,
    DateTime timestamp,
  ) async {
    try {
      final docRef = _groupsRef.doc(groupId);

      // Check if group exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: groupId,
        );
      }

      // Update last message
      await docRef.update({
        'lastMessage': {
          'text': messageText,
          'senderId': senderId,
          'timestamp': Timestamp.fromDate(timestamp),
          'type': 'text',
        },
        'lastUpdatedAt': Timestamp.fromDate(timestamp),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to update last message',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateUnreadCount(
    String groupId,
    String userId,
    int count,
  ) async {
    try {
      final docRef = _groupsRef.doc(groupId);

      // Check if group exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'GroupConversation',
          recordId: groupId,
        );
      }

      // Update unread count for user
      await docRef.update({'unreadCount.$userId': count});
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to update unread count',
        originalError: e,
      );
    }
  }

  /// Maps Firebase exceptions to application exceptions
  AppException _mapFirestoreException(FirebaseException exception) {
    switch (exception.code) {
      case 'permission-denied':
        return const UnauthorizedException(
          message: 'Permission denied to access group conversation',
        );
      case 'not-found':
        return const RecordNotFoundException(recordType: 'GroupConversation');
      case 'already-exists':
        return const RecordAlreadyExistsException(recordType: 'GroupConversation');
      case 'unavailable':
        return ServerException(
          message: 'Network unavailable: ${exception.message}',
          originalError: exception,
        );
      default:
        return UnknownException(
          message: 'Firestore error: ${exception.message}',
          originalError: exception,
        );
    }
  }
}
