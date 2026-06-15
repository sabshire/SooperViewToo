import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sooperview/PermissionHandler.dart';
import 'package:sooperview/ffmpeg_argument_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FileManager {

  static List<File> fileList = [];
  static int currentFile = 0;

  static String? outputPath;

  static void AddFile(List<File> files) {
    fileList.addAll(files);
  }

  static File? GetCurrentFile() {
    if (fileList.isEmpty) { return null; }
    return fileList[currentFile];
  }

  static File? NextFile() {
    currentFile++;
    return GetCurrentFile();
  }

  static void RemoveCurrentFile() {
    fileList.removeAt(currentFile);
  }

  static Future<void> moveExistingTempFile(String sourceFileStr) async {
    final Directory tempDir = await getTemporaryDirectory();
    final path = p.join(tempDir.path, sourceFileStr);
    File sourceFile = File(path);

    if (!await sourceFile.exists()) {
      print("Source file does not exist!");
      return;
    }

    String fileName = "SV-${p.basename(FileManager.GetCurrentFile()!.path)}";

    // 4. Construct the complete destination path
    //String newPath = '${}/$fileName';
    String newPath = p.join(await GetOutputDir(), fileName);

    try {
      // 5. Move the file
      // Note: rename() works instantly if on the same storage partition.
      await sourceFile.rename(newPath);
      print('File successfully moved to: $newPath');
    } catch (e) {
      // Fallback: If moving across different partitions (e.g., internal to SD card),
      // rename() might fail. Use copy and delete instead.
      final newFile = await sourceFile.copy(newPath);
      await sourceFile.delete();
      print('File copied and original deleted at: ${newFile.path}');
    }
  }

  static Future<String> GetOutputDir() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    outputPath = prefs.getString("OUTPUT_DIR");

    if (outputPath == null) { SetOutputDir(); }
    return outputPath!;
  }

  static void SetOutputDir() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    while (outputPath == null) {
      outputPath = await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose your output location");
    }
    prefs.setString("OUTPUT_DIR", outputPath!);
  }

}