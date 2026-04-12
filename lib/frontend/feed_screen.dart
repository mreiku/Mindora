import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend/auth_service.dart';
import '../backend/post_service.dart';
import 'profile_screen.dart';
import 'message_screen.dart';
import 'notif_screen.dart';
import 'settings_screen.dart';
import 'comment.dart';
import 'login_screen.dart';
import 'tracker_screen.dart';
import '../state/theme_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  Map<String, String>? _cachedUserData;
  late DateTime _currentTime;
  Timer? _timeAgoTimer;
  String? _highlightedPostId;

  // stores selected tab
  int selectedIndex = 0;

  final TextEditingController postDialogController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cachedUserData = _authService.cachedUserData;
    _currentTime = DateTime.now();
    _timeAgoTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timeAgoTimer?.cancel();
    postDialogController.dispose();
    super.dispose();
  }

  Future<void> _submitPost(
    TextEditingController controller, {
    bool closeAfter = false,
    String privacy = "Public",
  }) async {
    if (controller.text.trim().isEmpty) {
      return;
    }

    final error = await _postService.createPost(
      content: controller.text,
      privacy: privacy,
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

    controller.clear();

    if (closeAfter) {
      Navigator.pop(context);
    }
  }

  Future<void> _showViewProfileSheet({
    required String userId,
    required String username,
    required String displayName,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
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
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFFC84D4D),
                    size: 30,
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

  Future<void> _confirmDeletePost(String postId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete post?"),
          content: const Text(
            "This post will be removed from your feed.",
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

    if (shouldDelete == true) {
      await _postService.deletePost(postId);
    }
  }

  Future<void> _showEditPostDialog({
    required String postId,
    required String initialContent,
    required String username,
    required int remainingEdits,
  }) async {
    final controller = TextEditingController(text: initialContent);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    const Text(
                      "Edit Post",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "Editing",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                  color: const Color(0xFFC84D4D).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFC84D4D).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        color: Color(0xFFC84D4D),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : Colors.black87,
                              height: 1.3,
                            ),
                            children: [
                              const TextSpan(text: "You have "),
                              TextSpan(
                                text: "$remainingEdits",
                                style: const TextStyle(
                                  color: Color(0xFFC84D4D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text:
                                    " edit${remainingEdits == 1 ? "" : "s"} left in this 6-hour window",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Update your post",
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFC84D4D),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final error = await _postService.updatePost(
                        postId: postId,
                        content: controller.text,
                      );

                      if (!mounted) {
                        return;
                      }

                      if (error != null) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                        return;
                      }

                      navigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC84D4D),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
  }

  void _openPostFromProfile(String postId) {
    setState(() {
      selectedIndex = 0;
      _highlightedPostId = postId;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || _highlightedPostId != postId) {
        return;
      }
      setState(() {
        _highlightedPostId = null;
      });
    });
  }

  Future<void> _openSearch() async {
    final posts = await _postService.fetchPosts();
    final usersSnapshot = await FirebaseFirestore.instance.collection("users").get();

    if (!mounted) {
      return;
    }

    final selectedPostId = await showSearch<String?>(
      context: context,
      delegate: PostSearchDelegate(
        posts: posts,
        users: usersSnapshot.docs,
      ),
    );

    if (!mounted || selectedPostId == null) {
      return;
    }

    _openPostFromProfile(selectedPostId);
  }

  String _formatTimeAgo(DateTime? createdAt) {
    if (createdAt == null) {
      return "just now";
    }

    final difference = _currentTime.difference(createdAt);

    if (difference.inSeconds < 60) {
      return "just now";
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? "1 min ago" : "$minutes mins ago";
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? "1 hr ago" : "$hours hrs ago";
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? "1 day ago" : "$days days ago";
    }

    final weeks = (difference.inDays / 7).floor();
    if (weeks < 5) {
      return weeks == 1 ? "1 week ago" : "$weeks weeks ago";
    }

    final months = (difference.inDays / 30).floor();
    if (months < 12) {
      return months == 1 ? "1 month ago" : "$months months ago";
    }

    final years = (difference.inDays / 365).floor();
    return years == 1 ? "1 year ago" : "$years years ago";
  }

  // Facebook-style post dialog
  void showPostDialog() {
    String selectedPrivacy = "Public";
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        const Text(
                          "Create Post",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const Divider(),

                    // Profile section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _cachedUserData?["username"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              PopupMenuButton<String>(
                                initialValue: selectedPrivacy,
                                onSelected: (String value) {
                                  setStateDialog(() {
                                    selectedPrivacy = value;
                                  });
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    const PopupMenuItem<String>(
                                      value: "Public",
                                      child: Row(
                                        children: [
                                          Icon(Icons.public, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text("Public"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: "Friends Only",
                                      child: Row(
                                        children: [
                                          Icon(Icons.people, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text("Friends Only"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: "Custom",
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_add, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text("Custom"),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    selectedPrivacy,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Text input field
                    TextField(
                      controller: postDialogController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).scaffoldBackgroundColor,),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).scaffoldBackgroundColor,),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFC84D4D),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: BorderDirectional(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ActionButton(
                            icon: Icons.subject,
                            label: "Subject",
                            color: Colors.blue,
                          ),
                          ActionButton(
                            icon: Icons.lock,
                            label: "Privacy",
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Post button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _submitPost(
                          postDialogController,
                          closeAfter: true,
                          privacy: selectedPrivacy,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC84D4D),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Post",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // home feed widget
  Widget buildHome() {
    return Column(
      children: [
        // question feed
        Expanded(
          child: StreamBuilder(
            stream: _postService.getPostsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    "Couldn't load posts.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final currentUser = FirebaseAuth.instance.currentUser;
              final currentUserId = currentUser?.uid;
              final currentUserStream = currentUserId == null
                  ? null
                  : _authService.getUserStream(currentUserId);

              final posts = snapshot.data!.docs;

              if (posts.isEmpty) {
                return const Center(
                  child: Text(
                    "No questions posted yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: currentUserStream,
                builder: (context, userSnapshot) {
                  final isAdmin =
                      userSnapshot.data?.data()?["isAdmin"] as bool? ?? false;

                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final postData = post.data();
                      final postOwnerId = postData["userId"] as String? ?? "";
                      final isOwner = currentUserId == postOwnerId;
                      final canDelete = isOwner || isAdmin;
                      final likedBy = List<String>.from(postData["likedBy"] ?? []);
                      final isLiked = currentUserId != null &&
                          likedBy.contains(currentUserId);
                      final isHighlighted = _highlightedPostId == post.id;
                      final createdAtTimestamp = postData["createdAt"];
                      final createdAt = createdAtTimestamp is Timestamp
                          ? createdAtTimestamp.toDate()
                          : null;
                      final timeAgo = _formatTimeAgo(createdAt);
                      final storedDisplayName =
                          (postData["displayName"] ?? "").toString().trim();
                      final storedUsername =
                          (postData["username"] ?? "Username").toString().trim();
                      final editWindowStartedAtValue =
                          postData["editWindowStartedAt"];
                      final editWindowStartedAt =
                          editWindowStartedAtValue is Timestamp
                              ? editWindowStartedAtValue.toDate()
                              : null;
                      final rawEditCount = postData["editCount"];
                      final storedEditCount =
                          rawEditCount is int ? rawEditCount : 0;
                      final isEditWindowActive = editWindowStartedAt != null &&
                          _currentTime.difference(editWindowStartedAt) <
                              PostService.editWindowDuration;
                      final editsUsed =
                          isEditWindowActive ? storedEditCount : 0;
                      final remainingEdits =
                          PostService.maxEditsPerWindow - editsUsed;
                      final canEdit = isOwner && remainingEdits > 0;

                      return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: isHighlighted
                        ? const Color(0xFFC84D4D).withOpacity(0.10)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isHighlighted
                            ? const Color(0xFFC84D4D)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: postOwnerId.isEmpty
                            ? null
                            : () => _showViewProfileSheet(
                                  userId: postOwnerId,
                                  username: storedUsername.isEmpty
                                      ? "Username"
                                      : storedUsername,
                                  displayName: storedDisplayName.isEmpty
                                      ? (storedUsername.isEmpty
                                          ? "User"
                                          : storedUsername)
                                      : storedDisplayName,
                                ),
                        child: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: StreamBuilder<
                                  DocumentSnapshot<Map<String, dynamic>>
                                >(
                                  stream: postOwnerId.isEmpty
                                      ? null
                                      : _authService.getUserStream(postOwnerId),
                                  builder: (context, userSnapshot) {
                                    final liveUserData =
                                        userSnapshot.data?.data();
                                    final liveDisplayName =
                                        (liveUserData?["displayName"] ??
                                                storedDisplayName)
                                            .toString()
                                            .trim();
                                    final liveUsername =
                                        (liveUserData?["username"] ??
                                                storedUsername)
                                            .toString()
                                            .trim();
                                    final authorLabel = liveDisplayName.isEmpty
                                        ? "@$liveUsername"
                                        : liveUsername.isEmpty
                                            ? liveDisplayName
                                            : "$liveDisplayName (@$liveUsername)";

                                    return Text(
                                      authorLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            postData["content"] ?? "",
                            style: const TextStyle(
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: const Color(0xFFC84D4D),
                                ),
                                onPressed: () async {
                                  try {
                                    final error =
                                        await _postService.toggleLike(post.id);
                                    if (!mounted || error == null) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error)),
                                    );
                                  } catch (_) {
                                    if (!mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Couldn't update the reaction right now.",
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              Text("${postData["likeCount"] ?? 0}"),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommentScreen(
                                        postId: post.id,
                                        username:
                                            postData["username"] ?? "Username",
                                        question: postData["content"] ?? "",
                                      ),
                                    ),
                                  );
                                },
                              ),
                              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                stream: _postService.getCommentsStream(post.id),
                                builder: (context, commentSnapshot) {
                                  final commentCount =
                                      commentSnapshot.data?.docs.length ??
                                      (postData["commentCount"] ?? 0);
                                  return Text("$commentCount");
                                },
                              ),
                              const Spacer(),
                              if (isOwner)
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: canEdit
                                        ? const Color(0xFFC84D4D)
                                        : Colors.grey,
                                  ),
                                  onPressed: canEdit
                                      ? () async {
                                          await _showEditPostDialog(
                                            postId: post.id,
                                            initialContent:
                                                postData["content"] ?? "",
                                            username:
                                                postData["username"] ?? "Username",
                                            remainingEdits: remainingEdits,
                                          );
                                        }
                                      : () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Edit limit reached. Try again after 6 hours.",
                                              ),
                                            ),
                                          );
                                        },
                                ),
                              if (canDelete)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFC84D4D),
                                  ),
                                  onPressed: () async {
                                    await _confirmDeletePost(post.id);
                                  },
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
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = [
      buildHome(),
      const MessageScreen(),
      const NotifScreen(),
      ProfileScreen(onOpenPost: _openPostFromProfile),
    ];

    return Scaffold(
      
      // top app bar
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,

        title: Text(
          "Mindora",
          style: TextStyle(
            height: 2,
            color: theme.brightness == Brightness.dark 
                      ? Colors.white
                      : Color(0xFFFFEAD3),
            fontSize: 50,
            fontFamily: 'Jomhuria',),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _openSearch,
              icon: const Icon(Icons.search),
            ),
          ),
        ],
      ),

      // drawer menu
      drawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,

        child: ListView(
          padding: EdgeInsets.zero,

          children: [
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                final currentUser =
                    authSnapshot.data ?? FirebaseAuth.instance.currentUser;

                if (currentUser == null) {
                  return const DrawerHeader(
                    decoration: BoxDecoration(color: Color(0xFFC84D4D)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Color(0xFFC84D4D)),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "No user logged in",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder<Map<String, String>>(
                  key: ValueKey(currentUser.uid),
                  future: _authService.getUserData(),
                  builder: (context, userSnapshot) {
                    final resolvedUserData =
                        userSnapshot.data ?? _cachedUserData;

                    if (userSnapshot.data != null &&
                        userSnapshot.data != _cachedUserData) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _cachedUserData = userSnapshot.data;
                        });
                      });
                    }

                    final username = resolvedUserData?["username"] ?? "";
                    final email = resolvedUserData?["email"] ?? "";

                    return DrawerHeader(
                      decoration: const BoxDecoration(color: Color(0xFFC84D4D)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Color(0xFFC84D4D)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),

              onTap: () {
                Navigator.pop(context);

                setState(() {
                  selectedIndex = 3;
                });
              },
            ),

            ListTile(
              leading: const Icon(Icons.track_changes),
              title: const Text("Tracker"),

              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrackerScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),

              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                   builder: (context) => const SettingsScreen(),
                    ),
                  );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),

              onTap: () async {
                Navigator.pop(context);
                final error = await _authService.signOut();

                if (!mounted) {
                  return;
                }

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                  return;
                }

                ProviderScope.containerOf(
                  context,
                  listen: false,
                ).read(appThemeStateNotifier).resetToLightTheme();

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      // keeps tabs alive
      body: IndexedStack(index: selectedIndex, children: pages),

      // bottom navigation
      bottomNavigationBar: Container(
        height: 65,
        color: const Color(0xFFC84D4D),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,

          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  selectedIndex = 0;
                });
              },
              icon: const Icon(Icons.home, color: Colors.white),
            ),

            IconButton(
              onPressed: () {
                setState(() {
                  selectedIndex = 1;
                });
              },
              icon: const Icon(Icons.mail, color: Colors.white),
            ),

            // plus button posts question
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),

              child: IconButton(
                onPressed: showPostDialog,
                icon: const Icon(Icons.add, color: Color(0xFFC84D4D)),
              ),
            ),

            IconButton(
              onPressed: () {
                setState(() {
                  selectedIndex = 2;
                });
              },
              icon: const Icon(Icons.notifications, color: Colors.white),
            ),

            GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = 3;
                });
              },

              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFFC84D4D)),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// Action button widget for post dialog
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class PostSearchDelegate extends SearchDelegate<String?> {
  PostSearchDelegate({
    required this.posts,
    required this.users,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> posts;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> users;
  static const Color _accentColor = Color(0xFFC84D4D);
  static const Color _lightSurface = Color(0xFFFFF6EC);

  String get _normalizedQuery {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.startsWith("@")) {
      return trimmedQuery.substring(1);
    }
    return trimmedQuery;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filteredPosts {
    final trimmedQuery = _normalizedQuery;
    if (trimmedQuery.isEmpty) {
      return posts;
    }

    return posts.where((post) {
      final data = post.data();
      final username = (data["username"] ?? "").toString().toLowerCase();
      final displayName =
          (data["displayName"] ?? data["username"] ?? "").toString().toLowerCase();
      final content = (data["content"] ?? "").toString().toLowerCase();
      return username.contains(trimmedQuery) ||
          displayName.contains(trimmedQuery) ||
          content.contains(trimmedQuery);
    }).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filteredUsers {
    final trimmedQuery = _normalizedQuery;
    if (trimmedQuery.isEmpty) {
      return const [];
    }

    return users.where((userDoc) {
      final data = userDoc.data();
      final username = (data["username"] ?? "").toString().toLowerCase();
      final displayName =
          (data["displayName"] ?? data["username"] ?? "").toString().toLowerCase();
      return username.contains(trimmedQuery) || displayName.contains(trimmedQuery);
    }).toList();
  }

  @override
  String get searchFieldLabel => "Search posts";

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor:
            theme.brightness == Brightness.dark ? const Color(0xFF241C1C) : _lightSurface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: theme.brightness == Brightness.dark
              ? Colors.white
              : _accentColor,
        ),
      ),
      scaffoldBackgroundColor:
          theme.brightness == Brightness.dark ? const Color(0xFF181212) : const Color(0xFFFFFBF7),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: theme.brightness == Brightness.dark
              ? Colors.white38
              : Colors.black45,
        ),
        filled: true,
        fillColor:
            theme.brightness == Brightness.dark ? Colors.white10 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: _accentColor,
            width: 1.8,
          ),
        ),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(
          color: theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () {
            query = "";
          },
          icon: const Icon(Icons.close),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultList(context);
  }

  Widget _buildResultList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final results = _filteredPosts;
    final matchedUsers = _filteredUsers;
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : _lightSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white10 : _accentColor.withOpacity(0.10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    size: 32,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "Search the feed",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Find posts by username, keywords, or phrases inside the post content.",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _SearchHintChip(label: "@username", icon: Icons.person_outline),
                    _SearchHintChip(label: "anxiety", icon: Icons.psychology_alt_outlined),
                    _SearchHintChip(label: "study tips", icon: Icons.menu_book_outlined),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (results.isEmpty && matchedUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white10 : _accentColor.withOpacity(0.10),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 34,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No results matched \"$trimmedQuery\"",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try a different keyword, a shorter phrase, or search by username instead.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            "${matchedUsers.length + results.length} result${matchedUsers.length + results.length == 1 ? "" : "s"} for \"$trimmedQuery\"",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        if (matchedUsers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              "Users",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ...matchedUsers.map((userDoc) {
            final data = userDoc.data();
            final username = (data["username"] ?? "Username").toString();
            final displayName =
                (data["displayName"] ?? data["username"] ?? "Username").toString();

            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    viewedUserId: userDoc.id,
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : _lightSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? Colors.white10 : _accentColor.withOpacity(0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_search_rounded,
                        color: _accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "@$username",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: _accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
        if (results.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              "Posts",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ...results.map((post) {
            final data = post.data();
            final username = (data["username"] ?? "Username").toString();
            final content = (data["content"] ?? "").toString().trim();

            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => close(context, post.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : _lightSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? Colors.white10 : _accentColor.withOpacity(0.12),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFFC84D4D).withOpacity(0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: _accentColor,
                            size: 22,
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
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tap to jump to this post",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: _accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black12 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        content.isEmpty ? "No text in this post" : content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _SearchHintChip extends StatelessWidget {
  const _SearchHintChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : const Color(0xFFC84D4D).withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFFC84D4D),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

