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
  BMCRouter();
  final userProvider = UserProvider();
  AuthRefresh.instance.updateUserProvider(userProvider);
  ApiClient.instance.setUserProvider(userProvider);

  SocketService.instance.configure(
    socketUrl: ApiEndpoints.socketUrl,
    readAccessToken: SecureStorage.instance.getAccessToken,
    refreshAccessToken: AuthRefresh.instance.getFreshAccessToken,
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
        ChangeNotifierProvider.value(value: widget.userProvider),
        ChangeNotifierProvider(create: (_) => AvailabilityProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => RotaProvider()),
        ChangeNotifierProvider(create: (_) => PresenceProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(
          create: (_) => TeleMedicineProvider(
            service: TeleMedicineService(),
          ),
        ),
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
