import '../models/login_request.dart';
import '../models/login_response.dart';
import '../utils/api_config.dart';
import 'api_service.dart';

class AuthService {
  // Endpoint de login
  static const String loginEndpoint = ApiConfig.loginEndpoint;

  /// Realiza o login do usuário
  ///
  /// Retorna um [LoginResponse] com os dados do usuário e token de autenticação
  /// Lança uma [ApiException] em caso de erro
  static Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await ApiService.post(
        loginEndpoint,
        request.toJson(),
      );

      // Debug: mostrar resposta bruta da API
      print('Resposta bruta da API: $response');

      final loginResponse = LoginResponse.fromJson(response);

      // Debug: mostrar resposta parseada
      print(
          'LoginResponse parseada - Success: ${loginResponse.success}, Token: ${loginResponse.token != null ? "Presente" : "Ausente"}');

      return loginResponse;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Erro ao realizar login: ${e.toString()}');
    }
  }

  /// Valida se o token está válido
  ///
  /// Retorna true se o token for válido, false caso contrário
  static Future<bool> validateToken(String token) async {
    try {
      // TODO: Implementar endpoint de validação de token
      // Por enquanto, retorna true se o token não estiver vazio
      return token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Realiza logout
  ///
  /// Limpa os dados de autenticação
  static Future<void> logout() async {
    try {
      // TODO: Implementar endpoint de logout se necessário
      // Por enquanto, apenas limpa os dados localmente
    } catch (e) {
      throw ApiException('Erro ao realizar logout: ${e.toString()}');
    }
  }
}
