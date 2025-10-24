/// Helper utilities for displaying per-user read receipts in the UI.
library;

import 'package:flutter/material.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';

/// Helper class providing UI utilities for read receipt display.
///
/// Provides static methods for converting read receipt data into
/// user-friendly icons, colors, and text formats.
class ReadReceiptHelpers {
  /// Private constructor - this is a static utility class
  ReadReceiptHelpers._();

  /// Gets the appropriate icon for a message status.
  ///
  /// Maps status values to Material Design icons:
  /// - 'sent': [Icons.check] (single checkmark)
  /// - 'delivered': [Icons.done_all] (double checkmark)
  /// - 'read': [Icons.done_all] (double checkmark, color differs)
  /// - other: [Icons.schedule] (clock for pending/sending)
  static IconData getStatusIcon(final String status) => switch (status) {
        'sent' => Icons.check,
        'delivered' || 'read' => Icons.done_all,
        _ => Icons.schedule,
      };

  /// Gets the appropriate color for a message status.
  ///
  /// Uses the theme's color scheme:
  /// - 'read': [ColorScheme.primary] (blue)
  /// - other: [ColorScheme.outline] (grey)
  static Color getStatusColor(final BuildContext context, final String status) {
    final colorScheme = Theme.of(context).colorScheme;
    return status == 'read' ? colorScheme.primary : colorScheme.outline;
  }

  /// Formats the read receipt status for display in the UI.
  ///
  /// For 1-on-1 chats, shows simple status: "Read", "Delivered", or "Sent"
  /// For group chats, shows count: "Read by 3/5" or "Delivered to 2/5"
  static String formatStatus({
    required final Message message,
    required final List<String> allParticipantIds,
    required final bool isGroupChat,
  }) {
    if (!isGroupChat) {
      // 1-on-1 chat: Simple status
      final status = message.getAggregateStatus(allParticipantIds);
      return _capitalizeFirst(status);
    }

    // Group chat: Show read/delivered count
    final readCount = message.getReadCount(allParticipantIds);
    final otherParticipants =
        allParticipantIds.where((final id) => id != message.senderId).length;
    final status = message.getAggregateStatus(allParticipantIds);

    return switch (status) {
      'read' => 'Read by $readCount/$otherParticipants',
      'delivered' => 'Delivered to $readCount/$otherParticipants',
      _ => _capitalizeFirst(status),
    };
  }

  /// Gets a list of display names for users who have read the message.
  ///
  /// Used for displaying detailed read receipt information in dialogs.
  /// Returns 'Unknown' for users not found in the [userIdToNameMap].
  static List<String> getReadByNames({
    required final Message message,
    required final Map<String, String> userIdToNameMap,
  }) =>
      message
          .getReadByUserIds()
          .map((final userId) => userIdToNameMap[userId] ?? 'Unknown')
          .toList();

  /// Gets a list of display names for users who received but haven't read.
  ///
  /// Used for displaying detailed read receipt information in dialogs.
  /// Returns 'Unknown' for users not found in the [userIdToNameMap].
  static List<String> getDeliveredButNotReadNames({
    required final Message message,
    required final Map<String, String> userIdToNameMap,
  }) =>
      message
          .getDeliveredButNotReadUserIds()
          .map((final userId) => userIdToNameMap[userId] ?? 'Unknown')
          .toList();

  /// Formats a timestamp for read receipt display.
  ///
  /// Returns relative time for recent events and absolute times for older events:
  /// - Less than 1 minute ago: "Just now"
  /// - Less than 1 hour ago: "2m ago"
  /// - Less than 1 day ago: "3h ago"
  /// - Yesterday: "Yesterday at 3:45 PM"
  /// - Less than 1 week ago: "Monday at 3:45 PM"
  /// - Older: "31/12/2024 3:45 PM"
  static String formatTimestamp(final DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    return switch (difference) {
      Duration(inMinutes: < 1) => 'Just now',
      Duration(inMinutes: final m, inHours: < 1) => '${m}m ago',
      Duration(inHours: final h, inDays: < 1) => '${h}h ago',
      Duration(inDays: 1) => 'Yesterday at ${_formatTime(timestamp)}',
      Duration(inDays: final d) when d < 7 =>
        '${_getDayName(timestamp)} at ${_formatTime(timestamp)}',
      _ =>
        '${timestamp.day}/${timestamp.month}/${timestamp.year} ${_formatTime(timestamp)}',
    };
  }

  /// Capitalizes the first character of a string.
  static String _capitalizeFirst(final String text) {
    if (text.isEmpty) {
      return text;
    }
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Formats time as HH:MM AM/PM (12-hour format).
  static String _formatTime(final DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Gets the day of week name for a given date.
  static String _getDayName(final DateTime date) {
    const days = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[date.weekday - 1];
  }
}
