hs._asm.undocumented.bluetooth
==============================

This submodule provides access to Bluetooth availability and its power state, and the ability to change it.

This module utilizes undocumented or unpublished functions to manipulate options and features within OS X.  These are from "private" api's for Mac OS X and are not guaranteed to work with any particular version of OS X or at all.  This code was based primarily on code samples and segments found at https://github.com/toy/blueutil.

I make no promises that these will work for you or work at all with any, past, current, or future versions of OS X.  I can confirm only that they didn't crash my machine during testing under 10.10. You have been warned.


### Installation

A precompiled version of this module can be found in this directory with a name along the lines of `bluetooth-v0.x.tar.gz`. This can be installed by downloading the file and then expanding it as follows:

~~~sh
$ cd ~/.hammerspoon # or wherever your Hammerspoon init.lua file is located
$ tar -xzf ~/Downloads/bluetooth-v0.x.tar.gz # or wherever your downloads are located
~~~

If you wish to build this module yourself, and have XCode installed on your Mac, the best way (you are welcome to clone the entire repository if you like, but no promises on the current state of anything else) is to download `init.lua`, `internal.m`, and `Makefile` (at present, nothing else is required) into a directory of your choice and then do the following:

~~~sh
$ cd wherever-you-downloaded-the-files
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make docs install
~~~

If your Hammerspoon application is located in `/Applications`, you can leave out the `HS_APPLICATION` environment variable, and if your Hammerspoon files are located in their default location, you can leave out the `PREFIX` environment variable.  For most people it will be sufficient to just type `make docs install`.

As always, whichever method you chose, if you are updating from an earlier version it is recommended to fully quit and restart Hammerspoon after installing this module to ensure that the latest version of the module is loaded into memory.

### Usage
~~~lua
bluetooth = require("hs._asm.undocumented.bluetooth")
~~~

### Contents


##### Module Functions
* <a href="#available">bluetooth.available() -> bool</a>
* <a href="#discoverable">bluetooth.discoverable([state]) -> bool</a>
* <a href="#power">bluetooth.power([state]) -> bool</a>

- - -

### Module Functions

<a name="available"></a>
~~~lua
bluetooth.available() -> bool
~~~
Returns true or false, indicating whether bluetooth is available on this machine.

Parameters:
 * None

Returns:
 * true if bluetooth is available on this machine, false if it is not; returns nil if bluetooth framework unavailable (this has been observed in some virtual machines)

- - -

<a name="discoverable"></a>
~~~lua
bluetooth.discoverable([state]) -> bool
~~~
Get or set bluetooth discoverable state.

Parameters:
 * state - an optional boolean value indicating whether bluetooth the machine should be discoverable (true) or not (false)

Returns:
 * the (possibly changed) current value; returns nil if bluetooth framework unavailable (this has been observed in some virtual machines)

Notes:
 * use of this method to change discoverability has been observed to cause connected devices to disconnect in rare cases; use at your own risk.

- - -

<a name="power"></a>
~~~lua
bluetooth.power([state]) -> bool
~~~
Get or set bluetooth power state.

Parameters:
 * state - an optional boolean value indicating whether bluetooth power should be turned on (true) or off (false)

Returns:
 * the (possibly changed) current value; returns nil if bluetooth framework unavailable (this has been observed in some virtual machines)

- - -

### License

>     The MIT License (MIT)
>
> Copyright (c) 2020 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
>


