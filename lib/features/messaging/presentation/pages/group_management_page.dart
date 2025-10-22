/// Group management page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_management_page.g.dart';

/// Page for managing group conversation settings.
///
/// Allows admins to:
/// - Edit group name and image
/// - Add/remove members
/// - Promote/demote admins
///
/// Allows all members to:
/// - View group details
/// - Leave the group
class GroupManagementPage extends ConsumerStatefulWidget {
  const GroupManagementPage({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<GroupManagementPage> createState() =>
      _GroupManagementPageState();
}

class _GroupManagementPageState extends ConsumerState<GroupManagementPage> {
  final _groupNameController = TextEditingController();
  bool _isEditingName = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _updateGroupName(
    Conversation group,
    String currentUserId,
  ) async {
    if (_groupNameController.text.trim().isNotEmpty &&
        _groupNameController.text != group.groupName) {
      setState(() => _isLoading = true);

      final updateUseCase = ref.read(updateGroupInfoUseCaseProvider);
      final result = await updateUseCase(
        groupId: widget.conversationId,
        requesterId: currentUserId,
        groupName: _groupNameController.text.trim(),
      );

      setState(() => _isLoading = false);

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update name: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (_) {
          if (mounted) {
            setState(() => _isEditingName = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Group name updated')));
          }
        },
      );
    }
  }

  Future<void> _addMember(String currentUserId) async {
    // Show user selection dialog
    await showDialog(
      context: context,
      builder: (context) => _AddMemberDialog(
        conversationId: widget.conversationId,
        currentUserId: currentUserId,
      ),
    );
  }

  Future<void> _removeMember(
    String memberId,
    String memberName,
    String currentUserId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $memberName from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final removeUseCase = ref.read(removeGroupMemberUseCaseProvider);
    final result = await removeUseCase(
      groupId: widget.conversationId,
      userId: memberId,
      requesterId: currentUserId,
    );

    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove member: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Member removed')));
        }
      },
    );
  }

  Future<void> _leaveGroup(String currentUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? You can be added back by an admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final leaveUseCase = ref.read(leaveGroupUseCaseProvider);
    final result = await leaveUseCase(
      groupId: widget.conversationId,
      userId: currentUserId,
    );

    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to leave group: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          // Navigate back to conversation list
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Settings')),
        body: const Center(child: Text('Please sign in')),
      );
    }

    final conversationAsync = ref.watch(
      getConversationByIdProvider(widget.conversationId),
    );

    return conversationAsync.when(
      data: (group) {
        final isAdmin = group.adminIds?.contains(currentUser.uid) ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Group Settings'),
            actions: [
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
          body: ListView(
            children: [
              // Group info section
              _buildGroupInfoSection(group, currentUser.uid, isAdmin),
              const Divider(),
              // Members section
              _buildMembersSection(group, currentUser.uid, isAdmin),
              const Divider(),
              // Actions section
              _buildActionsSection(currentUser.uid, isAdmin),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Group Settings')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Group Settings')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildGroupInfoSection(
    Conversation group,
    String currentUserId,
    bool isAdmin,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Group Info',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Group avatar
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue[700],
              child: const Icon(Icons.group, color: Colors.white, size: 50),
            ),
          ),
          const SizedBox(height: 16),
          // Group name
          if (_isEditingName && isAdmin)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _isLoading
                      ? null
                      : () => _updateGroupName(group, currentUserId),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _isEditingName = false),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.groupName ?? 'Unknown Group',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _groupNameController.text = group.groupName ?? '';
                      setState(() => _isEditingName = true);
                    },
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            '${group.participantIds.length} members',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(
    Conversation group,
    String currentUserId,
    bool isAdmin,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Members',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isAdmin)
                TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _addMember(currentUserId),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...group.participants.map((participant) {
            final isCurrentUser = participant.uid == currentUserId;
            final isMemberAdmin =
                group.adminIds?.contains(participant.uid) ?? false;

            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  participant.name.isNotEmpty
                      ? participant.name[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      isCurrentUser ? 'You' : participant.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (isMemberAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: isAdmin && !isCurrentUser
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'remove') {
                          _removeMember(
                            participant.uid,
                            participant.name,
                            currentUserId,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            'Remove from group',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    )
                  : null,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionsSection(String currentUserId, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : () => _leaveGroup(currentUserId),
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            label: const Text(
              'Leave Group',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding a member to the group.
class _AddMemberDialog extends ConsumerStatefulWidget {
  const _AddMemberDialog({
    required this.conversationId,
    required this.currentUserId,
  });

  final String conversationId;
  final String currentUserId;

  @override
  ConsumerState<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<_AddMemberDialog> {
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedUserLanguage;
  bool _isLoading = false;

  Future<void> _addMember() async {
    if (_selectedUserId == null) return;

    setState(() => _isLoading = true);

    final addMemberUseCase = ref.read(addGroupMemberUseCaseProvider);
    final result = await addMemberUseCase(
      groupId: widget.conversationId,
      userId: _selectedUserId!,
      userName: _selectedUserName ?? 'Unknown',
      preferredLanguage: _selectedUserLanguage ?? 'en',
      requesterId: widget.currentUserId,
    );

    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add member: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Member added')));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(conversationUsersStreamProvider);

    return AlertDialog(
      title: const Text('Add Member'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: usersAsync.when(
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
                final isSelected = _selectedUserId == userId;

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(userName),
                  subtitle: Text(user['email'] as String? ?? ''),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : const Icon(Icons.radio_button_unchecked),
                  onTap: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _selectedUserId = userId;
                            _selectedUserName = userName;
                            _selectedUserLanguage =
                                user['preferredLanguage'] as String? ?? 'en';
                          });
                        },
                  selected: isSelected,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedUserId == null ? null : _addMember,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

/// Provider for getting a conversation by ID.
@riverpod
Future<Conversation> getConversationById(Ref ref, String conversationId) async {
  final useCase = ref.watch(getConversationByIdUseCaseProvider);
  final result = await useCase(conversationId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conversation) => conversation,
  );
}
