import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../authentication/widget.dart';
import '../home/widget.dart';
import '../on_boarding/widget.dart';
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
  static final GlobalKey<NavigatorState> messageTabNavigationKey = GlobalKey<NavigatorState>();
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

  // home pages
  static const String homePath = '/home';
  
  // availability
  static const String availabilityPath = '/availability';
  
  // rota
  static const String rotaPath = '/rota';

  // leave
  static const String leavePath = '/leave';

  // message
  static const String messagePath = '/message';

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
                      builder: (context, state) => BMCHome()),
                ]),
            StatefulShellBranch(
                navigatorKey: availabilityTabNavigationKey,
                routes: <RouteBase>[
                  GoRoute(
                      path: availabilityPath,
                      builder: (context, state) => Container()),
                ]),
            StatefulShellBranch(
                navigatorKey: rotaTabNavigationKey,
                routes: <RouteBase>[
                  GoRoute(
                    path: rotaPath,
                    builder: (context, state) => Container(),
                  ),
                ]),
            StatefulShellBranch(
                navigatorKey: leaveTabNavigationKey,
                routes: <RouteBase>[
                  GoRoute(
                    path: leavePath,
                    builder: (context, state) => Container(),
                  ),
                ]),
            StatefulShellBranch(
                navigatorKey: messageTabNavigationKey,
                routes: <RouteBase>[
                  GoRoute(
                      path: messagePath,
                      builder: (context, state) => Container(),
                      ),
                ]),
          ])
    ];

    router = GoRouter(
      navigatorKey: parentNavigatorKey,
      initialLocation: splashscreenPath,
      routes: routes,
    );
  }
}
