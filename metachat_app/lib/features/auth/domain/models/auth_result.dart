class AuthResult {
  final String userId;
  final String token;

  const AuthResult({
    required this.userId,
    required this.token,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      userId: json['id']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'token': token,
    };
  }
}

