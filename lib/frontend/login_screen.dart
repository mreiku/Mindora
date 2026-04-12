import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'login_form_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA33A37),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

        // app logo gif
        Image.asset(
          "assets/mindora.png",
          width: 350,
        ),

             const SizedBox(height: 5),

            // description
            const Text(
              "A collaborative space where you can connect, ask, and post questions, and help one another by sharing answers and thoughts.",
              // alignment
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFF5D6C6),
              fontSize: 20,
              fontFamily: 'Jost',
              height: 1.5
              ),
            ),

            const SizedBox(height: 40),

            // login button
            ElevatedButton(
              // style
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD65A55),
                minimumSize: const Size(double.infinity, 50),
              ),

              // once pressed goes to login screen
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginFormScreen(),
                  ),
                );
              },

              child: const Text(
                "Login",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 35,
                  fontFamily: 'Jomhuria'),
              ),
            ),

            const SizedBox(height: 15),

            // create account button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE7A39E),
                minimumSize: const Size(double.infinity, 50),
              ),

              // navigates to Sign Up screen
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },

              child: const Text(
                "Create New Account",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 35,
                  fontFamily: 'Jomhuria'),
               
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
