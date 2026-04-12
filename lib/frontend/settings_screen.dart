import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend/auth_service.dart';
import '../state/theme_provider.dart'; // Ensure this path is correct
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isDeleting = false;
  bool _isAdminDeletingUser = false;
  bool _isUpdatingUsername = false;
  bool _isUpdatingEmail = false;
  bool _isUpdatingPassword = false;
  bool _isCompletingVerifiedEmailChange = false;

  Future<void> _showUsernameDialog({
    required String currentUsername,
    required int remainingChanges,
  }) async {
    final controller = TextEditingController(text: currentUsername);
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text("Change username"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: "Username handle",
                      prefixText: "@",
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$remainingChanges of ${AuthService.maxUsernameChangesPerWeek} username changes left this week",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isUpdatingUsername
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _isUpdatingUsername
                      ? null
                      : () async {
                          setState(() {
                            _isUpdatingUsername = true;
                          });
                          setDialogState(() {
                            errorText = null;
                          });

                          final result = await _authService.updateUsername(
                            controller.text,
                          );

                          if (!mounted) {
                            return;
                          }

                          setState(() {
                            _isUpdatingUsername = false;
                          });

                          if (result != null) {
                            setDialogState(() {
                              errorText = result;
                            });
                            return;
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Username updated"),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC84D4D),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _isUpdatingUsername ? "Saving..." : "Save",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEmailDialog({required String currentEmail}) async {
    final controller = TextEditingController(text: currentEmail);
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text("Change email"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: "Email",
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We’ll send a verification link first. Your email changes only after you verify it.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isUpdatingEmail ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _isUpdatingEmail
                      ? null
                      : () async {
                          setState(() {
                            _isUpdatingEmail = true;
                          });
                          setDialogState(() {
                            errorText = null;
                          });

                          final result =
                              await _authService.requestEmailChangeVerification(
                            controller.text,
                          );

                          if (!mounted) {
                            return;
                          }

                          setState(() {
                            _isUpdatingEmail = false;
                          });

                          if (result != null) {
                            setDialogState(() {
                              errorText = result;
                            });
                            return;
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Verification link sent to your new email",
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC84D4D),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _isUpdatingEmail ? "Sending..." : "Verify First",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showPasswordDialog() async {
    final controller = TextEditingController();
    bool isHidden = true;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text("Change password"),
              content: TextField(
                controller: controller,
                obscureText: isHidden,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "New password",
                  errorText: errorText,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setDialogState(() {
                        isHidden = !isHidden;
                      });
                    },
                    icon: Icon(
                      isHidden ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isUpdatingPassword ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _isUpdatingPassword
                      ? null
                      : () async {
                          setState(() {
                            _isUpdatingPassword = true;
                          });
                          setDialogState(() {
                            errorText = null;
                          });

                          final result = await _authService.updatePassword(
                            controller.text,
                          );

                          if (!mounted) {
                            return;
                          }

                          setState(() {
                            _isUpdatingPassword = false;
                          });

                          if (result != null) {
                            setDialogState(() {
                              errorText = result;
                            });
                            return;
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Password updated"),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC84D4D),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _isUpdatingPassword ? "Saving..." : "Update",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _completeVerifiedEmailChange({String? pendingEmail}) async {
    if (_isCompletingVerifiedEmailChange) {
      return;
    }

    setState(() {
      _isCompletingVerifiedEmailChange = true;
    });

    Future<void> navigateToLogin() async {
      await _authService.signOut();
      if (!mounted) {
        return;
      }
      ref.read(appThemeStateNotifier).resetToLightTheme();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }

    bool shouldNavigateOnError(String error) {
      final lower = error.toLowerCase();
      return lower.contains('user-token-expired') ||
          lower.contains('no user logged in') ||
          lower.contains('requires-recent-login') ||
          lower.contains('user-disabled');
    }

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      final refreshedEmail = (refreshedUser?.email ?? "").trim();
      final trimmedPendingEmail = (pendingEmail ?? "").trim();

      if (trimmedPendingEmail.isNotEmpty &&
          refreshedEmail == trimmedPendingEmail) {
        final result = await _authService.syncVerifiedEmail();
        if (result != null) {
          if (shouldNavigateOnError(result)) {
            await navigateToLogin();
            return;
          }
          if (!mounted) {
            return;
          }
          setState(() {
            _isCompletingVerifiedEmailChange = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result),
            ),
          );
          return;
        }
        await navigateToLogin();
        return;
      }

      final result = await _authService.syncVerifiedEmail();

      if (!mounted) {
        return;
      }

      if (result == null) {
        await navigateToLogin();
        return;
      }

      if (shouldNavigateOnError(result)) {
        await navigateToLogin();
        return;
      }

      setState(() {
        _isCompletingVerifiedEmailChange = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      if (e is FirebaseAuthException &&
          (e.code == 'user-token-expired' ||
              e.code == 'requires-recent-login' ||
              e.code == 'user-disabled')) {
        await navigateToLogin();
        return;
      }
      setState(() {
        _isCompletingVerifiedEmailChange = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
        ),
      );
    }
  }

  Future<void> _refreshVerifiedEmail(String pendingEmail) async {
    await _completeVerifiedEmailChange(pendingEmail: pendingEmail);
  }

  Future<void> _cancelPendingEmailChange() async {
    final result = await _authService.cancelPendingEmailChange();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result ?? "Pending email verification cancelled",
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text("Delete account?"),
          content: Text(
            "This is permanent. Your account, posts, replies, and messages will be deleted and cannot be restored.",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _isDeleting ? null : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC84D4D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final error = await _authService.deleteAccount();

    if (!mounted) {
      return;
    }

    setState(() {
      _isDeleting = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _confirmAdminDeleteUser({
    required String targetUserId,
    required String username,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text("Delete user account?"),
          content: Text(
            "This will remove @$username from the app data, including their posts, replies, and conversations. Their Firebase Auth login will still exist unless removed server-side.",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isAdminDeletingUser
                  ? null
                  : () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _isAdminDeletingUser
                  ? null
                  : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC84D4D),
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isAdminDeletingUser = true;
    });

    final result = await _authService.deleteUserByAdmin(targetUserId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isAdminDeletingUser = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result ?? "User removed from app data",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appThemeState = ref.watch(appThemeStateNotifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white10 : const Color(0xFFF7EEE4);
    final borderColor = isDark
        ? Colors.white10
        : const Color(0xFFC85C55).withOpacity(0.15);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: currentUser == null
          ? const Center(child: Text("No user logged in."))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _authService.getUserStream(currentUser.uid),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() ?? {};
                final username = (userData["username"] ?? "").toString();
                final email = (userData["email"] ?? currentUser.email ?? "")
                    .toString();
                final pendingEmail =
                    (userData["pendingEmail"] ?? "").toString().trim();
                final currentAuthEmail =
                    (FirebaseAuth.instance.currentUser?.email ?? "")
                        .trim();
                final isAdmin = userData["isAdmin"] as bool? ?? false;
                final rawChangeCount = userData["usernameChangeCount"];
                final changeCount = rawChangeCount is int ? rawChangeCount : 0;
                final windowStartedAtValue =
                    userData["usernameChangeWindowStartedAt"];
                final windowStartedAt = windowStartedAtValue is Timestamp
                    ? windowStartedAtValue.toDate()
                    : null;
                final isWindowActive = windowStartedAt != null &&
                    DateTime.now().difference(windowStartedAt) <
                        AuthService.usernameChangeWindow;
                final changesUsed = isWindowActive ? changeCount : 0;
                final remainingChanges =
                    AuthService.maxUsernameChangesPerWeek - changesUsed;

                final shouldAutoCompleteVerifiedEmail = pendingEmail.isNotEmpty &&
                    currentAuthEmail.isNotEmpty &&
                    currentAuthEmail == pendingEmail &&
                    !_isCompletingVerifiedEmailChange;

                if (shouldAutoCompleteVerifiedEmail) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) {
                      return;
                    }
                    _completeVerifiedEmailChange(pendingEmail: pendingEmail);
                  });
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Account Settings",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildSettingItem(
                              context,
                              label: "Username",
                              value: "@$username",
                              helper:
                                  "$remainingChanges of ${AuthService.maxUsernameChangesPerWeek} changes left this week",
                              buttonLabel: "Change",
                              onPressed: () => _showUsernameDialog(
                                currentUsername: username,
                                remainingChanges: remainingChanges,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildSettingItem(
                              context,
                              label: "Email",
                              value: email,
                              helper: pendingEmail.isEmpty
                                  ? "Email changes require verification first."
                                  : "Pending verification: $pendingEmail",
                              buttonLabel: "Change",
                              onPressed: () =>
                                  _showEmailDialog(currentEmail: email),
                            ),
                            if (pendingEmail.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: _cancelPendingEmailChange,
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _refreshVerifiedEmail(pendingEmail),
                                    child: const Text("I already verified"),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),
                            _buildSettingItem(
                              context,
                              label: "Password",
                              value: "Change your password securely",
                              helper:
                                  "You may be asked to log in again before changing it.",
                              buttonLabel: "Change",
                              onPressed: _showPasswordDialog,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (isAdmin) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Admin Panel",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFC84D4D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "You can remove posts from the feed and remove user app data here.",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                stream: _authService.getAllUsersStream(),
                                builder: (context, usersSnapshot) {
                                  if (!usersSnapshot.hasData) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final otherUsers = usersSnapshot.data!.docs
                                      .where((doc) => doc.id != currentUser.uid)
                                      .toList()
                                    ..sort((a, b) {
                                      final aUsername =
                                          (a.data()["username"] ?? "")
                                              .toString()
                                              .toLowerCase();
                                      final bUsername =
                                          (b.data()["username"] ?? "")
                                              .toString()
                                              .toLowerCase();
                                      return aUsername.compareTo(bUsername);
                                    });

                                  if (otherUsers.isEmpty) {
                                    return Text(
                                      "No other users found.",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: otherUsers.map((userDoc) {
                                      final otherUserData = userDoc.data();
                                      final otherUsername =
                                          (otherUserData["username"] ??
                                                  "Username")
                                              .toString();
                                      final otherEmail =
                                          (otherUserData["email"] ?? "")
                                              .toString();
                                      final otherIsAdmin =
                                          otherUserData["isAdmin"] as bool? ??
                                              false;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.white.withOpacity(0.35),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "@$otherUsername${otherIsAdmin ? " • Admin" : ""}",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    otherEmail,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? Colors.white70
                                                          : Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: _isAdminDeletingUser
                                                  ? null
                                                  : () =>
                                                      _confirmAdminDeleteUser(
                                                    targetUserId: userDoc.id,
                                                    username: otherUsername,
                                                  ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFFC84D4D),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: Text(
                                                _isAdminDeletingUser
                                                    ? "Deleting..."
                                                    : "Delete",
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Dark Mode",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 18,
                                  ),
                            ),
                            Switch(
                              value: appThemeState.isDarkModeEnabled,
                              onChanged: (value) async {
                                if (value) {
                                  await ref
                                      .read(appThemeStateNotifier)
                                      .setDarkTheme();
                                } else {
                                  await ref
                                      .read(appThemeStateNotifier)
                                      .setLightTheme();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Delete Account",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFC84D4D),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "This action is permanent and cannot be undone.",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isDeleting ? null : _confirmDeleteAccount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC84D4D),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _isDeleting
                                      ? "Deleting..."
                                      : "Delete Account",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required String label,
    required String value,
    required String helper,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC84D4D),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

