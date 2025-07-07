import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:future_self/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:future_self/features/home/presentation/screens/home_screen.dart';
import 'package:future_self/features/chat/presentation/screens/chat_screen.dart';
import 'package:future_self/features/journal/presentation/screens/journal_screen.dart';
import 'package:future_self/features/vision_board/presentation/screens/vision_board_screen.dart';
import 'package:future_self/features/affirmations/presentation/screens/affirmations_screen.dart';
import 'package:future_self/features/activities/presentation/screens/activities_screen.dart';

final GoRouter router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingScreen();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (BuildContext context, GoRouterState state) {
        return const ChatScreen();
      },
    ),
    GoRoute(
      path: '/journal',
      builder: (BuildContext context, GoRouterState state) {
        return const JournalScreen();
      },
    ),
    GoRoute(
      path: '/vision-board',
      builder: (BuildContext context, GoRouterState state) {
        return const VisionBoardScreen();
      },
    ),
    GoRoute(
      path: '/affirmations',
      builder: (BuildContext context, GoRouterState state) {
        return const AffirmationsScreen();
      },
    ),
    GoRoute(
      path: '/activities',
      builder: (BuildContext context, GoRouterState state) {
        return const ActivitiesScreen();
      },
    ),
  ],
);
