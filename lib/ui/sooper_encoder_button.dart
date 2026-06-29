import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sooperview/file_manager.dart';
import 'package:sooperview/ffmpeg_argument_builder.dart';
import 'package:sooperview/remap_file_generator.dart';
import 'package:sooperview/ffmpeg_manager.dart';

import 'package:sooperview/permission_handler.dart';

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
    bool permissionsGood = await PermissionHandler.hasNeededPermissions();
    if (!permissionsGood) return;
    await FileManager.GetOutputDir();
    
    FFmpegManager.encoderStatus.value = SooperEncoderStatus.probe;
    onPressed?.call();
    FFmpegManager.ffprobeSession = await FFprobeKit.getMediaInformationAsync("'${FileManager.GetCurrentSelectedFile()?.path}'", onComplete: (session) async {
      FFmpegManager.encoderStatus.value = SooperEncoderStatus.encode;
      final result = session.getLogsAsString();

      final jsonRegex = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegex.stringMatch(result!);
      if (match == null) {
        throw const FormatException("No valid JSON block found in output string.");
      }
      final metadata = VideoProperties.fromFfprobeJson(match);
      var mapLoc = await RemapFileGenerator().generateCrossPlatformRemapFiles(metadata);
      final command = await FfmpegArgumentBuilder.BuildFFmpegArguments(FileManager.GetCurrentSelectedFile()!.path, mapLoc["xmap"]!, mapLoc["ymap"]!);

      
      FFmpegManager.SetSession(FFmpegKit.createSession(command), metadata.totalFrames);

      // set media duration for progress calculation
      final duration = metadata.duration * 1000;
      FFmpegManager.ffmpegSession!.setExpectedTranscodingDuration(
        Duration(milliseconds: duration.toInt()),
      );

      await FFmpegManager.ffmpegSession!.executeAsync(completeCallback: (session) async {
        final returnCode = session.getReturnCode();
        if (FFmpegManager.encoderStatus.value == SooperEncoderStatus.cancelling) {
          FFmpegManager.encoderStatus.value = SooperEncoderStatus.none;
          FFmpegManager.ffmpegProgressPercentage.value = 0;
          FFmpegManager.onFinish();
          onCancelled?.call();
          return;
        }
        if (ReturnCode.isSuccess(returnCode)) {
          // Call complete event
          onComplete?.call();
          FileManager.moveExistingTempFile("sooperview-temp.${FfmpegArgumentBuilder.videoFormat}", FileManager.GetCurrentSelectedFile()!);
        }  else {
          onFailure?.call();
        }

        if (FileManager.NextSelectedFileExists()) {
          // Another file needs encoding
          FileManager.NextSelectedFile();
          FFmpegManager.ffmpegProgressPercentage.value = 0;
          encode();
        } else {
          // Encoding is done
          FFmpegManager.encoderStatus.value = SooperEncoderStatus.finish;
          onFinished?.call();
          FFmpegManager.ffmpegProgressPercentage.value = 0;
          FFmpegManager.onFinish();
        }


      }, statisticsCallback: (statistics) async {
        FFmpegManager.ffmpegProgressPercentage.value = ((statistics.videoFrameNumber / FFmpegManager.ffmpegTotalFrameNum) * 100);
        onProgressUpdate?.call(FFmpegManager.ffmpegProgressPercentage.value);
      },);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: ((FFmpegManager.encoderStatus.value != SooperEncoderStatus.none) || (FileManager.selectedFileList.isEmpty)) ? null : encode,
      icon: const Icon(Icons.play_arrow, color: Colors.green,),
      label: const Text('Encode'),
    );
  }
}