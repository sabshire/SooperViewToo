import 'dart:io';
//import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sooperview/file_manager.dart';
import 'package:sooperview/tooltip_manager.dart';
import 'package:sooperview/ui/progress_widget.dart';
import '../ffmpeg_manager.dart';

/// A beautiful, mobile-friendly encoding progress widget
/// Displays a circular progress ring with percentage and status info
class EncodingProgressWidget extends StatefulWidget {
  /// Progress value between 0.0 and 1.0
  final double progress;

  /// Color for the progress ring
  final Color progressColor;

  /// Color for the background ring
  final Color backgroundColor;

  /// Width of the progress ring
  final double strokeWidth;

  /// Size of the progress ring
  final double size;

  /// Callback invoked when the Cancel button is pressed (while encoding)
  final VoidCallback? onCancelEncode;

  /// Callback invoked when the Exit button is pressed (after encoding finished)
  final VoidCallback? onExitWidget;

  const EncodingProgressWidget({
    super.key,
    required this.progress,
    this.progressColor = Colors.lightBlue,
    this.backgroundColor = Colors.blueGrey,
    this.strokeWidth = 12.0,
    this.size = 240.0,
    this.onCancelEncode,
    this.onExitWidget,
  });

  @override
  State<EncodingProgressWidget> createState() => _EncodingProgressWidgetState();
}

class _EncodingProgressWidgetState extends State<EncodingProgressWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.progress.clamp(0.0, 1.0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: _currentProgress,
    ).animate(_animationController);
    _animationController.forward();
  }

  @override
  void didUpdateWidget(EncodingProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _currentProgress = widget.progress.clamp(0.0, 1.0);
      _animation = Tween<double>(
        begin: _animation.value,
        end: _currentProgress,
      ).animate(_animationController);
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final percentage = (_animation.value * 100).toInt();
    //final isComplete = FFmpegManager.encoderStatus.value == SooperEncoderStatus.finish;
    final files = FileManager.selectedFileList; 

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        constraints: const BoxConstraints(
          maxWidth: double.infinity,                  
        ),
        child: Card(
          elevation: 8,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(              
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:EdgeInsetsGeometry.all(5),
                  child: Text(
                    getProcessingText(),
                    textAlign: TextAlign.center,   
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    )               
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: false,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return ListTile(
                          leading: getProgressIconWidget(index),
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
                        );
                      },
                    ),
                  ),
                ),

                // Cancel / Exit button
                const SizedBox(height: 24.0),
                Tooltip(
                  message:TooltipManager.getCancelTooltip(),
                  child: _buildActionButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final isFinished =
        FFmpegManager.encoderStatus.value == SooperEncoderStatus.finish;
    final isDisabled  = 
      FFmpegManager.encoderStatus.value == SooperEncoderStatus.cancelling;
    return SizedBox(
      width: widget.size,
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : isFinished ? widget.onExitWidget : widget.onCancelEncode,
        icon: Icon(
          isDisabled ? Icons.warning_rounded : isFinished ? Icons.logout : Icons.close,
          size: 20,
        ),
        label: Text(
          isFinished ? 'Exit' : FFmpegManager.encoderStatus.value == SooperEncoderStatus.cancelling ? 'Cancelling' :  'Cancel',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isFinished ? Colors.blue : Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget getProgressIconWidget(int index) {
    switch (FileManager.getFileEncodeStatus(index)) {
      case SooperEncoderStatus.encode: 
        return ProgressWidget(
          progress: widget.progress,
          size: 48,
        );
      case SooperEncoderStatus.probe:
        return Icon(Icons.file_open, size: 48, color: Colors.blueAccent);
      case SooperEncoderStatus.finish: 
        return Icon(Icons.check_circle, size: 48, color: Colors.green);
      case SooperEncoderStatus.error:
        return Icon(Icons.error, size: 48, color: Colors.red);
      case SooperEncoderStatus.cancelling:
        return Icon(Icons.warning_rounded, size: 48, color: Colors.grey);
      default: 
        return Icon(Icons.check_box_outline_blank_rounded, size: 48, color: Colors.grey,);
    }
  }

  String getProcessingText() {
    return FFmpegManager.encoderStatus.value == SooperEncoderStatus.finish ? "Processing Finished" : "Processing File ${FileManager.currentFile + 1} / ${FileManager.selectedFileList.length}";
  }
}