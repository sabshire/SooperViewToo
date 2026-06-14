import 'dart:io';

class FileManager {

  static List<File> fileList = [];
  static int currentFile = 0;

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
}