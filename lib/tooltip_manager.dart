class TooltipManager {
  static String getHardwareTooltip() {
    return "CPU or GPU (Nvidia, Intel, or AMD) encoding.\n\nCPU encoding is slower, but produces marginally better quality.\nGPU encoding is much faster.  Choose your brand of GPU";
  }

  static String getEncoderTooltip() {
    return "The type of encoding to use for the output video.";
  }

  static String getResolutionTooltip() {
    return "The output resolution for the encoded video.";
  }

  static String getCRFTooltip() {
    return "Valid values from 0 to 51.\n\n0 is losless encoding, while 51 is the worst possible encoding.\nValue of 17 or 18 is visually lossless or very close.";
  }

  static String getColorspaceTooltip() {
    return "10bit color or 8bit color";
  }

  static String getPresetTooltip() {
    return "Encoding presets, higher numerical value is better.  Slower encoding is better.";
  }

  static String getLoadDefaultsTooltip() {
    return "Load the application default settings";
  }

  static String getSaveSettingsTooltip() {
    return "Save the current settings as your preferred settings for encoding.\n\nThese will be loaded when the application opens.";
  }

  static String getFileListTooltip() {
    return "The list of files to encode.\n\nOnly checked files will be encoded.";
  }

  static String getChooseFilesTooltip() {
    return "Add files to be encoded";
  }

  static String getOutputFolderTooltip() {
    return "Folder where encoded files will be saved";
  }

  static String getSetOutputFolderTooltip() {
    return "Change the folder where encoded files will be saved";
  }

  static String getEncodeTooltip() {
    return "Encode the selected files and save them into the output folder";
  }

  static String getSetingsTooltip() {
    return "Switch the Settings screen to make changes to the encode settings";
  }

  static String getFileSelectorTooltip() {
    return "Switch to the File Selector screen to choose which files to encode";
  }

  static String getCancelTooltip() {
    return "Cancel encoding all files";
  }
}