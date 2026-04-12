import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'badge_service.dart';

class QuestDefinition {
  const QuestDefinition({
    required this.id,
    required this.title,
    required this.points,
    required this.type,
    this.description,
    this.targetCount,
    this.subject,
    this.question,
    this.correctAnswer,
  });

  final String id;
  final String title;
  final int points;
  final String type;
  final String? description;
  final int? targetCount;
  final String? subject;
  final String? question;
  final String? correctAnswer;
}

class QuestService {
  QuestService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final BadgeService _badgeService = BadgeService();

  static const dailyLoginQuest = QuestDefinition(
    id: "daily_login",
    title: "Daily Login",
    description: "Open Mindora and claim your daily login reward.",
    points: 5,
    type: "daily",
    targetCount: 1,
  );

  static const dailyPostQuest = QuestDefinition(
    id: "daily_post_question",
    title: "Post a Question",
    description: "Create 1 post today.",
    points: 5,
    type: "daily",
    targetCount: 1,
  );

  static const dailyReplyQuest = QuestDefinition(
    id: "daily_reply_post",
    title: "Reply to a Post",
    description: "Write 1 reply today.",
    points: 5,
    type: "daily",
    targetCount: 1,
  );

  static const subjectQuests = <QuestDefinition>[
    QuestDefinition(
      id: "subject_english_adjectives",
      title: "English Challenge",
      subject: "ENGLISH",
      question: "Adjectives always come before the noun they describe.",
      correctAnswer: "FALSE",
      points: 10,
      type: "subject",
    ),
    QuestDefinition(
      id: "subject_filipino_baybayin",
      title: "Filipino Challenge",
      subject: "FILIPINO",
      question:
          "Ano ang tawag sa sinaunang sistema ng pagsulat ng mga Pilipino?",
      correctAnswer: "Baybayin",
      points: 15,
      type: "subject",
    ),
    QuestDefinition(
      id: "subject_math_diameter",
      title: "Math Challenge",
      subject: "MATH",
      question:
          "If a circle has a radius of 5 units, what will be its diameter?",
      correctAnswer: "10",
      points: 10,
      type: "subject",
    ),
  ];

  String get _todayKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return "${now.year}-$month-$day";
  }

  String get todayKey => _todayKey;

  CollectionReference<Map<String, dynamic>> _userQuestLogs(String uid) {
    return _firestore.collection("users").doc(uid).collection("questLogs");
  }

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamQuestLogs() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream.empty();
    }

    return _userQuestLogs(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTodayQuestLogs() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream.empty();
    }

    return _userQuestLogs(uid)
        .where("dayKey", isEqualTo: _todayKey)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTodayPosts() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection("posts")
        .where("userId", isEqualTo: uid)
        .where("dayKey", isEqualTo: _todayKey)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTodayReplies() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection("replies")
        .where("userId", isEqualTo: uid)
        .where("dayKey", isEqualTo: _todayKey)
        .snapshots();
  }

  Future<bool> isQuestCompletedToday(String questId) async {
    final uid = currentUserId;
    if (uid == null) {
      return false;
    }

    final doc = await _userQuestLogs(uid).doc("${questId}_$_todayKey").get();
    return doc.exists;
  }

  Future<bool> isQuestCompleted(String questId) async {
    final uid = currentUserId;
    if (uid == null) {
      return false;
    }

    final doc = await _userQuestLogs(uid).doc(questId).get();
    return doc.exists;
  }

  Future<int> getTodayPostCount() async {
    final uid = currentUserId;
    if (uid == null) {
      return 0;
    }

    final snapshot = await _firestore
        .collection("posts")
        .where("userId", isEqualTo: uid)
        .where("dayKey", isEqualTo: _todayKey)
        .get();
    return snapshot.docs.length;
  }

  Future<int> getTodayReplyCount() async {
    final uid = currentUserId;
    if (uid == null) {
      return 0;
    }

    final snapshot = await _firestore
        .collection("replies")
        .where("userId", isEqualTo: uid)
        .where("dayKey", isEqualTo: _todayKey)
        .get();
    return snapshot.docs.length;
  }

  Future<String?> claimDailyQuest(
    QuestDefinition quest, {
    required int progressCount,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) {
        return "No user logged in";
      }

      final target = quest.targetCount ?? 1;
      if (progressCount < target) {
        return "Complete the quest requirement first";
      }

      final docId = "${quest.id}_$_todayKey";
      final docRef = _userQuestLogs(uid).doc(docId);
      final existingDoc = await docRef.get();

      if (existingDoc.exists) {
        return "You already claimed this quest today";
      }

      await docRef.set({
        "questId": quest.id,
        "title": quest.title,
        "type": quest.type,
        "points": quest.points,
        "targetCount": target,
        "progressCount": progressCount,
        "dayKey": _todayKey,
        "completedAt": FieldValue.serverTimestamp(),
      });

      await _badgeService.evaluateCurrentUserBadges();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> completeSubjectQuest(
    QuestDefinition quest, {
    required String answer,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) {
        return "No user logged in";
      }

      final trimmedAnswer = answer.trim();
      if (trimmedAnswer.isEmpty) {
        return "Please enter an answer";
      }

      final normalizedAnswer = trimmedAnswer.toLowerCase();
      final expectedAnswer = (quest.correctAnswer ?? "").trim().toLowerCase();

      if (normalizedAnswer != expectedAnswer) {
        return "That answer is not correct";
      }

      final docRef = _userQuestLogs(uid).doc(quest.id);
      final existingDoc = await docRef.get();
      if (existingDoc.exists) {
        return "You already completed this challenge";
      }

      await docRef.set({
        "questId": quest.id,
        "title": quest.title,
        "subject": quest.subject,
        "type": quest.type,
        "points": quest.points,
        "answer": trimmedAnswer,
        "dayKey": _todayKey,
        "completedAt": FieldValue.serverTimestamp(),
      });

      await _badgeService.evaluateCurrentUserBadges();

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
