/// User list item widget
library;

import 'package:flutter/material.dart';

/// Widget displaying a single user in the user selection list.
///
/// Shows user avatar, display name, and email.
class UserListItem extends StatelessWidget {
  const UserListItem({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.onTap,
    this.imageUrl,
    super.key,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildAvatar(),
      title: Text(
        displayName.isEmpty ? 'Unknown User' : displayName,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        email,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );

  Widget _buildAvatar() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: Colors.grey[300],
      );
    }

    // Generate color from name for consistent avatar colors
    final color = _generateColorFromString(displayName.isNotEmpty ? displayName : email);

    return CircleAvatar(
      radius: 24,
      backgroundColor: color,
      child: Text(
        _getInitials(displayName.isNotEmpty ? displayName : email),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Color _generateColorFromString(String str) {
    // Generate consistent color from string hash
    var hash = 0;
    for (var i = 0; i < str.length; i++) {
      hash = str.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Use predefined Material colors for better aesthetics
    final colors = [
      Colors.blue[700]!,
      Colors.green[700]!,
      Colors.orange[700]!,
      Colors.purple[700]!,
      Colors.red[700]!,
      Colors.teal[700]!,
      Colors.pink[700]!,
      Colors.indigo[700]!,
      Colors.cyan[700]!,
      Colors.amber[700]!,
    ];

    return colors[hash.abs() % colors.length];
  }
}
