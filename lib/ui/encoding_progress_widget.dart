import 'package:flutter/material.dart';
import 'package:sooperview/file_manager.dart';
import '../ffmpeg_manager.dart';

/// A beautiful, mobile-friendly encoding progress widget
/// Displays a circular progress ring with percentage and status info
class EncodingProgressWidget extends StatefulWidget {
  /// Progress value between 0.0 and 1.0
  final double progress;

  /// Progress value between 0.0 and 1.0
  final double fileProgress;

  /// Color for the progress ring
  final Color progressColor;

  /// Color for the inner file progress ring
  final Color fileProgressColor;

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
    required this.fileProgress,
    required this.progress,
    this.progressColor = Colors.blue,
    this.fileProgressColor = Colors.teal,
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
  late AnimationController _fileAnimationController;
  late Animation<double> _fileAnimation;
  double _currentProgress = 0.0;
  double _currentFileProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.progress.clamp(0.0, 1.0);
    _currentFileProgress = widget.fileProgress.clamp(0.0, 1.0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: _currentProgress,
    ).animate(_animationController);
    _animationController.forward();
    _fileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fileAnimation = Tween<double>(
      begin: 0.0,
      end: _currentFileProgress,
    ).animate(_fileAnimationController);
    _fileAnimationController.forward();
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
    if (oldWidget.fileProgress != widget.fileProgress) {
      _currentFileProgress = widget.fileProgress.clamp(0.0, 1.0);
      _fileAnimation = Tween<double>(
        begin: _animation.value,
        end: _currentFileProgress,
      ).animate(_fileAnimationController);
      _fileAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fileAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_animation.value * 100).toInt();
    final isComplete = FFmpegManager.encoderStatus.value == SooperEncoderStatus.finish;


    return Center(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        constraints: const BoxConstraints(
          maxWidth: 600,
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

                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return SizedBox(
                            width: widget.size,
                            height: widget.size,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background ring
                                CircularProgressIndicator(
                                  value: 1.0,
                                  strokeWidth: widget.strokeWidth,
                                  backgroundColor: widget.backgroundColor.withAlpha(
                                    (widget.backgroundColor.a * 0.3).toInt(),
                                  ),
                                  valueColor: AlwaysStoppedAnimation(
                                    widget.backgroundColor.withAlpha(
                                      (widget.backgroundColor.a * 0.3).toInt(),
                                    ),
                                  ),
                                ),
                                // Progress ring
                                SizedBox(
                                  width: widget.size / 1.25,  // Increase this value to make it bigger
                                  height: widget.size / 1.25, // Keep width and height identical
                                  child: CircularProgressIndicator(
                                    value: FFmpegManager.encoderStatus.value == SooperEncoderStatus.finish ? 1.0 :  _animation.value,
                                    strokeWidth: widget.strokeWidth,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation(
                                      isComplete
                                          ? Colors.green
                                          : widget.progressColor,
                                    ),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                // Center content
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Check icon when complete
                                    if (isComplete)
                                      Icon(
                                        Icons.check_circle,
                                        size: 48,
                                        color: Colors.green,
                                      )
                                    else
                                      ...[
                                        //keep box inside of progress circle
                                          Column(                                    
                                            spacing: 2,
                                            children: [
                                              Text(
                                                '$percentage%',
                                                style: TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .headlineMedium
                                                      ?.color,
                                                ),
                                              ),

                                              Text(
                                                '${FileManager.currentFile + 1} / ${FileManager.selectedFileList.length}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color,
                                                ),
                                              ),
                                            ]
                                          )
                                      ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // file progress ring
                      AnimatedBuilder(
                        animation: _fileAnimationController,
                        builder: (context, child) {
                          return SizedBox(
                            width: widget.size,
                            height: widget.size,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Progress ring
                                SizedBox(
                                  width: widget.size / 1.5,  // Increase this value to make it bigger
                                  height: widget.size / 1.5, // Keep width and height identical
                                  child: CircularProgressIndicator(
                                    value: FFmpegManager.encoderStatus.value == SooperEncoderStatus.finish ? 1.0 :  _fileAnimation.value,
                                    strokeWidth: widget.strokeWidth,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation(
                                      isComplete
                                          ? Colors.green
                                          : widget.fileProgressColor,
                                    ),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                // Center content
                              ],
                            ),
                          );
                        },
                      ),
                    ]
                  )
                ),

                ConstrainedBox(                                    
                  constraints: BoxConstraints(
                    maxWidth: widget.size,
                  ),
                  child:
                    Wrap(
                      alignment: WrapAlignment.center,
                      runSpacing: 4,
                      spacing: 5,
                      children: [
                        Text(
                          '${FFmpegManager.getStatusToText(FFmpegManager.encoderStatus.value)}:',
                          textAlign: TextAlign.center,                                       
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),
                        Text(
                          FileManager.getFileName(FileManager.selectedFileList[FileManager.currentFile].path),
                          textAlign: TextAlign.center,                                       
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),

                      ],
                    ),
                ),

                // Cancel / Exit button
                const SizedBox(height: 24.0),
                _buildActionButton(),
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

    return SizedBox(
      width: widget.size,
      child: ElevatedButton.icon(
        onPressed: isFinished ? widget.onExitWidget : widget.onCancelEncode,
        icon: Icon(
          isFinished ? Icons.logout : Icons.close,
          size: 20,
        ),
        label: Text(
          isFinished ? 'Exit' : 'Cancel',
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
}

/// A simplified version showing just the circular progress ring
class EncodingProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  const EncodingProgressRing({
    super.key,
    required this.progress,
    this.size = 120.0,
    this.strokeWidth = 10.0,
    this.progressColor = Colors.blue,
    this.backgroundColor = Colors.blueGrey,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress.clamp(0.0, 1.0) * 100).toInt();
    final isComplete = progress >= 1.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor.withAlpha(
              (backgroundColor.a * 0.3).toInt(),
            ),
            valueColor: AlwaysStoppedAnimation(
              backgroundColor.withAlpha(
                (backgroundColor.a * 0.3).toInt(),
              ),
            ),
          ),
          // Progress ring
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(
              isComplete ? Colors.green : progressColor,
            ),
            strokeCap: StrokeCap.round,
          ),
          // Center percentage text
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.bold,
              color: isComplete ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}