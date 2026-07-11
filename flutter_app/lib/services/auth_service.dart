import '../services/api_service.dart';

class AuthService {
  AuthService(this._api);

  final ApiService _api;

  Future<String> solicitarRecuperacionPassword(String email) async {
    final data = await _api.post('auth_recuperar_password', {
      'email': email.trim(),
    });
    return (data as Map<String, dynamic>)['mensaje'] as String;
  }
}
