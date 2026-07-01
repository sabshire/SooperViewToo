import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FileManager {

  static List<File> fileList = [];
  static List<File> selectedFileList = [];
  static int currentFile = 0;
  static final ValueNotifier<int> fileCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> selectedFileCount = ValueNotifier<int>(0);

  static String? outputPath;

  static void AddFile(List<File> files) {
    fileList.addAll(files);
    fileCount.value++;
  }

  static File? GetCurrentSelectedFile() {
    if (selectedFileList.isEmpty) { return null; }
    return selectedFileList[currentFile];
  }

  static File? NextSelectedFile() {
    currentFile++;
    return GetCurrentSelectedFile();
  }

  static bool NextSelectedFileExists() {
    if ((selectedFileList.length - 1) > (currentFile)) {
      return true;
    } else {
      return false;
    }
  }

  static void RemoveCurrentFile() {
    fileList.removeAt(currentFile);
    fileCount.value--;
  }

  static void RemoveFile(File file) {
    fileList.remove(file);
    fileCount.value--;
  }

  static void AddToSelectedFiles(File file) {
    selectedFileList.add(file);
    selectedFileCount.value++;
  }

  static void RemoveFromSelectedFiles(File file) {
    selectedFileList.remove(file);
    selectedFileCount.value--;
  }

  static String getFileName(String filePath) {
    return p.basename(filePath);
  }

  static Future<void> moveExistingTempFile(String sourceFileStr, File selectedFile) async {
    final Directory tempDir = await getTemporaryDirectory();
    final path = p.join(tempDir.path, sourceFileStr);
    File sourceFile = File(path);

    if (!await sourceFile.exists()) {
      print("Source file does not exist!");
      return;
    }

    String fileName = "SV-${p.basename(selectedFile.path)}";

    // 4. Construct the complete destination path
    //String newPath = '${}/$fileName';
    String newPath = p.join(await GetOutputDir(), fileName);

    //Ensure we don't overwrite existing files
    //if dest already exists, we change the name
    //by appending a number, and retest.  We continue
    //this until we find a unique name
    File tempDestFile = File(newPath);
    int fileCount = 1;
    while (await tempDestFile.exists()) {
      fileCount++;
      fileName = "SV-$fileCount-${p.basename(selectedFile.path)}";
      newPath = p.join(await GetOutputDir(), fileName);
      tempDestFile = File(newPath);
    }

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

    if (outputPath == null) { outputPath = await SetOutputDir(); }
    return outputPath!;
  }

  static Future<String> SetOutputDir({bool manuallySet = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (manuallySet) {
      outputPath = await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose your output location");
    }
    while (outputPath == null) {
      outputPath = await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose your output location");
    }
    
    prefs.setString("OUTPUT_DIR", outputPath!);
    return outputPath!;
  }

  static Future<void> CleanCache() async {
    if (Platform.isAndroid || Platform.isIOS) {
      FilePicker.platform.clearTemporaryFiles();
    }
  }

}