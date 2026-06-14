import 'dart:io';

import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';

class FFmpegManager {
  static FFmpegSession? ffmpegSession;
  static int ffmpegCurrentFrameNum = 0;
  static int ffmpegTotalFrameNum = 0;
  static double ffmpegProgressPercentage = 0;
  static bool isEncoding = false; // This is used in SooperEncoderButton to know if a current encoding session is running to disable button

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

}