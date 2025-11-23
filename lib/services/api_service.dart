import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

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

  // Método para upload de arquivo (multipart/form-data)
  static Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> fields, {
    String? token,
    String? fileFieldName,
    File? file,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final request = http.MultipartRequest('POST', uri);

      // Adicionar headers de autenticação
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Adicionar campos do formulário
      request.fields.addAll(fields);

      // Adicionar arquivo se fornecido
      int? fileSize;
      String? fileName;
      if (file != null && fileFieldName != null) {
        fileSize = await file.length();
        fileName = path
            .basename(file.path); // Usa path.basename para funcionar no Windows

        final fileStream = http.ByteStream(file.openRead());
        final multipartFile = http.MultipartFile(
          fileFieldName,
          fileStream,
          fileSize,
          filename: fileName,
        );
        request.files.add(multipartFile);
      }

      // Logs detalhados para debug - PAYLOAD COMPLETO
      print('═══════════════════════════════════════════════════════════');
      print('📤 PAYLOAD COMPLETO - POST MULTIPART');
      print('═══════════════════════════════════════════════════════════');
      print('🔗 URL: ${uri.toString()}');
      print('📋 Headers:');
      request.headers.forEach((key, value) {
        print('   $key: ${key == 'Authorization' ? 'Bearer ***' : value}');
      });
      print('📝 Campos (Fields):');
      fields.forEach((key, value) {
        print('   $key: "$value"');
      });
      if (file != null && fileFieldName != null) {
        print('📁 Arquivo:');
        print('   Campo: $fileFieldName');
        print('   Nome: $fileName');
        print('   Tamanho: $fileSize bytes');
        print('   Caminho: ${file.path}');
      }
      print('═══════════════════════════════════════════════════════════');
      
      print('⏳ Aguardando resposta do servidor...');
      print('   Timeout configurado: ${timeoutDuration.inSeconds} segundos');

      final streamedResponse = await request.send().timeout(
        timeoutDuration,
        onTimeout: () {
          print('⏰ TIMEOUT: Requisição demorou mais de ${timeoutDuration.inSeconds} segundos');
          throw TimeoutException(
            'A requisição demorou muito para responder. Verifique sua conexão.',
            timeoutDuration,
          );
        },
      );
      
      print('✅ Resposta recebida do servidor, processando...');
      final response = await http.Response.fromStream(streamedResponse);

      // Logs da resposta
      print('═══════════════════════════════════════════════════════════');
      print('📥 RESPOSTA DO SERVIDOR');
      print('═══════════════════════════════════════════════════════════');
      print('📊 Status Code: ${response.statusCode}');
      print('📋 Response Headers:');
      response.headers.forEach((key, value) {
        print('   $key: $value');
      });
      print('📄 Response Body:');
      try {
        // Tentar formatar JSON se possível
        final jsonData = jsonDecode(response.body);
        print(const JsonEncoder.withIndent('   ').convert(jsonData));
      } catch (e) {
        print('   ${response.body}');
      }
      print('═══════════════════════════════════════════════════════════');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Erro no upload de arquivo: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      throw ApiException('Erro no upload de arquivo: ${e.toString()}');
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
        String errorMessage = 'Erro desconhecido (Status: $statusCode)';

        if (jsonResponse is Map<String, dynamic>) {
          // Tentar extrair mensagem de erro de diferentes formatos
          errorMessage = jsonResponse['message'] as String? ??
              jsonResponse['error'] as String? ??
              jsonResponse['detail'] as String? ??
              jsonResponse['msg'] as String? ??
              (jsonResponse['errors'] != null
                  ? jsonResponse['errors'].toString()
                  : null) ??
              body;
        } else {
          errorMessage = body.isNotEmpty
              ? body
              : 'Erro desconhecido (Status: $statusCode)';
        }

        // Log detalhado do erro
        print('❌ Erro da API:');
        print('   Status: $statusCode');
        print('   Mensagem: $errorMessage');
        print('   Body completo: $body');

        throw ApiException('$errorMessage (Status: $statusCode)',
            statusCode: statusCode);
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
