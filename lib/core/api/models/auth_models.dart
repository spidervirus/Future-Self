import 'package:equatable/equatable.dart';

// User model
class User extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final bool isActive;
  final bool isVerified;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.isVerified,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'is_active': isActive,
      'is_verified': isVerified,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        isActive,
        isVerified,
        lastLogin,
        createdAt,
        updatedAt,
      ];
}

// Authentication response
class AuthResponse extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int? expiresIn;
  final User user;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.tokenType,
    this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final tokenData =
        json['token'] ?? json; // Handle both nested and flat structures
    return AuthResponse(
      accessToken: tokenData['access_token'],
      refreshToken: tokenData['refresh_token'],
      tokenType: tokenData['token_type'] ?? 'bearer',
      expiresIn: tokenData['expires_in'],
      user: User.fromJson(json['user']),
    );
  }

  @override
  List<Object?> get props =>
      [accessToken, refreshToken, tokenType, expiresIn, user];
}

// Login request
class LoginRequest extends Equatable {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [email, password];
}

// Registration request
class RegisterRequest extends Equatable {
  final String email;
  final String password;
  final String? fullName;
  final String? phoneNumber;

  const RegisterRequest({
    required this.email,
    required this.password,
    this.fullName,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone_number': phoneNumber,
    };
  }

  @override
  List<Object?> get props => [email, password, fullName, phoneNumber];
}

// Password reset request
class ForgotPasswordRequest extends Equatable {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }

  @override
  List<Object?> get props => [email];
}

// API Error model
class ApiError extends Equatable {
  final String message;
  final int? statusCode;
  final String? detail;

  const ApiError({
    required this.message,
    this.statusCode,
    this.detail,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? json['detail'] ?? 'Unknown error',
      statusCode: json['status_code'],
      detail: json['detail'],
    );
  }

  @override
  List<Object?> get props => [message, statusCode, detail];
}
