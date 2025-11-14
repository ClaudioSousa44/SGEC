import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../services/orders_service.dart';

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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleSignatureChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleSignatureChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleSignatureChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
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
      body: Stack(
        children: [
          Padding(
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
                          onPressed: _isSaving
                              ? null
                              : () {
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
                          onPressed: _controller.isEmpty || _isSaving
                              ? null
                              : _confirmSignature,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
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
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.2),
            ),
        ],
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

  Future<void> _saveSignature(Uint8List signatureData) async {
    final orderId = _resolveOrderId(widget.order);

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar a encomenda.'),
          backgroundColor: Color(0xFFE53E3E),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await OrdersService.confirmDeliveryWithSignature(
        orderId: orderId,
        signatureBytes: signatureData,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assinatura salva e encomenda marcada como entregue!'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 3),
        ),
      );

      // Voltar para a tela de listagem de encomendas
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erro ao salvar assinatura: ${e.toString().split(':').last}'),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  int? _resolveOrderId(Map<String, dynamic> order) {
    final dynamic rawId =
        order['id'] ?? order['orderId'] ?? order['id_encomenda'];
    if (rawId is int) {
      return rawId;
    }
    if (rawId is String) {
      return int.tryParse(rawId);
    }
    return null;
  }
}
