import 'dart:io' show Directory, Platform;

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Builder class for constructing ffmpeg/ffprobe command-line arguments.
class FfmpegArgumentBuilder {
  
  //static File? selectedFile;
  static String outputPath = "";

  static String selectedEncoder = "H264";
  //static final List<String> encoderItems = ["H264", "HEVC", "AV1"]; // This was swapped for availableEncoders Map. Delete when tested properly

  static String selectedHardware = "CPU";

  static String selectedResolution = "4K";
  static final List<String> resolutionItems = ["4K", "1440p", "1080p", "720p", "480p"];

  static const Map<String, List<String>> availableEncoders = {
    'CPU': ['H264', 'HEVC', 'AV1'],
    'NVIDIA': ['H264', 'HEVC', 'AV1'],
    'AMD': ['H264', 'HEVC', 'AV1'],
    'INTEL': ['H264', 'HEVC', 'AV1'],
    'Android': ['H264', 'HEVC'],
    'MacOS': ['H264', 'HEVC'],
    'iPhone': ['H264', 'HEVC'],
  };

  static List<String> getAvailableEncoders() {
    return availableEncoders[selectedHardware]!;
  }

  static const Map<(String hw, String encoder), String> encoderSettings = {
    // H264
    ('CPU', 'H264'): '-c:v libx264',
    ('NVIDIA', 'H264'): '-c:v h264_nvenc',
    ('AMD', 'H264'): '-c:v h264_amf',
    ('INTEL', 'H264'): '-c:v h264_qsv',
    ('MacOS', 'H264'): '-c:v h264_videotoolbox',
    ('iPhone', 'H264'): '-c:v hevc_videotoolbox',
    ('Android', 'H264'): '-c:v h264_mediacodec',

    // HEVC
    ('CPU', 'HEVC'): '-c:v libx265',
    ('NVIDIA', 'HEVC'): '-c:v hevc_nvenc',
    ('AMD', 'HEVC'): '-c:v hevc_amf',
    ('INTEL', 'HEVC'): '-c:v hevc_qsv',
    ('MacOS', 'HEVC'): '-c:v hevc_videotoolbox',
    ('iPhone', 'HEVC'): '-c:v hevc_videotoolbox',
    ('Android', 'HEVC'): '-c:v hevc_mediacodec',

    // AV1
    ('CPU', 'AV1'): '-c:v libsvtav1',
    ('NVIDIA', 'AV1'): '-c:v av1_nvenc',
    ('AMD', 'AV1'): '-c:v av1_amf',
    ('INTEL', 'AV1'): '-c:v av1_qsv',
    //('MacOS', 'AV1'): '-c:v av1_videotoolbox', // Doesn't seem to work (maybe different encoder name?)
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
    ('iPhone', 'H264'): [], // TODO
    ('Android', 'H264'): ["cq", "vbr", "cbr", "cbr_fd"],

    // HEVC
    ('CPU', 'HEVC'): ["ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow", "placebo"],
    ('NVIDIA', 'HEVC'): ["p1", "p2", "p3", "p4", "p5", "p6", "p7"],
    ('AMD', 'HEVC'): ["quality", "balance", "speed"],
    ('INTEL', 'HEVC'): ["veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow"],
    ('MacOS', 'HEVC'): [], // TODO
    ('iPhone', 'HEVC'): [], // TODO
    ('Android', 'HEVC'): ["cq", "vbr", "cbr", "cbr_fd"],

    // AV1
    ('CPU', 'AV1'): ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"],
    ('NVIDIA', 'AV1'): ["p1", "p2", "p3", "p4", "p5", "p6", "p7"],
    ('AMD', 'AV1'): ["quality", "balance", "speed"],
    ('INTEL', 'AV1'): ["veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow"],
    ('MacOS', 'AV1'): [], // TODO
    ('iPhone', 'AV1'): [], // TODO
    //('Android', 'AV1'): [],
    
  };

  static List<String>? GetCurrentPresetList() {
    return presetValues[(selectedHardware, selectedEncoder)];
  }

  static String nvidiaPresetValue = "p4";
  static String amdPresetValue = "balance";
  static String intelPresetValue = "medium";
  static String cpuH26XValue = "medium";
  static String cpuAV1Value = "6";
  static String selectedAndroidBitrateMode = "cq";

  static String GetCurrentPresetValue() {
    switch (selectedHardware) {
      case "NVIDIA":
        return nvidiaPresetValue;

      case "AMD":
        return amdPresetValue;

      case "INTEL":
        return intelPresetValue;

      case "Android":
        return selectedAndroidBitrateMode;
    }

    if (selectedHardware == "CPU") { // SHOULD BE CPU
      if (selectedEncoder == "AV1") {
        return cpuAV1Value; // AV1
      } else {
        return cpuH26XValue; // H264/HEVC
      }
    } else {
      return cpuH26XValue; // Return cpu h264 default just in case
    }
  }

  static void SetCurrentPresetValue(String value) {
    switch (selectedHardware) {
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

    if (selectedHardware == "CPU") { // SHOULD BE CPU
      if (selectedEncoder == "AV1") {
        cpuAV1Value = value; // AV1
        return;
      } else {
        cpuH26XValue = value; // H264/HEVC
        return;
      }
    }
  }

  static String GetPresetArgument() {
    switch (selectedHardware) {
      case "NVIDIA":
        return "-preset $nvidiaPresetValue";

      case "AMD":
        return "-preset $amdPresetValue";

      case "INTEL":
        return "-preset $intelPresetValue";
      
      case "Android":
        //return "-bitrate-mode $selectedAndroidBitrateMode"; // Doesn't seem to work
    }

    if (selectedHardware == "CPU") { // SHOULD BE CPU
      if (selectedEncoder == "AV1") {
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

    if (Platform.isIOS) {
      return ["CPU", "iPhone"];
    }

    if (Platform.isWindows) {
      return ["CPU", "NVIDIA", "AMD", "INTEL"];
    }

    return ["CPU", "NVIDIA", "AMD", "INTEL", "Android"];
  }

  static int crfValue = 18;
  static int crfAndroidValue = 80;
  static String GetCRFArgument() {
    switch(selectedHardware) {
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
  
  static List<int> GetCRFValueList() {
    if (selectedHardware == "Android") {
      return List.generate(101, (index) => index);
    } else {
      return List.generate(52, (index) => index);
    }
  }

  static int GetCRFValue() {
    if (selectedHardware == "Android") {
      return crfAndroidValue;
    } else {
      return crfValue;
    }
  }
  static void SetCRFValue(int crf) {
    if (selectedHardware == "Android") {
      crfAndroidValue = crf;
      return;
    } else {
      crfValue = crf;
    }
  }

  static String selectedColorspace = "8-bit";
  static final List<String> colorspaceItems = ["8-bit", "10-bit"];

  static String GetPixelFormat() {
    switch(selectedColorspace) {
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

      case "480p":
        return "480";

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

      case "480p":
        return "720";

      default:
        return "1920"; // Default just in case
    }
  }

  static String videoFormat = "mp4";
  static List<String> videoFormatList = ["mp4", "mov", "mkv", "webm", "avi"];
  // -v error -hide_banner -print_format json -show_format -show_streams -show_chapters -i 'C:\Users\Stacey Abshire\Videos\djio3\2026\04\18\DJI_0118.MP4'
  static String buildFfprobeArguments(String filePath) =>
    "-i ${wrapPathInQuotes(filePath)} -show_entries stream=width,height,duration -of json";

//  static String buildFFPlayArguments(String filePath, String xmapPath, String ymapPath) =>
//    '-i ${wrapPathInQuotes(filePath)} -vf "movie=${wrapPathInQuotes(xmapPath)}[x]; movie=${wrapPathInQuotes(ymapPath)}[y]; [in][x][y]remap,scale=${GetWidth(selectedResolution)}:${GetHeight(selectedResolution)}"';

  static String buildFFPlayArgumentsNew(
    String filePath,
    String xmapPath,
    String ymapPath,
  ) =>
    '-i "$filePath" '
    '-vf "movie=${wrapFilterPath(xmapPath)}[x]; '
    "movie=${wrapFilterPath(ymapPath)}[y]; "
    '[in][x][y]remap,scale=${GetWidth(selectedResolution)}:${GetHeight(selectedResolution)}" ';

  static String escapeFilterPath(String path) {
  return path
      .replaceAll(r'\', r'\\')
      .replaceAll(':', r'\:');
  }

  static String wrapFilterPath(String path) =>
    "'${escapeFilterPath(path)}'";

  static Future<String> BuildFFmpegArguments(String sourceFile, String xmapPath, String ymapPath) async {
    final Directory tempDir = await getTemporaryDirectory();
    final path = p.join(tempDir.path, "sooperview-temp.$videoFormat");
    String fileTag = ""; // For HEVC file tag to fix mac quicktime problems
    if (selectedEncoder == "HEVC" && Platform.isMacOS) { fileTag = " -tag:v hvc1"; } // TODO: Make this into a setting!
    return "-y -i ${wrapPathInQuotes(sourceFile)} -i $xmapPath -i $ymapPath -filter_complex [0:v][1:v][2:v]remap,scale=${GetWidth(selectedResolution)}:${GetHeight(selectedResolution)} ${encoderSettings[(selectedHardware, selectedEncoder)]} ${GetCRFArgument()} ${GetPresetArgument()} ${GetPixelFormat()}$fileTag ${path}";
  }

  static String wrapPathInQuotes(String path) => "'$path'";
}