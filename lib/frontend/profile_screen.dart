import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../backend/auth_service.dart';
import '../backend/badge_service.dart';
import '../backend/post_service.dart';
import 'comment.dart';
import 'edit_profile_screen.dart';
import 'quest_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onOpenPost,
    this.viewedUserId,
  });

  final ValueChanged<String>? onOpenPost;
  final String? viewedUserId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final BadgeService _badgeService = BadgeService();
  final PostService _postService = PostService();
  String? _lastKnownCurrentUserId;

  String _readString(Map<String, dynamic>? data, String key) {
    final value = data?[key];
    if (value == null) {
      return "";
    }
    return value.toString();
  }

  List<String> _readStringList(Map<String, dynamic>? data, String key) {
    final rawList = data?[key];
    if (rawList is! Iterable) {
      return const <String>[];
    }

    return rawList
        .map((item) => item?.toString() ?? "")
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _lastKnownCurrentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openPostDetails(String postId) async {
    try {
      if (widget.onOpenPost != null) {
        widget.onOpenPost!(postId);
        return;
      }

      final postSnapshot = await FirebaseFirestore.instance
          .collection("posts")
          .doc(postId)
          .get();
      final postData = postSnapshot.data();

      if (!mounted) {
        return;
      }

      if (postData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open this post right now.")),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommentScreen(
            postId: postId,
            username: (postData["username"] ?? "Username").toString(),
            question: (postData["content"] ?? "").toString(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open this post right now.")),
      );
    }
  }

  Future<void> _copyProfileHandle(String username) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No username available to copy.")),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: "@$trimmedUsername"));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("@$trimmedUsername copied.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final isViewingOtherUser = widget.viewedUserId != null;
    final canGoBack = Navigator.of(context).canPop();
    final showBackButton = isViewingOtherUser && canGoBack;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _lastKnownCurrentUserId = currentUser.uid;
    }
    final profileUserId = widget.viewedUserId ?? _lastKnownCurrentUserId;
    // Brand Colors
    const Color brandRed = Color(0xFFC85C55);
    const Color lightCream = Color(0xFFF9EBD2);
    const Color darkSurface = Color(0xFF1A1714); // Deep warm charcoal for dark mode

    if (profileUserId == null) {
      return Scaffold(
        backgroundColor: isDark ? darkSurface : lightCream,
        body: const Center(child: Text("No user logged in.")),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _authService.getUserStream(profileUserId),
      builder: (context, userDocSnapshot) {
            final userDoc = userDocSnapshot.data;
            final userDocData = userDoc?.data();

            if (userDocSnapshot.connectionState == ConnectionState.waiting &&
                userDocData == null) {
              return Scaffold(
                backgroundColor: isDark ? darkSurface : lightCream,
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (userDocSnapshot.hasError) {
              return Scaffold(
                backgroundColor: isDark ? darkSurface : lightCream,
                body: Center(
                  child: Text(
                    "Couldn't load this profile right now.",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              );
            }

            if (userDoc != null && !userDoc.exists) {
              return Scaffold(
                backgroundColor: isDark ? darkSurface : lightCream,
                body: Center(
                  child: Text(
                    "This profile is no longer available.",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              );
            }

            final isActive = _authService.isUserConsideredOnline(userDocData);
            final fallbackUsername = _readString(userDocData, "username");
            final profileDisplayName = _readString(userDocData, "displayName");
            final displayName = profileDisplayName.isNotEmpty
                ? profileDisplayName
                : fallbackUsername;
            final username = fallbackUsername;
            final pronouns = _readString(userDocData, "pronouns");
            final bio = _readString(userDocData, "bio");
            final displayBadgeIds = _readStringList(userDocData, "displayBadgeIds");

            return Scaffold(
                  backgroundColor: isDark ? darkSurface : lightCream,
                  body: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    height: 180,
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      color: brandRed,
                                    ),
                                    child: SafeArea(
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: showBackButton
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.only(left: 12, top: 6),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(999),
                                                    onTap: () => Navigator.pop(context),
                                                    child: Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.16),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.white.withOpacity(0.18),
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.arrow_back_rounded,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -55,
                                    left: 25,
                                    child: Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: isDark ? darkSurface : Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const CircleAvatar(
                                            radius: 60,
                                            backgroundImage: AssetImage(
                                              'assets/bila.jpg',
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            height: 22,
                                            width: 22,
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? const Color(0xFF94F194)
                                                  : Colors.grey[400],
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDark
                                                    ? darkSurface
                                                    : Colors.white,
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 65),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 50,
                                  fontFamily: 'Jomhuria',
                                  height: 0.9,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF94F194).withOpacity(0.2)
                                    : (isDark
                                        ? Colors.white10
                                        : Colors.black.withOpacity(0.05)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isActive
                                      ? const Color.fromARGB(255, 108, 239, 108)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color.fromARGB(255, 131, 241, 131)
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isActive ? "Active" : "Inactive",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? (isDark
                                              ? const Color(0xFF94F194)
                                              : Colors.green[700])
                                          : (isDark
                                              ? Colors.white38
                                              : Colors.black45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "@$username",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : Colors.black.withOpacity(0.3),
                            fontSize: 16,
                          ),
                        ),
                        if (pronouns.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : brandRed.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              pronouns,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : brandRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            bio,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _badgeService.streamUserBadges(profileUserId),
                          builder: (context, badgeSnapshot) {
                            if (badgeSnapshot.hasError) {
                              final fallbackBadgeTitles = displayBadgeIds
                                  .map(_badgeService.definitionForId)
                                  .whereType<BadgeDefinition>()
                                  .map((badge) => badge.title)
                                  .toList(growable: false);

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.white.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : brandRed.withOpacity(0.18),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.workspace_premium_rounded,
                                          color: brandRed,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Badges",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (fallbackBadgeTitles.isEmpty)
                                      Text(
                                        "Badges couldn't be loaded right now.",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.black54,
                                        ),
                                      ),
                                    if (fallbackBadgeTitles.isNotEmpty)
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: fallbackBadgeTitles.map((title) {
                                          return _buildBadgeChip(
                                            context,
                                            title: title,
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              );
                            }

                            final badges = [...(badgeSnapshot.data?.docs ?? [])]
                              ..sort((a, b) {
                                final aTimestamp = a.data()["earnedAt"] as Timestamp?;
                                final bTimestamp = b.data()["earnedAt"] as Timestamp?;
                                final aMillis = aTimestamp?.millisecondsSinceEpoch ?? 0;
                                final bMillis = bTimestamp?.millisecondsSinceEpoch ?? 0;
                                return bMillis.compareTo(aMillis);
                              });
                            final selectedBadges = badges
                                .where((badgeDoc) => displayBadgeIds.contains(
                                      (badgeDoc.data()["badgeId"] ?? "").toString(),
                                    ))
                                .toList();
                            final visibleBadges = selectedBadges.isNotEmpty
                                ? selectedBadges
                                : badges.take(5).toList(growable: false);

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.white.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : brandRed.withOpacity(0.18),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.workspace_premium_rounded,
                                        color: brandRed,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Badges",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (badges.isEmpty)
                                    Text(
                                      "Complete quests, post, reply, and stay active to unlock badges.",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                        height: 1.35,
                                      ),
                                    ),
                                  if (visibleBadges.isNotEmpty)
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: visibleBadges.map((badgeDoc) {
                                        final badge = badgeDoc.data();
                                        return _buildBadgeChip(
                                          context,
                                          title:
                                              (badge["title"] ?? "Badge").toString(),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    if (!isViewingOtherUser)
                                      _buildPillButton(
                                        "Quest",
                                        Icons.emoji_events,
                                        brandRed,
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const QuestScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    if (!isViewingOtherUser)
                                      _buildPillButton(
                                        "Edit Profile",
                                        null,
                                        brandRed,
                                        () async {
                                          final updated = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditProfileScreen(
                                                initialDisplayName: displayName,
                                                initialUsername: username,
                                                initialPronouns: pronouns,
                                                initialBio: bio,
                                                isActive: isActive,
                                                initialDisplayedBadgeIds:
                                                    displayBadgeIds,
                                              ),
                                            ),
                                          );

                                          if (updated == true && mounted) {
                                            setState(() {});
                                          }
                                        },
                                      ),
                                    _buildPillButton(
                                      "Share Profile",
                                      null,
                                      brandRed,
                                      () => _copyProfileHandle(username),
                                    ),
                                  ],
                                ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _ProfileTabBarDelegate(
                            backgroundColor: isDark ? darkSurface : lightCream,
                            dividerColor: brandRed.withOpacity(0.5),
                            tabBar: TabBar(
                              controller: _tabController,
                              labelColor: isDark
                                  ? Colors.white
                                  : const Color(0xFF4A4A4A),
                              unselectedLabelColor: isDark
                                  ? Colors.white24
                                  : const Color(0xFFA0A0A0),
                              indicatorColor: brandRed,
                              indicatorWeight: 3,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              tabs: const [
                                Tab(text: "Posts"),
                                Tab(text: "Replies"),
                              ],
                            ),
                          ),
                        ),
                      ];
                    },
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _postService.getUserPostsStream(profileUserId),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  "Couldn't load your posts.",
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final posts = [...snapshot.data!.docs]
                              ..sort((a, b) {
                                final aTimestamp = a.data()["createdAt"] as Timestamp?;
                                final bTimestamp = b.data()["createdAt"] as Timestamp?;
                                final aMillis = aTimestamp?.millisecondsSinceEpoch ?? 0;
                                final bMillis = bTimestamp?.millisecondsSinceEpoch ?? 0;
                                return bMillis.compareTo(aMillis);
                              });

                            if (posts.isEmpty) {
                              return Center(
                                child: Text(
                                  isViewingOtherUser
                                      ? "This user hasn't posted anything yet."
                                      : "You haven't posted anything yet.",
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              primary: false,
                              padding: const EdgeInsets.all(16),
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                final post = posts[index];
                                final postData = post.data();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : const Color(0xFFF7EEE4),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white10
                                          : const Color(0xFFC85C55).withOpacity(0.15),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (postData["content"] ?? "").toString(),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _openPostDetails(post.id),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFC85C55),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text("Go to Post"),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _postService.getUserRepliesStream(profileUserId),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  "Couldn't load your replies.",
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final replies = [...snapshot.data!.docs]
                              ..sort((a, b) {
                                final aTimestamp = a.data()["createdAt"] as Timestamp?;
                                final bTimestamp = b.data()["createdAt"] as Timestamp?;
                                final aMillis = aTimestamp?.millisecondsSinceEpoch ?? 0;
                                final bMillis = bTimestamp?.millisecondsSinceEpoch ?? 0;
                                return bMillis.compareTo(aMillis);
                              });

                            if (replies.isEmpty) {
                              return Center(
                                child: Text(
                                  isViewingOtherUser
                                      ? "This user hasn't posted any replies yet."
                                      : "You haven't posted any replies yet.",
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              primary: false,
                              padding: const EdgeInsets.all(16),
                              itemCount: replies.length,
                              itemBuilder: (context, index) {
                                final reply = replies[index];
                                final replyData = reply.data();
                                final parentPostId =
                                    replyData["postId"]?.toString();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : const Color(0xFFF7EEE4),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white10
                                          : const Color(0xFFC85C55).withOpacity(0.15),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (replyData["content"] ?? "").toString(),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: parentPostId == null
                                              ? null
                                              : () => _openPostDetails(parentPostId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFC85C55),
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: isDark
                                                ? Colors.white12
                                                : Colors.black12,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text("Go to Post"),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
  }

  Widget _buildPillButton(String label, IconData? icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(BuildContext context, {required String title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF9EBD2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFC85C55).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 16,
            color: Color(0xFFC85C55),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  _ProfileTabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
    required this.dividerColor,
  });

  final TabBar tabBar;
  final Color backgroundColor;
  final Color dividerColor;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tabBar,
          Divider(
            height: 1,
            thickness: 2,
            color: dividerColor,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.dividerColor != dividerColor;
  }
}
