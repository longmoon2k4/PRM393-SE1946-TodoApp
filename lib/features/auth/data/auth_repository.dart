import '../../../core/network/api_client.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
  });

  final String id;
  final String email;
  final String fullName;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    fullName: json['fullName'] as String? ?? '',
  );
}

class AuthRepository {
  const AuthRepository(this._client);

  final ApiClient _client;

  ApiClient get client => _client;

  Future<AuthUser> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final json = await _client.post(
      '/auth/register',
      body: {'email': email, 'password': password, 'fullName': fullName},
    );
    return AuthUser.fromJson(json as Map<String, dynamic>);
  }

  Future<void> login({required String email, required String password}) async {
    final json = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;
    await _client.saveToken(json['accessToken'] as String);
  }

  Future<AuthUser> currentUser() async {
    final json = await _client.get('/users/me');
    return AuthUser.fromJson(json as Map<String, dynamic>);
  }

  Future<void> logout() => _client.clearToken();
}
