_asm.undocumented
=================

**Over the course of the next few months, I anticipate either archiving most of these or moving them into the https://github.com/asmagill/hammerspoon_asm umbrella. With the exception of the bluetooth, touchbar, and touchdevice modules, most of this is outdated enough that it either doesn't work or at least doesn't work well.  I expect that it may be of some limited informational use, but no further maintenance is expected except for the three already listed.**

- - -

Organizational space for Hammerspoon modules using undocumented or Private APIs.

Any module I knowingly create which uses any undocumented or private API will be listed here.  For other modules, especially those which are not part of the core Hammerspoon application please check https://github.com/asmagill/hammerspoon_asm.

Because they use undocumented features, the mantra "Caveat Emptor" rings even more true than usual.  I make no claims or guarantees that these will work for you or that they will work with any past, present, or future version of OS X.  All I will state is that they do not crash on my primary machine, a MacBook Air running 10.10.X, and that they provide at least some of the desired functions (or else why bother?) for me.

I hope they work for you as well, but re-read the above paragraph and the License, and decide for yourself.

### Sub Modules (See folder README.md)
The following submodules are located in this repository for organizational purposes.  Installation instructions for each will be given in the appropriate subdirectory.

|Module                      | Description                                                                         |
|:---------------------------|:------------------------------------------------------------------------------------|
| hs._asm.undocumented.bluetooth | Toggle bluetooth power and discoverability.                                     |
| hs._asm.undocumented.cgsdebug  | Includes Hydra's hydra.shadow function and other _windowserver debug stuff |
| hs._asm.undocumented.coredock  | Manipulate Dock features including position, tilesize, etc.                      |
| [hs._asm.undocumented.spaces](https://github.com/asmagill/hs._asm.undocumented.spaces)    | (Archived, for informational purposes only)  |

### Installation

*See https://github.com/asmagill/hammerspoon_asm/blob/master/README.md for details about building this module as a Universal library*

Each sub-module has compilation instructions in the accompanying README file.  Installing this way will ensure that you have the latest and greatest.

At various points (i.e. when I feel like it or remember) I will add a precompiled release.  These will most likely contain all of the modules currently in this repository unless otherwise noted in the release notes.  You can always remove the ones you don't want, of course.

Download the release from https://github.com/asmagill/hammerspoon_asm.undocumented/releases and issue the following commands:

~~~sh
$ cd ~/.hammerspoon
$ tar -xzf ~/Downloads/undocumented-vX.Y.tar.gz
~~~

If you are upgrading an existing version, remember to fully stop and restart Hammerspoon to insure that the new version is the one being used.

### Documentation

For now, see the README.md in each folder.  Since the Hammerspoon document system supports external sources, I hope to one day add that to the modules as well.

### More Information
Most of the undocumented API information that is used within these modules I gleaned from one or more of the following sources:

 1. [Undocumented Goodness](https://code.google.com/p/undocumented-goodness/)
 2. [iTerm2's CGSInternal folder](https://github.com/gnachman/iterm2)
 3. [NUIKit/CGSInternal](https://github.com/NUIKit/CGSInternal)

### License

> Released under MIT license.
>
> Copyright (c) 2014 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
>
