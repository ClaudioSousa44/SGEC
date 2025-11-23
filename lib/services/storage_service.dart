import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_response.dart';

/// Serviço para armazenar dados do usuário localmente
class StorageService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  /// Salva os dados do usuário
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Recupera os dados do usuário
  static Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      print('Erro ao recuperar usuário: $e');
    }
    return null;
  }

  /// Salva o token de autenticação
  /// Se o token não for fornecido, gera um token local baseado no ID do usuário
  static Future<void> saveToken(String? token, {int? userId}) async {
    print('💾 StorageService.saveToken - Iniciando...');
    print('   Token recebido: ${token != null ? "${token.substring(0, token.length > 20 ? 20 : token.length)}... (${token.length} chars)" : "null"}');
    print('   User ID: $userId');
    
    final prefs = await SharedPreferences.getInstance();
    
    // Se não há token mas há userId, gerar um token local temporário
    if ((token == null || token.isEmpty) && userId != null) {
      print('   ⚠️ Token não fornecido, gerando token local baseado no ID do usuário...');
      // Gerar um token simples baseado no ID (temporário até o backend implementar JWT)
      final localToken = 'local_token_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      token = localToken;
      print('   ✅ Token local gerado: ${token.substring(0, 20)}...');
    }
    
    if (token != null && token.isNotEmpty) {
      final saved = await prefs.setString(_tokenKey, token);
      print('   Resultado do save: $saved');
      
      // Verificar imediatamente se foi salvo
      final verification = prefs.getString(_tokenKey);
      if (verification != null && verification == token) {
        print('   ✅ Token verificado após salvar: OK');
      } else {
        print('   ❌ ERRO: Token não foi salvo corretamente!');
        print('   Esperado: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        print('   Obtido: ${verification != null ? verification.substring(0, verification.length > 20 ? 20 : verification.length) : "null"}...');
      }
    } else {
      print('   ⚠️ Token é null ou vazio, removendo...');
      await prefs.remove(_tokenKey);
    }
  }

  /// Recupera o token de autenticação
  static Future<String?> getToken() async {
    print('🔍 StorageService.getToken - Buscando token...');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token != null && token.isNotEmpty) {
      print('   ✅ Token encontrado: ${token.substring(0, token.length > 20 ? 20 : token.length)}... (${token.length} chars)');
    } else {
      print('   ❌ Token NÃO encontrado!');
      print('   Chave usada: $_tokenKey');
      print('   Todas as chaves disponíveis: ${prefs.getKeys()}');
    }
    
    return token;
  }

  /// Limpa todos os dados (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }
}
