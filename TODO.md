List of bugs that need fixed (I added this recently so some older bugs I probably forgot about need to be added)

============= BUGS =============

- Swapping between tabs will cause error if ffplay session hasn't started properly before leaving its tab (Will probably be making ffplay start with a button but still needs fixed)

- 480p doesn't seem to work on ffplay, works on ffmpeg encode though (maybe colorspace issue?)

- Cache doesn't clean itself. Grows overtime everytime you add a file/encode


============= TODOs =============

- FFplay is very slow if file isn't h264. Android is pretty meh state (At least for Pixel 9). Could possibly work on some higher end devices? Maybe try finding a library that can handle remapping for preview like VLC?

- Split up encoder settings and file selector to separate windows to make it look more clean on small devices. No scroll! Maybe make it encode button be on the corner like a floating button or two. (For start cancel)

- Add a file selector to ffplay preview window widget. Make it only capable of having one selected, so instead of a check box just have a button that says like "Preview" in green. Then that will start the ffplay window preview. 