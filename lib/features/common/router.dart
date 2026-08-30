import 'package:bmc_app/features/notification/notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/models/widget.dart';
import '../authentication/widget.dart';
import '../availability/widget.dart';
import '../chatting/widget.dart';
import '../home/widget.dart';
import '../leave/widget.dart';
import '../on_boarding/widget.dart';
import '../profile/widget.dart';
import '../rota/widget.dart';
import '../telemedicine/widget.dart';
import 'widget.dart';

class BMCRouter {
  static final BMCRouter _instance = BMCRouter._internal();
  static BMCRouter get instance => _instance;
  static late final GoRouter router;
  static final GlobalKey<NavigatorState> parentNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> homeTabNavigationKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> availabilityTabNavigationKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> rotaTabNavigationKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> leaveTabNavigationKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> telemedTabNavigationKey =
      GlobalKey<NavigatorState>();
  BuildContext get context =>
      router.routerDelegate.navigatorKey.currentContext!;
  GoRouterDelegate get routerDelegate => router.routerDelegate;
  GoRouteInformationParser get routeInformationParser =>
      router.routeInformationParser;

  factory BMCRouter() {
    return _instance;
  }

  // onboarding pages
  static const String splashscreenPath = '/';
  static const String landingPagePath = '/landing';

  // auth pages
  static const String loginPath = '/login';
  static const String forgotPasswordPath = 'forgotPassword';

  // home pages
  static const String homePath = '/home';
  static const String chatPath = 'chat';
  static const String messagePath = 'message';
  static const String notificationsPath = 'notifications';
  static const String aboutAppPath = 'about';
  static const String profilePath = 'profile';
  static const String statsPath = 'stats';
  static const String documentsPath = 'documents';
  static const String documentViewerPath = 'document_viewer';

  // availability
  static const String availabilityPath = '/availability';

  // rota
  static const String rotaPath = '/rota';

  // leave
  static const String leavePath = '/leave';

  //telemedicine
  static const String telemedPath = '/telemedicine';
  static const String guestTelemedPath = 'guest_telemed';

  BMCRouter._internal() {
    final routes = <RouteBase>[
      GoRoute(
        path: splashscreenPath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: landingPagePath,
        builder: (context, state) => const Landing(),
      ),
      GoRoute(
        path: loginPath,
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: forgotPasswordPath,
            builder: (context, state) => const ForgotPassword(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: parentNavigatorKey,
        builder: (context, state, navigationShell) {
          return BMCAppNavBar(
            navigationShell: navigationShell,
            navStyle: NavStyle.floating,
          );
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: homeTabNavigationKey,
            routes: <RouteBase>[
              GoRoute(
                path: homePath,
                builder: (context, state) => BMCHome(),
                routes: [
                  GoRoute(
                    path: aboutAppPath,
                    builder: (context, state) => AboutApp(),
                  ),
                  GoRoute(
                    path: profilePath,
                    builder: (context, state) => Profile(),
                  ),
                  GoRoute(
                    path: documentsPath,
                    builder: (context, state) => Documents(),
                    routes: [
                      GoRoute(
                        path: documentViewerPath,
                        builder: (context, state) {
                          final extra = state.extra;
                          return extra is DocumentModel
                              ? DocumentViewerScreen(document: extra)
                              : const Scaffold(
                                  body: Center(
                                    child: Text('No document provided.'),
                                  ),
                                );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: notificationsPath,
                    builder: (context, state) => Notifications(),
                  ),
                  GoRoute(
                    path: messagePath,
                    builder: (context, state) => MessagesListScreen(),
                    routes: [
                      GoRoute(
                        path: chatPath,
                        builder: (context, state) {
                          final extra = state.extra;
                          return extra is ChatGroup
                              ? ChatScreen(group: extra)
                              : ChatScreen(peer: extra as SocketUser);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: statsPath,
                    builder: (context, state) => StatsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: availabilityTabNavigationKey,
            routes: <RouteBase>[
              GoRoute(
                path: availabilityPath,
                builder: (context, state) => AvailabilityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: rotaTabNavigationKey,
            routes: <RouteBase>[
              GoRoute(
                path: rotaPath,
                builder: (context, state) => RotaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: leaveTabNavigationKey,
            routes: <RouteBase>[
              GoRoute(
                path: leavePath,
                builder: (context, state) => LeaveScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: telemedTabNavigationKey,
            routes: <RouteBase>[
              GoRoute(
                path: telemedPath,
                builder: (context, state) => BookingVisitsScreen(),
                routes: [
                  GoRoute(
                    path: guestTelemedPath,
                    builder: (context, state) => TelemedGuestScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];

    router = GoRouter(
      navigatorKey: parentNavigatorKey,
      initialLocation: splashscreenPath,
      routes: routes,
    );
  }
}
