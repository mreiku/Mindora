import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../backend/notification_service.dart';

class NotifScreen extends StatelessWidget {
  const NotifScreen({super.key});

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) {
      return "just now";
    }

    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inMinutes < 1) {
      return "just now";
    }
    if (difference.inHours < 1) {
      return "${difference.inMinutes}m";
    }
    if (difference.inDays < 1) {
      return "${difference.inHours}h";
    }
    return "${difference.inDays}d";
  }

  IconData _iconForType(String type) {
    switch (type) {
      case "reaction":
        return Icons.favorite_rounded;
      case "reply":
        return Icons.chat_bubble_rounded;
      case "message":
        return Icons.mail_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notificationService = NotificationService();
    const brandRed = Color(0xFFC84D4D);
    final tileColor = isDark ? Colors.white10 : const Color(0xFFF7EEE4);
    final borderColor =
        isDark ? Colors.white10 : brandRed.withOpacity(0.15);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: notificationService.getNotificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Couldn't load notifications.",
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = [...snapshot.data!.docs]
          ..sort((a, b) {
            final aCreatedAt = a.data()["createdAt"];
            final bCreatedAt = b.data()["createdAt"];
            final aMillis = aCreatedAt is Timestamp
                ? aCreatedAt.millisecondsSinceEpoch
                : 0;
            final bMillis = bCreatedAt is Timestamp
                ? bCreatedAt.millisecondsSinceEpoch
                : 0;
            return bMillis.compareTo(aMillis);
          });

        if (notifications.isEmpty) {
          return Center(
            child: Text(
              "You don't have any notifications yet.",
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final notificationDoc = notifications[index];
            final notif = notificationDoc.data();
            final type = (notif["type"] ?? "").toString();
            final senderUsername =
                (notif["senderUsername"] ?? "Someone").toString();
            final senderDisplayName =
                (notif["senderDisplayName"] ?? senderUsername).toString();
            final message = (notif["message"] ?? "sent a notification")
                .toString();
            final createdAt = notif["createdAt"] as Timestamp?;
            final isRead = notif["isRead"] as bool? ?? false;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => notificationService.markAsRead(notificationDoc.id),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 23,
                          backgroundImage: AssetImage("assets/bila.jpg"),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: brandRed,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1A1714)
                                    : const Color(0xFFF9EBD2),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _iconForType(type),
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                                height: 1.35,
                              ),
                              children: [
                                TextSpan(
                                  text: "$senderDisplayName (@$senderUsername)",
                                  style: const TextStyle(
                                    color: brandRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: " $message"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatTimeAgo(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(left: 10, top: 4),
                        decoration: const BoxDecoration(
                          color: brandRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

