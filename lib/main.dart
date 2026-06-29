import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:sooperview/file_manager.dart';
import 'package:sooperview/save_manager.dart';
import 'package:sooperview/ui/mainapp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FFmpegKitExtended.initialize();
  await SaveManager.loadSettings();

  FileManager.CleanCache(); // Cleans cache on startup (Only affects mobile devices)

  runApp(const MainApp());
}



