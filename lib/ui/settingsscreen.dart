import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sooperview/ffmpeg_manager.dart';
import 'package:sooperview/save_manager.dart';
import 'package:sooperview/ffmpeg_argument_builder.dart';
import 'package:sooperview/ui/sooper_dropdown.dart';
import 'package:sooperview/ui/sooper_labelwidget.dart';

class SooperViewSettingsScreen extends StatefulWidget {
  const SooperViewSettingsScreen({super.key});

  @override
  State<SooperViewSettingsScreen> createState() => SooperViewSettingsState();
}

class SooperViewSettingsState extends State<SooperViewSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('SooperView Dev'),),
      body: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 300, 
          maxWidth: double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,              
                spacing: 20,
                children: [
                  const SizedBox(height: 20),
                  
                  // Settings Row 1: Hardware and Encoder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: SooperLabel(
                          label: "Hardware",
                          child: SooperDropdown(
                            dropdownValue: FfmpegArgumentBuilder.selectedHardware, 
                            dropdownValueList: FfmpegArgumentBuilder.GetAvailableHardwareList(),
                            onStateChanged: (hardwareValue) {
                              setState(() {
                                FfmpegArgumentBuilder.selectedHardware = hardwareValue ?? 'CPU';
                              });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: SooperLabel(
                          label: "Encoder",
                          child: SooperDropdown(
                            dropdownValue: FfmpegArgumentBuilder.selectedEncoder, 
                            dropdownValueList: FfmpegArgumentBuilder.encoderItems,
                            onStateChanged: (encoderValue) {
                              setState(() {
                                FfmpegArgumentBuilder.selectedEncoder = encoderValue ??  FfmpegArgumentBuilder.encoderItems[0];
                              });
                            },
                          ),
                        )
                      ),
                    ],
                  ),

                  // Settings Row 2: Resolution and CRF
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: SooperLabel(
                          label: "Resolution",
                          child: SooperDropdown(
                            dropdownValue: FfmpegArgumentBuilder.selectedResolution, 
                            dropdownValueList: FfmpegArgumentBuilder.resolutionItems,
                            onStateChanged: (resolutionValue) {
                              setState(() {
                                FfmpegArgumentBuilder.selectedResolution = resolutionValue ?? FfmpegArgumentBuilder.resolutionItems[0];
                              });
                            },
                          ),
                        )
                      ),
                      Expanded(
                        child: SooperLabel(
                          label: "CRF",
                          child: SooperDropdown<int>(
                            dropdownValue: FfmpegArgumentBuilder.GetCRFValue(), 
                            dropdownValueList: FfmpegArgumentBuilder.GetCRFValueList(),
                            onStateChanged: (int? crfValue) {
                              setState(() {
                                FfmpegArgumentBuilder.SetCRFValue(crfValue!);
                              });
                            },
                          ),
                        )
                      ),
                    ],
                  ),
                  // Row 3 (Colorspace, Presets)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: SooperLabel(
                          label: "Colorspace",
                          child: SooperDropdown(
                            dropdownValue: FfmpegArgumentBuilder.selectedColorspace, 
                            dropdownValueList: FfmpegArgumentBuilder.colorspaceItems,
                            onStateChanged: (colorspaceValue) {
                              setState(() {
                                FfmpegArgumentBuilder.selectedColorspace = colorspaceValue ?? '8-bit';
                              });
                            },
                          ),
                        )
                      ),

                      // PRESET VALUES
                      if (FfmpegArgumentBuilder.selectedHardware == "CPU" || FfmpegArgumentBuilder.selectedHardware == "NVIDIA" || FfmpegArgumentBuilder.selectedHardware == "AMD" || FfmpegArgumentBuilder.selectedHardware == "INTEL")
                        Expanded(
                          child: SooperLabel(
                            label: "Preset",
                            child: SooperDropdown(
                              dropdownValue: FfmpegArgumentBuilder.GetCurrentPresetValue(), 
                              dropdownValueList: FfmpegArgumentBuilder.GetCurrentPresetList()!,
                              onStateChanged: (presetValue) {
                                setState(() {
                                  setState(() => FfmpegArgumentBuilder.SetCurrentPresetValue(presetValue!));
                                });
                              },
                            ),
                          )
                        ),
                      ],
                  ),                

                  // Row 4 (Load and Save Settings Buttons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    spacing: 16,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: ((FFmpegManager.encoderStatus.value != SooperEncoderStatus.none)) ? null : () async {
                            await SaveManager.loadDefaultSettings();
                            setState(() {
                              // Load Default Settings done
                            });
                          },
                          label: const Text('Load Defaults'),
                        ),
                      ),

                      // Save Settings Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: ((FFmpegManager.encoderStatus.value != SooperEncoderStatus.none)) ? null : () async {
                            await SaveManager.saveSettings();
                            setState(() {
                              // Save New Settings done
                            });
                          },
                          icon: const Icon(Icons.save, color: Colors.blue,),
                          label: const Text('Save Settings'),
                        ), 
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}