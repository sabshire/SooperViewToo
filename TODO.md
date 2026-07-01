List of bugs and TODOs that need fixed

============= BUGS =============


============= TODOs =============

- Making HVC1 tagging on MacOS devices a setting? (Not important)

- Add current video being encoded file name to progress page

- Hide AV1 encoder on MacOS and iPhone, Apple does not current support AV1 encoding on MacOS and iPhone, only decoding

- Convert FfmpegArgumentBuilder.encoderItems to a Map with a String as the key and List<string> as value. Use this to get available encoders for each hardware type. This will allow hiding specific encoders on hardware.

=================== PREVIEW WINDOW TODOS =========================

- Swapping between tabs will cause error if ffplay session hasn't started properly before leaving its tab (Will probably be making ffplay start with a button but still needs fixed)

- 480p doesn't seem to work on ffplay, works on ffmpeg encode though (maybe colorspace issue?)

- FFplay is very slow if file isn't h264. Android is pretty meh state (At least for Pixel 9). Could possibly work on some higher end devices? Maybe try finding a library that can handle remapping for preview like VLC?

- Add a file selector to ffplay preview window widget. Make it only capable of having one selected, so instead of a check box just have a button that says like "Preview" in green. Then that will start the ffplay window preview. 