import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Widget para gerar o ícone do app
/// Execute: flutter run lib/tools/generate_app_icon.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const size = 1024.0;
  const backgroundColor = Color(0xFF2196F3); // Azul do app
  const iconColor = Colors.white;

  // Criar um recorder para capturar o widget
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Desenhar fundo circular azul
  final paint = Paint()..color = backgroundColor;
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    size / 2,
    paint,
  );

  // Desenhar o ícone de camadas (3 retângulos sobrepostos)
  final iconPaint = Paint()
    ..color = iconColor
    ..style = PaintingStyle.fill;

  final layerWidth = size * 0.5;
  final layerHeight = size * 0.08;
  final spacing = size * 0.06;
  final centerX = size / 2;
  final centerY = size / 2;
  final radius = size * 0.015;

  // Camada 1 (mais embaixo - maior)
  final layer1 = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(centerX, centerY + spacing),
      width: layerWidth,
      height: layerHeight,
    ),
    Radius.circular(radius),
  );
  canvas.drawRRect(layer1, iconPaint);

  // Camada 2 (meio - média)
  final layer2 = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: layerWidth * 0.9,
      height: layerHeight,
    ),
    Radius.circular(radius),
  );
  canvas.drawRRect(layer2, iconPaint);

  // Camada 3 (mais em cima - menor)
  final layer3 = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(centerX, centerY - spacing),
      width: layerWidth * 0.8,
      height: layerHeight,
    ),
    Radius.circular(radius),
  );
  canvas.drawRRect(layer3, iconPaint);

  // Converter para imagem
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  if (byteData != null) {
    // Criar diretório se não existir
    final directory = Directory('assets/icon');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Salvar a imagem
    final file = File('assets/icon/app_icon.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    print('✅ Ícone gerado com sucesso!');
    print('📁 Local: ${file.absolute.path}');
    print('📐 Tamanho: ${size.toInt()}x${size.toInt()} pixels');
    print(
        '\n📝 Próximo passo: Execute: flutter pub run flutter_launcher_icons');
  } else {
    print('❌ Erro ao gerar o ícone');
  }

  exit(0);
}


