import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:future_self/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:future_self/features/home/presentation/screens/home_screen.dart';
import 'package:future_self/features/chat/presentation/screens/chat_screen.dart';
import 'package:future_self/features/journal/presentation/screens/journal_screen.dart';
import 'package:future_self/features/vision_board/presentation/screens/vision_board_screen.dart';
import 'package:future_self/features/affirmations/presentation/screens/affirmations_screen.dart';
import 'package:future_self/features/activities/presentation/screens/activities_screen.dart';
import 'package:future_self/features/auth/presentation/screens/login_screen.dart';
import 'package:future_self/features/auth/presentation/screens/register_screen.dart';
import 'package:future_self/features/auth/presentation/screens/forgot_password_screen.dart';
import 'auth_wrapper.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: <GoRoute>[
    // Public routes (no auth required)
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterScreen();
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (BuildContext context, GoRouterState state) {
        return const ForgotPasswordScreen();
      },
    ),

    // Protected routes (auth required)
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return AuthWrapper(
          child: const HomeScreen(),
        );
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) {
        return AuthWrapper(
          child: const OnboardingScreen(),
        );
      },
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return AuthWrapper(
          child: const HomeScreen(),
        );
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (BuildContext context, GoRouterState state) {
        return AuthWrapper(
          child: const ChatScreen(),
        );
      },
    ),
    GoRoute(
      path: '/journal',
      builder: (BuildContext context, GoRouterState state) {
        return AuthWrapper(
          child: const JournalScreen(),
        );
      },
    ),
    GoRoute(
      path: '/vision-board',
      builder: (BuildContext context, GoRouterState state) {
        return AuthWrapper(
          child: const VisionBoardScreen(),
        );
      },
    ),
    GoRoute(
      path: '/affirmations',
      builder: (BuildContext context, GoRouterState state) {
        return AuthWrapper(
          child: const AffirmationsScreen(),
        );
      },
    ),
    GoRoute(
      path: '/activities',
      builder: (BuildContext context, GoRouterState state) {
        return AuthWrapper(
          child: const ActivitiesScreen(),
        );
      },
    ),
  ],
);
