import 'package:shared_preferences/shared_preferences.dart';
import 'package:sooperview/FileManager.dart';
import 'package:sooperview/ffmpeg_argument_builder.dart';

class SaveManager {

  static Future<void> LoadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    //prefs.remove("Encoder");
    //prefs.remove("Hardware");
    //prefs.remove("Colorspace");
    //prefs.remove("Resolution");
    //prefs.remove("CRF");
    //prefs.remove("Preset");


    if (prefs.containsKey("Encoder")) {
      var enc = prefs.getString("Encoder")!;
      if (enc.isNotEmpty) { FfmpegArgumentBuilder.selectedEncoder = enc; }
    }

    if (prefs.containsKey("Hardware")) {
      var hardware = prefs.getString("Hardware")!;
      if (hardware.isNotEmpty) { FfmpegArgumentBuilder.selectedHardware = hardware; }
    }

    if (prefs.containsKey("Colorspace")) {
      var color = prefs.getString("Colorspace")!;
      if (color.isNotEmpty) { FfmpegArgumentBuilder.selectedColorspace = color; }
    }

    if (prefs.containsKey("Resolution")) {
      var res = prefs.getString("Resolution")!;
      if (res.isNotEmpty) { FfmpegArgumentBuilder.selectedResolution = res; }
    }

    if (prefs.containsKey("CRF")) {
      int? crf = prefs.getInt("CRF");
      if (crf != null) { FfmpegArgumentBuilder.SetCRFValue(crf); }
    }

    if (prefs.containsKey("Preset")) {
      var preset = prefs.getString("Preset")!;
      if (preset.isNotEmpty) { FfmpegArgumentBuilder.SetCurrentPresetValue(preset); }
    }

    if (prefs.containsKey("OUTPUT_DIR")) {
      var outputDir = prefs.getString("OUTPUT_DIR")!;
      if (outputDir.isNotEmpty) { FileManager.outputPath = outputDir; }
    }    
  }

  static Future<void> SaveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString("Encoder", FfmpegArgumentBuilder.selectedEncoder);
    prefs.setString("Hardware", FfmpegArgumentBuilder.selectedHardware);
    prefs.setString("Colorspace", FfmpegArgumentBuilder.selectedColorspace);
    prefs.setString("Resolution", FfmpegArgumentBuilder.selectedResolution);
    prefs.setInt("CRF", FfmpegArgumentBuilder.GetCRFValue());
    prefs.setString("Preset", FfmpegArgumentBuilder.GetCurrentPresetValue());
  }

  static Future<void> LoadDefaultSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    FfmpegArgumentBuilder.selectedEncoder = "H264";
    FfmpegArgumentBuilder.selectedHardware = "CPU";
    FfmpegArgumentBuilder.selectedColorspace = "8-bit";
    FfmpegArgumentBuilder.selectedResolution = "4K";
    SetDefaultCRFValues();
    SetDefaultPresetValues();
  }

  static void SetDefaultPresetValues() {
    FfmpegArgumentBuilder.nvidiaPresetValue = "p4";
    FfmpegArgumentBuilder.amdPresetValue = "balance";
    FfmpegArgumentBuilder.intelPresetValue = "medium";
    FfmpegArgumentBuilder.cpuH26XValue = "medium";
    FfmpegArgumentBuilder.cpuAV1Value = "6";
    FfmpegArgumentBuilder.selectedAndroidBitrateMode = "cq";
  }

  static void SetDefaultCRFValues() {
    FfmpegArgumentBuilder.crfValue = 18;
    FfmpegArgumentBuilder.crfAndroidValue = 80;
  }

}