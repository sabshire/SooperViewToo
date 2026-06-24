import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
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

  Future<void> _handleDroppedFiles(List<DropItem> items) async {
    final List<File> newFiles = [];

    for (final item in items) {
      final path = item.path;

      final file = File(path);

      if (await file.exists() && !FileManager.fileList.any((e) => e.path == file.path)) {
        newFiles.add(file);
      }
    }

    if (newFiles.isNotEmpty) {
      setState(() {
        FileManager.AddFile(newFiles);
      });
    }
  }

  Widget _buildFileListUI() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: widget.fileList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No files added'),
                ],
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: widget.fileList.length,
              itemBuilder: (context, index) {
                final file = widget.fileList[index];
                final isSelected =
                    FileManager.selectedFileList.contains(file);

                return ListTile(
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (_) {
                      _toggleSelection(file);
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
                      setState(() {
                        FileManager.RemoveFromSelectedFiles(file);
                        widget.onRemove(file);
                      });
                    },
                  ),
                  onTap: () => _toggleSelection(file),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) {
      // Fallback for non-desktop platforms
      return _buildFileListUI();
    }

    return DropTarget(
      onDragEntered: (_) => setState(() {}),
      onDragExited: (_) => setState(() {}),
      onDragDone: (detail) async {
        await _handleDroppedFiles(detail.files);
      },
      child: _buildFileListUI(),
    );
  }
}