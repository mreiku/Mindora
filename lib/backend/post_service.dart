import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../backend/auth_service.dart';
import '../backend/badge_service.dart';
import '../backend/notification_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final BadgeService _badgeService = BadgeService();
  final NotificationService _notificationService = NotificationService();
  static const int maxEditsPerWindow = 5;
  static const Duration editWindowDuration = Duration(hours: 6);

  String _currentDayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return "${now.year}-$month-$day";
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPostsStream() {
    return _firestore
        .collection("posts")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchPosts() async {
    final snapshot = await _firestore
        .collection("posts")
        .orderBy("createdAt", descending: true)
        .get();
    return snapshot.docs;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserPostsStream(String userId) {
    return _firestore
        .collection("posts")
        .where("userId", isEqualTo: userId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserRepliesStream(String userId) {
    return _firestore
        .collection("replies")
        .where("userId", isEqualTo: userId)
        .snapshots();
  }

  Future<String?> createPost({
    required String content,
    String privacy = "Public",
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final trimmedContent = content.trim();
      if (trimmedContent.isEmpty) {
        return "Post cannot be empty";
      }

      final userData = await _authService.getUserData();

      await _firestore.collection("posts").add({
        "userId": user.uid,
        "username": userData["username"] ?? "",
        "displayName": userData["displayName"] ?? userData["username"] ?? "",
        "content": trimmedContent,
        "dayKey": _currentDayKey(),
        "privacy": privacy,
        "likeCount": 0,
        "commentCount": 0,
        "likedBy": <String>[],
        "editCount": 0,
        "editWindowStartedAt": null,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": null,
      });

      await _badgeService.evaluateCurrentUserBadges();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection("posts").doc(postId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCommentsStream(String postId) {
    return _firestore
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  Future<String?> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final trimmedContent = content.trim();
      if (trimmedContent.isEmpty) {
        return "Reply cannot be empty";
      }

      final userData = await _authService.getUserData();

      await _firestore
          .collection("posts")
          .doc(postId)
          .collection("comments")
          .add({
        "userId": user.uid,
        "username": userData["username"] ?? "",
        "displayName": userData["displayName"] ?? userData["username"] ?? "",
        "content": trimmedContent,
        "dayKey": _currentDayKey(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      await _firestore.collection("replies").add({
        "postId": postId,
        "userId": user.uid,
        "username": userData["username"] ?? "",
        "displayName": userData["displayName"] ?? userData["username"] ?? "",
        "content": trimmedContent,
        "dayKey": _currentDayKey(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      await _firestore.collection("posts").doc(postId).update({
        "commentCount": FieldValue.increment(1),
      });

      final postSnapshot = await _firestore.collection("posts").doc(postId).get();
      final postOwnerId = (postSnapshot.data()?["userId"] ?? "").toString();
      if (postOwnerId.isNotEmpty) {
        try {
          await _notificationService.createNotification(
            recipientUserId: postOwnerId,
            type: "reply",
            message: "replied to your post",
            relatedPostId: postId,
          );
        } catch (_) {}
      }

      await _badgeService.evaluateCurrentUserBadges();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final commentRef = _firestore
          .collection("posts")
          .doc(postId)
          .collection("comments")
          .doc(commentId);
      final commentSnapshot = await commentRef.get();
      final commentData = commentSnapshot.data();

      if (commentData == null) {
        return "Reply not found";
      }

      if (commentData["userId"] != user.uid) {
        return "You can only delete your own reply";
      }

      final mirroredReplies = await _firestore
          .collection("replies")
          .where("postId", isEqualTo: postId)
          .where("userId", isEqualTo: user.uid)
          .where("content", isEqualTo: commentData["content"] ?? "")
          .limit(1)
          .get();

      await commentRef.delete();

      if (mirroredReplies.docs.isNotEmpty) {
        await mirroredReplies.docs.first.reference.delete();
      }

      await _firestore.collection("posts").doc(postId).update({
        "commentCount": FieldValue.increment(-1),
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> toggleLike(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final postRef = _firestore.collection("posts").doc(postId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);
        final data = snapshot.data();

        if (data == null) {
          throw Exception("Post not found");
        }

        final likedBy = List<String>.from(data["likedBy"] ?? []);
        final isLiked = likedBy.contains(user.uid);

        if (isLiked) {
          likedBy.remove(user.uid);
        } else {
          likedBy.add(user.uid);
        }

        transaction.update(postRef, {
          "likedBy": likedBy,
          "likeCount": likedBy.length,
        });
      });

      final postSnapshot = await postRef.get();
      final postData = postSnapshot.data();
      final postOwnerId = (postData?["userId"] ?? "").toString();
      final likedBy = List<String>.from(postData?["likedBy"] ?? []);
      final isNowLiked = likedBy.contains(user.uid);

      if (isNowLiked && postOwnerId.isNotEmpty) {
        try {
          await _notificationService.createNotification(
            recipientUserId: postOwnerId,
            type: "reaction",
            message: "reacted to your post",
            relatedPostId: postId,
          );
        } catch (_) {}
      }

      await _badgeService.evaluateCurrentUserBadges();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updatePost({
    required String postId,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final trimmedContent = content.trim();
      if (trimmedContent.isEmpty) {
        return "Post cannot be empty";
      }

      final postRef = _firestore.collection("posts").doc(postId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);
        final data = snapshot.data();

        if (data == null) {
          throw Exception("Post not found");
        }

        if (data["userId"] != user.uid) {
          throw Exception("You can only edit your own posts");
        }

        final currentContent = (data["content"] ?? "").toString().trim();
        if (currentContent == trimmedContent) {
          throw Exception("No changes made");
        }

        final windowStartedAt = data["editWindowStartedAt"];
        final editWindowStartedAt = windowStartedAt is Timestamp
            ? windowStartedAt.toDate()
            : null;
        final rawEditCount = data["editCount"];
        var editCount = rawEditCount is int ? rawEditCount : 0;
        final now = DateTime.now();

        if (editWindowStartedAt == null ||
            now.difference(editWindowStartedAt) >= editWindowDuration) {
          editCount = 0;
        }

        if (editCount >= maxEditsPerWindow) {
          throw Exception(
            "You can only edit this post 5 times every 6 hours",
          );
        }

        transaction.update(postRef, {
          "content": trimmedContent,
          "editCount": editCount + 1,
          "editWindowStartedAt": editCount == 0
              ? Timestamp.fromDate(now)
              : data["editWindowStartedAt"],
          "updatedAt": FieldValue.serverTimestamp(),
        });
      });

      return null;
    } catch (e) {
      return e.toString().replaceFirst("Exception: ", "");
    }
  }
}

