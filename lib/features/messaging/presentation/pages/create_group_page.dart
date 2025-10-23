/// Create group page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/presentation/pages/chat_page.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';

/// Page for creating a new group conversation.
///
/// Allows user to:
/// - Enter group name
/// - Select multiple participants
/// - Create the group
class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  final Map<String, Map<String, String>> _userCache = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 members'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    // Build participants list (including current user)
    final participantIds = [currentUser.uid, ..._selectedUserIds];
    final participants = [
      Participant(
        uid: currentUser.uid,
        preferredLanguage: currentUser.preferredLanguage,
      ),
      ..._selectedUserIds.map((userId) {
        final userInfo = _userCache[userId]!;
        return Participant(
          uid: userId,
          preferredLanguage: userInfo['preferredLanguage'] ?? 'en',
        );
      }),
    ];

    final createGroupUseCase = ref.read(createGroupUseCaseProvider);
    final result = await createGroupUseCase(
      groupName: _groupNameController.text.trim(),
      participantIds: participantIds,
      participants: participants,
      adminIds: [currentUser.uid], // Creator is automatically an admin
      creatorId: currentUser.uid,
    );

    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create group: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (group) {
        if (mounted) {
          // Navigate to the new group chat
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (context) => ChatPage(
                conversationId: group.documentId,
                otherParticipantName: group.groupName ?? 'Group',
                otherParticipantId: '',
                isGroup: true,
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createGroup,
              child: const Text(
                'Create',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Group name input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Group name is required';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Members',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_selectedUserIds.length} selected)',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // User list
            Expanded(child: _buildUserList()),
          ],
        ),
      ),
    );

  Widget _buildUserList() {
    // In a real app, you'd fetch users from a backend API
    // For now, we'll use Firestore users collection
    final usersStream = ref.watch(conversationUsersStreamProvider);

    return usersStream.when(
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('No users available'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userId = user['uid'] as String;
            final userName = user['name'] as String? ?? 'Unknown';
            final userEmail = user['email'] as String? ?? '';
            final isSelected = _selectedUserIds.contains(userId);

            // Cache user info for later use
            _userCache[userId] = {
              'name': userName,
              'email': userEmail,
              'preferredLanguage': user['preferredLanguage'] as String? ?? 'en',
            };

            return CheckboxListTile(
              value: isSelected,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        if (value ?? false) {
                          _selectedUserIds.add(userId);
                        } else {
                          _selectedUserIds.remove(userId);
                        }
                      });
                    },
              title: Text(userName),
              subtitle: Text(userEmail),
              secondary: CircleAvatar(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error loading users: $error'),
          ],
        ),
      ),
    );
  }
}
