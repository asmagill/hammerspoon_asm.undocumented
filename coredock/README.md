_asm.undocumented.coredock
==========================

Functions to get and set undocumented options and features within OS X.  These are undocumented features from the "private" api's for Mac OS X and are not guaranteed to work with any particular version of OS X or at all.  This code was based primarily on code samples and segments found at (https://code.google.com/p/undocumented-goodness/) and (https://code.google.com/p/iterm2/source/browse/branches/0.10.x/CGSInternal/CGSDebug.h?r=2).

This submodule provides access to CoreDock related features.  This allows you to adjust the Dock's position, pinning, hiding, magnification and animation settings.

I make no promises that these will work for you or work at all with any, past, current, or future versions of OS X.  I can confirm only that they didn't crash my machine during testing under 10.10. You have been warned.

Note that the top orientation and dock pinning has not been supported even within the private APIs for some time and may disappear from here in a future release unless another solution can be found.  It is provided here for testing and to encourage suggestions if someone is aware of a solution that has not yet been tried.

### Installation

This does require that you have XCode or the XCode Command Line Tools installed.  See the App Store application or https://developer.apple.com to install these if necessary.

~~~bash
$ git clone https://github.com/asmagill/hammerspoon_asm.undocumented undocumented
$ cd undocumented/coredock
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make install
~~~

If Hammerspoon.app is in your /Applications folder, you may leave `HS_APPLICATION=/Applications` out and if you are fine with the module being installed in your Hammerspoon configuration directory, you may leave `PREFIX=~/.hammerspoon` out as well.  For most people, it will probably be sufficient to just type `make install`.

### Require

~~~lua
coredock = require("hs._asm.undocumented.coredock")
~~~

### Functions

~~~lua
coredock.animationEffect([effect]) -> effect
~~~
If an argument is provided, set the Dock hiding animation effect to the effect indicated by effect number and return the (possibly new) effect number.  If no argument is provided, then this function returns the current effect number. You can reference `hs._asm.undocumented.coredock.options.effect` to select the appropriate number for the desired effect or dereference the result.

~~~lua
coredock.autoHide([bool]) -> bool
~~~
If an argument is provided, set the Dock Hiding state to on or off and return the (possibly new) hiding state.  If no argument is provided, then this function returns the current hiding state.

~~~lua
coredock.magnification([bool]) -> bool
~~~
If an argument is provided, set the Dock Magnification state to on or off and return the (possibly new) magnification state.  If no argument is provided, then this function returns the current magnification state.

~~~lua
coredock.magnificationSize([float]) -> float
~~~
If an argument is provided, set the Dock icon magnification size to a number between 0.0 and 1.0 and return the (possibly new) magnification size.  If no argument is provided, then this function returns the current magnification size as a number between 0.0 and 1.0.

~~~lua
coredock.orientation([orientation]) -> orientation
~~~
If an argument is provided, set the Dock orientation to the position indicated by orientation number and return the (possibly new) orientation number.  If no argument is provided, then this function returns the current orientation number. You can reference `hs._asm.undocumented.coredock.options.orientation` to select the appropriate number for the desired orientation or dereference the result.

~~~lua
coredock.pinning([pinning]) -> pinning
~~~
If an argument is provided, set the Dock pinning to the position indicated by pinning number and return the (possibly new) pinning number.  If no argument is provided, then this function returns the current pinning number. You can reference `hs._asm.undocumented.coredock.options.pinning` to select the appropriate number for the desired pinning or dereference the result.

~~~lua
coredock.restartDock()
~~~
This function restarts the user's Dock instance.  This is not required for any of the functionality of this module, but does come in handy if your dock gets "misplaced" when you change monitor resolution or detach an external monitor (I've seen this occasionally when the Dock is on the left or right.)

~~~lua
coredock.tileSize([float]) -> float
~~~
If an argument is provided, set the Dock icon tile size to a number between 0.0 and 1.0 and return the (possibly new) tile size.  If no argument is provided, then this function returns the current tile size as a number between 0.0 and 1.0.

### Variables

~~~lua
coredock.options[]
~~~
Connivence table of all currently defined coredock options. You can reference this by name to get the number required in the above functions or by number to get a human readable result from the number returned by the functions above.

Note that the top orientation has not been supported even within the private APIs for some time and may disappear from here in a future release unless another solution can be found.
* options.orientation[]  -- an array of the orientation options available for `orientation`
  * top         -- put the dock at the top of the monitor
  * bottom      -- put the dock at the bottom of the monitor
  * left        -- put the dock at the left of the monitor
  * right       -- put the dock at the right of the monitor

Note that dock pinning has not been supported even within the private APIs for some time and may disappear from here in a future release unless another solution can be found.
* options.pinning[]  -- an array of the pinning options available for `pinning`
  * start       -- pin the dock at the start of its orientation
  * middle      -- pin the dock at the middle of its orientation
  * end         -- pin the dock at the end of its orientation

   Note that the suck animation is not displayed in the System Preferences panel correctly, but does remain in effect as long as you do not change this specific field while in the Preferences panel for the Dock.
* options.effect[]   -- an array of the dock animation options for  `animation_effect`
  * genie       -- use the genie animation
  * scale       -- use the scale animation
  * suck        -- use the suck animation


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
