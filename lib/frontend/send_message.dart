import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../backend/message_service.dart';
import 'profile_screen.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({
    super.key,
    required this.conversationId,
    this.recipientUserId,
    this.recipientUsername,
    this.recipientDisplayName,
    this.groupName,
    this.isGroup = false,
  });

  final String conversationId;
  final String? recipientUserId;
  final String? recipientUsername;
  final String? recipientDisplayName;
  final String? groupName;
  final bool isGroup;

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final error = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      content: _messageController.text,
    );

    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    _messageController.clear();
  }

  Future<void> _deleteMessage({
    required String messageId,
    required String content,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final panelColor =
            isDark ? const Color(0xFF2A201D) : const Color(0xFFFFF4E7);
        final borderColor = isDark
            ? Colors.white10
            : const Color(0xFFC85C55).withOpacity(0.18);
        final titleColor = isDark ? Colors.white : const Color(0xFF5A2420);
        final mutedColor = isDark ? Colors.white60 : const Color(0xFF8E5E56);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Delete Message?",
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 30,
                    fontFamily: "Jomhuria",
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content.trim().isEmpty
                      ? "This message will be removed from the conversation."
                      : "This will remove \"$content\" from the conversation.",
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: titleColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC84D4D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Delete"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final error = await _messageService.deleteMessage(
      conversationId: widget.conversationId,
      messageId: messageId,
    );

    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Message deleted.")),
    );
  }

  Future<void> _leaveGroup() async {
    final conversationSnapshot = await FirebaseFirestore.instance
        .collection("conversations")
        .doc(widget.conversationId)
        .get();
    final conversationData = conversationSnapshot.data() ?? {};
    final createdByUserId =
        (conversationData["createdByUserId"] ?? "").toString();
    final participants = Map<String, dynamic>.from(
      conversationData["participants"] ?? const <String, dynamic>{},
    );
    final activeParticipantIds = List<String>.from(
      conversationData["activeParticipantIds"] ?? const <String>[],
    );
    final currentUserId = _messageService.currentUserId;
    final remainingActiveIds = activeParticipantIds
        .where((memberId) => memberId != currentUserId)
        .toList();

    final willDeleteGroup =
        createdByUserId == currentUserId && remainingActiveIds.isEmpty;
    String? nextOwnerName;
    if (createdByUserId == currentUserId && remainingActiveIds.isNotEmpty) {
      final nextOwnerData = Map<String, dynamic>.from(
        participants[remainingActiveIds.first] ?? const <String, dynamic>{},
      );
      nextOwnerName =
          (nextOwnerData["displayName"] ??
                  nextOwnerData["username"] ??
                  "another member")
              .toString();
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final panelColor =
            isDark ? const Color(0xFF2A201D) : const Color(0xFFFFF4E7);
        final borderColor = isDark
            ? Colors.white10
            : const Color(0xFFC85C55).withOpacity(0.18);
        final titleColor = isDark ? Colors.white : const Color(0xFF5A2420);
        final mutedColor = isDark ? Colors.white60 : const Color(0xFF8E5E56);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC84D4D).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFC84D4D),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  willDeleteGroup ? "Delete Group?" : "Leave Group?",
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 30,
                    fontFamily: "Jomhuria",
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  willDeleteGroup
                      ? "You are the last active member. Leaving will permanently delete this group chat."
                      : (createdByUserId == currentUserId
                          ? "Leaving will transfer group ownership to $nextOwnerName."
                          : "You will leave this group, but your past messages will stay in the chat."),
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: titleColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC84D4D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          willDeleteGroup ? "Delete Group" : "Leave",
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final error = await _messageService.leaveGroup(widget.conversationId);
    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.pop(context);
  }

  Future<void> _kickMember({
    required String conversationId,
    required String memberUserId,
  }) async {
    final error = await _messageService.kickGroupMember(
      conversationId: conversationId,
      memberUserId: memberUserId,
    );

    if (!mounted || error == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  Future<void> _showViewProfileSheet({
    required String userId,
    required String username,
    required String displayName,
  }) async {
    final currentUserId = _messageService.currentUserId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetColor =
        isDark ? const Color(0xFF231B18) : const Color(0xFFFFF4E7);
    final panelColor =
        isDark ? const Color(0xFF2D2521) : const Color(0xFFF7EEE4);
    final borderColor = isDark
        ? Colors.white10
        : const Color(0xFFC85C55).withOpacity(0.18);
    final titleColor = isDark ? Colors.white : const Color(0xFF5A2420);
    final mutedColor = isDark ? Colors.white60 : const Color(0xFF8E5E56);

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: panelColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                    image: const DecorationImage(
                      image: AssetImage("assets/bila.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 30,
                    fontFamily: "Jomhuria",
                    height: 0.95,
                  ),
                ),
                Text(
                  "@$username",
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        this.context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            viewedUserId:
                                userId == currentUserId ? null : userId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC84D4D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("View Profile"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddMembersSheet({
    required String conversationId,
    required Map<String, dynamic> memberStatuses,
  }) async {
    final selectedUsers = <String, Map<String, String>>{};
    String? errorText;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final sheetColor =
                isDark ? const Color(0xFF231B18) : const Color(0xFFFFF4E7);
            final panelColor =
                isDark ? const Color(0xFF2D2521) : const Color(0xFFF7EEE4);
            final borderColor = isDark
                ? Colors.white10
                : const Color(0xFFC85C55).withOpacity(0.18);
            final titleColor =
                isDark ? Colors.white : const Color(0xFF5A2420);
            final mutedColor =
                isDark ? Colors.white60 : const Color(0xFF8E5E56);
            return SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Add Members",
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 30,
                        fontFamily: "Jomhuria",
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Invite more classmates into this group.",
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _messageService.getSuggestedUsersStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final currentUserId = _messageService.currentUserId;
                          final users = snapshot.data!.docs.where((doc) {
                            if (doc.id == currentUserId) {
                              return false;
                            }

                            final membership =
                                (memberStatuses[doc.id] ?? "").toString();
                            return membership != "active" &&
                                membership != "invited";
                          }).toList();

                          if (users.isEmpty) {
                            return Center(
                              child: Text(
                                "No more classmates to add.",
                                style: TextStyle(color: mutedColor),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: users.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: borderColor),
                            itemBuilder: (context, index) {
                              final userDoc = users[index];
                              final userData = userDoc.data();
                              final username =
                                  (userData["username"] ?? "Username").toString();
                              final displayName = (userData["displayName"] ??
                                      userData["username"] ??
                                      "Username")
                                  .toString();
                              final isSelected =
                                  selectedUsers.containsKey(userDoc.id);

                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: const Color(0xFFC84D4D),
                                checkColor: Colors.white,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  username,
                                  style: TextStyle(color: titleColor),
                                ),
                                subtitle: Text(
                                  displayName,
                                  style: TextStyle(color: mutedColor),
                                ),
                                onChanged: (value) {
                                  setSheetState(() {
                                    if (value == true) {
                                      selectedUsers[userDoc.id] = {
                                        "userId": userDoc.id,
                                        "username": username,
                                        "displayName": displayName,
                                      };
                                    } else {
                                      selectedUsers.remove(userDoc.id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC84D4D).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC84D4D).withOpacity(0.24),
                          ),
                        ),
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFC84D4D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: titleColor,
                              side: BorderSide(color: borderColor),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setSheetState(() {
                                      isSubmitting = true;
                                      errorText = null;
                                    });

                                    final error = await _messageService
                                        .inviteMembersToGroup(
                                      conversationId: conversationId,
                                      selectedUsers:
                                          selectedUsers.values.toList(),
                                    );

                                    if (!mounted) {
                                      return;
                                    }

                                    if (error != null) {
                                      setSheetState(() {
                                        isSubmitting = false;
                                        errorText = error;
                                      });
                                      return;
                                    }

                                    Navigator.pop(context);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC84D4D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child:
                                Text(isSubmitting ? "Inviting..." : "Invite"),
                          ),
                        ),
                      ],
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

  Future<void> _showManageMembersSheet({
    required String conversationId,
    required String currentUserId,
    required Map<String, dynamic> participants,
    required Map<String, dynamic> memberStatuses,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final sheetColor =
            isDark ? const Color(0xFF231B18) : const Color(0xFFFFF4E7);
        final panelColor =
            isDark ? const Color(0xFF2D2521) : const Color(0xFFF7EEE4);
        final borderColor = isDark
            ? Colors.white10
            : const Color(0xFFC85C55).withOpacity(0.18);
        final titleColor = isDark ? Colors.white : const Color(0xFF5A2420);
        final mutedColor = isDark ? Colors.white60 : const Color(0xFF8E5E56);
        final members = participants.entries
            .where((entry) {
              if (entry.key == currentUserId) {
                return false;
              }

              final membership =
                  (memberStatuses[entry.key] ?? "unknown").toString();
              return membership != "removed" &&
                  membership != "left" &&
                  membership != "declined";
            })
            .toList();

        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Manage Members",
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 30,
                    fontFamily: "Jomhuria",
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Invite, review, or remove people from this group.",
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _showAddMembersSheet(
                        conversationId: conversationId,
                        memberStatuses: memberStatuses,
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text("Add Members"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC84D4D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (members.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      "No other members in this group.",
                      style: TextStyle(color: mutedColor),
                    ),
                  ),
                if (members.isNotEmpty)
                  ...members.map((entry) {
                    final memberData =
                        Map<String, dynamic>.from(entry.value as Map);
                    final membership =
                        (memberStatuses[entry.key] ?? "unknown").toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFC84D4D)
                                .withOpacity(isDark ? 0.28 : 0.15),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFFC84D4D),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (memberData["displayName"] ??
                                          memberData["username"] ??
                                          "Username")
                                      .toString(),
                                  style: TextStyle(
                                    color: titleColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                        "@${(memberData["username"] ?? "username").toString()} • $membership",
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (membership == "active" || membership == "invited")
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _kickMember(
                                  conversationId: conversationId,
                                  memberUserId: entry.key,
                                );
                              },
                              child: const Text(
                                "Kick",
                                style: TextStyle(
                                  color: Color(0xFFC84D4D),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("conversations")
          .doc(widget.conversationId)
          .snapshots(),
      builder: (context, conversationSnapshot) {
        final conversationData = conversationSnapshot.data?.data() ?? {};
        final currentUserId = _messageService.currentUserId;
        final isGroupChat = widget.isGroup;
        final participants = Map<String, dynamic>.from(
          conversationData["participants"] ?? const <String, dynamic>{},
        );
        final memberStatuses = Map<String, dynamic>.from(
          conversationData["memberStatuses"] ?? const <String, dynamic>{},
        );
        final currentMembership =
            (memberStatuses[currentUserId] ?? "active").toString();
        final createdByUserId =
            (conversationData["createdByUserId"] ?? "").toString();
        final isCreator = isGroupChat && createdByUserId == currentUserId;
        final activeParticipantIds = List<String>.from(
          conversationData["activeParticipantIds"] ?? const <String>[],
        );

        if (isGroupChat && currentMembership == "removed") {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            isGroupChat
                ? const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFC84D4D),
                    child: Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .doc(widget.recipientUserId ?? "")
                        .snapshots(),
                    builder: (context, snapshot) {
                      final userData = snapshot.data?.data();
                      final lastActiveAt = userData?["lastActiveAt"] as Timestamp?;
                      final lastActiveTime = lastActiveAt?.toDate();
                      final isRecentlyActive =
                          lastActiveTime != null &&
                          DateTime.now().difference(lastActiveTime).inMinutes < 2;
                      final isActive =
                          (userData?["isActive"] as bool? ?? false) &&
                          isRecentlyActive;

                      return GestureDetector(
                        onTap: () => _showViewProfileSheet(
                          userId: widget.recipientUserId ?? "",
                          username:
                              (widget.recipientUsername ?? "Username")
                                  .toString(),
                          displayName:
                              (widget.recipientDisplayName ??
                                      widget.recipientUsername ??
                                      "Username")
                                  .toString(),
                        ),
                        child: Stack(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundImage: AssetImage("assets/bila.jpg"),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF94F194)
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context)
                                            .appBarTheme
                                            .backgroundColor ??
                                        Theme.of(context).colorScheme.surface,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isGroupChat
                      ? ((conversationData["groupName"] ??
                                  widget.groupName ??
                                  "Group Chat")
                              .toString())
                      : (widget.recipientUsername ?? "Username"),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isGroupChat
                      ? "${activeParticipantIds.length} active member${activeParticipantIds.length == 1 ? "" : "s"}"
                      : (widget.recipientDisplayName ?? ""),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (isGroupChat && currentMembership == "active")
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == "leave") {
                  await _leaveGroup();
                  return;
                }

                if (value == "manage") {
                  await _showManageMembersSheet(
                    conversationId: widget.conversationId,
                    currentUserId: currentUserId ?? "",
                    participants: participants,
                    memberStatuses: memberStatuses,
                  );
                }
              },
              itemBuilder: (context) => [
                if (isCreator)
                  const PopupMenuItem<String>(
                    value: "manage",
                    child: Text("Manage Members"),
                  ),
                const PopupMenuItem<String>(
                  value: "leave",
                  child: Text("Leave Group"),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (isGroupChat && currentMembership == "invited")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: const Color(0xFFF7EEE4),
              child: Text(
                "Accept this group invite from the Requests tab before sending messages.",
                style: TextStyle(
                  color: isDark ? Colors.black87 : const Color(0xFF6B2C27),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (isGroupChat && currentMembership == "left")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: const Color(0xFFF7EEE4),
              child: const Text(
                "You left this group. Past messages stay in the chat history for the group.",
                style: TextStyle(
                  color: Color(0xFF6B2C27),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messageService.getMessagesStream(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Couldn't load messages."),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "No messages yet. Start the conversation.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final message = messageDoc.data();
                    final isSystemMessage =
                        (message["type"] ?? "").toString() == "system";
                    final isMine = message["senderId"] == currentUserId;
                    final senderName = isMine
                        ? "You"
                        : ((message["senderDisplayName"] ??
                                    message["senderUsername"] ??
                                    widget.recipientDisplayName ??
                                    widget.recipientUsername ??
                                    "User")
                                .toString());
                    final createdAt = message["createdAt"];
                    final sentAt = createdAt is Timestamp
                        ? TimeOfDay.fromDateTime(createdAt.toDate())
                        : null;

                    if (isSystemMessage) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFF3E2D3),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFC85C55).withOpacity(0.18),
                            ),
                          ),
                          child: Text(
                            message["content"] ?? "",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: isMine
                            ? () => _deleteMessage(
                                  messageId: messageDoc.id,
                                  content: (message["content"] ?? "").toString(),
                                )
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? const Color(0xFFC84D4D)
                                : (isDark
                                    ? Colors.white10
                                    : const Color(0xFFF7EEE4)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                senderName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isMine
                                      ? Colors.white70
                                      : const Color(0xFFC84D4D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message["content"] ?? "",
                                style: TextStyle(
                                  color: isMine
                                      ? Colors.white
                                      : (isDark ? Colors.white : Colors.black87),
                                  height: 1.3,
                                ),
                              ),
                              if (sentAt != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  sentAt.format(context),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMine
                                        ? Colors.white70
                                        : (isDark
                                            ? Colors.white54
                                            : Colors.black45),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !isGroupChat || currentMembership == "active",
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: !isGroupChat || currentMembership == "active"
                            ? "Write a message..."
                            : "You cannot message in this group",
                        filled: true,
                        fillColor:
                            isDark ? Colors.white10 : const Color(0xFFF7EEE4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFC84D4D),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFC84D4D),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: !isGroupChat || currentMembership == "active"
                          ? _sendMessage
                          : null,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

