import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../backend/quest_service.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  final QuestService _questService = QuestService();

  Future<void> _claimDailyQuest(
    QuestDefinition quest, {
    required int progressCount,
  }) async {
    final result = await _questService.claimDailyQuest(
      quest,
      progressCount: progressCount,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result ?? "${quest.title} added to your tracker"),
      ),
    );
  }

  Future<void> _submitSubjectQuest(QuestDefinition quest) async {
    final controller = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFEAD3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                "Answer ${quest.subject}",
                style: const TextStyle(color: Color(0xFF9B3B35)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.question ?? "",
                    style: const TextStyle(
                      color: Color(0xFF9B3B35),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Your answer...",
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await _questService.completeSubjectQuest(
                      quest,
                      answer: controller.text,
                    );

                    if (!mounted) {
                      return;
                    }

                    if (result != null) {
                      setDialogState(() {
                        errorText = result;
                      });
                      return;
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${quest.title} completed and logged in tracker",
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4554E),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandCream = isDark ? const Color(0xFF151313) : const Color(0xFFFFEAD3);
    final brandDarkRed =
        isDark ? const Color(0xFFFFEAD3) : const Color(0xFF9B3B35);

    return Scaffold(
      backgroundColor: brandCream,
      appBar: AppBar(
        backgroundColor: brandCream,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: brandDarkRed),
        title: Text(
          "Quests",
          style: TextStyle(
            color: brandDarkRed,
            fontFamily: 'Jomhuria',
            fontSize: 50,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _questService.streamQuestLogs(),
        builder: (context, questSnapshot) {
          final completedDocs = questSnapshot.data?.docs ?? [];
          final completedIds =
              completedDocs.map((doc) => (doc.data()["questId"] ?? "").toString()).toSet();
          final todayKey = _questService.todayKey;
          final completedTodayIds = completedDocs
              .where((doc) => (doc.data()["dayKey"] ?? "").toString() == todayKey)
              .map((doc) => (doc.data()["questId"] ?? "").toString())
              .toSet();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _questService.streamTodayPosts(),
            builder: (context, postSnapshot) {
              final postCount = postSnapshot.data?.docs.length ?? 0;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _questService.streamTodayReplies(),
                builder: (context, replySnapshot) {
                  final replyCount = replySnapshot.data?.docs.length ?? 0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE08980),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF9B3B35),
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Quest Board",
                                style: TextStyle(
                                  fontSize: 42,
                                  fontFamily: 'Jomhuria',
                                  height: 0.9,
                                  color: brandDarkRed,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Finish daily actions and subject challenges to log them in your tracker.",
                                style: TextStyle(
                                  color: Color(0xFFF6E3CC),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Daily Quests",
                          style: TextStyle(
                            fontSize: 32,
                            fontFamily: 'Jomhuria',
                            color: brandDarkRed,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _DailyQuestCard(
                          quest: QuestService.dailyLoginQuest,
                          progressCount: 1,
                          isClaimed: completedTodayIds.contains(
                            QuestService.dailyLoginQuest.id,
                          ),
                          onClaim: () => _claimDailyQuest(
                            QuestService.dailyLoginQuest,
                            progressCount: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DailyQuestCard(
                          quest: QuestService.dailyPostQuest,
                          progressCount: postCount,
                          isClaimed: completedTodayIds.contains(
                            QuestService.dailyPostQuest.id,
                          ),
                          onClaim: () => _claimDailyQuest(
                            QuestService.dailyPostQuest,
                            progressCount: postCount,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DailyQuestCard(
                          quest: QuestService.dailyReplyQuest,
                          progressCount: replyCount,
                          isClaimed: completedTodayIds.contains(
                            QuestService.dailyReplyQuest.id,
                          ),
                          onClaim: () => _claimDailyQuest(
                            QuestService.dailyReplyQuest,
                            progressCount: replyCount,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Subject Challenges",
                          style: TextStyle(
                            fontSize: 32,
                            fontFamily: 'Jomhuria',
                            color: brandDarkRed,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...QuestService.subjectQuests.map((quest) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _SubjectQuestCard(
                              quest: quest,
                              isCompleted: completedIds.contains(quest.id),
                              onAnswer: () => _submitSubjectQuest(quest),
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

class _DailyQuestCard extends StatelessWidget {
  const _DailyQuestCard({
    required this.quest,
    required this.progressCount,
    required this.isClaimed,
    required this.onClaim,
  });

  final QuestDefinition quest;
  final int progressCount;
  final bool isClaimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final targetCount = quest.targetCount ?? 1;
    final clampedProgress = progressCount > targetCount ? targetCount : progressCount;
    final isReady = clampedProgress >= targetCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE08980),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9B3B35),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x33FFEAD3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Daily Quest",
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF9B3B35),
                    fontFamily: 'Jomhuria',
                    height: 0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quest.title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFF6E3CC),
                    fontFamily: 'Jost',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${quest.description} ($clampedProgress/$targetCount)",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFFEAD3),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isClaimed
                  ? Colors.white
                  : isReady
                      ? const Color(0xFFD4554E)
                      : const Color(0xFFB46B64),
              foregroundColor:
                  isClaimed ? const Color(0xFFD4554E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: isClaimed || !isReady ? null : onClaim,
            child: Text(isClaimed ? "Claimed" : "${quest.points} pts"),
          ),
        ],
      ),
    );
  }
}

class _SubjectQuestCard extends StatelessWidget {
  const _SubjectQuestCard({
    required this.quest,
    required this.isCompleted,
    required this.onAnswer,
  });

  final QuestDefinition quest;
  final bool isCompleted;
  final VoidCallback onAnswer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE08980),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF9B3B35),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 40,
                    color: Color(0xFFF6E3CC),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.subject ?? "",
                          style: const TextStyle(
                            fontSize: 45,
                            fontFamily: 'Jomhuria',
                            color: Color(0xFF9B3B35),
                            height: 1,
                          ),
                        ),
                        Text(
                          quest.question ?? "",
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Jost',
                            color: Color(0xFFF6E3CC),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isCompleted ? Colors.green : const Color(0xFFD4554E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isCompleted ? null : onAnswer,
                  child: Text(
                    isCompleted
                        ? "Completed"
                        : "Answer (+${quest.points} pts)",
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Jomhuria',
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isCompleted)
          const Positioned(
            top: 8,
            right: 8,
            child: Icon(
              Icons.verified,
              color: Colors.green,
              size: 30,
            ),
          ),
      ],
    );
  }
}

