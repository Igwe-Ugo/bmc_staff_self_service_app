import 'package:bmc_app/core/network/services/widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client/widget.dart';
import 'core/network/interceptors/auth_refresh.dart';
import 'core/storage/secure_storage.dart';
import 'features/common/widget.dart';
import '../../core/network/provider/widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // MUST precede configure() below
  ApiEndpoints.validateEnv(); // validating environment variables at startup
  BMCRouter(); // 👈 triggers _internal() which sets router

  // Created here — NOT inside MultiProvider's `create:` — because
  // SocketService.configure()'s privileges()/dnd() closures and
  // AuthRefresh need to read the SAME UserProvider instance the widget tree
  // uses. MultiProvider's `create:` callback doesn't run until the tree
  // builds, which is too late for configure() below.
  final userProvider = UserProvider();

  // Keeps a refresh (triggered by either Dio or the socket) writing back to
  // the same UserProvider the interceptor already updates on 401s.
  AuthRefresh.instance.updateUserProvider(userProvider);
  // Same instance ApiClient's AuthInterceptor uses (confirmed via
  // login_screen.dart, which previously called this only after a successful
  // login). Calling it here too means the interceptor has a UserProvider
  // wired from cold start — including the checkAuthStatus() warm-start path,
  // which never went through login_screen.dart at all.
  ApiClient.instance.setUserProvider(userProvider);

  SocketService.instance.configure(
    // Must be the deployment ORIGIN (https://host), not the /api base URL —
    // confirm ApiEndpoints.socketUrl already strips to that with your
    // env.json-based ApiEndpoints. If it doesn't yet, wrap it here instead:
    //   socketUrl: SocketService.originFromApiBaseUrl(ApiEndpoints.baseUrl),
    socketUrl: ApiEndpoints.socketUrl,
    readAccessToken: SecureStorage.instance.getAccessToken,
    // Same single-flight refresh AuthInterceptor uses — never a second,
    // independent refresh path. See auth_refresh.dart for why that matters.
    refreshAccessToken: AuthRefresh.instance.getFreshAccessToken,
    // TODO: point this at BMCRouter's actual login route constant — guessed
    // as loginPath to match the homePath/landingPagePath naming already in
    // this file; confirm against BMCRouter itself.
    onAuthLost: () => BMCRouter.router.go(BMCRouter.loginPath),
    // The server ignores these at connect time (it trusts the token's
    // claims instead), but the handshake payload still expects them.
    privileges: () => userProvider.user?.privileges ?? const [],
    dnd: () => userProvider.user?.doNotDisturb ?? false,
  );

  runApp(BMCStaffSelfService(userProvider: userProvider));
}

class BMCStaffSelfService extends StatefulWidget {
  final UserProvider userProvider;

  const BMCStaffSelfService({super.key, required this.userProvider});

  // ignore: library_private_types_in_public_api
  static _BMCStaffSelfServiceState of(BuildContext context) =>
      context.findAncestorStateOfType<_BMCStaffSelfServiceState>()!;

  @override
  State<BMCStaffSelfService> createState() => _BMCStaffSelfServiceState();
}

class _BMCStaffSelfServiceState extends State<BMCStaffSelfService> {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  @override
  void initState() {
    super.initState();
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme = await themeChangeProvider
        .bmcStaffPreferences
        .getTheme();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            return themeChangeProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // .value, not create: — this is the SAME instance main() already
        // wired into AuthRefresh and the socket's privileges()/dnd()
        // closures. Using create: here would silently give the widget tree
        // a second, disconnected UserProvider.
        ChangeNotifierProvider.value(value: widget.userProvider),
        ChangeNotifierProvider(create: (_) => AvailabilityProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => RotaProvider()),
        ChangeNotifierProvider(create: (_) => PresenceProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<DarkThemeProvider>(
        builder: (context, themeData, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'BMC Staff Self-Service',
            routerConfig: BMCRouter.router,
            theme: Styles.themeData(themeChangeProvider.darkTheme, context),
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(
                    mediaQuery.textScaler.scale(1.0).clamp(1.0, 1.1),
                  ),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
