import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'debug_scan_screen.dart';
import '../services/orders_service.dart';
import '../services/residents_service.dart';
import '../services/storage_service.dart';
import '../models/resident.dart';
import '../models/unit.dart';
import '../services/api_service.dart';

class ScanResultScreen extends StatefulWidget {
  final String residentName;
  final String block;
  final String apartment;
  final String? imagePath;
  final Map<String, dynamic>? rawApiResponse;
  final Map<String, dynamic>? debugInfo;
  final String? reason;

  const ScanResultScreen({
    super.key,
    this.residentName = 'Mariana Oliveira',
    this.block = 'Bloco B',
    this.apartment = 'Apto 304',
    this.imagePath,
    this.rawApiResponse,
    this.debugInfo,
    this.reason,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isCreatingOrder = false;

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
          'Resultado do Escaneamento',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.debugInfo != null)
            IconButton(
              onPressed: () => _navigateToDebug(context),
              icon: const Icon(
                Icons.bug_report,
                color: Color(0xFF2196F3),
              ),
              tooltip: 'Ver debug completo',
            ),
          if (widget.rawApiResponse != null)
            IconButton(
              onPressed: () => _showApiResponseDialog(context),
              icon: const Icon(
                Icons.info_outline,
                color: Color(0xFF2C3E50),
              ),
              tooltip: 'Ver resposta da API',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Imagem enviada
            if (widget.imagePath != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.imagePath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Indicador de sucesso ou aviso
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (widget.residentName.contains('Nenhum') ||
                        widget.residentName.contains('não encontrado'))
                    ? Colors.orange.shade50
                    : const Color(0xFFE3F2FD),
                border: Border.all(
                  color: (widget.residentName.contains('Nenhum') ||
                          widget.residentName.contains('não encontrado'))
                      ? Colors.orange
                      : const Color(0xFF2196F3),
                  width: 3,
                ),
              ),
              child: Icon(
                (widget.residentName.contains('Nenhum') ||
                        widget.residentName.contains('não encontrado'))
                    ? Icons.warning
                    : Icons.check,
                color: (widget.residentName.contains('Nenhum') ||
                        widget.residentName.contains('não encontrado'))
                    ? Colors.orange
                    : const Color(0xFF2196F3),
                size: 40,
              ),
            ),

            const SizedBox(height: 24),

            // Mensagem de sucesso ou aviso
            Text(
              widget.residentName.contains('Nenhum') ||
                      widget.residentName.contains('não encontrado')
                  ? 'Etiqueta Processada'
                  : 'Etiqueta Lida com Sucesso!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.reason != null
                  ? widget.reason!
                  : (widget.residentName.contains('Nenhum') ||
                          widget.residentName.contains('não encontrado')
                      ? 'Nenhum dado foi encontrado na etiqueta.'
                      : 'Confira os dados da encomenda abaixo.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: (widget.residentName.contains('Nenhum') ||
                        widget.residentName.contains('não encontrado'))
                    ? Colors.orange.shade700
                    : const Color(0xFF7F8C8D),
              ),
            ),

            const SizedBox(height: 32),

            // Cartão de informações
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Seção Morador
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'Morador',
                    value: widget.residentName,
                  ),

                  const Divider(
                    color: Color(0xFFE0E0E0),
                    height: 32,
                  ),

                  // Seção Bloco
                  _buildInfoRow(
                    icon: Icons.business,
                    label: 'Bloco',
                    value: widget.block,
                  ),

                  const Divider(
                    color: Color(0xFFE0E0E0),
                    height: 32,
                  ),

                  // Seção Apartamento
                  _buildInfoRow(
                    icon: Icons.door_front_door,
                    label: 'Apartamento',
                    value: widget.apartment,
                  ),
                ],
              ),
            ),

            // Botões de ação (apenas se houver dados válidos)
            if (!widget.residentName.contains('Nenhum') &&
                !widget.residentName.contains('não encontrado'))
              Column(
                children: [
                  // Botão Confirmar Entrega
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isCreatingOrder
                          ? null
                          : () {
                              _showConfirmationDialog(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCreatingOrder
                            ? Colors.grey
                            : const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isCreatingOrder
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Criando encomenda...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Confirmar Entrega',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botão Editar Dados
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        _showEditDialog(context);
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit,
                            color: Color(0xFF2C3E50),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Editar Dados',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFE3F2FD),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2196F3),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Entrega'),
        content: const Text(
          'Tem certeza que deseja criar esta encomenda?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelivery(context);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelivery(BuildContext context) async {
    // Verificar se há dados válidos
    if (widget.residentName.contains('Nenhum') ||
        widget.residentName.contains('não encontrado')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível criar encomenda sem dados válidos'),
          backgroundColor: Color(0xFFFF5722),
        ),
      );
      return;
    }

    // Verificar se há foto
    if (widget.imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto é obrigatória para criar a encomenda'),
          backgroundColor: Color(0xFFFF5722),
        ),
      );
      return;
    }

    print('🚀 Iniciando criação de encomenda...');
    
    setState(() {
      _isCreatingOrder = true;
    });
    
    // Mostrar overlay de loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Criando encomenda...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // Buscar usuário logado (porteiro)
      final user = await StorageService.getUser();
      if (user == null) {
        throw ApiException('Usuário não autenticado');
      }

      // Buscar morador e unidade
      print('🔍 Buscando morador...');
      print('   Nome escaneado: ${widget.residentName}');
      print('   Bloco: ${widget.block}');
      print('   Apartamento: ${widget.apartment}');
      
      final resident = await _findResident();
      if (resident == null) {
        final errorMsg = 'Morador não encontrado.\n\n'
            'Dados escaneados:\n'
            '• Nome: ${widget.residentName}\n'
            '• Bloco: ${widget.block}\n'
            '• Apartamento: ${widget.apartment}\n\n'
            'Verifique se:\n'
            '• O nome está correto\n'
            '• O morador está cadastrado no sistema\n'
            '• A unidade (bloco/apartamento) está correta';
        throw ApiException(errorMsg);
      }
      
      print('✅ Morador encontrado: ${resident.name} (ID: ${resident.id})');

      // Criar dados da encomenda
      print('📦 Criando encomenda...');
      print('   Porteiro ID: ${user.id}');
      print('   Morador ID: ${resident.id}');
      print('   Foto: ${widget.imagePath}');
      
      // Criar dados da encomenda
      final orderData = {
        'codigo_rastreio': 'BR12731723', // Código de rastreio fixo para encomendas via scan
        'descricao': '', // String vazia (igual ao manual quando não preenchido)
        'id_porteiro_recebimento': user.id,
        'id_morador_destinatario': resident.id,
      };
      
      print('📋 Dados da encomenda (SCAN):');
      print('   codigo_rastreio: ${orderData['codigo_rastreio']} (fixo)');
      print('   descricao: "${orderData['descricao']}"');
      print('   id_porteiro_recebimento: ${orderData['id_porteiro_recebimento']}');
      print('   id_morador_destinatario: ${orderData['id_morador_destinatario']}');

      // Criar encomenda com foto
      final photoFile = File(widget.imagePath!);
      
      // Verificar se o arquivo existe
      if (!await photoFile.exists()) {
        throw ApiException('Arquivo de foto não encontrado: ${widget.imagePath}');
      }
      
      print('📤 Enviando requisição para criar encomenda...');
      
      // Adicionar timeout wrapper para garantir que não trave
      final createdOrder = await OrdersService.createOrderWithPhoto(orderData, photoFile)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              print('⏰ TIMEOUT: Criação de encomenda demorou mais de 60 segundos');
              throw ApiException(
                'A criação da encomenda está demorando muito. Verifique sua conexão e tente novamente.',
              );
            },
          );
      
      print('✅ Encomenda criada com sucesso! ID: ${createdOrder.id}');

      if (!mounted) return;
      
      // Fechar overlay de loading
      _closeLoadingDialog();
      
      setState(() {
        _isCreatingOrder = false;
      });
      
      // Aguardar um pouco para garantir que o estado foi atualizado
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      _showSuccessMessage(context);
    } catch (e, stackTrace) {
      // Log detalhado do erro para debug
      print('❌ ERRO ao criar encomenda após scan:');
      print('   Tipo: ${e.runtimeType}');
      print('   Mensagem: ${e.toString()}');
      if (e is ApiException) {
        print('   Status Code: ${e.statusCode}');
      }
      print('   Stack Trace: $stackTrace');
      
      // Fechar overlay de loading - GARANTIR que seja fechado
      _closeLoadingDialog();
      
      if (!mounted) {
        print('⚠️ Widget não está montado, não é possível mostrar erro');
        return;
      }
      
      // Garantir que o estado seja atualizado
      setState(() {
        _isCreatingOrder = false;
      });
      
      // Aguardar um pouco para garantir que o estado foi atualizado
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      // Mostrar erro no front-end - SEMPRE exibir
      print('📢 Exibindo erro no front-end...');
      
      // Primeiro, mostrar SnackBar imediatamente (mais confiável)
      if (mounted) {
        String errorMsg = _getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF5722),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Ver Detalhes',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _showErrorDialog(context, e);
              },
            ),
          ),
        );
      }
      
      // Depois, tentar mostrar diálogo detalhado
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _showErrorDialog(context, e);
        }
      } catch (dialogError) {
        print('❌ Erro ao mostrar diálogo: $dialogError');
        // SnackBar já foi mostrado, então está ok
      }
    }
  }

  void _closeLoadingDialog() {
    print('🔄 Fechando overlay de loading...');
    try {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        print('   ✅ Overlay fechado');
      } else {
        print('   ⚠️ Não foi possível fechar overlay (canPop: ${mounted ? Navigator.of(context).canPop() : "widget não montado"})');
      }
    } catch (closeError) {
      print('   ❌ Erro ao fechar overlay: $closeError');
      // Tentar novamente após um delay
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              print('   ✅ Overlay fechado na segunda tentativa');
            }
          } catch (e2) {
            print('   ❌ Erro na segunda tentativa: $e2');
          }
        });
      }
    }
  }

  Future<Resident?> _findResident() async {
    try {
      print('🔍 Buscando moradores e unidades...');
      // Buscar todos os moradores e unidades
      final residents = await ResidentsService.getResidents();
      final units = await ResidentsService.getUnits();
      
      print('   Total de moradores: ${residents.length}');
      print('   Total de unidades: ${units.length}');
      
      if (residents.isEmpty) {
        print('⚠️ Nenhum morador encontrado no sistema');
        return null;
      }
      
      if (units.isEmpty) {
        print('⚠️ Nenhuma unidade encontrada no sistema');
        return null;
      }

      // Extrair bloco e apartamento do scan
      final blockName = widget.block.replaceAll('Bloco ', '').trim();
      final apartmentNumber = widget.apartment.replaceAll('Apto ', '').trim();

      // Encontrar a unidade correspondente
      Unit? matchingUnit;
      for (final unit in units) {
        final unitBlock = unit.block.trim();
        final unitApartment = unit.apartment.trim();

        if (unitBlock.toLowerCase() == blockName.toLowerCase() &&
            unitApartment == apartmentNumber) {
          matchingUnit = unit;
          break;
        }
      }

      if (matchingUnit == null) {
        print('⚠️ Unidade não encontrada: Bloco $blockName, Apto $apartmentNumber');
        print('   Unidades disponíveis:');
        for (final unit in units) {
          print('     - Bloco ${unit.block}, Apto ${unit.apartment}');
        }
        return null;
      }
      
      print('✅ Unidade encontrada: Bloco ${matchingUnit.block}, Apto ${matchingUnit.apartment} (ID: ${matchingUnit.id})');

      // Encontrar o morador pelo nome e unidade
      final residentName = widget.residentName.trim();
      Resident? matchingResident;

      for (final resident in residents) {
        if (resident.unitId == matchingUnit.id) {
          // Comparar nomes (case-insensitive, removendo espaços extras)
          final residentNameNormalized = resident.name
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'\s+'), ' ');
          final scanNameNormalized =
              residentName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

          // Verificar correspondência exata ou parcial
          if (residentNameNormalized == scanNameNormalized ||
              residentNameNormalized.contains(scanNameNormalized) ||
              scanNameNormalized.contains(residentNameNormalized)) {
            matchingResident = resident;
            break;
          }
        }
      }

      if (matchingResident == null) {
        print(
            '⚠️ Morador não encontrado: $residentName na unidade ${matchingUnit.id}');
        // Se não encontrou pelo nome, retornar o primeiro morador da unidade
        final residentsInUnit = residents
            .where((r) => r.unitId == matchingUnit!.id)
            .toList();
        if (residentsInUnit.isNotEmpty) {
          print('⚠️ Usando primeiro morador da unidade: ${residentsInUnit.first.name}');
          return residentsInUnit.first;
        }
      }

      return matchingResident;
    } catch (e, stackTrace) {
      print('❌ ERRO ao buscar morador:');
      print('   Tipo: ${e.runtimeType}');
      print('   Mensagem: ${e.toString()}');
      print('   Stack Trace: $stackTrace');
      return null;
    }
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Dados'),
        content: const Text(
          'Funcionalidade de edição será implementada em breve.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.statusCode == 400) {
        return 'Dados inválidos. Verifique as informações.';
      } else if (error.statusCode == 401) {
        return 'Sessão expirada. Faça login novamente.';
      } else if (error.statusCode == 404) {
        return 'Recurso não encontrado. Verifique os dados.';
      } else if (error.statusCode == 500) {
        return 'Erro no servidor. Tente novamente.';
      }
      return error.message;
    } else if (error.toString().contains('Morador não encontrado')) {
      return 'Morador não encontrado. Verifique os dados escaneados.';
    } else if (error.toString().contains('Usuário não autenticado')) {
      return 'Sessão expirada. Faça login novamente.';
    } else if (error.toString().contains('timeout') || 
               error.toString().contains('Timeout')) {
      return 'Tempo esgotado. Verifique sua conexão.';
    } else if (error.toString().contains('SocketException') ||
               error.toString().contains('Failed host lookup')) {
      return 'Sem conexão. Verifique sua internet.';
    }
    return 'Erro: ${error.toString()}';
  }

  void _showErrorDialog(BuildContext context, dynamic error) {
    // Verificar se o contexto está montado
    if (!context.mounted) {
      print('⚠️ Contexto não está montado, não é possível mostrar diálogo de erro');
      return;
    }
    
    String errorTitle = 'Erro ao Criar Encomenda';
    String errorMessage = 'Ocorreu um erro ao criar a encomenda.';
    String? errorDetails;

    // Extrair informações detalhadas do erro
    if (error is ApiException) {
      errorTitle = 'Erro na API';
      errorMessage = error.message;
      if (error.statusCode != null) {
        errorDetails = 'Código de status: ${error.statusCode}';
        
        // Mensagens mais amigáveis baseadas no status code
        if (error.statusCode == 400) {
          errorMessage = 'Dados inválidos. Verifique as informações escaneadas.';
          errorDetails = 'Detalhes: ${error.message}';
        } else if (error.statusCode == 401) {
          errorMessage = 'Não autorizado. Faça login novamente.';
        } else if (error.statusCode == 404) {
          errorMessage = 'Recurso não encontrado. Verifique se o morador existe no sistema.';
        } else if (error.statusCode == 500) {
          errorMessage = 'Erro no servidor. Tente novamente mais tarde.';
          errorDetails = 'Erro interno do servidor';
        }
      }
    } else if (error.toString().contains('Morador não encontrado')) {
      errorTitle = 'Morador Não Encontrado';
      errorMessage = 'Não foi possível encontrar o morador com os dados escaneados.';
      errorDetails = 'Verifique se:\n'
          '• O nome está correto\n'
          '• O bloco e apartamento estão corretos\n'
          '• O morador está cadastrado no sistema';
    } else if (error.toString().contains('Usuário não autenticado')) {
      errorTitle = 'Sessão Expirada';
      errorMessage = 'Sua sessão expirou. Faça login novamente.';
    } else if (error.toString().contains('timeout') || 
               error.toString().contains('Timeout')) {
      errorTitle = 'Tempo Esgotado';
      errorMessage = 'A requisição demorou muito para responder. Verifique sua conexão com a internet.';
    } else if (error.toString().contains('SocketException') ||
               error.toString().contains('Failed host lookup')) {
      errorTitle = 'Sem Conexão';
      errorMessage = 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.';
    } else {
      errorDetails = error.toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFFF5722),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                ),
              ),
              if (errorDetails != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalhes técnicos:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        errorDetails,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Fechar',
              style: TextStyle(
                color: Color(0xFF2196F3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Tentar novamente
              _confirmDelivery(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(BuildContext context) {
    print('✅ Mostrando mensagem de sucesso');
    
    // Mostrar diálogo de sucesso primeiro
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Sucesso!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        content: const Text(
          'Encomenda criada com sucesso!',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF2C3E50),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fechar diálogo
              // Voltar para a tela principal
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    // Fallback: também mostrar SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Encomenda criada com sucesso!'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToDebug(BuildContext context) {
    if (widget.debugInfo == null) return;

    final requestInfo = widget.debugInfo!['request'] as Map<String, dynamic>?;
    final responseInfo = widget.debugInfo!['response'] as Map<String, dynamic>?;
    final imagePath = widget.debugInfo!['imagePath'] as String?;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DebugScanScreen(
          requestInfo: requestInfo,
          responseData: responseInfo,
          imageFile: imagePath != null ? File(imagePath) : null,
        ),
      ),
    );
  }

  void _showApiResponseDialog(BuildContext context) {
    if (widget.rawApiResponse == null) return;

    // Formatar JSON de forma legível
    final jsonString =
        const JsonEncoder.withIndent('  ').convert(widget.rawApiResponse);

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
                    'Resposta Completa da API',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
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
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonString,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF2C3E50),
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
                    onPressed: () {
                      // Copiar para clipboard (opcional)
                      Navigator.of(context).pop();
                    },
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
