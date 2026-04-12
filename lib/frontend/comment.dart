import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../backend/post_service.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String username;
  final String question;

  const CommentScreen({
    super.key,
    required this.postId,
    required this.username,
    required this.question,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController replyController = TextEditingController();
  final PostService _postService = PostService();

  Future<void> _confirmDeleteReply(String commentId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete reply?"),
          content: const Text(
            "This reply will be removed permanently.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Color(0xFFC84D4D)),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final error = await _postService.deleteComment(
      postId: widget.postId,
      commentId: commentId,
    );

    if (!mounted || error == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  Future<void> postReply() async {
    if (replyController.text.trim().isEmpty) return;

    final error = await _postService.addComment(
      postId: widget.postId,
      content: replyController.text,
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

    replyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Brand Colors
    const Color brandRed = Color(0xFFC84D4D);
    const Color lightCream = Color(0xFFFFEAD3);
    const Color darkSurface = Color(0xFF2D2822); // Darker version of your cream
    final Color replyCardColor =
        isDark ? const Color(0xFF221F1A) : const Color(0xFFFFF7EE);
    final Color inputSurface =
        isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Comments",
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Jomhuria',
            fontSize: 40,
          ),
        ),
        backgroundColor: brandRed,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? darkSurface : lightCream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : brandRed.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: brandRed.withOpacity(0.14),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 20,
                                color: brandRed,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.username,
                                    style: TextStyle(
                                      fontFamily: 'Jost',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: isDark
                                          ? const Color(0xFFFFD2CC)
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "Original post",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.question,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Text(
                        "Replies",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _postService.getCommentsStream(widget.postId),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.docs.length ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: brandRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "$count",
                              style: const TextStyle(
                                color: brandRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _postService.getCommentsStream(widget.postId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Couldn't load replies",
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.grey[600],
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: isDark ? Colors.white70 : brandRed,
                            ),
                          );
                        }

                        final replies = snapshot.data!.docs;

                        if (replies.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 28,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: isDark ? Colors.white38 : Colors.grey,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "No replies yet",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Start the discussion with the first reply.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: replies.length,
                          itemBuilder: (context, index) {
                            final replyDoc = replies[index];
                            final replyData = replies[index].data();
                            final isOwner =
                                replyData["userId"] ==
                                FirebaseAuth.instance.currentUser?.uid;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: replyCardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : brandRed.withOpacity(0.10),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: brandRed.withOpacity(0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 18,
                                      color: brandRed,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                replyData["username"] ??
                                                    "Username",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? const Color(0xFFFFD2CC)
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                            if (isOwner)
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                constraints:
                                                    const BoxConstraints(),
                                                splashRadius: 18,
                                                onPressed: () async {
                                                  await _confirmDeleteReply(
                                                    replyDoc.id,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: brandRed,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          replyData["content"] ?? "",
                                          style: TextStyle(
                                            height: 1.4,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: inputSurface,
                border: Border.all(color: brandRed.withOpacity(0.75)),
                borderRadius: BorderRadius.circular(22),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: brandRed.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: brandRed,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: replyController,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: "Write a reply...",
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8, bottom: 2),
                    decoration: const BoxDecoration(
                      color: brandRed,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: postReply,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }
}
