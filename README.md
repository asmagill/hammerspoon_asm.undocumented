_asm.undocumented
=================

*Note: Development on the Mjolnir branch is suspended as I no longer use Mjolnir even for testing.  The master branch will be refactored and focus solely on Hammerspoon.*

Organizational space for Hammerspoon/Mjolnir modules using undocumented or Private APIs.  To the best of my knowledge, all other modules I've created use only standard, stock OSX API functionality.  Since a large number were ported from a previous project that led to [Mjolnir](https://github.com/sdegutis/mjolnir) and later [Hammerspoon](https://github.com/Hammerspoon/hammerspoon), I can't say that with absolute certainty, but it is certainly what I aim for.

Any module I knowingly create which uses any undocumented or private API will be listed here.  For other modules, especially those which are not part of the core application (Hammerspoon) or already in Luarocks (Mjolnir), check https://github.com/asmagill/hammerspoon_asm.

Because these use undocumented features, the mantra "Caveat Emptor" rings even more true than usual.  I make no claims or guarantees that these will work for you or that they will work with any past, present, or future version of OS X.  All I will state is that they do not crash on my primary machine, a MacBook Air running 10.10.X, and that they provide at least some of the desired functions (or else why bother?) for me.  I also try most of my modules under a VirtualBox Guest running 10.8, but not as rigorously or thoroughly.  Unless otherwise indicated, each module will run successfully under Hammerspoon or Mjolnir, and specific instructions for installing in your environment are provided in the subdirectories README.

I hope they work for you as well, but re-read the above paragraph and the License, and decide for yourself.

Most of these features currently come from one or both of the following sources:

 1. [Undocumented Goodness](https://code.google.com/p/undocumented-goodness/)
 2. [iTerm2's CGSInternal folder](https://github.com/gnachman/iterm2)

### Sub Modules (See folder README.md)
The following submodules are located in this repository for organizational purposes.  Installation instructions for each will be given in the appropriate subdirectory.

|Module                      | Available | Description                                                                |
|:---------------------------|:---------:|:---------------------------------------------------------------------------|
|_asm.undocumented.bluetooth | Git       | Toggle bluetooth power and discoverability.                                |
|_asm.undocumented.cgsdebug  | Git       | Includes Hydra's hydra.shadow function and other _windowserver debug stuff |
|_asm.undocumented.coredock  | Git       | Manipulate Dock features including position, tilesize, etc.                |
|_asm.undocumented.spaces    | Git       | Access OS X Spaces functionality.                                          |

I am uncertain at this time if I will be providing these and future modules via Luarocks... I am less than impressed with it's limited flexibility concerning makefiles and local variances.  If there is interest in precompiled binaries for these modules, post an issue and I'll see what the interest level is.

### Documentation

The json files provided at this level contain the documentation for all of these modules in a format suitable for use with Hammerspoon's `hs.doc.fromJSONFile(file)` function.  In the near future, I hope to extend this support to Mjolnir and provide a simple mechanism for combining multiple json files into one set of documents for use within the appropriate console and Dash docsets.

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