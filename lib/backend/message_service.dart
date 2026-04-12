import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../backend/auth_service.dart';
import '../backend/badge_service.dart';
import '../backend/notification_service.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final BadgeService _badgeService = BadgeService();
  final NotificationService _notificationService = NotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> getConversationsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection("conversations")
        .where("participantIds", arrayContains: user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(
    String conversationId,
  ) {
    return _firestore
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .orderBy("createdAt")
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSuggestedUsersStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore.collection("users").limit(20).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getConversation(
    String conversationId,
  ) {
    return _firestore.collection("conversations").doc(conversationId).get();
  }

  Future<void> _addSystemMessage({
    required DocumentReference<Map<String, dynamic>> conversationRef,
    required String content,
  }) {
    return conversationRef.collection("messages").add({
      "senderId": "",
      "senderUsername": "system",
      "senderDisplayName": "Mindora",
      "content": content,
      "type": "system",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<String?> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final trimmedContent = content.trim();
      if (trimmedContent.isEmpty) {
        return "Message cannot be empty";
      }

      final userData = await _authService.getUserData();
      final conversationRef =
          _firestore.collection("conversations").doc(conversationId);

      await _firestore.runTransaction((transaction) async {
        final conversationSnapshot = await transaction.get(conversationRef);
        final conversationData = conversationSnapshot.data();

        if (conversationData == null) {
          throw Exception("Conversation not found");
        }

        final status = conversationData["status"] as String? ?? "accepted";
        final requestedToUserId =
            conversationData["requestedToUserId"] as String? ?? "";
        final isGroup = conversationData["isGroup"] as bool? ?? false;
        final memberStatuses = Map<String, dynamic>.from(
          conversationData["memberStatuses"] ?? const <String, dynamic>{},
        );

        if (status == "denied") {
          throw Exception("This message request was denied");
        }

        if (isGroup) {
          final membership = (memberStatuses[user.uid] ?? "removed").toString();
          if (membership != "active") {
            throw Exception("Join this group first before sending messages");
          }
        }

        if (status == "pending" && requestedToUserId == user.uid) {
          throw Exception("Accept this request before replying");
        }

        final messageRef = conversationRef.collection("messages").doc();

        transaction.set(messageRef, {
          "senderId": user.uid,
          "senderUsername": userData["username"] ?? "",
          "senderDisplayName":
              userData["displayName"] ?? userData["username"] ?? "",
          "content": trimmedContent,
          "createdAt": FieldValue.serverTimestamp(),
        });

        transaction.update(conversationRef, {
          "lastMessage": trimmedContent,
          "lastMessageSenderId": user.uid,
          "updatedAt": FieldValue.serverTimestamp(),
        });
      });

      final conversationSnapshot = await conversationRef.get();
      final conversationData = conversationSnapshot.data() ?? const <String, dynamic>{};
      final isGroup = conversationData["isGroup"] as bool? ?? false;
      final participantIds = isGroup
          ? List<String>.from(
              conversationData["activeParticipantIds"] ?? const <String>[],
            )
          : List<String>.from(
              conversationData["participantIds"] ?? const <String>[],
            );

      for (final participantId in participantIds) {
        if (participantId == user.uid) {
          continue;
        }

        try {
          await _notificationService.createNotification(
            recipientUserId: participantId,
            type: "message",
            message: "sent you a message",
            relatedConversationId: conversationId,
          );
        } catch (_) {}
      }

      await _badgeService.evaluateCurrentUserBadges();

      return null;
    } catch (e) {
      return e.toString().replaceFirst("Exception: ", "");
    }
  }

  Future<String?> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final conversationRef =
          _firestore.collection("conversations").doc(conversationId);
      final messageRef = conversationRef.collection("messages").doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final conversationSnapshot = await transaction.get(conversationRef);
        final conversationData = conversationSnapshot.data();
        if (conversationData == null) {
          throw Exception("Conversation not found");
        }

        final messageSnapshot = await transaction.get(messageRef);
        final messageData = messageSnapshot.data();
        if (messageData == null) {
          throw Exception("Message not found");
        }

        final senderId = (messageData["senderId"] ?? "").toString();
        final messageType = (messageData["type"] ?? "").toString();
        if (messageType == "system") {
          throw Exception("System messages cannot be deleted");
        }

        if (senderId != user.uid) {
          throw Exception("You can only delete your own messages");
        }

        transaction.delete(messageRef);
      });

      final remainingMessages = await conversationRef
          .collection("messages")
          .orderBy("createdAt", descending: true)
          .limit(1)
          .get();

      if (remainingMessages.docs.isEmpty) {
        await conversationRef.update({
          "lastMessage": "",
          "lastMessageSenderId": "",
          "updatedAt": FieldValue.serverTimestamp(),
        });
        return null;
      }

      final latestMessage = remainingMessages.docs.first.data();
      await conversationRef.update({
        "lastMessage": (latestMessage["content"] ?? "").toString(),
        "lastMessageSenderId": (latestMessage["senderId"] ?? "").toString(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return e.toString().replaceFirst("Exception: ", "");
    }
  }

  Future<String?> createOrOpenConversation({
    required String otherUserId,
    required String otherUsername,
    String? otherDisplayName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final userData = await _authService.getUserData();
      final participantIds = [user.uid, otherUserId]..sort();
      final conversationId = participantIds.join("_");
      final conversationRef =
          _firestore.collection("conversations").doc(conversationId);
      final conversationSnapshot = await conversationRef.get();

      if (!conversationSnapshot.exists) {
        await conversationRef.set({
          "participantIds": participantIds,
          "participantUsernames": [
            userData["username"] ?? "",
            otherUsername,
          ]..sort(),
          "participants": {
            user.uid: {
              "username": userData["username"] ?? "",
              "displayName":
                  userData["displayName"] ?? userData["username"] ?? "",
            },
            otherUserId: {
              "username": otherUsername,
              "displayName": otherDisplayName ?? otherUsername,
            },
          },
          "status": "pending",
          "requestedByUserId": user.uid,
          "requestedToUserId": otherUserId,
          "lastMessage": "",
          "lastMessageSenderId": "",
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }

      await _badgeService.evaluateCurrentUserBadges();

      return conversationId;
    } catch (e) {
      return e.toString().replaceFirst("Exception: ", "");
    }
  }

  Future<String?> createGroupConversation({
    required String groupName,
    required List<Map<String, String>> selectedUsers,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final trimmedGroupName = groupName.trim();
      if (trimmedGroupName.isEmpty) {
        return "Group name cannot be empty";
      }

      if (selectedUsers.isEmpty) {
        return "Choose at least one member";
      }

      final currentUserData = await _authService.getUserData();
      final participantIds = <String>{
        user.uid,
        ...selectedUsers.map((user) => user["userId"] ?? ""),
      }.where((id) => id.trim().isNotEmpty).toList()
        ..sort();

      if (participantIds.length < 2) {
        return "Choose at least one member";
      }

      final participantUsernames = <String>[
        currentUserData["username"] ?? "",
        ...selectedUsers.map((user) => user["username"] ?? ""),
      ]..sort();

      final participants = <String, Map<String, String>>{
        user.uid: {
          "username": currentUserData["username"] ?? "",
          "displayName":
              currentUserData["displayName"] ?? currentUserData["username"] ?? "",
        },
      };

      for (final selectedUser in selectedUsers) {
        final userId = (selectedUser["userId"] ?? "").trim();
        if (userId.isEmpty) {
          continue;
        }

        participants[userId] = {
          "username": selectedUser["username"] ?? "Username",
          "displayName":
              selectedUser["displayName"] ??
              selectedUser["username"] ??
              "Username",
        };
      }

      final conversationRef = _firestore.collection("conversations").doc();
      final invitedUserIds = selectedUsers
          .map((user) => (user["userId"] ?? "").trim())
          .where((id) => id.isNotEmpty)
          .toList();
      final memberStatuses = <String, String>{
        user.uid: "active",
        for (final invitedUserId in invitedUserIds) invitedUserId: "invited",
      };
      final invitedByUserIds = <String, String>{
        for (final invitedUserId in invitedUserIds) invitedUserId: user.uid,
      };
      await conversationRef.set({
        "isGroup": true,
        "groupName": trimmedGroupName,
        "participantIds": participantIds,
        "activeParticipantIds": [user.uid],
        "invitedUserIds": invitedUserIds,
        "invitedByUserIds": invitedByUserIds,
        "participantUsernames": participantUsernames,
        "participants": participants,
        "memberStatuses": memberStatuses,
        "status": "accepted",
        "createdByUserId": user.uid,
        "lastMessage": "",
        "lastMessageSenderId": "",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      for (final selectedUser in selectedUsers) {
        final userId = (selectedUser["userId"] ?? "").trim();
        if (userId.isEmpty) {
          continue;
        }

        try {
          await _notificationService.createNotification(
            recipientUserId: userId,
            type: "message",
            message: "invited you to join $trimmedGroupName",
            relatedConversationId: conversationRef.id,
          );
        } catch (_) {}
      }

      await _badgeService.evaluateCurrentUserBadges();
      return conversationRef.id;
    } catch (e) {
      return "Couldn't create group right now";
    }
  }

  Future<String?> respondToRequest({
    required String conversationId,
    required bool accept,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final conversationRef =
          _firestore.collection("conversations").doc(conversationId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(conversationRef);
        final data = snapshot.data();

        if (data == null) {
          throw Exception("Conversation not found");
        }

        if (data["requestedToUserId"] != user.uid) {
          throw Exception("You cannot respond to this request");
        }

        transaction.update(conversationRef, {
          "status": accept ? "accepted" : "denied",
          "updatedAt": FieldValue.serverTimestamp(),
        });
      });

      return null;
    } catch (e) {
      return e.toString().replaceFirst("Exception: ", "");
    }
  }

  Future<String?> respondToGroupInvite({
    required String conversationId,
    required bool accept,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final conversationRef =
          _firestore.collection("conversations").doc(conversationId);
      String? joiningName;
      String? inviterName;

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(conversationRef);
        final data = snapshot.data();

        if (data == null) {
          throw Exception("Conversation not found");
        }

        final isGroup = data["isGroup"] as bool? ?? false;
        if (!isGroup) {
          throw Exception("This is not a group invitation");
        }

        final memberStatuses = Map<String, dynamic>.from(
          data["memberStatuses"] ?? const <String, dynamic>{},
        );
        final membership = (memberStatuses[user.uid] ?? "").toString();
        if (membership != "invited") {
          throw Exception("No group invite found");
        }

        final activeParticipantIds = List<String>.from(
          data["activeParticipantIds"] ?? const <String>[],
        );
        final invitedUserIds = List<String>.from(
          data["invitedUserIds"] ?? const <String>[],
        );
        final invitedByUserIds = Map<String, dynamic>.from(
          data["invitedByUserIds"] ?? const <String, dynamic>{},
        );
        final participants = Map<String, dynamic>.from(
          data["participants"] ?? const <String, dynamic>{},
        );
        final joiningParticipant = Map<String, dynamic>.from(
          participants[user.uid] ?? const <String, dynamic>{},
        );
        joiningName = (joiningParticipant["displayName"] ??
                joiningParticipant["username"] ??
                "A member")
            .toString();
        final inviterUserId = (invitedByUserIds[user.uid] ?? "").toString();
        if (inviterUserId.isNotEmpty) {
          final inviterParticipant = Map<String, dynamic>.from(
            participants[inviterUserId] ?? const <String, dynamic>{},
          );
          inviterName = (inviterParticipant["displayName"] ??
                  inviterParticipant["username"] ??
                  "A member")
              .toString();
        }

        memberStatuses[user.uid] = accept ? "active" : "declined";

        if (accept && !activeParticipantIds.contains(user.uid)) {
          activeParticipantIds.add(user.uid);
        }
        invitedUserIds.remove(user.uid);
        invitedByUserIds.remove(user.uid);

        transaction.update(conversationRef, {
          "memberStatuses": memberStatuses,
          "activeParticipantIds": activeParticipantIds,
          "invitedUserIds": invitedUserIds,
          "invitedByUserIds": invitedByUserIds,
          "updatedAt": FieldValue.serverTimestamp(),
        });
      });

      if (accept) {
        final joinMessage = inviterName == null || inviterName!.isEmpty
            ? "${joiningName ?? "A member"} joined the group."
            : "${joiningName ?? "A member"} joined the group via ${inviterName!}'s invite.";
        await _addSystemMessage(
          conversationRef: conversationRef,
          content: joinMessage,
        );
      }

      return null;
    } catch (e) {
      return e.toString().replaceFirst("Exception: ", "");
    }
  }

  Future<String?> leaveGroup(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final conversationRef =
          _firestore.collection("conversations").doc(conversationId);

      final snapshot = await conversationRef.get();
      final data = snapshot.data();

      if (data == null) {
        return "Conversation not found";
      }

      final isGroup = data["isGroup"] as bool? ?? false;
      if (!isGroup) {
        return "This is not a group chat";
      }

      final participants = Map<String, dynamic>.from(
        data["participants"] ?? const <String, dynamic>{},
      );
      final currentParticipant = Map<String, dynamic>.from(
        participants[user.uid] ?? const <String, dynamic>{},
      );
      final leavingName =
          (currentParticipant["displayName"] ??
                  currentParticipant["username"] ??
                  "A member")
              .toString();

      final createdByUserId = (data["createdByUserId"] ?? "").toString();
      final activeParticipantIds = List<String>.from(
        data["activeParticipantIds"] ?? const <String>[],
      );
      final remainingActiveIds = activeParticipantIds
          .where((memberId) => memberId != user.uid)
          .toList();

      if (createdByUserId == user.uid && remainingActiveIds.isEmpty) {
        final messagesSnapshot = await conversationRef.collection("messages").get();
        final batch = _firestore.batch();
        for (final message in messagesSnapshot.docs) {
          batch.delete(message.reference);
        }
        batch.delete(conversationRef);
        await batch.commit();
        return null;
      }

      await _firestore.runTransaction((transaction) async {
        final freshSnapshot = await transaction.get(conversationRef);
        final freshData = freshSnapshot.data();

        if (freshData == null) {
          throw Exception("Conversation not found");
        }

        final freshMemberStatuses = Map<String, dynamic>.from(
          freshData["memberStatuses"] ?? const <String, dynamic>{},
        );
        final freshActiveParticipantIds = List<String>.from(
          freshData["activeParticipantIds"] ?? const <String>[],
        );

        freshMemberStatuses[user.uid] = "left";
        freshActiveParticipantIds.remove(user.uid);

        final updateData = <String, Object?>{
          "memberStatuses": freshMemberStatuses,
          "activeParticipantIds": freshActiveParticipantIds,
          "updatedAt": FieldValue.serverTimestamp(),
        };

        if (createdByUserId == user.uid && remainingActiveIds.isNotEmpty) {
          updateData["createdByUserId"] = remainingActiveIds.first;
        }

        transaction.update(conversationRef, updateData);
      });

      await _addSystemMessage(
        conversationRef: conversationRef,
        content: "$leavingName left the group.",
      );

      return null;
    } catch (e) {
      return e.toString().replaceFirst("Exception: ", "");
    }
  }

  Future<String?> kickGroupMember({
    required String conversationId,
    required String memberUserId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final conversationRef =
          _firestore.collection("conversations").doc(conversationId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(conversationRef);
        final data = snapshot.data();

        if (data == null) {
          throw Exception("Conversation not found");
        }

        final isGroup = data["isGroup"] as bool? ?? false;
        if (!isGroup) {
          throw Exception("This is not a group chat");
        }

        final createdByUserId = (data["createdByUserId"] ?? "").toString();
        if (createdByUserId != user.uid) {
          throw Exception("Only the group creator can remove members");
        }

        if (memberUserId == createdByUserId) {
          throw Exception("The creator cannot remove themselves");
        }

        final participants = Map<String, dynamic>.from(
          data["participants"] ?? const <String, dynamic>{},
        );
        final kickedParticipant = Map<String, dynamic>.from(
          participants[memberUserId] ?? const <String, dynamic>{},
        );
        final removedName =
            (kickedParticipant["displayName"] ??
                    kickedParticipant["username"] ??
                    "A member")
                .toString();

        final memberStatuses = Map<String, dynamic>.from(
          data["memberStatuses"] ?? const <String, dynamic>{},
        );
        final activeParticipantIds = List<String>.from(
          data["activeParticipantIds"] ?? const <String>[],
        );
        final invitedUserIds = List<String>.from(
          data["invitedUserIds"] ?? const <String>[],
        );

        memberStatuses[memberUserId] = "removed";
        activeParticipantIds.remove(memberUserId);
        invitedUserIds.remove(memberUserId);

        transaction.update(conversationRef, {
          "memberStatuses": memberStatuses,
          "activeParticipantIds": activeParticipantIds,
          "invitedUserIds": invitedUserIds,
          "updatedAt": FieldValue.serverTimestamp(),
        });

        final messageRef = conversationRef.collection("messages").doc();
        transaction.set(messageRef, {
          "senderId": "",
          "senderUsername": "system",
          "senderDisplayName": "Mindora",
          "content": "$removedName was removed from the group.",
          "type": "system",
          "createdAt": FieldValue.serverTimestamp(),
        });
      });

      return null;
    } catch (e) {
      return e.toString().replaceFirst("Exception: ", "");
    }
  }

  Future<String?> inviteMembersToGroup({
    required String conversationId,
    required List<Map<String, String>> selectedUsers,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      if (selectedUsers.isEmpty) {
        return "Choose at least one member";
      }

      final conversationRef =
          _firestore.collection("conversations").doc(conversationId);

      late String groupName;
      late List<String> invitedUserIds;

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(conversationRef);
        final data = snapshot.data();

        if (data == null) {
          throw Exception("Conversation not found");
        }

        final isGroup = data["isGroup"] as bool? ?? false;
        if (!isGroup) {
          throw Exception("This is not a group chat");
        }

        final createdByUserId = (data["createdByUserId"] ?? "").toString();
        if (createdByUserId != user.uid) {
          throw Exception("Only the group creator can add members");
        }

        groupName = (data["groupName"] ?? "Group Chat").toString();

        final participantIds = List<String>.from(
          data["participantIds"] ?? const <String>[],
        );
        final invitedIds = List<String>.from(
          data["invitedUserIds"] ?? const <String>[],
        );
        final participantUsernames = List<String>.from(
          data["participantUsernames"] ?? const <String>[],
        );
        final participants = Map<String, dynamic>.from(
          data["participants"] ?? const <String, dynamic>{},
        );
        final memberStatuses = Map<String, dynamic>.from(
          data["memberStatuses"] ?? const <String, dynamic>{},
        );
        final invitedByUserIds = Map<String, dynamic>.from(
          data["invitedByUserIds"] ?? const <String, dynamic>{},
        );

        invitedUserIds = [];

        for (final selectedUser in selectedUsers) {
          final userId = (selectedUser["userId"] ?? "").trim();
          if (userId.isEmpty) {
            continue;
          }

          final membership = (memberStatuses[userId] ?? "").toString();
          if (membership == "active" || membership == "invited") {
            continue;
          }

          if (!participantIds.contains(userId)) {
            participantIds.add(userId);
          }

          final username = (selectedUser["username"] ?? "Username").trim();
          if (username.isNotEmpty && !participantUsernames.contains(username)) {
            participantUsernames.add(username);
          }

          participants[userId] = {
            "username": username.isEmpty ? "Username" : username,
            "displayName": (selectedUser["displayName"] ??
                    selectedUser["username"] ??
                    "Username")
                .trim(),
          };
          memberStatuses[userId] = "invited";
          invitedByUserIds[userId] = user.uid;
          if (!invitedIds.contains(userId)) {
            invitedIds.add(userId);
          }
          invitedUserIds.add(userId);
        }

        if (invitedUserIds.isEmpty) {
          throw Exception("No new members selected");
        }

        participantIds.sort();
        participantUsernames.sort();

        transaction.update(conversationRef, {
          "participantIds": participantIds,
          "participantUsernames": participantUsernames,
          "participants": participants,
          "memberStatuses": memberStatuses,
          "invitedUserIds": invitedIds,
          "invitedByUserIds": invitedByUserIds,
          "updatedAt": FieldValue.serverTimestamp(),
        });
      });

      for (final invitedUserId in invitedUserIds) {
        try {
          await _notificationService.createNotification(
            recipientUserId: invitedUserId,
            type: "message",
            message: "invited you to join $groupName",
            relatedConversationId: conversationId,
          );
        } catch (_) {}
      }

      return null;
    } catch (e) {
      return e.toString().replaceFirst("Exception: ", "");
    }
  }
}

