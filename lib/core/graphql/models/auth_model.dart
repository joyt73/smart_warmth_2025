// lib/graphql/models/auth_model.dart
class LoginRequestInput {
  final String email;
  final String password;

  LoginRequestInput({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequestInput {
  final String email;
  final String password;
  final String displayName;

  RegisterRequestInput({
    required this.email,
    required this.password,
    required this.displayName
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'displayName': displayName,
    };
  }
}

class AuthResponse {
  final String token;

  AuthResponse({required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
    );
  }
}

class ForgotPasswordInput {
  final String email;

  ForgotPasswordInput({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class ForgotPasswordResponse {
  final bool success;

  ForgotPasswordResponse({required this.success});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      success: json['success'],
    );
  }
}