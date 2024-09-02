import 'package:apollo_app/Screens/AppHandeling/error_page.dart';
import 'package:apollo_app/Screens/Auth/auth_page.dart';
import 'package:apollo_app/Screens/UserLogic/audio.dart';
import 'package:apollo_app/Screens/UserLogic/chat.dart';
import 'package:apollo_app/Screens/UserLogic/profile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyAppRouter {
  GoRouter router = GoRouter(
    routes: [
      GoRoute(
        name: 'auth',
        path: '/',
        pageBuilder: (context, state) {
          return const MaterialPage(child: AuthPage());
        },
      ),
      GoRoute(
        name: 'home',
        path: '/home',
        pageBuilder: (context, state) {
          return MaterialPage(child: AudioPage());
        },
      ),
      GoRoute(
        name: 'profile',
        path: '/profile',
        pageBuilder: (context, state) {
          return const MaterialPage(child: Profile());
        },
      ),
      GoRoute(
        name: 'chat',
        path: '/chat',
        pageBuilder: (context, state) {
          return const MaterialPage(child: Chat());
        },
      )
    ],
    errorPageBuilder: (context, state) {
      return MaterialPage(child: ErrorPage());
    },
  );
}
