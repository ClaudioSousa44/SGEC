import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const SignatureScreen({
    super.key,
    required this.order,
  });

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF2C3E50),
          ),
        ),
        title: const Text(
          'Assinatura do Recebedor',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instrução
            const Text(
              'Peça para o recebedor assinar no campo abaixo.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
            ),

            const SizedBox(height: 20),

            // Área de assinatura
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Stack(
                  children: [
                    // Widget de assinatura
                    Signature(
                      controller: _controller,
                      backgroundColor: Colors.white,
                    ),

                    // Botão Limpar no canto superior direito
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          _controller.clear();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.clear,
                                color: Color(0xFF7F8C8D),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Limpar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7F8C8D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botões de ação
            Row(
              children: [
                // Botão Cancelar
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2C3E50),
                        side: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Botão Confirmar
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _controller.isEmpty ? null : _confirmSignature,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, capture a assinatura antes de confirmar.'),
          backgroundColor: Color(0xFFFFC107),
        ),
      );
      return;
    }

    try {
      // Exportar a assinatura como imagem
      final signatureData = await _controller.toPngBytes();
      
      if (signatureData != null) {
        // Mostrar diálogo de confirmação
        _showConfirmationDialog(signatureData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao processar assinatura. Tente novamente.'),
          backgroundColor: Color(0xFFE53E3E),
        ),
      );
    }
  }

  void _showConfirmationDialog(Uint8List signatureData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Assinatura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Deseja confirmar esta assinatura?'),
            const SizedBox(height: 16),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  signatureData,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveSignature(signatureData);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _saveSignature(Uint8List signatureData) {
    // Aqui você salvaria a assinatura no banco de dados ou sistema de arquivos
    // Por enquanto, vamos apenas mostrar uma mensagem de sucesso
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assinatura capturada com sucesso!'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 3),
      ),
    );

    // Voltar para a tela anterior após 1 segundo
    Future.delayed(const Duration(seconds: 1), () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}
