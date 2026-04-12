import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../backend/quest_service.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandCream = isDark ? const Color(0xFF151313) : const Color(0xFFFFEAD3);
    final brandDarkRed =
        isDark ? const Color(0xFFFFEAD3) : const Color(0xFF9B3B35);
    final questService = QuestService();

    return Scaffold(
      backgroundColor: brandCream,
      appBar: AppBar(
        backgroundColor: brandCream,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: brandDarkRed),
        title: Text(
          "Tracker",
          style: TextStyle(
            color: brandDarkRed,
            fontFamily: 'Jomhuria',
            fontSize: 50,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: questService.streamQuestLogs(),
        builder: (context, snapshot) {
          final docs = [...(snapshot.data?.docs ?? [])]
            ..sort((a, b) {
              final aTimestamp = a.data()["completedAt"] as Timestamp?;
              final bTimestamp = b.data()["completedAt"] as Timestamp?;
              final aMillis = aTimestamp?.millisecondsSinceEpoch ?? 0;
              final bMillis = bTimestamp?.millisecondsSinceEpoch ?? 0;
              return bMillis.compareTo(aMillis);
            });
          final totalPoints = docs.fold<int>(
            0,
            (sum, doc) => sum + ((doc.data()["points"] as int?) ?? 0),
          );
          final todayKey = questService.todayKey;
          final completedToday = docs
              .where((doc) => (doc.data()["dayKey"] ?? "").toString() == todayKey)
              .toList();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: questService.streamTodayPosts(),
            builder: (context, postSnapshot) {
              final postCount = postSnapshot.data?.docs.length ?? 0;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: questService.streamTodayReplies(),
                builder: (context, replySnapshot) {
                  final replyCount = replySnapshot.data?.docs.length ?? 0;

                  return SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97C73),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF8B2E2E),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Quest Summary",
                            style: TextStyle(
                              fontSize: 38,
                              fontFamily: 'Jomhuria',
                              height: 0.9,
                              color: brandDarkRed,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "$totalPoints total points earned",
                            style: const TextStyle(
                              color: Color(0xFFF6E3CC),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${completedToday.length} quest${completedToday.length == 1 ? "" : "s"} completed today",
                            style: const TextStyle(
                              color: Color(0xFFFFEAD3),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                        const SizedBox(height: 20),
                        Text(
                      "Daily Progress",
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'Jomhuria',
                        color: brandDarkRed,
                      ),
                    ),
                        const SizedBox(height: 14),
                        _QuestProgressCard(
                      title: "Daily Login",
                      subtitle: "Claim this from the Quest page once per day.",
                      progress: completedToday.any((doc) =>
                              (doc.data()["questId"] ?? "") ==
                              QuestService.dailyLoginQuest.id)
                          ? 1
                          : 0,
                      target: 1,
                    ),
                        _QuestProgressCard(
                      title: "Post a Question",
                      subtitle: "Today's posting progress",
                      progress: postCount,
                      target: QuestService.dailyPostQuest.targetCount ?? 1,
                    ),
                        _QuestProgressCard(
                      title: "Reply to a Post",
                      subtitle: "Today's reply progress",
                      progress: replyCount,
                      target: QuestService.dailyReplyQuest.targetCount ?? 1,
                    ),
                        _QuestProgressCard(
                      title: "Subject Challenges",
                      subtitle: "Completed learning challenges",
                      progress: docs
                          .where((doc) => (doc.data()["type"] ?? "") == "subject")
                          .length,
                      target: QuestService.subjectQuests.length,
                    ),
                        const SizedBox(height: 20),
                        Text(
                      "Recent Quest Log",
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'Jomhuria',
                        color: brandDarkRed,
                      ),
                    ),
                        const SizedBox(height: 12),
                        if (docs.isEmpty)
                          Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97C73),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          "No quest entries yet. Complete a quest from the Quest page and it will appear here.",
                          style: TextStyle(
                            color: Color(0xFFFFEAD3),
                            height: 1.4,
                          ),
                        ),
                      ),
                        ...docs.take(10).map((doc) {
                          final data = doc.data();
                          final title = (data["title"] ?? "Quest").toString();
                          final points = (data["points"] ?? 0).toString();
                          final subject = (data["subject"] ?? "").toString();
                          final dayKey = (data["dayKey"] ?? "").toString();
                          final type = (data["type"] ?? "").toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97C73),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF8B2E2E),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBD5BE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    type == "subject"
                                        ? Icons.menu_book_rounded
                                        : Icons.emoji_events,
                                    color: const Color(0xFF8B2E2E),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6B1F1F),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subject.isEmpty
                                            ? "Completed on $dayKey"
                                            : "$subject challenge completed on $dayKey",
                                        style: const TextStyle(
                                          color: Color(0xFFF6E3CC),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "+$points",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6B1F1F),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _QuestProgressCard extends StatelessWidget {
  const _QuestProgressCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.target,
  });

  final String title;
  final String subtitle;
  final int progress;
  final int target;

  @override
  Widget build(BuildContext context) {
    final cappedProgress = progress > target ? target : progress;
    final progressRatio = target == 0 ? 0.0 : cappedProgress / target;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD97C73),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B2E2E), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBD5BE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Color(0xFF8B2E2E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B1F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFF6E3CC),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBD5BE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progressRatio,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB84842),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          "$cappedProgress/$target",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B1F1F),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
