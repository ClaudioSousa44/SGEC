import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Serviço para escanear fotos usando a API de reconhecimento
class ScanService {
  // URL base da API de escaneamento
  static const String scanApiUrl =
      'https://condo-api.greenmeadow-9d169997.brazilsouth.azurecontainerapps.io/';

  // Timeout para requisições
  static const Duration timeoutDuration = Duration(seconds: 60);

  /// Escaneia uma foto e retorna os dados extraídos
  ///
  /// [imageFile] - Arquivo da imagem a ser escaneada
  /// Retorna um Map com os dados extraídos da etiqueta e informações de debug
  static Future<Map<String, dynamic>> scanPhoto(File imageFile) async {
    try {
      // Criar requisição multipart (igual ao Swagger)
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$scanApiUrl/extract/'), // Endpoint: /extract/
      );

      // Headers mínimos (o multipart/form-data é adicionado automaticamente)
      request.headers['Accept'] = 'application/json';

      // Ler o arquivo em bytes (igual ao Swagger)
      final fileBytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split(Platform.pathSeparator).last;

      // Criar MultipartFile (igual ao Swagger - campo "file")
      final multipartFile = http.MultipartFile.fromBytes(
        'file', // Nome do campo exatamente como no Swagger
        fileBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // Informações da requisição para debug
      final requestInfo = {
        'url': '$scanApiUrl/extract/',
        'method': 'POST',
        'headers': Map<String, String>.from(request.headers),
        'fileSize': fileBytes.length,
        'fileName': fileName,
        'fieldName': 'file',
      };

      print('📸 Enviando foto para API de escaneamento...');
      print('🔗 URL: ${requestInfo['url']}');
      print('📁 Campo: ${requestInfo['fieldName']}');
      print('📄 Filename: ${requestInfo['fileName']}');
      print('📦 Tamanho: ${requestInfo['fileSize']} bytes');
      print('📋 Headers: ${requestInfo['headers']}');

      // Enviar requisição
      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      // Informações da resposta para debug
      Map<String, dynamic> responseBody;
      try {
        responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        responseBody = {'raw': response.body};
      }

      final responseInfo = {
        'statusCode': response.statusCode,
        'headers': Map<String, String>.from(response.headers),
        'body': responseBody,
      };

      print('📥 Status Code: ${responseInfo['statusCode']}');
      print('📥 Headers: ${responseInfo['headers']}');
      print('📥 Response Body: ${response.body}');

      // Processar resposta
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Adicionar informações de debug à resposta
        responseBody['_debug'] = {
          'request': requestInfo,
          'response': responseInfo,
          'imagePath': imageFile.path,
        };
        return responseBody;
      } else {
        // Tratar erro
        String errorMessage = 'Erro ao escanear foto';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson is Map<String, dynamic>) {
            errorMessage = errorJson['message'] as String? ??
                errorJson['error'] as String? ??
                errorMessage;
          }
        } catch (e) {
          errorMessage = response.body;
        }
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Erro ao escanear foto: ${e.toString()}');
    }
  }

  /// Verifica se a API está online
  static Future<bool> checkApiStatus() async {
    try {
      final response = await http
          .get(Uri.parse(scanApiUrl))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Erro ao verificar status da API: $e');
      return false;
    }
  }
}
