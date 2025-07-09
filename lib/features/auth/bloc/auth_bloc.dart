import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/services/auth_service.dart';
import '../../../core/api/models/auth_models.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthProfileUpdateRequested>(_onAuthProfileUpdateRequested);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
    on<AuthChangePasswordRequested>(_onAuthChangePasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final loginRequest = LoginRequest(
        email: event.email,
        password: event.password,
      );

      final authResponse = await _authService.login(loginRequest);
      emit(AuthAuthenticated(user: authResponse.user));
    } catch (e) {
      String errorMessage = 'Login failed';
      if (e is ApiError) {
        errorMessage = e.message;
      }
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final registerRequest = RegisterRequest(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        phoneNumber: event.phoneNumber,
      );

      final authResponse = await _authService.register(registerRequest);
      emit(AuthRegistrationSuccess(user: authResponse.user));

      // After successful registration, immediately authenticate
      emit(AuthAuthenticated(user: authResponse.user));
    } catch (e) {
      String errorMessage = 'Registration failed';
      if (e is ApiError) {
        errorMessage = e.message;
      }
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authService.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      // Even if logout fails, clear local state
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;

    emit(AuthLoading());

    try {
      final updatedUser = await _authService.updateProfile(
        fullName: event.fullName,
        phoneNumber: event.phoneNumber,
        birthDate: event.birthDate,
        location: event.location,
      );

      emit(AuthProfileUpdated(user: updatedUser));
      emit(AuthAuthenticated(user: updatedUser));
    } catch (e) {
      String errorMessage = 'Profile update failed';
      if (e is ApiError) {
        errorMessage = e.message;
      }
      emit(AuthError(message: errorMessage));

      // Restore previous state
      if (state is AuthAuthenticated) {
        emit(state);
      }
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final request = ForgotPasswordRequest(email: event.email);
      await _authService.forgotPassword(request);
      emit(AuthPasswordResetSent(email: event.email));
    } catch (e) {
      String errorMessage = 'Failed to send reset email';
      if (e is ApiError) {
        errorMessage = e.message;
      }
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onAuthChangePasswordRequested(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;

    final currentState = state as AuthAuthenticated;
    emit(AuthLoading());

    try {
      await _authService.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      emit(AuthPasswordChanged());
      emit(AuthAuthenticated(user: currentState.user));
    } catch (e) {
      String errorMessage = 'Password change failed';
      if (e is ApiError) {
        errorMessage = e.message;
      }
      emit(AuthError(message: errorMessage));
      emit(AuthAuthenticated(user: currentState.user));
    }
  }
}
