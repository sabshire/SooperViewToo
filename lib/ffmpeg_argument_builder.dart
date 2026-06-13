import 'dart:io' show Platform, Directory;

import 'package:sooperview/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Builder class for constructing ffmpeg/ffprobe command-line arguments.
class FfmpegArgumentBuilder {
  static const Map<(String hw, String encoder), String> encoderSettings = {
    // H264
    ('CPU', 'H264'): '-c:v libx264',
    ('NVIDIA', 'H264'): '-c:v h264_nvenc',
    ('AMD', 'H264'): '-c:v h264_amf',
    ('INTEL', 'H264'): '-c:v h264_qsv',
    ('MacOS', 'H264'): '-c:v h264_videotoolbox',
    ('Android', 'H264'): '-c:v h264_mediacodec',

    // HEVC
    ('CPU', 'HEVC'): '-c:v libx265',
    ('NVIDIA', 'HEVC'): '-c:v hevc_nvenc',
    ('AMD', 'HEVC'): '-c:v hevc_amf',
    ('INTEL', 'HEVC'): '-c:v hevc_qsv',
    ('MacOS', 'HEVC'): '-c:v hevc_videotoolbox',
    ('Android', 'HEVC'): '-c:v hevc_mediacodec',

    // AV1
    ('CPU', 'AV1'): '-c:v libsvtav1',
    ('NVIDIA', 'AV1'): '-c:v av1_nvenc',
    ('AMD', 'AV1'): '-c:v av1_amf',
    ('INTEL', 'AV1'): '-c:v av1_qsv',
    ('MacOS', 'AV1'): '-c:v av1_videotoolbox',
    //('Android', 'AV1'): '-c:v av1_mediacodec',
    
  };

  // Bit overcomplicated but might be easier to manage adding values for new encoders?
  static const Map<(String hw, String encoder), List<String>> presetValues = {
    // H264
    ('CPU', 'H264'): ["ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow", "placebo"],
    ('NVIDIA', 'H264'): ["p1", "p2", "p3", "p4", "p5", "p6", "p7"],
    ('AMD', 'H264'): ["quality", "balance", "speed"],
    ('INTEL', 'H264'): ["veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow"],
    ('MacOS', 'H264'): [], // TODO
    ('Android', 'H264'): ["cq", "vbr", "cbr", "cbr_fd"],

    // HEVC
    ('CPU', 'HEVC'): ["ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow", "placebo"],
    ('NVIDIA', 'HEVC'): ["p1", "p2", "p3", "p4", "p5", "p6", "p7"],
    ('AMD', 'HEVC'): ["quality", "balance", "speed"],
    ('INTEL', 'HEVC'): ["veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow"],
    ('MacOS', 'HEVC'): [], // TODO
    ('Android', 'HEVC'): ["cq", "vbr", "cbr", "cbr_fd"],

    // AV1
    ('CPU', 'AV1'): ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"],
    ('NVIDIA', 'AV1'): ["p1", "p2", "p3", "p4", "p5", "p6", "p7"],
    ('AMD', 'AV1'): ["quality", "balance", "speed"],
    ('INTEL', 'AV1'): ["veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow"],
    ('MacOS', 'AV1'): [], // TODO
    //('Android', 'AV1'): [],
    
  };

  static String nvidiaPresetValue = "p4";
  static String amdPresetValue = "balance";
  static String intelPresetValue = "medium";
  static String cpuH26XValue = "medium";
  static String cpuAV1Value = "6";
  static String selectedAndroidBitrateMode = "cq";

  static String GetCurrentPresetValue(String hw, String encoderType) {
    switch (hw) {
      case "NVIDIA":
        return nvidiaPresetValue;

      case "AMD":
        return amdPresetValue;

      case "INTEL":
        return intelPresetValue;

      case "Android":
        return selectedAndroidBitrateMode;
    }

    if (hw == "CPU") { // SHOULD BE CPU
      if (encoderType == "AV1") {
        return cpuAV1Value; // AV1
      } else {
        return cpuH26XValue; // H264/HEVC
      }
    } else {
      return cpuH26XValue; // Return cpu h264 default just in case
    }
  }

  static void SetCurrentPresetValue(String hw, String encoderType, String value) {
    switch (hw) {
      case "NVIDIA":
        nvidiaPresetValue = value;
        return;

      case "AMD":
        amdPresetValue = value;
        return;

      case "INTEL":
        intelPresetValue = value;
        return;
      
      case "Android":
        selectedAndroidBitrateMode = value;
        return;
    }

    if (hw == "CPU") { // SHOULD BE CPU
      if (encoderType == "AV1") {
        cpuAV1Value = value; // AV1
        return;
      } else {
        cpuH26XValue = value; // H264/HEVC
        return;
      }
    }
  }

  static String GetPresetArgument(String hw, String encoderType) {
    switch (hw) {
      case "NVIDIA":
        return "-preset $nvidiaPresetValue";

      case "AMD":
        return "-preset $amdPresetValue";

      case "INTEL":
        return "-preset $intelPresetValue";
      
      case "Android":
        //return "-bitrate-mode $selectedAndroidBitrateMode"; // Doesn't seem to work
    }

    if (hw == "CPU") { // SHOULD BE CPU
      if (encoderType == "AV1") {
        return "-preset $cpuAV1Value";
      } else {
        return "-preset $cpuH26XValue";
      }
    } else {
      return ""; // If no presets are found return empty
    }
  }

  static List<String> GetAvailableHardwareList() {
    if (Platform.isAndroid) {
      return ["CPU", "Android"];
    }

    if (Platform.isMacOS) {
      return ["CPU", "MacOS"];
    }

    return ["CPU", "NVIDIA", "AMD", "INTEL", "Android", "MacOS"];
  }

  static int crfValue = 18;
  static int crfAndroidValue = 80;
  static String GetCRFArgument(String hw) {
    switch(hw) {
      case "NVIDIA":
        return "-rc constqp -cq:v $crfValue -b:v 0"; // Not sure if -b:v is needed

      case "AMD":
        return "-rc cqp -qp_i $crfValue -qp_p $crfValue";

      case "INTEL":
        return "-global_quality $crfValue";

      case "Android":
        return "-global_quality $crfAndroidValue"; // (0-100) Higher is better

      case "CPU":
      default:
        return "-crf $crfValue"; // Not sure if -b:v is needed
    }
  }
  
  static List<int> GetCRFValueList(String hw) {
    if (hw == "Android") {
      return List.generate(101, (index) => index);
    } else {
      return List.generate(52, (index) => index);
    }
  }

  static int GetCRFValue(String hw) {
    if (hw == "Android") {
      return crfAndroidValue;
    } else {
      return crfValue;
    }
  }
  static void SetCRFValue(String hw, int crf) {
    if (hw == "Android") {
      crfAndroidValue = crf;
      return;
    } else {
      crfValue = crf;
    }
  }

  static String GetPixelFormat(String colorSpace) {
    switch(colorSpace) {
      case "10-bit":
        return "-pix_fmt yuv420p10le";

      case "8-bit":
      default:
        return "-pix_fmt yuv420p";
    }
  }
  
  static String GetHeight(String res) {
    switch(res) {
      case "720p":
        return "720";

      case "1080p":
        return "1080";

      case "1440p":
        return "1440";

      case "4K":
        return "2160";

      default:
        return "1080"; // Default just in case
    }
  }

  static String GetWidth(String res) {
    switch(res) {
      case "720p":
        return "1280";

      case "1080p":
        return "1920";

      case "1440p":
        return "2560";

      case "4K":
        return "3840";

      default:
        return "1920"; // Default just in case
    }
  }
  // -v error -hide_banner -print_format json -show_format -show_streams -show_chapters -i 'C:\Users\Stacey Abshire\Videos\djio3\2026\04\18\DJI_0118.MP4'
  static String buildFfprobeArguments(String filePath) =>
      "-i ${wrapPathInQuotes(filePath)} -show_entries stream=width,height,duration -of json";

  static Future<String> BuildFFmpegArguments(String sourceFile, String xmapPath, String ymapPath, String resolution, String hardware, String encoderType, String colorspace) async { // TODO Move some of these variables to this class
    final Directory tempDir = await getTemporaryDirectory();
    final path = p.join(tempDir.path, "sooperview-temp.mp4");

    return "-y -i ${wrapPathInQuotes(sourceFile)} -i $xmapPath -i $ymapPath -filter_complex [0:v][1:v][2:v]remap,scale=${GetWidth(resolution)}:${GetHeight(resolution)} ${encoderSettings[(hardware, encoderType)]} ${GetCRFArgument(hardware)} ${GetPresetArgument(hardware, encoderType)} ${GetPixelFormat(colorspace)} ${path}";
  }

  static String wrapPathInQuotes(String path) => "'$path'";
}