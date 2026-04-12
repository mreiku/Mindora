import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../backend/auth_service.dart';
import '../state/theme_provider.dart';
import 'feed_screen.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isRefreshing = false;
  bool _isSending = false;
  bool _isSigningOut = false;

  Future<void> _refreshVerification() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _authService.syncCurrentUserEmailVerification();
      final isVerified =
          await _authService.isCurrentUserEmailVerified(reload: true);

      if (!mounted) {
        return;
      }

      if (!isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your email is still not verified yet."),
          ),
        );
        return;
      }

      await ref.read(appThemeStateNotifier).loadThemeForCurrentUser();
      await _authService.syncCurrentUserPresence(true);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const FeedScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _resendVerification() async {
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final result = await _authService.sendSignupEmailVerification();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result ?? "Verification email sent."),
      ),
    );
  }

  Future<void> _signOut() async {
    if (_isSigningOut) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    await _authService.signOut();

    if (!mounted) {
      return;
    }

    ref.read(appThemeStateNotifier).resetToLightTheme();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "your email";

    return Scaffold(
      backgroundColor: const Color(0xFFA33A37),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA33A37),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xffe07a72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xffc85c55),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("assets/mindora.png", width: 280),
                const SizedBox(height: 10),
                const Text(
                  "Verify Email First",
                  style: TextStyle(
                    fontSize: 36,
                    fontFamily: 'Jomhuria',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "We sent a verification email to $email. You need to verify it before using your account.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRefreshing ? null : _refreshVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEAD3),
                      foregroundColor: const Color(0xFFA33A37),
                    ),
                    child: Text(
                      _isRefreshing ? "Checking..." : "I Already Verified",
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSending ? null : _resendVerification,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: Text(
                      _isSending ? "Sending..." : "Resend Verification Email",
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isSigningOut ? null : _signOut,
                  child: Text(
                    _isSigningOut ? "Signing out..." : "Back to Login",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
