import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
}

class BadgeService {
  BadgeService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const definitions = <BadgeDefinition>[
    BadgeDefinition(
      id: "newcomer",
      title: "Newcomer",
      description: "For joining and completing first steps.",
      icon: "sparkles",
    ),
    BadgeDefinition(
      id: "conversation_starter",
      title: "Conversation Starter",
      description: "For making first posts or starting discussions.",
      icon: "forum",
    ),
    BadgeDefinition(
      id: "helpful_classmate",
      title: "Helpful Classmate",
      description: "For replying to others and giving answers.",
      icon: "school",
    ),
    BadgeDefinition(
      id: "study_buddy",
      title: "Study Buddy",
      description: "For being active in helping classmates consistently.",
      icon: "groups",
    ),
    BadgeDefinition(
      id: "campus_connector",
      title: "Campus Connector",
      description: "For messaging and interacting with more students.",
      icon: "chat",
    ),
    BadgeDefinition(
      id: "daily_achiever",
      title: "Daily Achiever",
      description: "For completing daily quests often.",
      icon: "calendar",
    ),
    BadgeDefinition(
      id: "streak_master",
      title: "Streak Master",
      description: "For logging in or staying active for many days in a row.",
      icon: "local_fire_department",
    ),
    BadgeDefinition(
      id: "subject_expert",
      title: "Subject Expert",
      description:
          "For doing well in subject challenges like English, Math, Science, or Filipino.",
      icon: "emoji_events",
    ),
    BadgeDefinition(
      id: "top_contributor",
      title: "Top Contributor",
      description: "For receiving many likes or replies.",
      icon: "thumb_up",
    ),
    BadgeDefinition(
      id: "supportive_friend",
      title: "Supportive Friend",
      description: "For often responding to others’ posts or messages.",
      icon: "favorite",
    ),
    BadgeDefinition(
      id: "profile_pro",
      title: "Profile Pro",
      description: "For completing profile setup and staying active.",
      icon: "person",
    ),
    BadgeDefinition(
      id: "quest_champion",
      title: "Quest Champion",
      description: "For earning lots of points from quests.",
      icon: "military_tech",
    ),
  ];

  BadgeDefinition? definitionForId(String badgeId) {
    for (final definition in definitions) {
      if (definition.id == badgeId) {
        return definition;
      }
    }
    return null;
  }

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _badgeCollection(String uid) {
    return _firestore.collection("users").doc(uid).collection("badges");
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCurrentUserBadges() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream.empty();
    }

    return _badgeCollection(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserBadges(String uid) {
    return _badgeCollection(uid).snapshots();
  }

  Future<void> _awardBadge(String uid, BadgeDefinition definition) async {
    final docRef = _badgeCollection(uid).doc(definition.id);
    final doc = await docRef.get();
    if (doc.exists) {
      return;
    }

    await docRef.set({
      "badgeId": definition.id,
      "title": definition.title,
      "description": definition.description,
      "icon": definition.icon,
      "earnedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> evaluateCurrentUserBadges() async {
    final uid = currentUserId;
    if (uid == null) {
      return;
    }

    final userDoc = await _firestore.collection("users").doc(uid).get();
    final userData = userDoc.data() ?? {};
    final displayName = (userData["displayName"] ?? "").toString().trim();
    final username = (userData["username"] ?? "").toString().trim();
    final emailVerified = userData["emailVerified"] as bool? ?? false;
    final isActive = userData["isActive"] as bool? ?? false;

    final postsSnapshot = await _firestore
        .collection("posts")
        .where("userId", isEqualTo: uid)
        .get();
    final repliesSnapshot = await _firestore
        .collection("replies")
        .where("userId", isEqualTo: uid)
        .get();
    final questLogsSnapshot = await _firestore
        .collection("users")
        .doc(uid)
        .collection("questLogs")
        .get();
    final conversationsSnapshot = await _firestore
        .collection("conversations")
        .where("participantIds", arrayContains: uid)
        .get();

    final postCount = postsSnapshot.docs.length;
    final replyCount = repliesSnapshot.docs.length;
    final dailyQuestCount = questLogsSnapshot.docs
        .where((doc) => (doc.data()["type"] ?? "").toString() == "daily")
        .length;
    final subjectQuestCount = questLogsSnapshot.docs
        .where((doc) => (doc.data()["type"] ?? "").toString() == "subject")
        .length;
    final totalQuestPoints = questLogsSnapshot.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()["points"] as int?) ?? 0),
    );
    final distinctConversationCount = conversationsSnapshot.docs.length;
    final totalLikesAndRepliesOnPosts = postsSnapshot.docs.fold<int>(
      0,
      (sum, doc) {
        final data = doc.data();
        final likes = data["likeCount"] as int? ?? 0;
        final replies = data["commentCount"] as int? ?? 0;
        return sum + likes + replies;
      },
    );

    final loginDays = questLogsSnapshot.docs
        .where((doc) => (doc.data()["questId"] ?? "") == "daily_login")
        .map((doc) => (doc.data()["dayKey"] ?? "").toString())
        .where((dayKey) => dayKey.isNotEmpty)
        .toSet()
        .length;

    if (emailVerified) {
      await _awardBadge(uid, definitions.firstWhere((b) => b.id == "newcomer"));
    }

    if (postCount >= 1) {
      await _awardBadge(
        uid,
        definitions.firstWhere((b) => b.id == "conversation_starter"),
      );
    }

    if (replyCount >= 1) {
      await _awardBadge(
        uid,
        definitions.firstWhere((b) => b.id == "helpful_classmate"),
      );
    }

    if (replyCount >= 10) {
      await _awardBadge(
        uid,
        definitions.firstWhere((b) => b.id == "study_buddy"),
      );
      await _awardBadge(
        uid,
        definitions.firstWhere((b) => b.id == "supportive_friend"),
      );
    }

    if (distinctConversationCount >= 3) {
      await _awardBadge(
        uid,
        definitions.firstWhere((b) => b.id == "campus_connector"),
      );
    }

    if (dailyQuestCount >= 5) {
      await _awardBadge(
        uid,
        definitions.firstWhere((b) => b.id == "daily_achiever"),
      );
    }

    if (loginDays >= 7) {
      await _awardBadge(
        uid,
        definitions.firstWhere((b) => b.id == "streak_master"),
      );
    }

    if (subjectQuestCount >= 2) {
      await _awardBadge(
        uid,
        definitions.firstWhere((b) => b.id == "subject_expert"),
      );
    }

    if (totalLikesAndRepliesOnPosts >= 10) {
      await _awardBadge(
        uid,
        definitions.firstWhere((b) => b.id == "top_contributor"),
      );
    }

    if (displayName.isNotEmpty &&
        username.isNotEmpty &&
        emailVerified &&
        isActive) {
      await _awardBadge(
        uid,
        definitions.firstWhere((b) => b.id == "profile_pro"),
      );
    }

    if (totalQuestPoints >= 50) {
      await _awardBadge(
        uid,
        definitions.firstWhere((b) => b.id == "quest_champion"),
      );
    }
  }
}
