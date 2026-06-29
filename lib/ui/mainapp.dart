import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:sooperview/FileManager.dart';
import 'package:sooperview/ui/hometabscreen.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Encoder',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        )
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        )
      ),
      home: SafeArea(child: const HomeTabScreen()),
      themeMode: ThemeMode.system, 
      builder: (context, child) {
        return DropTarget(
          onDragEntered: (details) => print('DEBUG: file entered the window!'),
          onDragExited: (details) => print('DEBUG: file left the window!'),
          onDragDone: (details) async {
            for (final file in details.files) {
              File f = File(file.path);
              FileManager.AddFile([f]);
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
