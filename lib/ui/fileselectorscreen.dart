import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sooperview/ffmpeg_manager.dart';
import 'package:sooperview/file_manager.dart';
import 'package:sooperview/ui/file_list_widget.dart';
import 'package:sooperview/ui/sooper_encoder_button.dart';

class FileSelectorScreen extends StatefulWidget {
  const FileSelectorScreen({super.key});

  @override
  State<FileSelectorScreen> createState() => FileSelectorScreenState();
}

class FileSelectorScreenState extends State<FileSelectorScreen> {

  Future<void> pickFile() async {
    FilePickerResult? result;
    if (Platform.isIOS) { result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: true); }
    else { result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true); }
    
    if (result != null && result.files.isNotEmpty) {
      //final filePath = result.files.single.path;
      List<File> files = [];
      for (int fileNum = 0; fileNum < result.files.length; fileNum++) {
        if (result.files[fileNum].path == null) continue;
        files.add(File(result.files[fileNum].path!));
      }
      
      setState(() {
        FileManager.AddFile(files);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        spacing: 20,
        children: [
          Expanded(
            child: (
              FileListWidget(
                fileList: FileManager.fileList,
                onRemove: (file) => FileManager.RemoveFile(file),
                onSelectionUpdate: () => setState(() {
                  // Updates on selecting for UI
                }),
              )
            )
          ),
          // Add Files Button
          ElevatedButton.icon(
            onPressed: (FFmpegManager.encoderStatus.value == SooperEncoderStatus.none) ? pickFile : null,
            icon: const Icon(Icons.add),
            label: const Text('Choose Video(s)'),
          ),

          // Set Output Dir Button
          ElevatedButton.icon(
          onPressed: (FFmpegManager.encoderStatus.value == SooperEncoderStatus.none) 
            ? () async {
                await FileManager.SetOutputDir(manuallySet: true);
                setState(() {});
              } : null,          
            icon: const Icon(Icons.folder),
            label: const Text('Set Output Folder'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Text(
                "Current:",
                style: TextStyle(
                  fontWeight: FontWeight.bold
                )
              ),
              Text(
                FileManager.outputPath ?? "Not Set",
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: FontStyle.italic
                )
              ),
            ],
          ),
          SooperEncoderButton(),
        ],
      )
    );
  }
}

