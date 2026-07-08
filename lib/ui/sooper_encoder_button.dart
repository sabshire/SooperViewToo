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
    FileManager.markCurrentFileStatus(SooperEncoderStatus.probe);
    FFmpegManager.ffprobeSession = await FFprobeKit.getMediaInformationAsync("'${FileManager.GetCurrentSelectedFile()?.path}'", onComplete: (session) async {
      FFmpegManager.encoderStatus.value = SooperEncoderStatus.encode;
      final result = session.getLogsAsString();

      //print(result);

      final jsonRegex = RegExp(r'\{[\s\S]*?\S[\s\S]*\}');
      final match = jsonRegex.stringMatch(result!);

      if (match == null || match.isEmpty) {
        onFailure?.call();
        FileManager.markCurrentFileStatus(SooperEncoderStatus.error);
        checkIfMoreFilesToProcess();
        return;
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

      FileManager.markCurrentFileStatus(SooperEncoderStatus.encode);
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
          FileManager.markCurrentFileStatus(SooperEncoderStatus.finish);
        }  else {
          onFailure?.call();
          //track errors for when finished
          FileManager.markCurrentFileStatus(SooperEncoderStatus.error);
        }

        checkIfMoreFilesToProcess();


      }, statisticsCallback: (statistics) async {
        FFmpegManager.ffmpegProgressPercentage.value = ((statistics.videoFrameNumber / FFmpegManager.ffmpegTotalFrameNum) * 100);
        onProgressUpdate?.call(FFmpegManager.ffmpegProgressPercentage.value);
      }, logCallback: (log) async {
        
        //print(log);
      });
    });
  }

  void checkIfMoreFilesToProcess() {
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
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        FFmpegManager.encoderStatus,
        FileManager.selectedFileCount, // Ensure you add this static notifier to FileManager
      ]), // Replace with your ChangeNotifier or ValueNotifier
      builder: (context, child) { 
        return ElevatedButton.icon(
          onPressed: ((FFmpegManager.encoderStatus.value != SooperEncoderStatus.none) || (FileManager.selectedFileCount.value == 0) || (!FileManager.isOutputPathSet())) ? null : () {FileManager.reset(); encode();},
          icon: Icon(Icons.play_arrow, color: getEncodeButtonIconColor(),),
          label: const Text('Encode'),
        );
      },
    );
  }

  MaterialColor getEncodeButtonIconColor() {
    return ((FFmpegManager.encoderStatus.value != SooperEncoderStatus.none) || (FileManager.selectedFileCount.value == 0) || (!FileManager.isOutputPathSet())) ? Colors.grey : Colors.green;
  }
}