import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:future_self/app/theme/cosmic_dream_theme.dart';
import 'package:future_self/core/routing/app_router.dart';
import 'package:future_self/core/di/service_locator.dart';
import 'package:future_self/features/auth/bloc/auth_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies (service locator)
  await initializeDependencies();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Future Self',
        theme: CosmicDreamTheme.themeData,
        routerConfig: router,
      ),
    );
  }
}
