import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sooperview/ffmpeg_manager.dart';
import 'package:sooperview/file_manager.dart';
//import 'package:sooperview/file_manager.dart';
import 'package:sooperview/tooltip_manager.dart';
import 'package:sooperview/ui/encoding_progress_widget.dart';
import 'package:sooperview/ui/fileselectorscreen.dart';
import 'package:sooperview/ui/settingsscreen.dart';

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder listens directly to the encoder status changes
    return ValueListenableBuilder<SooperEncoderStatus>(
      valueListenable: FFmpegManager.encoderStatus,
      builder: (context, status, child) {
        // Condition 1: If encoding is active, completely swap out the screen
        if (status != SooperEncoderStatus.none) {
          return Scaffold(
            body: ValueListenableBuilder<double>( // Assuming ffmpegProgressPercentage is a double or num
              valueListenable: FFmpegManager.ffmpegProgressPercentage,
              builder: (context, progressPercentage, child) {
                return EncodingProgressWidget(
                  // The progress math now dynamically updates whenever progressPercentage changes
                  progress: progressPercentage / 100,
                  //progress: ((FileManager.currentFile) / FileManager.selectedFileList.length) + 
                  //          (progressPercentage / 100 / FileManager.selectedFileList.length),
                  onExitWidget: () {
                    FFmpegManager.encoderStatus.value = SooperEncoderStatus.none;
                  },
                  onCancelEncode: () {
                    switch (FFmpegManager.encoderStatus.value) {
                      case SooperEncoderStatus.encode:
                      case SooperEncoderStatus.probe:
                        FFmpegManager.encoderStatus.value = SooperEncoderStatus.cancelling;
                        FFmpegKitExtended.cancelAllSessions();
                        FileManager.markUnprocessedFiles(SooperEncoderStatus.cancelling);
                        break;
                      case SooperEncoderStatus.finish:
                      default:
                        FFmpegManager.encoderStatus.value = SooperEncoderStatus.none;
                        break;
                    }
                  },
                );
              },
            ),
          );
        }

        // Condition 2: Default behavior when status is SooperEncoderStatus.none
        return DefaultTabController(
          length: 2,
          initialIndex: 1,
          child: Scaffold(
            bottomNavigationBar: TabBar(
              tabs: [
                Tooltip(
                  message:TooltipManager.getSetingsTooltip(),
                  child:Tab(text: 'Settings'),
                ),
                Tooltip(
                  message:TooltipManager.getFileSelectorTooltip(),
                  child:Tab(text: 'File Selector'),
                ),
                //Tab(text: 'Preview (BETA)')
              ],
              indicatorColor: Colors.white,
              indicatorWeight: 3.0,
            ),
            body: const TabBarView(
              children: [
                SooperViewSettingsScreen(),
                FileSelectorScreen(),
                //SooperViewPreviewer(),
              ],
            ),
          ),
        );
      },
    );
  }
}