import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';

/// Tela de verificação de autenticação
/// Verifica se o usuário já está logado e redireciona adequadamente
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Aguardar um pouco para mostrar o splash (opcional)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      // Verificar se existe token salvo
      final token = await StorageService.getToken();
      final user = await StorageService.getUser();

      // Debug: verificar o que foi recuperado
      print(
          '🔐 AuthCheck - Token: ${token != null ? "Presente (${token.length} chars)" : "Ausente"}');
      print(
          '👤 AuthCheck - User: ${user != null ? "Presente (${user.name})" : "Ausente"}');

      // Verificar se há usuário salvo (token é opcional, mas usuário é obrigatório)
      if (user != null) {
        // Se tem usuário salvo, mantém logado
        // Token pode ser opcional dependendo da API
        print(
            '✅ AuthCheck - Usuário autenticado (${user.name}), redirecionando para MainScreen');
        if (token != null && token.isNotEmpty) {
          print('   Token presente: ${token.length} caracteres');
        } else {
          print('   Token não presente (pode ser normal dependendo da API)');
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
        return;
      } else {
        print(
            '❌ AuthCheck - Sem usuário salvo, redirecionando para LoginScreen');
      }

      // Não há token válido, ir para a tela de login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      // Em caso de erro, ir para login
      print('⚠️ AuthCheck - Erro: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ou ícone do app
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.layers,
                color: Color(0xFF2196F3),
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            // Indicador de carregamento
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'SGEC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
