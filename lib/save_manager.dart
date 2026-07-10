import 'package:shared_preferences/shared_preferences.dart';
import 'package:sooperview/file_manager.dart';
import 'package:sooperview/ffmpeg_argument_builder.dart';

class SaveManager {

  static Future<void> loadSettings() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();

    if (await prefs.containsKey("Encoder")) {
      var enc = await prefs.getString("Encoder");
      if (enc != null && enc.isNotEmpty) { FfmpegArgumentBuilder.selectedEncoder = enc; }
    }

    if (await prefs.containsKey("Hardware")) {
      var hardware = await prefs.getString("Hardware");
      if (hardware != null && hardware.isNotEmpty) { FfmpegArgumentBuilder.selectedHardware = hardware; }
    }

    if (await prefs.containsKey("Colorspace")) {
      var color = await prefs.getString("Colorspace");
      if (color != null && color.isNotEmpty) { FfmpegArgumentBuilder.selectedColorspace = color; }
    }

    if (await prefs.containsKey("Resolution")) {
      var res = await prefs.getString("Resolution");
      if (res != null && res.isNotEmpty) { FfmpegArgumentBuilder.selectedResolution = res; }
    }

    if (await prefs.containsKey("CRF")) {
      int? crf = await prefs.getInt("CRF");
      if (crf != null) { FfmpegArgumentBuilder.setCRFValue(crf); }
    }

    if (await prefs.containsKey("Preset")) {
      var preset = await prefs.getString("Preset");
      if (preset != null && preset.isNotEmpty) { FfmpegArgumentBuilder.setCurrentPresetValue(preset); }
    }

    if (await prefs.containsKey("OUTPUT_DIR")) {
      var outputDir = await prefs.getString("OUTPUT_DIR");
      if (outputDir != null && outputDir.isNotEmpty) { FileManager.outputPath = outputDir; }
    }    
  }

  static Future<void> saveSettings() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();

    prefs.setString("Encoder", FfmpegArgumentBuilder.selectedEncoder);
    prefs.setString("Hardware", FfmpegArgumentBuilder.selectedHardware);
    prefs.setString("Colorspace", FfmpegArgumentBuilder.selectedColorspace);
    prefs.setString("Resolution", FfmpegArgumentBuilder.selectedResolution);
    prefs.setInt("CRF", FfmpegArgumentBuilder.getCRFValue());
    prefs.setString("Preset", FfmpegArgumentBuilder.getCurrentPresetValue());
  }

  static Future<void> loadDefaultSettings() async {
    FfmpegArgumentBuilder.selectedEncoder = "H264";
    FfmpegArgumentBuilder.selectedHardware = "CPU";
    FfmpegArgumentBuilder.selectedColorspace = "8-bit";
    FfmpegArgumentBuilder.selectedResolution = "4K";
    setDefaultCRFValues();
    setDefaultPresetValues();
  }

  static void setDefaultPresetValues() {
    FfmpegArgumentBuilder.nvidiaPresetValue = "p4";
    FfmpegArgumentBuilder.amdPresetValue = "balance";
    FfmpegArgumentBuilder.intelPresetValue = "medium";
    FfmpegArgumentBuilder.cpuH26XValue = "medium";
    FfmpegArgumentBuilder.cpuAV1Value = "6";
    FfmpegArgumentBuilder.selectedAndroidBitrateMode = "cq";
  }

  static void setDefaultCRFValues() {
    FfmpegArgumentBuilder.crfValue = 18;
    FfmpegArgumentBuilder.crfAndroidValue = 80;
  }

}