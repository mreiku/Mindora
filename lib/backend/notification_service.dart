import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../backend/auth_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection("notifications")
        .where("recipientUserId", isEqualTo: user.uid)
        .snapshots();
  }

  Future<void> createNotification({
    required String recipientUserId,
    required String type,
    required String message,
    String? relatedPostId,
    String? relatedConversationId,
  }) async {
    final user = _auth.currentUser;
    if (user == null || recipientUserId == user.uid) {
      return;
    }

    final userData = await _authService.getUserData();

    await _firestore.collection("notifications").add({
      "recipientUserId": recipientUserId,
      "senderUserId": user.uid,
      "senderUsername": userData["username"] ?? "",
      "senderDisplayName": userData["displayName"] ?? userData["username"] ?? "",
      "type": type,
      "message": message,
      "relatedPostId": relatedPostId,
      "relatedConversationId": relatedConversationId,
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection("notifications").doc(notificationId).set({
      "isRead": true,
    }, SetOptions(merge: true));
  }
}

