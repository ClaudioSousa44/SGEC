import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;
  static const Duration timeoutDuration =
      Duration(seconds: ApiConfig.timeoutSeconds);

  // Headers padrão
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Headers com autenticação
  static Map<String, String> getAuthHeaders(String? token) {
    final headers = ApiService.headers;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Método genérico para requisições GET
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, String>? queryParameters,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');

      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      final response = await http
          .get(
            uri,
            headers: getAuthHeaders(token),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Erro na requisição GET: ${e.toString()}');
    }
  }

  // Método genérico para requisições POST
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      // Log para debug (remover em produção)
      print('POST ${uri.toString()}');
      print('Body: ${jsonEncode(body)}');
      print('Headers: ${getAuthHeaders(token)}');

      final response = await http
          .post(
            uri,
            headers: getAuthHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      // Log da resposta para debug
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Erro na requisição POST: ${e.toString()}');
    }
  }

  // Método genérico para requisições PUT
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http
          .put(
            uri,
            headers: getAuthHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Erro na requisição PUT: ${e.toString()}');
    }
  }

  // Método genérico para requisições DELETE
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http
          .delete(
            uri,
            headers: getAuthHeaders(token),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Erro na requisição DELETE: ${e.toString()}');
    }
  }

  // Tratamento de resposta
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (body.isEmpty) {
      if (statusCode >= 200 && statusCode < 300) {
        return {'success': true};
      }
      throw ApiException('Resposta vazia do servidor (Status: $statusCode)');
    }

    try {
      final jsonResponse = jsonDecode(body);

      if (statusCode >= 200 && statusCode < 300) {
        // Garantir que retorna um Map
        if (jsonResponse is Map<String, dynamic>) {
          return jsonResponse;
        } else {
          return {'success': true, 'data': jsonResponse};
        }
      } else {
        // Tratamento melhorado para erros
        String errorMessage = 'Erro desconhecido';

        if (jsonResponse is Map<String, dynamic>) {
          errorMessage = jsonResponse['message'] as String? ??
              jsonResponse['error'] as String? ??
              jsonResponse['errors']?.toString() ??
              body;
        } else {
          errorMessage = body;
        }

        throw ApiException(errorMessage, statusCode: statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Se não conseguir decodificar JSON, mostrar o body bruto
      throw ApiException(
        'Erro ao processar resposta: ${e.toString()}\nResposta do servidor: $body',
        statusCode: statusCode,
      );
    }
  }
}

// Exceção personalizada para erros da API
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
