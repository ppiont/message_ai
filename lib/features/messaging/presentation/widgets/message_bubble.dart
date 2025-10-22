/// Message bubble widget
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget displaying a single message bubble in the chat.
///
/// Shows different styling for sent vs received messages,
/// includes sender name, timestamp, and delivery status.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isMe,
    required this.senderName,
    required this.timestamp,
    this.showTimestamp = false,
    this.status = 'sent',
    super.key,
  });

  final String message;
  final bool isMe;
  final String senderName;
  final DateTime timestamp;
  final bool showTimestamp;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (showTimestamp) _buildTimestampDivider(context),
        Padding(
          padding: EdgeInsets.only(
            left: isMe ? 64 : 8,
            right: isMe ? 8 : 64,
            top: 4,
            bottom: 4,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: isMe
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 15,
                        color: isMe ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat.jm().format(timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(context),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimestampDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatTimestampDivider(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    // Debug: Print status to see what we're getting
    print('MessageBubble status: "$status" for isMe=$isMe');

    switch (status) {
      case 'sent':
        return Icon(
          Icons.check,
          size: 16, // Increased from 14
          color: Colors.white, // Changed from white70 to full white
        );
      case 'delivered':
        return Icon(
          Icons.done_all,
          size: 16, // Increased from 14
          color: Colors.white, // Changed from white70 to full white
        );
      case 'read':
        return Icon(
          Icons.done_all,
          size: 16, // Increased from 14
          color: Colors.lightBlueAccent, // More visible color for read status
        );
      default:
        print(
          'MessageBubble: Unknown status "$status", returning empty widget',
        );
        return const SizedBox.shrink();
    }
  }

  String _formatTimestampDivider(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.EEEE().format(timestamp); // e.g., "Monday"
    } else {
      return DateFormat.yMMMd().format(timestamp); // e.g., "Jan 15, 2024"
    }
  }
}
