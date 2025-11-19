import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/scan_service.dart';
import 'scan_result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Verificar permissão da câmera
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showPermissionDialog();
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Erro ao inicializar câmera: $e');
      _showErrorDialog('Erro ao inicializar câmera');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final imageFile = File(photo.path);

      if (mounted) {
        // Mostrar loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Enviar foto para API de escaneamento
      final scannedData = await ScanService.scanPhoto(imageFile);

      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading

        // Extrair informações de debug se existirem
        Map<String, dynamic>? debugInfo;
        Map<String, dynamic>? cleanData = scannedData;

        if (scannedData.containsKey('_debug')) {
          debugInfo = scannedData['_debug'] as Map<String, dynamic>;
          // Remover debug dos dados principais
          cleanData = Map<String, dynamic>.from(scannedData);
          cleanData.remove('_debug');
        }

        // Processar resposta da API
        _processScanResult(cleanData, imageFile.path, debugInfo);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading se estiver aberto
        print('❌ Erro ao escanear foto: $e');
        _showErrorDialog('Erro ao escanear foto: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _processScanResult(
    Map<String, dynamic> scannedData,
    String imagePath,
    Map<String, dynamic>? debugInfo,
  ) {
    try {
      // Log completo da resposta para debug
      print('🔍 Processando resposta da API:');
      print('📦 Dados recebidos: $scannedData');
      print('📦 Status: ${scannedData['status']}');

      // Estrutura da resposta da API (conforme analisado):
      // {
      //   "status": "success",
      //   "data": {
      //     "candidates": 2,
      //     "names_with_units_info": {
      //       "Nome do Morador": {"apartment": "101", "block": "A"}
      //     },
      //     "reason": "Motivo..."
      //   }
      // }

      String residentName = 'Nenhum dado encontrado';
      String block = 'Nenhum dado encontrado';
      String apartment = 'Nenhum dado encontrado';
      String? reason;

      // Verificar se a resposta tem status de sucesso
      if (scannedData['status'] == 'success' &&
          scannedData.containsKey('data')) {
        final data = scannedData['data'] as Map<String, dynamic>;

        print('📊 Data recebida: $data');
        print('📊 Candidates: ${data['candidates']}');
        print('📊 Reason: ${data['reason']}');

        // Extrair reason se existir
        reason = data['reason'] as String?;

        // Extrair names_with_units_info
        if (data.containsKey('names_with_units_info')) {
          final namesWithUnits =
              data['names_with_units_info'] as Map<String, dynamic>;

          print('📊 names_with_units_info: $namesWithUnits');
          print('📊 Quantidade de nomes: ${namesWithUnits.length}');

          if (namesWithUnits.isNotEmpty) {
            // Pegar o primeiro nome encontrado
            final firstEntry = namesWithUnits.entries.first;
            residentName = firstEntry.key;
            print('✅ Nome encontrado: $residentName');

            final unitInfo = firstEntry.value as Map<String, dynamic>;
            print('📊 Unit info: $unitInfo');

            final aptValue = unitInfo['apartment'] as String?;
            final blockValue = unitInfo['block'] as String?;

            // Formatar apartamento
            if (aptValue != null && aptValue.isNotEmpty) {
              apartment = 'Apto $aptValue';
              print('✅ Apartamento: $apartment');
            } else {
              apartment = 'Apto não informado';
              print('⚠️ Apartamento não encontrado');
            }

            // Formatar bloco
            if (blockValue != null && blockValue.isNotEmpty) {
              block = 'Bloco $blockValue';
              print('✅ Bloco: $block');
            } else {
              block = 'Bloco não informado';
              print('⚠️ Bloco não encontrado');
            }
          } else {
            print('⚠️ names_with_units_info está vazio');
            residentName = 'Nenhum nome encontrado na etiqueta';
            if (reason != null) {
              residentName += '\n($reason)';
            }
          }
        } else {
          print('⚠️ Campo names_with_units_info não encontrado na resposta');
          if (reason != null) {
            residentName = 'Nenhum dado encontrado\n($reason)';
          }
        }
      } else if (scannedData['status'] == 'error') {
        // Tratar erro da API
        final errorData = scannedData['data'] as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ?? 'Erro desconhecido';
        print('❌ Erro da API: $errorMessage');
        _showErrorDialog('Erro na API: $errorMessage');
        return;
      } else {
        print('⚠️ Status desconhecido ou estrutura inesperada');
        print('📦 Resposta completa: $scannedData');
      }

      // Navegar para a tela de resultado com dados completos
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ScanResultScreen(
            residentName: residentName,
            block: block,
            apartment: apartment,
            imagePath: imagePath,
            rawApiResponse: scannedData, // Passar resposta completa da API
            debugInfo: debugInfo, // Passar informações de debug
            reason: reason, // Passar motivo da resposta
          ),
        ),
      );
    } catch (e) {
      print('❌ Erro ao processar resultado: $e');
      _showErrorDialog('Erro ao processar dados escaneados: ${e.toString()}');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissão Necessária'),
        content: const Text(
            'Este app precisa de acesso à câmera para escanear etiquetas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Configurações'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Escanear Etiqueta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildCameraView(),
    );
  }

  Widget _buildCameraView() {
    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Inicializando câmera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Preview da câmera
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),

        // Overlay com guia de escaneamento
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
            ),
            child: Column(
              children: [
                const Spacer(),

                // Área de escaneamento
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Cantos da área de escaneamento
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2196F3),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2196F3),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2196F3),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2196F3),
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Instruções
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Posicione a etiqueta dentro da área destacada e toque no botão para escanear',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Botão de captura
                Container(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: GestureDetector(
                    onTap: _isCapturing ? null : _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing ? Colors.grey : Colors.white,
                        border: Border.all(
                          color: _isCapturing
                              ? Colors.grey
                              : const Color(0xFF2196F3),
                          width: 4,
                        ),
                      ),
                      child: _isCapturing
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Color(0xFF2196F3),
                              size: 32,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
