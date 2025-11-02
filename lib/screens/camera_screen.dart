import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
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

      // Simular processamento da foto
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Mostrar resultado do escaneamento
        _showScanResult(photo.path);
      }
    } catch (e) {
      print('Erro ao capturar foto: $e');
      _showErrorDialog('Erro ao capturar foto');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _showScanResult(String imagePath) {
    // Simular dados escaneados da etiqueta
    // Em um app real, aqui você processaria a imagem e extrairia os dados
    final scannedData = _simulateScannedData();
    
    // Navegar para a tela de resultado
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ScanResultScreen(
          residentName: scannedData['residentName']!,
          block: scannedData['block']!,
          apartment: scannedData['apartment']!,
        ),
      ),
    );
  }

  Map<String, String> _simulateScannedData() {
    // Simular diferentes dados baseados no timestamp
    final now = DateTime.now();
    final seed = now.millisecondsSinceEpoch % 3;
    
    final residents = ['Mariana Oliveira', 'João Silva', 'Ana Costa'];
    final blocks = ['Bloco A', 'Bloco B', 'Bloco C'];
    final apartments = ['Apto 101', 'Apto 204', 'Apto 305'];
    
    return {
      'residentName': residents[seed],
      'block': blocks[seed],
      'apartment': apartments[seed],
    };
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
