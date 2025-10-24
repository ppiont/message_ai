/// Helper functions for displaying read receipts in the UI
library;

import 'package:flutter/material.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';

/// Helper class for read receipt UI logic
class ReadReceiptHelpers {
  ReadReceiptHelpers._(); // Private constructor - static class only

  /// Gets the appropriate icon for a message status
  ///
  /// - 'sent': Single checkmark
  /// - 'delivered': Double checkmark (grey)
  /// - 'read': Double checkmark (blue)
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'sent':
        return Icons.check; // Single checkmark
      case 'delivered':
        return Icons.done_all; // Double checkmark
      case 'read':
        return Icons.done_all; // Double checkmark (color changes)
      default:
        return Icons.schedule; // Clock for pending/sending
    }
  }

  /// Gets the appropriate color for a message status
  ///
  /// - 'read': Primary color (blue)
  /// - Others: Grey
  static Color getStatusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;

    if (status == 'read') {
      return colorScheme.primary; // Blue for read
    }

    return colorScheme.outline; // Grey for sent/delivered
  }

  /// Formats the read receipt status for display
  ///
  /// For group chats, shows count like "Read by 3/5"
  /// For 1-on-1 chats, shows simple status like "Read"
  static String formatStatus({
    required Message message,
    required List<String> allParticipantIds,
    required bool isGroupChat,
  }) {
    if (!isGroupChat) {
      // 1-on-1 chat: Simple status
      final status = message.getAggregateStatus(allParticipantIds);
      return _capitalizeFirst(status);
    }

    // Group chat: Show read count
    final readCount = message.getReadCount(allParticipantIds);
    final otherParticipants = allParticipantIds
        .where((id) => id != message.senderId)
        .length;

    final status = message.getAggregateStatus(allParticipantIds);

    if (status == 'read') {
      return 'Read by $readCount/$otherParticipants';
    } else if (status == 'delivered') {
      return 'Delivered to $readCount/$otherParticipants';
    } else {
      return _capitalizeFirst(status);
    }
  }

  /// Gets a list of participant names who have read the message
  ///
  /// Used for displaying detailed read receipt info (e.g., in a dialog)
  static List<String> getReadByNames({
    required Message message,
    required Map<String, String> userIdToNameMap,
  }) {
    final readByIds = message.getReadByUserIds();
    return readByIds
        .map((userId) => userIdToNameMap[userId] ?? 'Unknown')
        .toList();
  }

  /// Gets a list of participant names who received but haven't read
  ///
  /// Used for displaying detailed read receipt info
  static List<String> getDeliveredButNotReadNames({
    required Message message,
    required Map<String, String> userIdToNameMap,
  }) {
    final deliveredIds = message.getDeliveredButNotReadUserIds();
    return deliveredIds
        .map((userId) => userIdToNameMap[userId] ?? 'Unknown')
        .toList();
  }

  /// Formats a timestamp for read receipt display
  ///
  /// Shows relative time like "2m ago" or "Yesterday at 3:45 PM"
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${_getDayName(timestamp)} at ${_formatTime(timestamp)}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${_formatTime(timestamp)}';
    }
  }

  /// Capitalizes first letter of a string
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Formats time as HH:MM AM/PM
  static String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Gets day name (Monday, Tuesday, etc.)
  static String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }
}
