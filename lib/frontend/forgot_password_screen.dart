import 'package:flutter/material.dart';
import '../backend/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final AuthService _authService = AuthService();
  String feedbackMessage = "";
  bool isError = false;
  bool isSending = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void sendResetLink() async {
    if (emailController.text.trim().isEmpty) {
      setState(() {
        isError = true;
        feedbackMessage = "Please enter your email or username.";
      });
      return;
    }

    setState(() {
      isSending = true;
      feedbackMessage = "";
    });

    final error =
        await _authService.resetPassword(emailController.text.trim());

    if (!mounted) {
      return;
    }

    setState(() {
      isSending = false;
      isError = error != null;
      feedbackMessage =
          error ?? "Reset link sent! Check your email inbox.";
    });
  }

  Widget _buildFeedbackBanner() {
    if (feedbackMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? const Color(0x66A33A37)
            : const Color(0x33ffffead3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0xFFFFEAD3) : const Color(0xFFFFF1D8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.mark_email_read_outlined,
            color: const Color(0xFFFFEAD3),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feedbackMessage,
              style: const TextStyle(
                color: Color(0xFFFFEAD3),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandDarkRed = Color(0xFFA33A37);
    const Color brandLightRed = Color(0xFFE17A74);
    const Color brandCream = Color(0xFFFFEAD3);

    return Scaffold(
      backgroundColor: brandDarkRed,
      appBar: AppBar(
        backgroundColor: brandDarkRed,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Image.asset("assets/mindora.png", width: 300),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: brandLightRed,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD65A55),
                    width: 3,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Forgot Password",
                      style: TextStyle(
                        fontSize: 56,
                        fontFamily: 'Jomhuria',
                        color: Colors.white,
                        height: 0.9,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Enter the email or username linked to your account. We'll send a reset link so you can get back in.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFEAD3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0x55FFEAD3),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "You can type either your email address or your username here.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Email or Username",
                        filled: true,
                        fillColor: brandCream,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_search_outlined,
                          color: brandDarkRed,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFA33A37),
                            width: 2,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSending ? null : sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandCream,
                          foregroundColor: brandDarkRed,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isSending ? "Sending..." : "Send Reset Link",
                          style: const TextStyle(
                            fontSize: 34,
                            fontFamily: 'Jomhuria',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildFeedbackBanner(),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Remembered your password? Go back and log in.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFEAD3),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
