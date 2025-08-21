import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Generate icon dengan ukuran yang berbeda
  await generateIcon(48, 'mipmap-mdpi');
  await generateIcon(72, 'mipmap-hdpi');
  await generateIcon(96, 'mipmap-xhdpi');
  await generateIcon(144, 'mipmap-xxhdpi');
  await generateIcon(192, 'mipmap-xxxhdpi');
  
  print('Icons generated successfully!');
}

Future<void> generateIcon(int size, String folder) async {
  // Load logo.png dari assets
  final ByteData data = await rootBundle.load('assets/logo.png');
  final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final ui.FrameInfo fi = await codec.getNextFrame();
  final ui.Image originalImage = fi.image;
  
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Background circle dengan warna tema
  final paint = Paint()
    ..color = const Color(0xFF34495e)
    ..style = PaintingStyle.fill;
  
  canvas.drawCircle(Offset(size/2, size/2), size/2, paint);
  
  // Draw logo image centered
  final src = Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble());
  final dst = Rect.fromCenter(
    center: Offset(size/2, size/2),
    width: size * 0.6,
    height: size * 0.6,
  );
  
  canvas.drawImageRect(originalImage, src, dst, Paint());
  
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  
  // Create directory if not exists
  final directory = Directory('android/app/src/main/res/$folder');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  
  // Save icon
  final file = File('${directory.path}/ic_launcher.png');
  await file.writeAsBytes(bytes);
  
  print('Generated $folder/ic_launcher.png (${size}x${size})');
} 