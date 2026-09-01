import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../../core/network/provider/widget.dart';
import '../common/widget.dart'; // adjust path

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        // Added SafeArea to protect top and bottom notches
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior
              .onDrag, // Optional: dismisses keyboard on drag
          child: Padding(
            padding: const EdgeInsets.only(
              top: 30.0,
              left: 30,
              right: 30,
              bottom: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// 隼 BACK BUTTON
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          GoRouter.of(context).push(BMCRouter.landingPagePath),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.black12.withOpacity(0.3)
                            : Theme.of(context).hoverColor,
                        child: Icon(Iconsax.arrow_left, size: 18),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final themeProvider = Provider.of<DarkThemeProvider>(
                          context,
                          listen: false,
                        );
                        themeProvider.darkTheme = !themeProvider.darkTheme;
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.black12.withOpacity(0.3)
                            : Theme.of(context).hoverColor,
                        child: Icon(
                          isDark ? Iconsax.sun_1 : Iconsax.moon,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 80,
                ), // Reduced from 120 to optimize viewport space on small screens
                /// LOGO
                Image.asset(
                  'assets/images/bmc_image.png',
                  width: 50,
                  height: 50,
                ),

                const SizedBox(height: 23),

                /// TITLE
                const Text(
                  "PASSWORD RESET",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please enter your email to request password reset",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Lexend',
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 25),

                /// Email
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Enter Email",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.grey,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextInput(
                  controller: _emailController,
                  hint: "email",
                  prefixIcon: Icons.email,
                ),
                const SizedBox(
                  height: 40,
                ), // 👈 2. Replaced Spacer() with a fixed height Box
                ///LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestPasswordReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading == true
                        ? LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white,
                            size: 35,
                          )
                        : const Text(
                            "Request Password Reset",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Lexend',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => GoRouter.of(context).go(BMCRouter.loginPath),
                  child: const Text(
                    "Back to Login",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w400,
                      color: Colors.blue,
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

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      showMessage(
        'Please enter your email address.',
        context,
        status: MessageStatus.warning,
        title: 'Missing Fields',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    await authProvider.forgotPassword(email);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (authProvider.errorMessage == null) {
      await Future.delayed(const Duration(milliseconds: 200));
      showMessage(
        'Password reset request sent. Please check your email for further instructions.',
        context,
        status: MessageStatus.success,
        title: 'Success',
      );
      if (!mounted) return;
      GoRouter.of(context).go(BMCRouter.loginPath);
      navBarVisible.value = true;
    } else {
      showMessage(
        authProvider.errorMessage ?? 'Password reset failed.',
        context,
        status: MessageStatus.error,
        title: authProvider.errorTitle ?? 'Error',
      );
    }
  }
}
