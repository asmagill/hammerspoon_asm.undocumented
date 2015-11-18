_asm.undocumented.cgsdebug
==========================

***NOTE: This module does not work under OS X 10.11 due to security restrictions added to limit which applications can make change requests to the window server.  I am looking for a work around, but it doesn't look promising.  Please file an issue if you are aware of a work around or have any ideas.***

Functions to get and set undocumented options and features within OS X.  These are undocumented features from the "private" api's for Mac OS X and are not guaranteed to work with any particular version of OS X or at all.  This code was based primarily on code samples and segments found at (https://code.google.com/p/undocumented-goodness/) and (https://code.google.com/p/iterm2/source/browse/branches/0.10.x/CGSInternal/CGSDebug.h?r=2).

This submodule provides access to CGSDebug related features.  Most notably, this contains the hydra.shadow(bool) functionality, and a specific function is provided for just that functionality.

I make no promises that these will work for you or work at all with any, past, current, or future versions of OS X.  I can confirm only that they didn't crash my machine during testing under 10.10. You have been warned.

### Installation

This does require that you have XCode or the XCode Command Line Tools installed.  See the App Store application or https://developer.apple.com to install these if necessary.

~~~bash
$ git clone https://github.com/asmagill/hammerspoon_asm.undocumented undocumented
$ cd undocumented/cgsdebug
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make install
~~~

If Hammerspoon.app is in your /Applications folder, you may leave `HS_APPLICATION=/Applications` out and if you are fine with the module being installed in your Hammerspoon configuration directory, you may leave `PREFIX=~/.hammerspoon` out as well.  For most people, it will probably be sufficient to just type `make install`.

### Require

~~~lua
cgsdebug = require("hs._asm.undocumented.cgsdebug")
~~~

### Functions

~~~lua
cgsdebug.get(option) -> boolean
~~~
Returns a boolean indicating whether the specified CGSDebug option is set or not where `option` is a number corresponding to a label defined in `cgsdebug.options[]`.

~~~lua
cgsdebug.set(option, boolean)
~~~
Enables (value == true) or disables (value == false) the specified CGSDebug option where `option` is a number corresponding to a label defined in `cgsdebug.options[]`.

~~~lua
cgsdebug.clear()
~~~
Clears all of the CGSDebug option flags.

~~~lua
cgsdebug.getMask() -> number
~~~
Returns the numeric value representing the bitmask of all currently set CGSDebug options.

~~~lua
cgsdebug.shadow(bool)
~~~
Sets whether OSX apps have shadows.

### Variables

~~~lua
cgsdebug.options[]
~~~
Convenience table of the currently known debug options.

| Option                   | Description |
|:-------------------------|-------------|
| flashScreenUpdates       | All screen updates are flashed in yellow. Regions under a DisableUpdate are flashed in orange. Regions that are hardware accellerated are painted green. |
| colorByAccelleration     | Colors windows green if they are accellerated, otherwise red. Doesn't cause things to refresh properly - leaves excess rects cluttering the screen. |
| noShadows                | Disables shadows on all windows. |
| noDelayAfterFlash        | Setting this disables the pause after a flash when using FlashScreenUpdates or FlashIdenticalUpdates. |
| autoflushDrawing         | Flushes the contents to the screen after every drawing operation. |
| showMouseTrackingAreas   | Highlights mouse tracking areas. Doesn't cause things to refresh correctly - leaves excess rectangles cluttering the screen. |
| flashIdenticalUpdates    | Flashes identical updates in red. |
| dumpWindowListToFile     | Dumps a list of windows to /tmp/WindowServer.winfo.out. This is what Quartz Debug uses to get the window list. |
| dumpConnectionListToFile | Dumps a list of connections to /tmp/WindowServer.cinfo.out. |
| verboseLogging           | Dumps a very verbose debug log of the WindowServer to /tmp/CGLog_WinServer_<PID>. |
| verboseLoggingAllApps    | Dumps a very verbose debug log of all processes to /tmp/CGLog_<NAME>_<PID>. |
| dumpHotKeyListToFile     | Dumps a list of hotkeys to /tmp/WindowServer.keyinfo.out. |
| dumpSurfaceInfo          | Dumps SurfaceInfo? to /tmp/WindowServer.sinfo.out |
| dumpOpenGLInfoToFile     | Dumps information about OpenGL extensions, etc to /tmp/WindowServer.glinfo.out. |
| dumpShadowListToFile     | Dumps a list of shadows to /tmp/WindowServer.shinfo.out. |
| dumpWindowListToPlist    | Dumps a list of windows to `/tmp/WindowServer.winfo.plist`. This is what Quartz Debug on 10.5 uses to get the window list. |
| dumpResourceUsageToFiles | Dumps information about an application's resource usage to `/tmp/CGResources_<NAME>_<PID>`. |

### License

> Released under MIT license.
>
> Copyright (c) 2015 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
