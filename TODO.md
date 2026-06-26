List of bugs that need fixed (I added this recently so some older bugs I probably forgot about need to be added)

============= BUGS =============

- Swapping between tabs will cause error if ffplay session hasn't started properly before leaving its tab (Will probably be making ffplay start with a button but still needs fixed)

- 480p doesn't seem to work on ffplay, works on ffmpeg encode though (maybe colorspace issue?)


============= TODOs =============

- FFplay is very slow if file isn't h264. Android is pretty meh state (At least for Pixel 9). Could possibly work on some higher end devices? Maybe try finding a library that can handle remapping for preview like VLC?

- Add a file selector to ffplay preview window widget. Make it only capable of having one selected, so instead of a check box just have a button that says like "Preview" in green. Then that will start the ffplay window preview. 

- Make HVC1 file tagging a setting! This is mostly useful for apple devices!

- Figure out if MacOS has a hardware encoder for AV1

- Add button to set / change output folder location. (Also display current output folder)

- Add button to save current settings