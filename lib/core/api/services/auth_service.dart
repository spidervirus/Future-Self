import 'package:dio/dio.dart';
import '../api_client.dart';
import '../models/auth_models.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Save token for future requests
      await _apiClient.saveToken(authResponse.accessToken);

      return authResponse;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Login failed: ${e.toString()}');
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Save token for future requests
      await _apiClient.saveToken(authResponse.accessToken);

      return authResponse;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      // Call logout endpoint
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Even if logout fails on server, clear local token
      print('Logout error: $e');
    } finally {
      // Always clear local token
      await _apiClient.clearToken();
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to get current user: ${e.toString()}');
    }
  }

  Future<User> updateProfile({
    String? fullName,
    String? phoneNumber,
    DateTime? birthDate,
    String? location,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (birthDate != null) data['birth_date'] = birthDate.toIso8601String();
      if (location != null) data['location'] = location;

      final response = await _apiClient.put(
        '/auth/profile',
        data: data,
      );

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to update profile: ${e.toString()}');
    }
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try {
      await _apiClient.post(
        '/auth/forgot-password',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to send reset email: ${e.toString()}');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiError(message: 'Failed to change password: ${e.toString()}');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getToken();
    return token != null;
  }

  ApiError _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return ApiError.fromJson(data);
      }
      return ApiError(
        message: data.toString(),
        statusCode: e.response!.statusCode,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return const ApiError(message: 'Connection timeout');
      case DioExceptionType.receiveTimeout:
        return const ApiError(message: 'Receive timeout');
      case DioExceptionType.sendTimeout:
        return const ApiError(message: 'Send timeout');
      case DioExceptionType.connectionError:
        return const ApiError(
            message:
                'Connection error. Please check your internet connection.');
      default:
        return ApiError(message: 'Network error: ${e.message}');
    }
  }
}
