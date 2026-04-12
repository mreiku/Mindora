import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../backend/message_service.dart';
import 'profile_screen.dart';
import 'send_message.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = "Messages";

  String _normalizedSearchQuery() {
    final rawQuery = _searchController.text.trim().toLowerCase();
    if (rawQuery.startsWith("@")) {
      return rawQuery.substring(1);
    }
    return rawQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openConversation({
    required String userId,
    required String username,
    required String displayName,
  }) async {
    final conversationResult = await _messageService.createOrOpenConversation(
      otherUserId: userId,
      otherUsername: username,
      otherDisplayName: displayName,
    );

    if (!mounted) {
      return;
    }

    if (conversationResult == null ||
        conversationResult.startsWith("No ") ||
        conversationResult.startsWith("Missing") ||
        conversationResult.startsWith("[") ||
        conversationResult.startsWith("permission") ||
        conversationResult.startsWith("Exception")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            conversationResult ?? "Couldn't open this conversation right now.",
          ),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewMessageScreen(
          conversationId: conversationResult,
          recipientUserId: userId,
          recipientUsername: username,
          recipientDisplayName: displayName,
        ),
      ),
    );
  }

  Future<void> _openGroupConversation({
    required String conversationId,
    required String groupName,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewMessageScreen(
          conversationId: conversationId,
          isGroup: true,
          groupName: groupName,
        ),
      ),
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

  Future<void> _showCreateGroupDialog() async {
    final groupNameController = TextEditingController();
    final selectedUsers = <String, Map<String, String>>{};
    String? errorText;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final panelColor =
                isDark ? const Color(0xFF2A201D) : const Color(0xFFFFF4E7);
            final fieldColor =
                isDark ? const Color(0xFF201816) : const Color(0xFFF7EEE4);
            final borderColor = isDark
                ? Colors.white10
                : const Color(0xFFC85C55).withOpacity(0.18);
            final titleColor = isDark ? Colors.white : const Color(0xFF5A2420);
            final mutedColor = isDark ? Colors.white60 : const Color(0xFF8E5E56);

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.26 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Create Group Chat",
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 30,
                        fontFamily: "Jomhuria",
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Name your group and choose who you want to invite.",
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: fieldColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: groupNameController,
                        style: TextStyle(color: titleColor),
                        decoration: InputDecoration(
                          hintText: "Study Group",
                          hintStyle: TextStyle(color: mutedColor),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Invite classmates",
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: fieldColor,
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
                            return doc.id != currentUserId;
                          }).toList();

                          if (users.isEmpty) {
                            return Center(
                              child: Text(
                                "No classmates available yet.",
                                style: TextStyle(color: mutedColor),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: users.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: borderColor,
                            ),
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
                                  setDialogState(() {
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(dialogContext),
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
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isSubmitting = true;
                                      errorText = null;
                                    });

                                    final conversationId =
                                        await _messageService
                                            .createGroupConversation(
                                      groupName: groupNameController.text,
                                      selectedUsers:
                                          selectedUsers.values.toList(),
                                    );

                                    if (!mounted) {
                                      return;
                                    }

                                    if (conversationId == null ||
                                        conversationId.startsWith("Couldn't") ||
                                        conversationId.startsWith("No ") ||
                                        conversationId.startsWith("Choose") ||
                                        conversationId.startsWith("Group")) {
                                      setDialogState(() {
                                        isSubmitting = false;
                                        errorText = conversationId ??
                                            "Couldn't create group right now";
                                      });
                                      return;
                                    }

                                    Navigator.pop(dialogContext);
                                    await _openGroupConversation(
                                      conversationId: conversationId,
                                      groupName:
                                          groupNameController.text.trim(),
                                    );
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
                            child: Text(
                              isSubmitting ? "Creating..." : "Create",
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
      },
    );

    groupNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF1A1714) : const Color(0xFFF9EBD2);
    final cardColor = isDark ? Colors.white10 : const Color(0xFFF7EEE4);
    final borderColor = isDark
        ? Colors.white10
        : const Color(0xFFC85C55).withOpacity(0.15);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Messages",
                      style: TextStyle(
                        fontSize: 36,
                        fontFamily: 'Jomhuria',
                        height: 0.95,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showCreateGroupDialog,
                    icon: const Icon(Icons.group_add_rounded, size: 18),
                    label: const Text("New Group"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC84D4D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Search messages",
                    hintStyle: TextStyle(color: textMuted),
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.search,
                      size: 20,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MessageFilterChip(
                      label: "Messages",
                      isSelected: _selectedFilter == "Messages",
                      onTap: () =>
                          setState(() => _selectedFilter = "Messages"),
                    ),
                    const SizedBox(width: 10),
                    _MessageFilterChip(
                      label: "Groups",
                      isSelected: _selectedFilter == "Groups",
                      onTap: () => setState(() => _selectedFilter = "Groups"),
                    ),
                    const SizedBox(width: 10),
                    _MessageFilterChip(
                      label: "Request",
                      isSelected: _selectedFilter == "Request",
                      onTap: () => setState(() => _selectedFilter = "Request"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _messageService.getConversationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Couldn't load messages.",
                          style: TextStyle(color: textPrimary),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final currentUserId = _messageService.currentUserId;
                    final query = _normalizedSearchQuery();
                    final acceptedConversationUserIds = snapshot.data!.docs
                        .where((doc) {
                          final data = doc.data();
                          final isGroup = data["isGroup"] as bool? ?? false;
                          if (isGroup) {
                            return false;
                          }
                          return (data["status"] as String? ?? "accepted") ==
                              "accepted";
                        })
                        .expand((doc) {
                          final data = doc.data();
                          final ids = List<String>.from(
                            data["participantIds"] ?? const <String>[],
                          );
                          return ids.where((id) => id != currentUserId);
                        })
                        .toSet();
                    final conversations = snapshot.data!.docs.where((doc) {
                      final data = doc.data();
                      final isGroup = data["isGroup"] as bool? ?? false;
                      final status = data["status"] as String? ?? "accepted";
                      final groupName =
                          (data["groupName"] ?? "Group Chat").toString();
                      final memberStatuses = Map<String, dynamic>.from(
                        data["memberStatuses"] ?? const <String, dynamic>{},
                      );
                      final currentMembership =
                          (memberStatuses[currentUserId] ?? "").toString();
                      final participants =
                          Map<String, dynamic>.from(data["participants"] ?? {});
                      final others = participants.entries
                          .where((entry) => entry.key != currentUserId)
                          .toList();

                      if (!isGroup && others.isEmpty) {
                        return false;
                      }

                      final otherData = others.isEmpty
                          ? <String, dynamic>{}
                          : Map<String, dynamic>.from(
                              others.first.value as Map,
                            );
                      final username = isGroup
                          ? groupName.toLowerCase()
                          : (otherData["username"] ?? "")
                              .toString()
                              .toLowerCase();
                      final displayName = isGroup
                          ? others
                              .map((entry) {
                                final data =
                                    Map<String, dynamic>.from(entry.value as Map);
                                return (data["displayName"] ??
                                        data["username"] ??
                                        "")
                                    .toString()
                                    .toLowerCase();
                              })
                              .join(" ")
                          : (otherData["displayName"] ??
                                  otherData["username"] ??
                                  "")
                              .toString()
                              .toLowerCase();
                      final lastMessage =
                          (data["lastMessage"] ?? "").toString().toLowerCase();

                      if (_selectedFilter == "Groups") {
                        return isGroup &&
                            currentMembership == "active" &&
                            (query.isEmpty ||
                                username.contains(query) ||
                                displayName.contains(query) ||
                                lastMessage.contains(query));
                      }

                      if (_selectedFilter == "Messages" &&
                          (isGroup || status != "accepted")) {
                        return false;
                      }

                      if (_selectedFilter == "Request" &&
                          !((isGroup && currentMembership == "invited") ||
                              (!isGroup &&
                                  status == "pending" &&
                                  data["requestedToUserId"] == currentUserId))) {
                        return false;
                      }

                      if (query.isEmpty) {
                        return true;
                      }

                      return username.contains(query) ||
                          displayName.contains(query) ||
                          lastMessage.contains(query);
                    }).toList()
                      ..sort((a, b) {
                        final aUpdatedAt = a.data()["updatedAt"];
                        final bUpdatedAt = b.data()["updatedAt"];
                        final aMillis = aUpdatedAt is Timestamp
                            ? aUpdatedAt.millisecondsSinceEpoch
                            : 0;
                        final bMillis = bUpdatedAt is Timestamp
                            ? bUpdatedAt.millisecondsSinceEpoch
                            : 0;
                        return bMillis.compareTo(aMillis);
                      });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (conversations.isEmpty)
                          _EmptyMessageState(
                            cardColor: cardColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            isDark: isDark,
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: conversations.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final conversation = conversations[index];
                                final data = conversation.data();
                                final isGroup = data["isGroup"] as bool? ?? false;
                                final groupName =
                                    (data["groupName"] ?? "Group Chat").toString();
                                final memberStatuses = Map<String, dynamic>.from(
                                  data["memberStatuses"] ??
                                      const <String, dynamic>{},
                                );
                                final currentMembership =
                                    (memberStatuses[currentUserId] ?? "")
                                        .toString();
                                final participants = Map<String, dynamic>.from(
                                  data["participants"] ?? {},
                                );
                                final otherEntries = participants.entries
                                    .where((entry) => entry.key != currentUserId)
                                    .toList();
                                final otherEntry = otherEntries.isEmpty
                                    ? null
                                    : otherEntries.first;
                                final otherData = otherEntry == null
                                    ? <String, dynamic>{}
                                    : Map<String, dynamic>.from(
                                        otherEntry.value as Map,
                                      );

                                return _ConversationTile(
                                  username: isGroup
                                      ? groupName
                                      : otherData["username"] ?? "Username",
                                  subtitle: (data["lastMessage"] ?? "")
                                          .toString()
                                          .trim()
                                          .isEmpty
                                      ? (isGroup && currentMembership == "invited"
                                          ? "Group invitation"
                                          : "No messages yet")
                                      : data["lastMessage"] ?? "",
                                  isGroup: isGroup,
                                  isRequest: _selectedFilter == "Request",
                                  requestLabel: isGroup
                                      ? "Group Invite"
                                      : "Message Request",
                                  onAvatarTap: isGroup || otherEntry == null
                                      ? null
                                      : () => _showViewProfileSheet(
                                            userId: otherEntry.key,
                                            username:
                                                (otherData["username"] ??
                                                        "Username")
                                                    .toString(),
                                            displayName:
                                                (otherData["displayName"] ??
                                                        otherData["username"] ??
                                                        "Username")
                                                    .toString(),
                                          ),
                                  onAccept: _selectedFilter == "Request"
                                      ? () async {
                                          final error = isGroup
                                              ? await _messageService
                                                  .respondToGroupInvite(
                                                    conversationId:
                                                        conversation.id,
                                                    accept: true,
                                                  )
                                              : await _messageService
                                                  .respondToRequest(
                                                    conversationId:
                                                        conversation.id,
                                                    accept: true,
                                                  );
                                          if (!mounted || error == null) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(content: Text(error)),
                                          );
                                        }
                                      : null,
                                  onDeny: _selectedFilter == "Request"
                                      ? () async {
                                          final error = isGroup
                                              ? await _messageService
                                                  .respondToGroupInvite(
                                                    conversationId:
                                                        conversation.id,
                                                    accept: false,
                                                  )
                                              : await _messageService
                                                  .respondToRequest(
                                                    conversationId:
                                                        conversation.id,
                                                    accept: false,
                                                  );
                                          if (!mounted || error == null) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(content: Text(error)),
                                          );
                                        }
                                      : null,
                                  onTap: isGroup
                                      ? () => _openGroupConversation(
                                            conversationId: conversation.id,
                                            groupName: groupName,
                                          )
                                      : () => _openConversation(
                                            userId: otherEntry!.key,
                                            username:
                                                otherData["username"] ??
                                                    "Username",
                                            displayName:
                                                otherData["displayName"] ??
                                                    otherData["username"] ??
                                                    "Username",
                                          ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          "Suggested",
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child:
                              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _messageService.getSuggestedUsersStream(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.hasError) {
                                return const SizedBox.shrink();
                              }

                              if (!userSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final users =
                                  userSnapshot.data!.docs.where((doc) {
                                if (doc.id == currentUserId) {
                                  return false;
                                }

                                if (acceptedConversationUserIds.contains(
                                  doc.id,
                                )) {
                                  return false;
                                }

                                final data = doc.data();
                                final username = (data["username"] ?? "")
                                    .toString()
                                    .toLowerCase();
                                final displayName = (data["displayName"] ??
                                        data["username"] ??
                                        "")
                                    .toString()
                                    .toLowerCase();

                                if (query.isEmpty) {
                                  return true;
                                }

                                return username.contains(query) ||
                                    displayName.contains(query);
                              }).take(10).toList();

                              if (users.isEmpty) {
                                return Center(
                                  child: Text(
                                    "No users found.",
                                    style: TextStyle(color: textMuted),
                                  ),
                                );
                              }

                              return ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: users.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final userDoc = users[index];
                                  final userData = userDoc.data();
                                  final lastActiveAt =
                                      userData["lastActiveAt"] as Timestamp?;
                                  final lastActiveTime =
                                      lastActiveAt?.toDate();
                                  final isRecentlyActive =
                                      lastActiveTime != null &&
                                      DateTime.now()
                                              .difference(lastActiveTime)
                                              .inMinutes <
                                          2;
                                  final isActive =
                                      (userData["isActive"] as bool? ?? false) &&
                                      isRecentlyActive;

                                  return _SuggestedMessageTile(
                                    username: userData["username"] ?? "Username",
                                    subtitle:
                                        userData["displayName"] ?? "Suggestion",
                                    isActive: isActive,
                                    onAvatarTap: () => _showViewProfileSheet(
                                      userId: userDoc.id,
                                      username:
                                          (userData["username"] ?? "Username")
                                              .toString(),
                                      displayName:
                                          (userData["displayName"] ??
                                                  userData["username"] ??
                                                  "Username")
                                              .toString(),
                                    ),
                                    onTap: () => _openConversation(
                                      userId: userDoc.id,
                                      username:
                                          userData["username"] ?? "Username",
                                      displayName: userData["displayName"] ??
                                          userData["username"] ??
                                          "Username",
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageFilterChip extends StatelessWidget {
  const _MessageFilterChip({
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFC84D4D)
              : (isDark ? Colors.white10 : const Color(0xFFF3E2D3)),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC84D4D)
                : (isDark
                    ? Colors.white10
                    : const Color(0xFFC85C55).withOpacity(0.2)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyMessageState extends StatelessWidget {
  const _EmptyMessageState({
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
  });

  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2B2522)
                  : const Color(0xFFFFE1C8),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFC84D4D).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Ask and Connect",
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start a conversation with people you want to connect with.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textMuted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.username,
    required this.subtitle,
    this.isGroup = false,
    this.isRequest = false,
    this.onAvatarTap,
    this.requestLabel,
    this.onAccept,
    this.onDeny,
    required this.onTap,
  });

  final String username;
  final String subtitle;
  final bool isGroup;
  final bool isRequest;
  final VoidCallback? onAvatarTap;
  final String? requestLabel;
  final VoidCallback? onAccept;
  final VoidCallback? onDeny;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F1614);
    final textMuted = isDark ? Colors.white54 : Colors.black45;
    final tileColor = isDark ? Colors.white10 : const Color(0xFFF7EEE4);
    final borderColor = isDark
        ? Colors.white10
        : const Color(0xFFC85C55).withOpacity(0.15);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isRequest ? null : onTap,
            child: Row(
              children: [
                GestureDetector(
                  onTap: onAvatarTap,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: isGroup
                        ? const Color(0xFFC84D4D)
                        : null,
                    backgroundImage: isGroup
                        ? null
                        : const AssetImage("assets/bila.jpg"),
                    child: isGroup
                        ? const Icon(
                            Icons.groups_rounded,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 13,
                        ),
                      ),
                      if (isRequest && requestLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          requestLabel!,
                          style: const TextStyle(
                            color: Color(0xFFC84D4D),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isRequest
                      ? Icons.mail_outline_rounded
                      : (isGroup
                          ? Icons.forum_rounded
                          : Icons.chevron_right_rounded),
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
          ),
          if (isRequest) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC84D4D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Accept"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDeny,
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white70 : Colors.black54,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Deny"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestedMessageTile extends StatelessWidget {
  const _SuggestedMessageTile({
    required this.username,
    required this.subtitle,
    required this.isActive,
    this.onAvatarTap,
    required this.onTap,
  });

  final String username;
  final String subtitle;
  final bool isActive;
  final VoidCallback? onAvatarTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F1614);
    final textMuted = isDark ? Colors.white54 : Colors.black45;
    final tileColor = isDark ? Colors.white10 : const Color(0xFFF7EEE4);
    final borderColor = isDark
        ? Colors.white10
        : const Color(0xFFC85C55).withOpacity(0.15);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFC84D4D),
                      width: 1.2,
                    ),
                    image: const DecorationImage(
                      image: AssetImage("assets/bila.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF94F194)
                        : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1A1714)
                          : const Color(0xFFF9EBD2),
                      width: 1.3,
                    ),
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
                Text(
                  username,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC84D4D),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Message",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

