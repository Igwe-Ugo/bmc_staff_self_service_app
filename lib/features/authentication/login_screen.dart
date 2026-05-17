import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/network/provider/widget.dart';
import '../common/widget.dart'; // adjust path

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

                CustomTextInput(
                  controller: _usernameController,
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
                CustomTextInput(
                  controller: _passwordController,
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
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ): const Text(
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

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showMessage(
        'Please enter your username and password.',
        context,
        status: MessageStatus.warning,
        title: 'Missing Fields',
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final success = await authProvider.login(username, password, userProvider);

    if (!mounted) return;

    if (success) {
      showMessage(
        'Welcome back! Redirecting you now.',
        context,
        status: MessageStatus.success,
        title: 'Login Successful',
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      GoRouter.of(context).go(BMCRouter.homePath);
    } else {
      showMessage(
        authProvider.errorMessage ?? 'Login failed.',
        context,
        status: MessageStatus.error,
        title: authProvider.errorTitle ?? 'Error',
      );
    }
  }
}
