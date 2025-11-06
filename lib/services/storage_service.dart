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
  static Future<void> saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  /// Recupera o token de autenticação
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Limpa todos os dados (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }
}
