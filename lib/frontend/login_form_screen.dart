import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'feed_screen.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import '../backend/auth_service.dart';
import '../state/theme_provider.dart';

class LoginFormScreen extends ConsumerStatefulWidget {
  const LoginFormScreen({super.key});

  @override
  ConsumerState<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends ConsumerState<LoginFormScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isHidden = true;
  String errorMessage = "";

  final AuthService _authService = AuthService();

  void login() async {
    String? error = await _authService.login(
      username: usernameController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (error != null) {
      if (error == "EMAIL_NOT_VERIFIED") {
        if (!mounted) {
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const EmailVerificationScreen(),
          ),
        );
        return;
      }

      setState(() {
        errorMessage = error;
      });
    } else {
      await ref.read(appThemeStateNotifier).loadThemeForCurrentUser();
      if (!mounted) {
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FeedScreen()),
      );
    }
  }

  void goToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandDarkRed = Color(0xFFA33A37);
    const Color brandLightRed = Color(0xFFE17A74);
    const Color brandCream = Color(0xFFFFEAD3);

    return Scaffold(
      backgroundColor: brandDarkRed,

      // ✅ THIS IS THE FIX
      appBar: AppBar(
        backgroundColor: brandDarkRed,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                Image.asset("assets/mindora.png", width: 300),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: brandLightRed,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFD65A55),
                      width: 3,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 60,
                          fontFamily: 'Jomhuria',
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          hintText: "Username",
                          filled: true,
                          fillColor: brandCream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
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
                              isHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: brandDarkRed,
                            ),
                            onPressed: () =>
                                setState(() => isHidden = !isHidden),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: goToForgotPassword,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandCream,
                    foregroundColor: brandDarkRed,
                    minimumSize: const Size(200, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 45,
                      fontFamily: 'Jomhuria',
                    ),
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

