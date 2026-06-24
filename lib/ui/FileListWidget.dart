import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sooperview/FileManager.dart';

class FileListWidget extends StatefulWidget {
  final List<File> fileList;
  final Function(File) onRemove;
  final VoidCallback? onSelectionUpdate;

  const FileListWidget({
    super.key,
    required this.fileList,
    required this.onRemove,
    this.onSelectionUpdate,
  });

  @override
  State<FileListWidget> createState() => _FileListWidgetState();
}

class _FileListWidgetState extends State<FileListWidget> {
  //final Set<File> _selectedFiles = <File>{};

  void _toggleSelection(File file) {
    
    setState(() {
      if (FileManager.selectedFileList.contains(file)) {
        //_selectedFiles.remove(file);
        FileManager.RemoveFromSelectedFiles(file);
      } else {

        //_selectedFiles.add(file);
        FileManager.AddToSelectedFiles(file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true, // Fixes infinite height error
      physics: const NeverScrollableScrollPhysics(), // Allows parent to scroll
      itemCount: widget.fileList.length,
      itemBuilder: (context, index) {
        //final file = widget.fileList[index];
        final file = FileManager.fileList[index];
        final isSelected = FileManager.selectedFileList.contains(file);

        return ListTile(
          leading: Checkbox(
            value: isSelected,
            onChanged: (_) {
              setState(() {
                _toggleSelection(file);
                widget.onSelectionUpdate?.call();
              });
            },
          ),
          title: Text(
            file.path.split('/').last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                FileManager.RemoveFromSelectedFiles(file);
                widget.onRemove(file);
              });
              //setState(() => _selectedFiles.remove(file));
              
            },
          ),
          onTap: () => _toggleSelection(file),
        );
      },
    );
  }
}
