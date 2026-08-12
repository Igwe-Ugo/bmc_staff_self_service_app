import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client/widget.dart';
import '../../core/network/provider/widget.dart';
import '../../core/network/services/widget.dart';
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
  bool _rememberMe = false;
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final savedUser = await _secureStorage.read(key: 'remembered_username');
      final savedPass = await _secureStorage.read(key: 'remembered_password');
      final rememberMeStatus = await _secureStorage.read(
        key: 'remembered_me_status',
      );

      if (rememberMeStatus == "true" &&
          savedUser != null &&
          savedPass != null) {
        setState(() {
          _rememberMe = true;
          _usernameController.text = savedUser;
          _passwordController.text = savedPass;
        });
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
      showMessage(
        "Error loading saved credentials.",
        context,
        status: MessageStatus.error,
        title: "Error",
      );
    }
  }

  // save or clear storage action
  Future<void> _handleCredentialPersistence() async {
    if (_rememberMe) {
      await _secureStorage.write(
        key: 'remembered_username',
        value: _usernameController.text,
      );
      await _secureStorage.write(
        key: 'remembered_password',
        value: _passwordController.text,
      );
      await _secureStorage.write(key: 'remembered_me_status', value: "true");
    } else {
      await _secureStorage.delete(key: 'remembered_username');
      await _secureStorage.delete(key: 'remembered_password');
      await _secureStorage.delete(key: 'remembered_me_status');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        // Added SafeArea to protect top and bottom notches
        child: SingleChildScrollView(
          // 👈 1. Wrap with SingleChildScrollView
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

                /// 隼 TITLE
                const Text(
                  "LOGIN PORTAL",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please enter you credentials to log in",
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

                /// 隼 USERNAME
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Username",
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
                  controller: _usernameController,
                  hint: "John",
                  prefixIcon: Icons.person,
                ),
                const SizedBox(height: 24),

                /// 隼 PASSWORD
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password",
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
                  controller: _passwordController,
                  hint: "*************",
                  prefixIcon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 20),

                // ─── Remember Me & Forgot Password Row ───────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          checkColor: Colors.white,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (bool? newValue) {
                            setState(() {
                              _rememberMe = newValue ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        child: Text(
                          "Remember me",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Lexend',
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.black87
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 70,
                ), // 👈 2. Replaced Spacer() with a fixed height Box
                ///LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading == true ? null : _login,
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
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Lexend',
                              fontSize: 15,
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

  // _login function logic remains identical below...
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
      // NOTE: this used to return here without ever setting _isLoading back
      // to false, since it was set true below the original check. Moved the
      // setState below this guard so the button doesn't get stuck spinning
      // on an empty-fields submit.
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final presenceProvider = context.read<PresenceProvider>();
    final chatProvider = context.read<ChatProvider>();
    final documentProvider = context.read<DocumentProvider>();
    ProfileService.preload();
    final success = await authProvider.login(
      username,
      password,
      userProvider,
      presenceProvider,
      chatProvider,
      documentProvider,
    );

    if (success) {
      // sawe or clear credentials asynchronously before route redirection
      await _handleCredentialPersistence();
      ApiClient.instance.setUserProvider(userProvider);
      showMessage(
        'Welcome back! Redirecting you now.',
        context,
        status: MessageStatus.success,
        title: 'Login Successful',
      );
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      GoRouter.of(context).go(BMCRouter.homePath);
      navBarVisible.value = true;
    } else {
      setState(() {
        _isLoading = false;
      });
      showMessage(
        authProvider.errorMessage ?? 'Login failed.',
        context,
        status: MessageStatus.error,
        title: authProvider.errorTitle ?? 'Error',
      );
    }
  }
}
