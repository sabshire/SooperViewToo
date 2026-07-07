import 'package:flutter/material.dart';

class ProgressWidget extends StatefulWidget {

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

  const ProgressWidget({
    super.key,
    required this.progress,
    this.progressColor = Colors.lightBlue,
    this.backgroundColor = Colors.blueGrey,
    this.strokeWidth = 2,
    this.size = 32.0,
  });

  @override
  State<ProgressWidget> createState() => _ProgressWidgetState();

}

class _ProgressWidgetState extends State<ProgressWidget>
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
  void didUpdateWidget(ProgressWidget oldWidget) {
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
    final percentage = (_animation.value * 100).toInt();

    return SizedBox(
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
                      width: widget.size / 1.2,  // Increase this value to make it bigger
                      height: widget.size / 1.2, // Keep width and height identical
                      child: CircularProgressIndicator(
                        value: _animation.value,
                        strokeWidth: widget.strokeWidth,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(
                          widget.progressColor,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // Center content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      //keep box inside of progress circle
                        Column(                                    
                          spacing: 2,
                          children: [
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: widget.size / 4,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.color,
                              ),
                            ),
                          ]
                        )
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ]
      )
    );
  }
}