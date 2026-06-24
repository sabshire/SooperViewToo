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
    
    FFmpegManager.encoderStatus = SooperEncoderStatus.probe;
    onPressed?.call();
    FFmpegManager.ffprobeSession = await FFprobeKit.getMediaInformationAsync("'${FileManager.GetCurrentSelectedFile()?.path}'", onComplete: (session) async {
    //await FFprobeKit.executeAsync(cmd, onComplete: (session) async {
      FFmpegManager.encoderStatus = SooperEncoderStatus.encode;
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
        if (FFmpegManager.encoderStatus == SooperEncoderStatus.cancelling) {
          FFmpegManager.encoderStatus = SooperEncoderStatus.none;
          FFmpegManager.ffmpegProgressPercentage = 0;
          FFmpegManager.onFinish();
          onCancelled?.call();
          return;
        }
        if (ReturnCode.isSuccess(returnCode)) {
          // Call complete event
          onComplete?.call();
        }  else {
          onFailure?.call();
        }

        if (FileManager.NextSelectedFileExists()) {
          // Another file needs encoding
          FileManager.NextSelectedFile();
          FFmpegManager.ffmpegProgressPercentage = 0;
          encode();
        } else {
          // Encoding is done
          FFmpegManager.encoderStatus = SooperEncoderStatus.finish;
          onFinished?.call();
          FFmpegManager.onFinish();
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
      onPressed: ((FFmpegManager.encoderStatus != SooperEncoderStatus.none) || (FileManager.selectedFileList.isEmpty)) ? null : encode,
      icon: const Icon(Icons.play_arrow, color: Colors.green,),
      label: const Text('Encode'),
    );
  }
}