import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  bool get isDesktop =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  void _toggleSelection(File file) {
    setState(() {
      if (FileManager.selectedFileList.contains(file)) {
        FileManager.RemoveFromSelectedFiles(file);
      } else {
        FileManager.AddToSelectedFiles(file);
      }
    });

    widget.onSelectionUpdate?.call();
  }

  Widget _buildFileListUI(BuildContext context) {
    return ListenableBuilder(
      // Listen to both file additions/removals and selection changes
      listenable: Listenable.merge([
        FileManager.fileCount,
        FileManager.selectedFileCount, // Ensure you add this static notifier to FileManager
      ]),
      builder: (context, child) {
        // Fetch the live files directly from your static manager
        final files = widget.fileList; 

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Drag Files Here'),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: false,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final isSelected = FileManager.selectedFileList.contains(file);

                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (_) {
                          _toggleSelection(file); // Make sure this updates your selection notifier
                        },
                      ),
                      title: Text(
                        file.path.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        file.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Keep mutations inside the static manager; it handles the notification
                          FileManager.RemoveFile(file); 
                          widget.onRemove(file); 
                        },
                      ),
                      onTap: () => _toggleSelection(file),
                    );
                  },
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildFileListUI(context);
  }
}