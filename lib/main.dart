import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
//import 'package:file_selector/file_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_file_manager/open_file_manager.dart';


import 'package:sooperview/ffmpeg_argument_builder.dart';
import 'package:sooperview/remap_file_generator.dart';
// UI imports
import 'package:sooperview/ui/sooper_dropdown.dart';
import 'package:sooperview/ui/sooper_labelwidget.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FFmpegKitExtended.initialize();
  
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Encoder',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const SooperViewScreen(),
    );
  }
}

class SooperViewScreen extends StatefulWidget {
  const SooperViewScreen({super.key});

  @override
  State<SooperViewScreen> createState() => SooperViewMainState();
}

class SooperViewMainState extends State<SooperViewScreen> {
  File? _selectedFile;
  bool _isEncoding = false;
  String _status = 'Select a video file';
  String? _outputPath;
  int _totalFrames = 0;
  FFmpegSession? ffmpeg;

  double _progressPercentage = -1;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.single.path;
      if (filePath != null) {
        setState(() {
          _selectedFile = File(filePath);
          _status = 'Selected: ${result.files.single.name}';
        });
      }
    }
  }
  
  Future<void> _openOutputFolder() async {
    if (Platform.isAndroid) {
      // Android uses specific intent targets to reach the Files app safely
      await openFileManager(
        androidConfig: AndroidConfig(
          folderType: AndroidFolderType.other,
          folderPath: _outputPath!,
        ),
      );
    } 
    else if (Platform.isWindows) {
      // Windows: Trigger explorer.exe
      await Process.run('explorer.exe', [_outputPath!]);
    } 
    else if (Platform.isMacOS) {
      // macOS: Trigger the 'open' command to launch Finder
      await Process.run('open', [_outputPath!]);
    } 
    else if (Platform.isLinux) {
      // Linux: Trigger xdg-open to load the desktop-assigned file manager
      await Process.run('xdg-open', [_outputPath!]);
    }
  }

  Future<void> encode() async {
    setState(() => _isEncoding = true);

    //await pickOutputDir();
    var cmd = FfmpegArgumentBuilder.buildFfprobeArguments(_selectedFile!.path);
    await FFprobeKit.getMediaInformationAsync("'${_selectedFile!.path}'", onComplete: (session) async {
    //await FFprobeKit.executeAsync(cmd, onComplete: (session) async {
      print(session.command);
      final result = session.getLogsAsString();
      print(result);

      final jsonRegex = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegex.stringMatch(result!);
      if (match == null) {
        throw const FormatException("No valid JSON block found in output string.");
      }
      final metadata = VideoProperties.fromFfprobeJson(match);
      _totalFrames = metadata.totalFrames;
      print("${metadata.width}x${metadata.height} | ${metadata.duration}");
      var mapLoc = await RemapFileGenerator().generateCrossPlatformRemapFiles(metadata);
      print(mapLoc["xmap"]);
      print(mapLoc["ymap"]);
      final command = await FfmpegArgumentBuilder.BuildFFmpegArguments(_selectedFile!.path, mapLoc["xmap"]!, mapLoc["ymap"]!, _selectedResolution, _selectedHardware, _selectedEncoder, _selectedColorspace);
      print(command);

      ffmpeg = FFmpegKit.createSession(command);
      // set media duration for progress calculation
      final duration = metadata.duration * 1000;
      ffmpeg!.setExpectedTranscodingDuration(
        Duration(milliseconds: duration.toInt()),
      );

      await ffmpeg!.executeAsync(completeCallback: (session) async {
        final returnCode = session.getReturnCode();
        final logs = session.getLogsAsString();
        
        if (ReturnCode.isSuccess(returnCode)) {
          print("Finish logs: $logs");
          print("Command success");

          // Move to new folder
          final Directory tempDir = await getTemporaryDirectory();
          final path = p.join(tempDir.path, "sooperview-temp.mp4");
          moveExistingFile(File(path));
        } else if (ReturnCode.isCancel(returnCode)) {
          print("Command cancelled");
        } else {
          print("Command failed with state ${session.getState()}");
          print("Stack trace: $logs");
        }
        setState(() {
          _isEncoding = false;
          _progressPercentage = -1;
          ffmpeg = null;
        });
      }, statisticsCallback: (statistics) async {
        print(statistics.transcodingProgressPercent);
        setState(() {
          _progressPercentage = ((statistics.videoFrameNumber / _totalFrames) * 100);
        });
      },);
    });
  }

  Future<void> moveExistingFile(File sourceFile) async {
    // 1. Verify the source file actually exists
    if (!await sourceFile.exists()) {
      print("Source file does not exist!");
      return;
    }

    // 2. Let the user choose the target directory
    String? targetDirectory = await FilePicker.platform.getDirectoryPath();

    if (targetDirectory != null) {
      // 3. Extract the original filename (e.g., 'document.pdf')
      setState(() {
        _outputPath = targetDirectory;
      });
      //String fileName = p.basename(sourceFile.path);
      String fileName = "SV-${p.basename(_selectedFile!.path)}";

      // 4. Construct the complete destination path
      String newPath = '$targetDirectory/$fileName';

      try {
        // 5. Move the file
        // Note: rename() works instantly if on the same storage partition.
        await sourceFile.rename(newPath);
        print('File successfully moved to: $newPath');
      } catch (e) {
        // Fallback: If moving across different partitions (e.g., internal to SD card),
        // rename() might fail. Use copy and delete instead.
        final newFile = await sourceFile.copy(newPath);
        await sourceFile.delete();
        print('File copied and original deleted at: ${newFile.path}');
      }
    } else {
      print('User canceled the folder selection.');
    }
  }

  String _selectedEncoder = "H264";
  final List<String> _encoderItems = ["H264", "HEVC", "AV1"];

  String _selectedHardware = "CPU";
  //final List<String> _hardwareItems = ["CPU", "NVIDIA", "AMD", "INTEL", "Android"];

  String _selectedResolution = "4K";
  final List<String> _resolutionItems = ["4K", "1440p", "1080p", "720p"];

  String _selectedColorspace = "8-bit";
  final List<String> _colorspaceItems = ["8-bit", "10-bit"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SooperView Dev'),),
      body: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 300, maxWidth: double.infinity),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
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
                          dropdownValue: _selectedHardware, 
                          dropdownValueList: FfmpegArgumentBuilder.GetAvailableHardwareList(),
                          onStateChanged: (hardwareValue) {
                            setState(() {
                              _selectedHardware = hardwareValue ?? 'CPU';
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: SooperLabel(
                        label: "Encoder",
                        child: SooperDropdown(
                          dropdownValue: _selectedEncoder, 
                          dropdownValueList: _encoderItems,
                          onStateChanged: (encoderValue) {
                            setState(() {
                              _selectedEncoder = encoderValue ?? 'H264';
                            });
                          },
                        ),
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Settings Row 2: Resolution and CRF
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: SooperLabel(
                        label: "Resolution",
                        child: SooperDropdown(
                          dropdownValue: _selectedResolution, 
                          dropdownValueList: _resolutionItems,
                          onStateChanged: (resolutionValue) {
                            setState(() {
                              _selectedResolution = resolutionValue ?? '4K';
                            });
                          },
                        ),
                      )
                    ),
                    Expanded(
                      child: SooperLabel(
                        label: "CRF",
                        child: SooperDropdown<int>(
                          dropdownValue: FfmpegArgumentBuilder.GetCRFValue(_selectedHardware), 
                          dropdownValueList: FfmpegArgumentBuilder.GetCRFValueList(_selectedHardware),
                          onStateChanged: (int? crfValue) {
                            setState(() {
                              FfmpegArgumentBuilder.SetCRFValue(_selectedHardware, crfValue!);
                            });
                          },
                        ),
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Padding
                // Row 3 (Colorspace, Presets)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: SooperLabel(
                        label: "Colorspace",
                        child: SooperDropdown(
                          dropdownValue: _selectedColorspace, 
                          dropdownValueList: _colorspaceItems,
                          onStateChanged: (colorspaceValue) {
                            setState(() {
                              _selectedColorspace = colorspaceValue ?? '8-bit';
                            });
                          },
                        ),
                      )
                    ),

                    // PRESET VALUES
                    if (_selectedHardware == "CPU" || _selectedHardware == "NVIDIA" || _selectedHardware == "AMD" || _selectedHardware == "INTEL" /*|| _selectedHardware == "Android"*/)
                      Expanded(
                        child: SooperLabel(
                          label: "Preset",
                          child: SooperDropdown(
                            dropdownValue: FfmpegArgumentBuilder.GetCurrentPresetValue(_selectedHardware, _selectedEncoder), 
                            dropdownValueList: FfmpegArgumentBuilder.presetValues[(_selectedHardware, _selectedEncoder)]!,
                            onStateChanged: (presetValue) {
                              setState(() {
                                setState(() => FfmpegArgumentBuilder.SetCurrentPresetValue(_selectedHardware, _selectedEncoder, presetValue!));
                              });
                            },
                          ),
                        )
                      ),
                    ],
                ),

                // End of Dropdowns

                if (_selectedFile != null)  // Displays Current Selected File
                  Text(_status),

                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _isEncoding ? null : pickFile,
                  icon: const Icon(Icons.add),
                  label: const Text('Choose Video'),
                ),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isEncoding ? null : encode,
                  icon: const Icon(Icons.play_arrow, color: Colors.green,),
                  label: const Text('Encode'),
                ),
                if (_outputPath != null) ...[
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _openOutputFolder,
                    child: const Text('Open Output'),
                  ),
                ],
                if (_progressPercentage > -1) ...[
                  const SizedBox(height: 20),
                  Text("Progress: ${_progressPercentage.toStringAsFixed(2)}%"),
                ],
                if (ffmpeg != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: ffmpeg!.cancel,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}