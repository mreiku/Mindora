import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

// static screen with no changing data
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA33A37),

      body: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Mindora",
              style: TextStyle(
                color: Color(0xFFF5D6C6),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            // login button section
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD65A55),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Login", style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 15),

            // sign up button section
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE7A39E),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Create New Account",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

