import 'package:get_it/get_it.dart';

import '../api/api_client.dart';
import '../api/services/auth_service.dart';
import '../api/services/chat_service.dart';
import '../api/services/websocket_service.dart';
import '../api/services/onboarding_service.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/chat/bloc/chat_bloc.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Core services
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // API services
  sl.registerLazySingleton<AuthService>(() => AuthService(sl()));
  sl.registerLazySingleton<ChatService>(() => ChatService(sl()));
  sl.registerLazySingleton<WebSocketService>(() => WebSocketService());
  sl.registerLazySingleton<OnboardingService>(
      () => OnboardingService(apiClient: sl()));

  // BLoCs
  sl.registerFactory<AuthBloc>(() => AuthBloc(authService: sl()));
  sl.registerFactory<ChatBloc>(() => ChatBloc(
        chatService: sl(),
        webSocketService: sl(),
      ));
  sl.registerFactory<OnboardingBloc>(
      () => OnboardingBloc(onboardingService: sl()));
}
