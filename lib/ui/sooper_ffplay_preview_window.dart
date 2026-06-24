import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:sooperview/FileManager.dart';
import 'package:sooperview/ffmpeg_argument_builder.dart';
import 'package:sooperview/remap_file_generator.dart';

class SooperViewPreviewer extends StatefulWidget {
  const SooperViewPreviewer({
    Key? key,
  }) : super(key: key);

  @override
  State<SooperViewPreviewer> createState() => _SooperViewPreviewerState();
}

class _SooperViewPreviewerState extends State<SooperViewPreviewer> {
  FFplaySession? _playSession;
  FFplaySurface? _surface;
  Size _videoSize = const Size(16, 9); // Fallback aspect ratio
  int _videoWidth = 0;
  int _videoHeight = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFFplay();
  }

  Future<void> _prepareSurface() async {
    final old = _surface;
    if (mounted) {
      setState(() {
        _surface = null;
        //_hasVideo = false;
      });
    }
    await old?.release();
  }

  Future<void> _initializeFFplay() async {
    try {
      String filePath = FileManager.GetCurrentSelectedFile()!.path;
      await FFprobeKit.getMediaInformationAsync("'${filePath}'", onComplete: (session) async {
        print(session.command);
        final result = session.getLogsAsString();
        print(result);

        final jsonRegex = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegex.stringMatch(result!);
        if (match == null) {
          throw const FormatException("No valid JSON block found in output string.");
        }
        final metadata = VideoProperties.fromFfprobeJson(match);
        print("${metadata.width}x${metadata.height} | ${metadata.duration}");
        var mapLoc = await RemapFileGenerator().generateCrossPlatformRemapFiles(metadata);

        
        // Create surface for video to attach to
        await _prepareSurface();
        _surface = await FFplaySurface.create();
        
        // Create ffplay session and start playback
        String args = FfmpegArgumentBuilder.buildFFPlayArgumentsNew(filePath, mapLoc["xmap"]!, mapLoc["ymap"]!);
        debugPrint(args);
        _playSession = await FFplayKit.executeAsync(
          args,
          onComplete: (session) {
            debugPrint(session.getLogsAsString());
            debugPrint('Playback session complete.');
          },
        );

        // 2. Listen to real-time size events emitted by the decoder engine
        _playSession?.videoSizeStream.listen((size) {
          final (w, h) = size;
          if (mounted && w > 0 && h > 0) {
            setState(() {
              _videoWidth = w;
              _videoHeight = h;
              //_hasVideo = true;
            });
            }
        });

        setState(() {
          _isInitialized = true;
        });
      });

    } catch (e) {
      debugPrint('Error starting FFplay: $e');
    }
  }

  @override
  void dispose() {
    // Crucial: Terminate active playback pipelines to prevent native memory leaks
    if (_playSession != null) {
      FFplayKit.cancel(_playSession!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _playSession == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'This uses your files current codec! If its HEVC or AV1 it probably will run worse.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          AspectRatio(
            aspectRatio: _videoSize.width / _videoSize.height,
            child: FFplayView(
              surface: _surface!,
              videoWidth: _videoSize.width.toInt(),
              videoHeight: _videoSize.height.toInt(),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Rewind 10s',
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    debugPrint(_playSession!.getPosition().toString());
                  },
                ),

                IconButton(
                  tooltip: 'Restart',
                  icon: const Icon(
                    Icons.restart_alt,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _playSession?.setPosition(0);
                      _playSession?.resume();
                    });
                  },
                ),

                IconButton(
                  tooltip: 'Play / Pause',
                  icon: Icon(
                    _playSession!.isPlaying()
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_playSession!.isPlaying()) {
                        _playSession?.pause();
                      } else {
                        _playSession?.resume();
                      }
                    });

                  },
                ),

                IconButton(
                  tooltip: 'Forward 10s',
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    //_forward10Seconds();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
