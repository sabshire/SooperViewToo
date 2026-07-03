List of bugs and TODOs that need fixed

============= BUGS =============



============= TODOs =============

- Making HVC1 tagging on MacOS devices a setting? (Not important)
- Make progress show both file and overall progress using a double ring, out ring showing overall progress, while and inner ring shows progress on the file

=================== LOW PRIORITY TODO (After Release) ==========================

- Modify logic to run probes first, this could be used to get frame count for all files at start and use this with frames being rendered per second to estimate encoding time left across all files in total. This would require rewriting a decent chunk of code.

- Save xmap/ymap files for each resolution type instead of for each video. This could limit overwriting files which are the same resolution and don't need to be rewritten. Since most people only probably record in a small amount of resolutions/aspect ratios.

=================== PREVIEW WINDOW TODOS =========================

- Swapping between tabs will cause error if ffplay session hasn't started properly before leaving its tab (Will probably be making ffplay start with a button but still needs fixed)

- 480p doesn't seem to work on ffplay, works on ffmpeg encode though (maybe colorspace issue?)

- FFplay is very slow if file isn't h264. Android is pretty meh state (At least for Pixel 9). Could possibly work on some higher end devices? Maybe try finding a library that can handle remapping for preview like VLC?

- Add a file selector to ffplay preview window widget. Make it only capable of having one selected, so instead of a check box just have a button that says like "Preview" in green. Then that will start the ffplay window preview. 