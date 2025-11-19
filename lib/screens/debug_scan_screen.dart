import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

/// Tela de debug para visualizar requisições e respostas da API de escaneamento
class DebugScanScreen extends StatelessWidget {
  final Map<String, dynamic>? requestInfo;
  final Map<String, dynamic>? responseData;
  final File? imageFile;

  const DebugScanScreen({
    super.key,
    this.requestInfo,
    this.responseData,
    this.imageFile,
  });

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
          'Debug - Requisição API',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Use o botão "Ver Texto Completo" para copiar'),
                ),
              );
            },
            icon: const Icon(
              Icons.copy,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção: Informações da Requisição
            _buildSection(
              title: '📤 Requisição Enviada',
              icon: Icons.upload,
              child: requestInfo != null
                  ? _buildRequestInfo(requestInfo!)
                  : const Text('Nenhuma requisição registrada'),
            ),

            const SizedBox(height: 24),

            // Seção: Resposta da API
            _buildSection(
              title: '📥 Resposta da API',
              icon: Icons.download,
              child: responseData != null
                  ? _buildResponseInfo(responseData!)
                  : const Text('Nenhuma resposta registrada'),
            ),

            const SizedBox(height: 24),

            // Seção: Imagem Enviada
            if (imageFile != null)
              _buildSection(
                title: '🖼️ Imagem Enviada',
                icon: Icons.image,
                child: _buildImageInfo(imageFile!),
              ),

            const SizedBox(height: 24),

            // Botão para ver texto completo
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showFullTextDialog(context),
                icon: const Icon(Icons.text_fields),
                label: const Text('Ver Texto Completo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2196F3), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRequestInfo(Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('URL', info['url'] as String? ?? 'N/A'),
        _buildInfoRow('Método', info['method'] as String? ?? 'N/A'),
        if (info['headers'] != null)
          _buildExpandableSection(
            'Headers',
            info['headers'] as Map<String, dynamic>,
          ),
        if (info['fileSize'] != null)
          _buildInfoRow('Tamanho do Arquivo', '${info['fileSize']} bytes'),
        if (info['fileName'] != null)
          _buildInfoRow('Nome do Arquivo', info['fileName'] as String),
        if (info['fieldName'] != null)
          _buildInfoRow('Campo', info['fieldName'] as String),
      ],
    );
  }

  Widget _buildResponseInfo(Map<String, dynamic> response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (response['statusCode'] != null)
          _buildInfoRow(
            'Status Code',
            '${response['statusCode']}',
            color: _getStatusColor(response['statusCode'] as int),
          ),
        if (response['headers'] != null)
          _buildExpandableSection(
            'Headers',
            response['headers'] as Map<String, dynamic>,
          ),
        if (response['body'] != null)
          _buildExpandableJsonSection(
            'Body (JSON)',
            response['body'] as Map<String, dynamic>,
          ),
        if (response['error'] != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'Erro: ${response['error']}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildImageInfo(File imageFile) {
    return FutureBuilder<FileStat>(
      future: imageFile.stat(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final stat = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Caminho', imageFile.path),
              _buildInfoRow('Tamanho', '${stat.size} bytes'),
              _buildInfoRow('Modificado', stat.modified.toString()),
              const SizedBox(height: 12),
              // Preview da imagem
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color ?? const Color(0xFF2C3E50),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(String title, Map<String, dynamic> data) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableJsonSection(String title, Map<String, dynamic> data) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            jsonString,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return Colors.green;
    } else if (statusCode >= 400 && statusCode < 500) {
      return Colors.orange;
    } else if (statusCode >= 500) {
      return Colors.red;
    }
    return const Color(0xFF2C3E50);
  }

  String _generateDebugText() {
    final buffer = StringBuffer();
    buffer.writeln('=== DEBUG - Requisição API de Escaneamento ===\n');

    if (requestInfo != null) {
      buffer.writeln('📤 REQUISIÇÃO:');
      buffer.writeln('URL: ${requestInfo!['url']}');
      buffer.writeln('Método: ${requestInfo!['method']}');
      if (requestInfo!['headers'] != null) {
        buffer.writeln('Headers:');
        (requestInfo!['headers'] as Map).forEach((key, value) {
          buffer.writeln('  $key: $value');
        });
      }
      buffer.writeln('');
    }

    if (responseData != null) {
      buffer.writeln('📥 RESPOSTA:');
      buffer.writeln('Status Code: ${responseData!['statusCode']}');
      if (responseData!['body'] != null) {
        buffer.writeln('Body:');
        buffer.writeln(
            const JsonEncoder.withIndent('  ').convert(responseData!['body']));
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  void _showFullTextDialog(BuildContext context) {
    final debugText = _generateDebugText();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Debug Completo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      debugText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
