import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'badge_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BadgeService _badgeService = BadgeService();
  static Map<String, String>? _cachedUserData;
  static const int maxUsernameChangesPerWeek = 3;
  static const Duration usernameChangeWindow = Duration(days: 7);
  static const Duration activeThreshold = Duration(seconds: 20);

  Map<String, String>? get cachedUserData => _cachedUserData;

  Future<bool> isCurrentUserEmailVerified({bool reload = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    if (reload) {
      await user.reload();
    }

    final refreshedUser = _auth.currentUser;
    return refreshedUser?.emailVerified ?? false;
  }

  // SIGN UP
  Future<String?> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      var usernameCheck = await _firestore
          .collection("users")
          .where("username", isEqualTo: username)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        return "Username already taken";
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "username": username,
        "displayName": username,
        "pronouns": "",
        "bio": "",
        "email": email,
        "emailVerified": false,
        "isAdmin": false,
        "isDarkModeEnabled": false,
        "usernameChangeCount": 0,
        "usernameChangeWindowStartedAt": null,
        "manualIsActive": true,
        "isActive": true,
        "lastActiveAt": FieldValue.serverTimestamp(),
      });

      _cachedUserData = {
        "username": username,
        "displayName": username,
        "pronouns": "",
        "bio": "",
        "email": email,
      };

      await userCredential.user?.sendEmailVerification();
      await _badgeService.evaluateCurrentUserBadges();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // LOGIN USING USERNAME
  Future<String?> login({
    required String username,
    required String password,
  }) async {
    try {
      final result = await _firestore
          .collection("users")
          .where("username", isEqualTo: username)
          .get();

      if (result.docs.isEmpty) {
        return "Username not found";
      }

      final userData = result.docs.first.data();
      final isDisabled = userData["isDisabled"] as bool? ?? false;
      if (isDisabled) {
        return "This account is no longer available";
      }

      final userRef = _firestore.collection("users").doc(result.docs.first.id);
      final primaryEmail = (userData["email"] ?? "").toString().trim();
      final pendingEmail = (userData["pendingEmail"] ?? "").toString().trim();
      final candidateEmails = <String>[
        if (primaryEmail.isNotEmpty) primaryEmail,
        if (pendingEmail.isNotEmpty && pendingEmail != primaryEmail) pendingEmail,
      ];

      UserCredential? credential;
      String? signedInEmail;

      for (final email in candidateEmails) {
        try {
          credential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          signedInEmail = email;
          break;
        } on FirebaseAuthException {
          continue;
        }
      }

      if (credential == null || signedInEmail == null) {
        return "Login failed";
      }

      if (pendingEmail.isNotEmpty && pendingEmail == signedInEmail) {
        await userRef.set({
          "email": signedInEmail,
          "pendingEmail": FieldValue.delete(),
        }, SetOptions(merge: true));
      }

      await syncCurrentUserEmailVerification();

      final isVerified = await isCurrentUserEmailVerified();
      if (!isVerified) {
        return "EMAIL_NOT_VERIFIED";
      }

      await syncCurrentUserPresence(true);
      await _badgeService.evaluateCurrentUserBadges();

      _cachedUserData = {
        "username": result.docs.first["username"],
        "displayName": result.docs.first["displayName"] ?? result.docs.first["username"],
        "pronouns": (result.docs.first.data()["pronouns"] ?? "").toString(),
        "bio": (result.docs.first.data()["bio"] ?? "").toString(),
        "email": signedInEmail,
      };

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Login failed";
    } catch (e) {
      return "Login failed";
    }
  }

  // RESET PASSWORD
  Future<String?> resetPassword(String emailOrUsername) async {
    try {
      final trimmedValue = emailOrUsername.trim();
      if (trimmedValue.isEmpty) {
        return "Please enter your email or username";
      }

      String emailToReset = trimmedValue;

      if (!trimmedValue.contains("@")) {
        final result = await _firestore
            .collection("users")
            .where("username", isEqualTo: trimmedValue)
            .limit(1)
            .get();

        if (result.docs.isEmpty) {
          return "Username not found";
        }

        emailToReset = (result.docs.first.data()["email"] ?? "").toString().trim();
      }

      if (emailToReset.isEmpty) {
        return "No email found for this account";
      }

      await _auth.sendPasswordResetEmail(email: emailToReset);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "invalid-email":
          return "Please enter a valid email";
        case "user-not-found":
          return "No account found for that email";
        default:
          return e.message ?? "Failed to send reset link";
      }
    } catch (e) {
      return "Failed to send reset link";
    }
  }

  Future<String?> sendSignupEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Failed to send verification email";
    } catch (e) {
      return "Failed to send verification email";
    }
  }

  Future<void> syncCurrentUserEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) {
      return;
    }

    await _firestore.collection("users").doc(refreshedUser.uid).set({
      "emailVerified": refreshedUser.emailVerified,
    }, SetOptions(merge: true));
    await _badgeService.evaluateCurrentUserBadges();
  }

  // GET FULL USER DATA
  Future<Map<String, String>> getUserData() async {
    String uid = _auth.currentUser!.uid;

    var doc = await _firestore.collection("users").doc(uid).get();

    _cachedUserData = {
      "username": doc["username"],
      "displayName": doc["displayName"] ?? doc["username"],
      "pronouns": (doc.data()?["pronouns"] ?? "").toString(),
      "bio": (doc.data()?["bio"] ?? "").toString(),
      "email": doc["email"],
    };

    return _cachedUserData!;
  }

  Future<String?> updateDisplayName(String newDisplayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final trimmedDisplayName = newDisplayName.trim();
      if (trimmedDisplayName.isEmpty) {
        return "Name cannot be empty";
      }

      await _firestore.collection("users").doc(user.uid).update({
        "displayName": trimmedDisplayName,
      });

      if (_cachedUserData != null) {
        _cachedUserData = {
          ..._cachedUserData!,
          "displayName": trimmedDisplayName,
        };
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProfileDetails({
    required String displayName,
    required String pronouns,
    required String bio,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final trimmedDisplayName = displayName.trim();
      final trimmedPronouns = pronouns.trim();
      final trimmedBio = bio.trim();

      if (trimmedDisplayName.isEmpty) {
        return "Display name cannot be empty";
      }

      await _firestore.collection("users").doc(user.uid).set({
        "displayName": trimmedDisplayName,
        "pronouns": trimmedPronouns,
        "bio": trimmedBio,
      }, SetOptions(merge: true));

      if (_cachedUserData != null) {
        _cachedUserData = {
          ..._cachedUserData!,
          "displayName": trimmedDisplayName,
          "pronouns": trimmedPronouns,
          "bio": trimmedBio,
        };
      }

      await _badgeService.evaluateCurrentUserBadges();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateDisplayedBadges(List<String> badgeIds) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final uniqueBadgeIds = <String>{...badgeIds}.take(5).toList();

      await _firestore.collection("users").doc(user.uid).set({
        "displayBadgeIds": uniqueBadgeIds,
      }, SetOptions(merge: true));

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _firestore.collection("users").doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsersStream() {
    return _firestore.collection("users").snapshots();
  }

  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    final doc = await _firestore.collection("users").doc(user.uid).get();
    return doc.data()?["isAdmin"] as bool? ?? false;
  }

  Future<String?> updateUsername(String newUsername) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final trimmedUsername = newUsername.trim();
      if (trimmedUsername.isEmpty) {
        return "Username cannot be empty";
      }

      final userRef = _firestore.collection("users").doc(user.uid);
      final currentSnapshot = await userRef.get();
      final currentData = currentSnapshot.data();

      if (currentData == null) {
        return "User data not found";
      }

      final currentUsername = (currentData["username"] ?? "").toString().trim();
      if (trimmedUsername == currentUsername) {
        return "That is already your username";
      }

      final usernameCheck = await _firestore
          .collection("users")
          .where("username", isEqualTo: trimmedUsername)
          .get();

      final isTaken = usernameCheck.docs.any((doc) => doc.id != user.uid);
      if (isTaken) {
        return "Username already taken";
      }

      final windowStartedAtValue = currentData["usernameChangeWindowStartedAt"];
      final windowStartedAt = windowStartedAtValue is Timestamp
          ? windowStartedAtValue.toDate()
          : null;
      final rawChangeCount = currentData["usernameChangeCount"];
      final storedChangeCount = rawChangeCount is int ? rawChangeCount : 0;
      final now = DateTime.now();
      final isWindowActive = windowStartedAt != null &&
          now.difference(windowStartedAt) < usernameChangeWindow;
      final changeCount = isWindowActive ? storedChangeCount : 0;
      final Object nextWindowStartedAt;
      if (isWindowActive) {
        final activeWindowStartedAt = windowStartedAt;
        nextWindowStartedAt = Timestamp.fromDate(activeWindowStartedAt);
      } else {
        nextWindowStartedAt = FieldValue.serverTimestamp();
      }

      if (changeCount >= maxUsernameChangesPerWeek) {
        return "You can only change your username 3 times per week";
      }

      await userRef.set({
        "username": trimmedUsername,
        "usernameChangeCount": changeCount + 1,
        "usernameChangeWindowStartedAt": nextWindowStartedAt,
      }, SetOptions(merge: true));

      if (_cachedUserData != null) {
        _cachedUserData = {
          ..._cachedUserData!,
          "username": trimmedUsername,
        };
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> requestEmailChangeVerification(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final trimmedEmail = newEmail.trim();
      if (trimmedEmail.isEmpty) {
        return "Email cannot be empty";
      }

      if (trimmedEmail == (user.email ?? "").trim()) {
        return "That is already your current email";
      }

      await user.verifyBeforeUpdateEmail(trimmedEmail);
      await _firestore.collection("users").doc(user.uid).set({
        "pendingEmail": trimmedEmail,
      }, SetOptions(merge: true));

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == "requires-recent-login") {
        return "Please log in again before changing your email";
      }
      return e.message ?? "Failed to send email verification";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> syncVerifiedEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      await user.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        return "No user logged in";
      }

      final userRef = _firestore.collection("users").doc(refreshedUser.uid);
      final doc = await userRef.get();
      final pendingEmail = (doc.data()?["pendingEmail"] ?? "").toString().trim();
      final currentEmail = (refreshedUser.email ?? "").trim();

      if (pendingEmail.isEmpty || pendingEmail != currentEmail) {
        return "No verified email change found yet";
      }

      await userRef.set({
        "email": currentEmail,
        "pendingEmail": FieldValue.delete(),
      }, SetOptions(merge: true));

      if (_cachedUserData != null) {
        _cachedUserData = {
          ..._cachedUserData!,
          "email": currentEmail,
        };
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> cancelPendingEmailChange() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      await _firestore.collection("users").doc(user.uid).set({
        "pendingEmail": FieldValue.delete(),
      }, SetOptions(merge: true));

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final trimmedPassword = newPassword.trim();
      if (trimmedPassword.length < 6) {
        return "Password must be at least 6 characters";
      }

      await user.updatePassword(trimmedPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == "requires-recent-login") {
        return "Please log in again before changing your password";
      }
      return e.message ?? "Failed to update password";
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> getCurrentUserDarkModePreference() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    final doc = await _firestore.collection("users").doc(user.uid).get();
    return doc.data()?["isDarkModeEnabled"] as bool? ?? false;
  }

  Future<void> updateDarkModePreference(bool isEnabled) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    await _firestore.collection("users").doc(user.uid).set({
      "isDarkModeEnabled": isEnabled,
    }, SetOptions(merge: true));
  }

  Future<void> syncCurrentUserPresence(bool isActive) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final doc = await _firestore.collection("users").doc(user.uid).get();
    final manualIsActive = doc.data()?["manualIsActive"] as bool? ?? true;
    final effectiveIsActive = manualIsActive && isActive;

    await _firestore.collection("users").doc(user.uid).set({
      "isActive": effectiveIsActive,
      "lastActiveAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  bool isUserConsideredOnline(Map<String, dynamic>? userData) {
    final isMarkedActive = userData?["isActive"] as bool? ?? false;
    if (!isMarkedActive) {
      return false;
    }

    final lastActiveAt = userData?["lastActiveAt"];
    if (lastActiveAt is! Timestamp) {
      return false;
    }

    return DateTime.now().difference(lastActiveAt.toDate()) < activeThreshold;
  }

  Future<String?> updateActiveStatus(bool isActive) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      await _firestore.collection("users").doc(user.uid).set({
        "manualIsActive": isActive,
        "isActive": isActive,
        "lastActiveAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _badgeService.evaluateCurrentUserBadges();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signOut() async {
    try {
      await syncCurrentUserPresence(false);
      await _auth.signOut();
      _cachedUserData = null;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteUserByAdmin(String targetUserId) async {
    try {
      final adminUser = _auth.currentUser;
      if (adminUser == null) {
        return "No user logged in";
      }

      final adminDoc =
          await _firestore.collection("users").doc(adminUser.uid).get();
      final isAdmin = adminDoc.data()?["isAdmin"] as bool? ?? false;
      if (!isAdmin) {
        return "Only admins can delete user accounts";
      }

      if (targetUserId == adminUser.uid) {
        return "Use the normal delete account option for your own account";
      }

      final userRef = _firestore.collection("users").doc(targetUserId);
      final userSnapshot = await userRef.get();
      if (!userSnapshot.exists) {
        return "User not found";
      }

      final userPosts = await _firestore
          .collection("posts")
          .where("userId", isEqualTo: targetUserId)
          .get();
      for (final post in userPosts.docs) {
        final comments = await post.reference.collection("comments").get();
        for (final comment in comments.docs) {
          await comment.reference.delete();
        }
        await post.reference.delete();
      }

      final userReplies = await _firestore
          .collection("replies")
          .where("userId", isEqualTo: targetUserId)
          .get();
      for (final reply in userReplies.docs) {
        await reply.reference.delete();
      }

      final allPosts = await _firestore.collection("posts").get();
      for (final post in allPosts.docs) {
        final comments = await post.reference
            .collection("comments")
            .where("userId", isEqualTo: targetUserId)
            .get();
        for (final comment in comments.docs) {
          await comment.reference.delete();
        }
      }

      final conversations = await _firestore
          .collection("conversations")
          .where("participantIds", arrayContains: targetUserId)
          .get();
      for (final conversation in conversations.docs) {
        final messages = await conversation.reference.collection("messages").get();
        for (final message in messages.docs) {
          await message.reference.delete();
        }
        await conversation.reference.delete();
      }

      await userRef.delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      final uid = user.uid;

      final userPosts =
          await _firestore.collection("posts").where("userId", isEqualTo: uid).get();
      for (final post in userPosts.docs) {
        final comments = await post.reference.collection("comments").get();
        for (final comment in comments.docs) {
          await comment.reference.delete();
        }
        await post.reference.delete();
      }

      final userReplies = await _firestore
          .collection("replies")
          .where("userId", isEqualTo: uid)
          .get();
      for (final reply in userReplies.docs) {
        await reply.reference.delete();
      }

      final conversations = await _firestore
          .collection("conversations")
          .where("participantIds", arrayContains: uid)
          .get();
      for (final conversation in conversations.docs) {
        final messages = await conversation.reference.collection("messages").get();
        for (final message in messages.docs) {
          await message.reference.delete();
        }
        await conversation.reference.delete();
      }

      await _firestore.collection("users").doc(uid).delete();
      await user.delete();
      _cachedUserData = null;

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == "requires-recent-login") {
        return "Please log in again before deleting your account";
      }
      return e.message ?? "Failed to delete account";
    } catch (e) {
      return e.toString();
    }
  }
}
