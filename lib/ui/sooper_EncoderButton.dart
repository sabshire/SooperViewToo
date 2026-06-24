import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sooperview/FileManager.dart';
import 'package:sooperview/ffmpeg_argument_builder.dart';
import 'package:sooperview/remap_file_generator.dart';
import 'package:sooperview/FFmpegManager.dart';

import 'package:sooperview/PermissionHandler.dart';

class SooperEncoderButton extends StatelessWidget {
  
  final VoidCallback? onPressed;
  final VoidCallback? onComplete;
  final Function(double progressPercentage)? onProgressUpdate;
  final VoidCallback? onFailure;
  final VoidCallback? onCancelled;
  final VoidCallback? onProbeFinished;
  final VoidCallback? onFinished;


  const SooperEncoderButton({
    super.key,
    this.onPressed,
    this.onComplete,
    this.onProgressUpdate,
    this.onFailure,
    this.onCancelled,
    this.onProbeFinished,
    this.onFinished,
  });

  Future<void> encode() async {
    bool permissionsGood = await PermissionHandler.HasNeededPermissions();
    if (!permissionsGood) return;
    FileManager.GetOutputDir();

    FFmpegManager.isEncoding = true;
    onPressed?.call();
    await FFprobeKit.getMediaInformationAsync("'${FileManager.GetCurrentSelectedFile()?.path}'", onComplete: (session) async {
    //await FFprobeKit.executeAsync(cmd, onComplete: (session) async {
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
      final command = await FfmpegArgumentBuilder.BuildFFmpegArguments(FileManager.GetCurrentSelectedFile()!.path, mapLoc["xmap"]!, mapLoc["ymap"]!);
      print(command);

      FFmpegManager.SetSession(FFmpegKit.createSession(command), metadata.totalFrames);

      // set media duration for progress calculation
      final duration = metadata.duration * 1000;
      FFmpegManager.ffmpegSession!.setExpectedTranscodingDuration(
        Duration(milliseconds: duration.toInt()),
      );

      await FFmpegManager.ffmpegSession!.executeAsync(completeCallback: (session) async {
        final returnCode = session.getReturnCode();
        
        if (ReturnCode.isSuccess(returnCode)) {
          // Call complete event
          onComplete?.call();
          //final Directory tempDir = await getTemporaryDirectory();
          //final path = p.join(tempDir.path, "sooperview-temp.mp4");
          //moveExistingFile(File(path));
        } else if (ReturnCode.isCancel(returnCode)) {
          onCancelled?.call();
        } else {
          onFailure?.call();
        }

        if (FileManager.NextSelectedFileExists()) {
          // Another file needs encoding
          FileManager.NextSelectedFile();
          encode();
        } else {
          // Encoding is done
          FFmpegManager.isEncoding = false;
          onFinished?.call();
        }


      }, statisticsCallback: (statistics) async {
        //print(statistics.transcodingProgressPercent);
        FFmpegManager.ffmpegProgressPercentage = ((statistics.videoFrameNumber / FFmpegManager.ffmpegTotalFrameNum) * 100);
        onProgressUpdate?.call(FFmpegManager.ffmpegProgressPercentage);
      },);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: (FFmpegManager.isEncoding || (FileManager.selectedFileList.isEmpty)) ? null : encode,
      icon: const Icon(Icons.play_arrow, color: Colors.green,),
      label: const Text('Encode'),
    );
  }
}