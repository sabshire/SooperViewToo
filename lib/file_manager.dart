import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sooperview/ffmpeg_manager.dart';


class FileManager {

  static List<SooperEncoderStatus> fileEncodeStatus = [];
  static List<File> fileList = [];
  static List<File> selectedFileList = [];
  static int currentFile = 0;
  static final ValueNotifier<int> fileCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> selectedFileCount = ValueNotifier<int>(0);

  static String? outputPath;

  static bool isOutputPathSet() {
    if (outputPath != null) {
      if(outputPath!.isEmpty) {
        return false;
      }
      return true;
    }
    return false;
  }

  static void markCurrentFileStatus(SooperEncoderStatus status) {
    fileEncodeStatus[currentFile] = status;
  }

  static void markUnprocessedFiles(SooperEncoderStatus status) {
    for (int i = 0; i < fileEncodeStatus.length; i++) {
      if (fileEncodeStatus[i] == SooperEncoderStatus.none) {
        fileEncodeStatus[i] = status;
      }
    }
  }

  static SooperEncoderStatus getFileEncodeStatus(int index) {
    if (index < 0 || index >= fileEncodeStatus.length) return SooperEncoderStatus.none;
    return fileEncodeStatus[index];
  }

  static void reset() {
    currentFile = 0;
    //failedFileList.clear();
    for (int i = 0; i < fileEncodeStatus.length; i++) {
      fileEncodeStatus[i] = SooperEncoderStatus.none;
    }
  }

  static void addFile(List<File> files) {
    fileList.addAll(files);
    fileCount.value+=files.length;
    for(int i = 0; i< files.length; i++) {
      fileEncodeStatus.add(SooperEncoderStatus.none);
    }
  }

  static File? getCurrentSelectedFile() {
    if (selectedFileList.isEmpty) { return null; }
    return selectedFileList[currentFile];
  }

  static File? nextSelectedFile() {
    currentFile++;
    return getCurrentSelectedFile();
  }

  static bool nextSelectedFileExists() {
    if ((selectedFileList.length - 1) > (currentFile)) {
      return true;
    } else {
      return false;
    }
  }

  static void removeCurrentFile() {
    fileList.removeAt(currentFile);
    fileCount.value--;
  }

  static void removeFile(File file) {
    fileList.remove(file);
    fileCount.value--;
  }

  static void addToSelectedFiles(File file) {
    selectedFileList.add(file);
    selectedFileCount.value++;
  }

  static void removeFromSelectedFiles(File file) {
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
      return;
    }

    String fileName = "SV-${p.basename(selectedFile.path)}";

    // 4. Construct the complete destination path
    //String newPath = '${}/$fileName';
    String newPath = p.join(await getOutputDir(), fileName);

    //Ensure we don't overwrite existing files
    //if dest already exists, we change the name
    //by appending a number, and retest.  We continue
    //this until we find a unique name
    File tempDestFile = File(newPath);
    int fileCount = 1;
    while (await tempDestFile.exists()) {
      fileCount++;
      fileName = "SV-$fileCount-${p.basename(selectedFile.path)}";
      newPath = p.join(await getOutputDir(), fileName);
      tempDestFile = File(newPath);
    }

    try {
      // 5. Move the file
      // Note: rename() works instantly if on the same storage partition.
      await sourceFile.rename(newPath);
    } catch (e) {
      // Fallback: If moving across different partitions (e.g., internal to SD card),
      // rename() might fail. Use copy and delete instead.
      await sourceFile.copy(newPath);
      await sourceFile.delete();
    }
  }

  static Future<String> getOutputDir() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    outputPath = await prefs.getString("OUTPUT_DIR");

    outputPath ??= await setOutputDir();
    return outputPath!;
  }

  static Future<String> setOutputDir({bool manuallySet = false}) async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    if (manuallySet) {
      outputPath = await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose your output location");
    }
    while (outputPath == null) {
      outputPath = await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose your output location");
    }
    
    await prefs.setString("OUTPUT_DIR", outputPath!);
    return outputPath!;
  }

  static Future<void> cleanCache() async {
    if (Platform.isAndroid || Platform.isIOS) {
      FilePicker.platform.clearTemporaryFiles();
    }
  }

}