import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../core/api/services/onboarding_service.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final OnboardingService _onboardingService = OnboardingService();
  bool _isCheckingOnboarding = false;
  DateTime? _lastOnboardingCheck;
  bool _hasCheckedOnboardingForCurrentAuth = false;

  @override
  void initState() {
    super.initState();
    // Check auth status when the wrapper is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(AuthCheckRequested());
      }
    });
  }

  Future<void> _checkOnboardingStatus(BuildContext context) async {
    // Prevent rapid successive checks
    final now = DateTime.now();
    if (_lastOnboardingCheck != null &&
        now.difference(_lastOnboardingCheck!).inSeconds < 5) {
      return;
    }

    if (_isCheckingOnboarding) return;

    setState(() {
      _isCheckingOnboarding = true;
      _lastOnboardingCheck = now;
    });

    try {
      final progress = await _onboardingService.getProgress();
      print(
          '📊 AuthWrapper - Raw progress: isComplete=${progress.isComplete}, completedSteps=${progress.completedSteps}');

      if (mounted) {
        String? currentRoute;
        try {
          final routerState = GoRouterState.of(context);
          currentRoute = routerState.uri.path;
        } catch (e) {
          // If we can't get the current route, assume we need to navigate
          currentRoute = null;
        }

        print(
            '🔍 Onboarding Status: isComplete=${progress.isComplete}, currentRoute=$currentRoute');

        if (!progress.isComplete) {
          // User hasn't completed onboarding
          if (currentRoute != '/onboarding') {
            print('🔄 Redirecting to onboarding (not complete)');
            if (mounted) {
              context.go('/onboarding');
            }
          }
        } else {
          // User has completed onboarding
          if (currentRoute == '/' || currentRoute == '/onboarding') {
            print('🏠 Redirecting to home (onboarding complete)');
            if (mounted) {
              context.go('/home');
            }
          } else {
            print('✅ User on correct route after onboarding completion');
          }
        }

        // Mark that we've checked for this auth session
        _hasCheckedOnboardingForCurrentAuth = true;
      }
    } catch (e) {
      print('❌ Error checking onboarding status: $e');
      // If we can't check onboarding status, handle gracefully
      if (mounted) {
        String? currentRoute;
        try {
          final routerState = GoRouterState.of(context);
          currentRoute = routerState.uri.path;
        } catch (e) {
          // If we can't get the route, default to onboarding
          currentRoute = null;
        }

        // Only redirect if we're not already on onboarding and we haven't checked yet
        if (currentRoute != '/onboarding' &&
            !_hasCheckedOnboardingForCurrentAuth) {
          context.go('/onboarding');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOnboarding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          _hasCheckedOnboardingForCurrentAuth = false;
          context.go('/login');
        } else if (state is AuthAuthenticated &&
            !_hasCheckedOnboardingForCurrentAuth) {
          // Only check onboarding status if we haven't checked for this auth session
          _checkOnboardingStatus(context);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading ||
              state is AuthInitial ||
              _isCheckingOnboarding) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is AuthUnauthenticated) {
            // This will be handled by the listener
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return widget.child;
        },
      ),
    );
  }
}
