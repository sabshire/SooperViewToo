import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Video properties containing source and target dimensions.
class VideoProperties {
  final int width;
  final int height;
  final double duration;

  VideoProperties({
    required this.width,
    required this.height,
    required this.duration
  });

  /// Creates VideoProperties from a direct JSON object (e.g., from ffprobe output)
  ///
  /// The JSON should have format:
  /// {
  ///   "width": 1920,
  ///   "height": 1080,
  ///   "duration": "10.5"
  /// }
  factory VideoProperties.fromJson(Map<String, dynamic> json) {
    return VideoProperties(
      width: json['width'] as int,
      height: json['height'] as int,
      // Parse string duration securely into a double
      duration: double.tryParse(json['duration']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  /// Creates VideoProperties from ffprobe JSON output.
  ///
  /// ffprobe outputs a JSON array of streams, so this method finds
  /// the first video stream with width and height properties.
  ///
  /// Example ffprobe JSON structure:
  /// {
  ///   "streams": [
  ///     {"width": 2688, "height": 2016, "duration": "7.670000"},
  ///     {"duration": "7.678367"},
  ///     ...
  ///   ]
  /// }
  factory VideoProperties.fromFfprobeJson(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final streams = data['streams'] as List<dynamic>?;

    // Find the first video stream with width and height
    int? width;
    int? height;
    double? duration;

    if (streams != null) {
      for (final stream in streams) {
        final s = stream as Map<String, dynamic>;
        if (s.containsKey('width') && s.containsKey('height')) {
          width = s['width'];
          height = s['height'];
          duration = double.tryParse(s['duration'].toString());
          break;
        }
      }
    }

    if (width == null || height == null || duration == null) {
      throw FormatException(
        "No video stream with width and height found in ffprobe output.",
      );
    }

    return VideoProperties(
      width: width,
      height: height,
      duration: duration!,
    );
  }
}



/// Generates the xmap/ymap PGM remap files used by ffmpeg's remap filter.
/// Implements the SuperView stretch algorithm.
/// Reference: https://intofpv.com/t-using-free-command-line-sorcery-to-fake-superview
class RemapFileGenerator {

  /// Calculates the x-coordinate transformation using the SuperView algorithm.
  /// This is the "DerpIt" function from the original implementation.
  ///
  /// [tx] - Target x coordinate (0 to targetWidth)
  /// [targetWidth] - Desired output width (calculated as height * 16/9)
  /// [srcWidth] - Original source width
  ///
  /// Returns the transformed x-coordinate value for the PGM file.
  double derpIt(int tx, int targetWidth, int srcWidth) {
    final x = (tx / targetWidth - 0.5) * 2; // Map to -1 -> 1 range
    final sx = tx - (targetWidth - srcWidth) / 2.0;
    final offset = pow(x, 2) * (x < 0 ? -1 : 1) * ((targetWidth - srcWidth) / 2.0);
    return sx - offset;
  }

  Future<Map<String, String>> generateCrossPlatformRemapFiles(VideoProperties vidProperties) async {
    // 1. Resolve safe local temporary workspace cache natively on iOS/Android/Desktop
    final Directory tempDir = await getTemporaryDirectory();
    final String outputDirectory = tempDir.path;

    final xmapPath = p.join(outputDirectory, "temp_xmap.pgm");
    final ymapPath = p.join(outputDirectory, "temp_ymap.pgm");
    //final xmapPath = '$outputDirectory/temp_xmap.pgm';
    //final ymapPath = '$outputDirectory/temp_ymap.pgm';
    final targetWidth = (vidProperties.height * 16 / 9).toInt();

    // 2. Offload work to an isolated thread to prevent UI freezing
    await Isolate.run(() => _isolateWorker({
      'width': vidProperties.width,
      'height': vidProperties.height,
      'xMapPath': xmapPath,
      'yMapPath': ymapPath,
      'targetWidth': targetWidth
    }));

    return {'xmap': xmapPath, 'ymap': ymapPath};
  }

  void _isolateWorker(Map<String, dynamic> params) async {
    try {
      final int sourceWidth = params['width'];
      final int sourceHeight = params['height'];
      final int targetWidth = params['targetWidth'];
      //final targetWidth = 1280;
      final String xMapPath = params['xMapPath'];
      final String yMapPath = params['yMapPath'];

      final File xFile = File(xMapPath);
      final File yFile = File(yMapPath);

      // Use IOSink streaming to safely write line-by-line directly to disk storage
      final IOSink xSink = xFile.openWrite(mode: FileMode.write);
      final IOSink ySink = yFile.openWrite(mode: FileMode.write);

      try {
        // 1. Write the 16-bit ASCII PGM headers (P2 Magic Number)
        xSink.write('P2\n$targetWidth $sourceHeight\n65535\n');
        ySink.write('P2\n$targetWidth $sourceHeight\n65535\n');

        // 2. Pre-generate the static Y row contents once outside the loop
        // This eliminates recreating the same identical string thousands of times
        final List<int> yLineValues = List<int>.generate(targetWidth, (x) => 0);

        // 3. Process maps simultaneously line-by-line to minimize RAM footprints
        for (int y = 0; y < sourceHeight; y++) {
          final List<int> xLineValues = <int>[];
          
          for (int x = 0; x < targetWidth; x++) {
            // Compute custom SuperView non-linear stretching algorithm for X map
            final double fudgeit = derpIt(x, targetWidth, sourceWidth);
            xLineValues.add(fudgeit.toInt());
            
            // Capture the static Y linear value mapping row
            yLineValues[x] = y;
          }

          // Cleanly stream the data buffers straight into the filesystems
          xSink.write('${xLineValues.join(' ')}\n');
          ySink.write('${yLineValues.join(' ')}\n');
        }
      } finally {
        // 4. Force OS to flush buffer data to disk before terminating thread
        await xSink.close();
        await ySink.close();
      }
      
    } catch (exception, stackTrace) {

    }
  }

}