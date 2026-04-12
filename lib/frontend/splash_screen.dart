import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../backend/auth_service.dart';
import 'email_verification_screen.dart';
import 'feed_screen.dart';
import 'login_screen.dart';

// stateful because of the timer
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // waits 6 seconds then routes based on persisted auth session
    Future.delayed(const Duration(seconds: 6), () async {
      if (!mounted) {
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final isVerified = currentUser == null
          ? false
          : await _authService.isCurrentUserEmailVerified(reload: true);

      if (currentUser != null) {
        await _authService.syncCurrentUserEmailVerification();
      }

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            if (currentUser == null) {
              return const LoginScreen();
            }
            if (!isVerified) {
              return const EmailVerificationScreen();
            }
            return const FeedScreen();
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA03A36),

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.gif',
            width: 200,
            ),

            const Text(
              "Mindora",
              style: TextStyle(
                color: Color(0xFFF5D6C6),
                fontSize: 70,
                fontFamily: 'Jomhuria',
                height: 1,
              ),
            )
          ],
        )
      ),
    );
  }
}

