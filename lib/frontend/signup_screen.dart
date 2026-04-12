import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend/auth_service.dart';
import 'email_verification_screen.dart';
import '../state/theme_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isHidden = true;
  bool isSigningUp = false;
  String errorMessage = "";

  final AuthService _authService = AuthService();

  void signUp() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        errorMessage = "Please fill in all fields.";
      });
      return;
    }

    setState(() {
      isSigningUp = true;
      errorMessage = "";
    });

    String? error = await _authService.signUp(
      username: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (error != null) {
      setState(() {
        isSigningUp = false;
        errorMessage = error;
      });
    } else {
      if (!mounted) {
        return;
      }

      await ref.read(appThemeStateNotifier).loadThemeForCurrentUser();
      if (!mounted) {
        return;
      }

      setState(() {
        isSigningUp = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const EmailVerificationScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandCream = Color(0xFFFFEAD3);

    return Scaffold(
      backgroundColor: const Color(0xFFA33A37),
      appBar: AppBar(backgroundColor: const Color(0xFFA33A37), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 80),

              Image.asset("assets/mindora.png", width: 350),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xffe07a72),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffc85c55), width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 40,
                        fontFamily: 'Jomhuria',
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Username",
                        filled: true,
                        fillColor: brandCream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: "Email",
                        filled: true,
                        fillColor: brandCream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: isHidden,
                      decoration: InputDecoration(
                        hintText: "Password",
                        filled: true,
                        fillColor: brandCream,
                        suffixIcon: IconButton(
                          icon: Icon(
                            isHidden ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              isHidden = !isHidden;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (errorMessage.isNotEmpty)
                      Text(errorMessage,
                          style: const TextStyle(color: Colors.yellow)),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: isSigningUp ? null : signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandCream,
                      ),
                      child: Text(
                        isSigningUp ? "Creating..." : "Sign Up",
                        style: TextStyle(
                          fontSize: 30,
                          fontFamily: 'Jomhuria',
                          color: Color(0xFFA33A37),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

