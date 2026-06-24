import 'dart:io';

import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:sooperview/FileManager.dart';

// Status Types for encoder
enum SooperEncoderStatus {
  none,
  probe,
  encode,
  finish,
  cancelling
}

class FFmpegManager {
  static FFmpegSession? ffmpegSession;
  static FFprobeSession? ffprobeSession;

  static int ffmpegCurrentFrameNum = 0;
  static int ffmpegTotalFrameNum = 0;
  static double ffmpegProgressPercentage = 0;
  static SooperEncoderStatus encoderStatus = SooperEncoderStatus.none;
  //static bool isEncoding = false; // This is used in SooperEncoderButton to know if a current encoding session is running to disable button

  static FFplaySession? ffplaySession;

  static void SetSession(FFmpegSession session, int totalFrames) {
    ffmpegSession = session;
    ffmpegTotalFrameNum = totalFrames;
  }

  static SessionState? GetState() {
    if (ffmpegSession != null) {
      return ffmpegSession!.getState();
    }
    return null;
  }

  static void ResetFFmpeg() {
    ffmpegSession = null;
    ffmpegTotalFrameNum = 0;
    ffmpegCurrentFrameNum = 0;
  }

  static void onFinish() {
    ResetFFmpeg();
    FileManager.currentFile = 0;
  }

  static String getStatusToText(SooperEncoderStatus status) {
    switch (status) {
      case SooperEncoderStatus.encode:
        return "Encoding";
      case SooperEncoderStatus.probe:
        return "Probing";
      case SooperEncoderStatus.cancelling:
        return "Cancelling";
      case SooperEncoderStatus.finish:
        return "Finished";
      default:
        return "Shouldn't see this";
    }
  }

}