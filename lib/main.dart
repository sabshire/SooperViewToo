import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:sooperview/FFmpegManager.dart';
import 'package:sooperview/FileManager.dart';


import 'package:sooperview/ffmpeg_argument_builder.dart';
import 'package:sooperview/ui/EncodingProgressWidget.dart';
import 'package:sooperview/ui/FileListWidget.dart';
import 'package:sooperview/ui/sooper_EncoderButton.dart';
// UI imports
import 'package:sooperview/ui/sooper_dropdown.dart';
import 'package:sooperview/ui/sooper_ffplay_preview_window.dart';
import 'package:sooperview/ui/sooper_labelwidget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FFmpegKitExtended.initialize();
  //FileManager.SetOutputDir();
  /*if (Platform.isIOS || Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Makes status bar background transparent
    statusBarIconBrightness: Brightness.dark, // Dark icons for light backgrounds
    statusBarBrightness: Brightness.light, // For iOS status bar icons
  ));
  }*/

  FileManager.CleanCache(); // Cleans cache on startup (Only affects mobile devices)

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Encoder',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const HomeTabScreen(),
      builder: (context, child) {
        return DropTarget(
          onDragEntered: (details) => print('DEBUG: file entered the window!'),
          onDragExited: (details) => print('DEBUG: file left the window!'),
          onDragDone: (details) async {
            for (final file in details.files) {
              File f = File(file.path);
              FileManager.AddFile([f]);
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class SooperViewScreen extends StatefulWidget {
  const SooperViewScreen({super.key});

  @override
  State<SooperViewScreen> createState() => SooperViewMainState();
}

class SooperViewMainState extends State<SooperViewScreen> {
  //File? _selectedFile;
  //bool _isEncoding = false;
  //String? _outputPath;
  //int _totalFrames = 0;
  //FFmpegSession? ffmpeg;

  /*
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      //final filePath = result.files.single.path;
      List<File> files = [];
      for (int fileNum = 0; fileNum < result.files.length; fileNum++) {
        if (result.files[fileNum].path == null) continue;
        files.add(File(result.files[fileNum].path!));
      }
      
      setState(() {
        FileManager.AddFile(files);
      });
    }
  }
  
  Future<void> _openOutputFolder() async {
    if (Platform.isAndroid) {
      // Android uses specific intent targets to reach the Files app safely
      await openFileManager(
        androidConfig: AndroidConfig(
          folderType: AndroidFolderType.other,
          folderPath: await FileManager.GetOutputDir(),
        ),
      );
    } 
    else if (Platform.isWindows) {
      // Windows: Trigger explorer.exe
      await Process.run('explorer.exe', [await FileManager.GetOutputDir()]);
    } 
    else if (Platform.isMacOS) {
      // macOS: Trigger the 'open' command to launch Finder
      await Process.run('open', [await FileManager.GetOutputDir()]);
    } 
    else if (Platform.isLinux) {
      // Linux: Trigger xdg-open to load the desktop-assigned file manager
      await Process.run('xdg-open', [await FileManager.GetOutputDir()]);
    }
  }*/

  @override
  Widget build(BuildContext context) {
    /*if (FFmpegManager.encoderStatus.value != SooperEncoderStatus.none) {
      return EncodingProgressWidget(
        progress: ((FileManager.currentFile) / FileManager.selectedFileList.length) + (FFmpegManager.ffmpegProgressPercentage / 100 / FileManager.selectedFileList.length),
        onExitWidget: () {
          setState(() {
            FFmpegManager.encoderStatus.value = SooperEncoderStatus.none;
          });
        },
        onCancelEncode: () {
          setState(() {
            switch(FFmpegManager.encoderStatus.value) {
              case SooperEncoderStatus.encode:
              case SooperEncoderStatus.probe:
              FFmpegManager.encoderStatus.value = SooperEncoderStatus.cancelling;
                FFmpegKitExtended.cancelAllSessions();
              break;

              case SooperEncoderStatus.finish:
              default:
                FFmpegManager.encoderStatus.value = SooperEncoderStatus.none;
              break;
            }
          });
        },
        );
    }*/

    return Scaffold(
      //appBar: AppBar(title: const Text('SooperView Dev'),),
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
                const SizedBox(height: 20),

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
                const SizedBox(height: 20), // Padding
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

                // End of Dropdowns

                //if (FileManager.GetCurrentFile() != null)  // Displays Current Selected File
                //  Text(_status),

                /*const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: (FFmpegManager.encoderStatus == SooperEncoderStatus.none) ? pickFile : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Choose Video'),
                ),

                const SizedBox(height: 20),
                SooperEncoderButton(
                  onProgressUpdate: (progressPercentage) => setState(() {
                    // This should call update for Progress Percentage?
                  }),
                  onComplete: () {
                    setState(() {
                      FileManager.moveExistingTempFile("sooperview-temp.${FfmpegArgumentBuilder.videoFormat}", FileManager.GetCurrentSelectedFile()!);
                    });
                  },
                  onFinished: () {
                    setState(() {
                      // Finished all encoding
                    });
                  },
                  onCancelled: () {
                    setState(() {
                      // On Cancelled called and completed
                    });
                  },
                  onPressed: () => setState(() {
                    
                  }),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _openOutputFolder,
                  child: const Text('Open Output'),
                ),*/
                /*if (FFmpegManager.ffmpegProgressPercentage > -1) ...[
                  const SizedBox(height: 20),
                  Text("Progress: ${FFmpegManager.ffmpegProgressPercentage.toStringAsFixed(2)}% ${(FileManager.currentFile + 1)}/${FileManager.selectedFileList.length}"),
                ],
                if (FFmpegManager.ffmpegSession != null) ...[ // TODO: This needs to be better and work in all stages of encoding / ffprobe. Currently only works during encoding!
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: FFmpegManager.ffmpegSession!.cancel,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Cancel'),
                  ),
                ],*/
                //if (FileManager.fileList.isNotEmpty)
                /*if (true)
                  FileListWidget(
                    fileList: FileManager.fileList,
                    onRemove: (file) => setState(() => FileManager.RemoveFile(file)),
                    onSelectionUpdate: () => setState(() {
                      
                    }),
                  ),
                */
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FileSelectorScreen extends StatefulWidget {
  const FileSelectorScreen({super.key});

  @override
  State<FileSelectorScreen> createState() => FileSelectorScreenState();
}

class FileSelectorScreenState extends State<FileSelectorScreen> {

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      //final filePath = result.files.single.path;
      List<File> files = [];
      for (int fileNum = 0; fileNum < result.files.length; fileNum++) {
        if (result.files[fileNum].path == null) continue;
        files.add(File(result.files[fileNum].path!));
      }
      
      setState(() {
        FileManager.AddFile(files);
      });
    }
  }
  
  Future<void> _openOutputFolder() async {
    if (Platform.isAndroid) {
      // Android uses specific intent targets to reach the Files app safely
      await openFileManager(
        androidConfig: AndroidConfig(
          folderType: AndroidFolderType.other,
          folderPath: await FileManager.GetOutputDir(),
        ),
      );
    } 
    else if (Platform.isWindows) {
      // Windows: Trigger explorer.exe
      await Process.run('explorer.exe', [await FileManager.GetOutputDir()]);
    } 
    else if (Platform.isMacOS) {
      // macOS: Trigger the 'open' command to launch Finder
      await Process.run('open', [await FileManager.GetOutputDir()]);
    } 
    else if (Platform.isLinux) {
      // Linux: Trigger xdg-open to load the desktop-assigned file manager
      await Process.run('xdg-open', [await FileManager.GetOutputDir()]);
    }
  }

  @override
  Widget build(BuildContext context) {

    /*if (FFmpegManager.encoderStatus.value != SooperEncoderStatus.none) {
      return EncodingProgressWidget(
        progress: ((FileManager.currentFile) / FileManager.selectedFileList.length) + (FFmpegManager.ffmpegProgressPercentage / 100 / FileManager.selectedFileList.length),
        onExitWidget: () {
          setState(() {
            FFmpegManager.encoderStatus.value = SooperEncoderStatus.none;
          });
        },
        onCancelEncode: () {
          setState(() {
            switch(FFmpegManager.encoderStatus.value) {
              case SooperEncoderStatus.encode:
              case SooperEncoderStatus.probe:
              FFmpegManager.encoderStatus.value = SooperEncoderStatus.cancelling;
                FFmpegKitExtended.cancelAllSessions();
              break;

              case SooperEncoderStatus.finish:
              default:
                FFmpegManager.encoderStatus.value = SooperEncoderStatus.none;
              break;
            }
          });
        },
        );
    }*/

    return Column(
      children: [
        SizedBox(height: 20),
        FileListWidget(
          fileList: FileManager.fileList,
          onRemove: (file) => FileManager.RemoveFile(file),
          onSelectionUpdate: () => setState(() {
            // Updates on selecting for UI
          }),
        ),

        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: (FFmpegManager.encoderStatus.value == SooperEncoderStatus.none) ? pickFile : null,
          icon: const Icon(Icons.add),
          label: const Text('Choose Video'),
        ),

        const SizedBox(height: 20),
        SooperEncoderButton(
          /*onProgressUpdate: (progressPercentage) => setState(() {
            // This should call update for Progress Percentage?
          }),
          onComplete: () {
            setState(() {
              FileManager.moveExistingTempFile("sooperview-temp.${FfmpegArgumentBuilder.videoFormat}", FileManager.GetCurrentSelectedFile()!);
            });
          },
          onFinished: () {
            setState(() {
              // Finished all encoding
            });
          },
          onCancelled: () {
            setState(() {
              // On Cancelled called and completed
            });
          },
          onPressed: () => setState(() {
            
          }),*/
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: _openOutputFolder,
          child: const Text('Open Output'),
        ),

      ],
    );
  }
}


class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({Key? key}) : super(key: key);

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
                  progress: ((FileManager.currentFile) / FileManager.selectedFileList.length) + 
                            (progressPercentage / 100 / FileManager.selectedFileList.length),
                  onExitWidget: () {
                    FFmpegManager.encoderStatus.value = SooperEncoderStatus.none;
                  },
                  onCancelEncode: () {
                    switch (FFmpegManager.encoderStatus.value) {
                      case SooperEncoderStatus.encode:
                      case SooperEncoderStatus.probe:
                        FFmpegManager.encoderStatus.value = SooperEncoderStatus.cancelling;
                        FFmpegKitExtended.cancelAllSessions();
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
          length: 3,
          initialIndex: 1,
          child: Scaffold(
            bottomNavigationBar: const TabBar(
              tabs: [
                Tab(text: 'Settings'),
                Tab(text: 'File Selector'),
                Tab(text: 'Preview (BETA)')
              ],
              indicatorColor: Colors.white,
              indicatorWeight: 3.0,
            ),
            body: const TabBarView(
              children: [
                SooperViewScreen(),
                FileSelectorScreen(),
                SooperViewPreviewer(),
              ],
            ),
          ),
        );
      },
    );
  }
}