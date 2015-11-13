_asm.undocumented.spaces
========================

Functions to get and set undocumented options and features within OS X.  These are undocumented features from the "private" api's for Mac OS X and are not guaranteed to work with any particular version of OS X or at all.  This code was based primarily on code samples and segments found at https://github.com/toy/blueutil.

This module provides the functionality, as it was in Hydra and Mjolnir, for `spaces`.

These functions utilize private API's within the OS X internals, and are known to have unpredictable behavior under Mavericks and Yosemite when "Displays have separate Spaces" is checked under the Mission Control system preferences.

This module is based primarily on code from the previous incarnation of Mjolnir by [Steven Degutis](https://github.com/sdegutis/).

I make no promises that these will work for you or work at all with any, past, current, or future versions of OS X.  I can confirm only that they didn't crash my machine during testing under 10.10. You have been warned.

### Installation

This does require that you have XCode or the XCode Command Line Tools installed.  See the App Store application or https://developer.apple.com to install these if necessary.

~~~bash
$ git clone https://github.com/asmagill/hammerspoon_asm.undocumented undocumented
$ cd undocumented/spaces
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make install
~~~

If Hammerspoon.app is in your /Applications folder, you may leave `HS_APPLICATION=/Applications` out and if you are fine with the module being installed in your Hammerspoon configuration directory, you may leave `PREFIX=~/.hammerspoon` out as well.  For most people, it will probably be sufficient to just type `make install`.

### Require

~~~lua
spaces = require("hs._asm.undocumented.spaces")
~~~

### Functions

~~~lua
spaces.animating([screen]) -> boolean
~~~
Returns the state of space changing animation for the specified monitor, or for any monitor if no parameter is specified.  To specify a specific monitor, use its `hs.screen` object.

~~~lua
spaces.count() -> number
~~~
The number of spaces you currently have.

~~~lua
spaces.currentspace() -> number
~~~
The index of the space you're currently on, 1-indexed (as usual).

~~~lua
spaces.movetospace(number)
~~~
Switches to the space at the given index, 1-indexed (as usual).

~~~lua
spaces.screensHaveSeparateSpaces() -> boolean
~~~
Returns true or false representing the status of the "Displays Have Separate Spaces" option within Mission Control.

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
