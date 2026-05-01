import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../common/widget.dart'; // adjust path

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 50.0, left: 30, right: 30, bottom: 50),
            child: Column(
              children: [
                /// 🔹 BACK BUTTON
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: GoRouter.of(context).pop,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade300,
                      child: Icon(Icons.arrow_back, size: 16, weight: 20,),
                    ),
                  ),
                ),

                const SizedBox(height: 120),

                /// 🔹 LOGO
                Image.asset(
                  'assets/images/bmc_image.png',
                  width: 50,
                  height: 50,
                ),

                const SizedBox(height: 23),

                /// 🔹 TITLE
                const Text(
                  "LOGIN PORTAL",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Please enter you credentials to log in",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Lexend',
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 25),

                /// 🔹 USERNAME
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Username",
                    style: TextStyle(
                        fontFamily: 'Lexend',
                        color: Theme.of(context).disabledColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                const CustomTextInput(
                  hint: "John",
                  prefixIcon: Icons.person,
                ),

                const SizedBox(height: 24),

                /// 🔹 PASSWORD
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password",
                    style: TextStyle(
                        fontFamily: 'Lexend',
                        color: Theme.of(context).disabledColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                const CustomTextInput(
                  hint: "*************",
                  prefixIcon: Icons.lock,
                  isPassword: true,
                ),

                const SizedBox(height: 10),

                /// 🔹 FORGOT PASSWORD
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Forget Password?",
                      style: TextStyle(
                          fontSize: 16,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w400,
                        color: Colors.blue
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                /// 🔹 LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => GoRouter.of(context).go(BMCRouter.homePath),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                          fontFamily: 'Lexend',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                      ),
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
