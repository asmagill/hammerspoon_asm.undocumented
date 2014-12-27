_asm.undocumented.bluetooth
===========================

Functions to get and set undocumented options and features within OS X.  These are undocumented features from the "private" api's for Mac OS X and are not guaranteed to work with any particular version of OS X or at all.  This code was based primarily on code samples and segments found at https://github.com/toy/blueutil.

This submodule provides access to Bluetooth availability and its power state, and the ability to change it.

I make no promises that these will work for you or work at all with any, past, current, or future versions of OS X.  I can confirm only that they didn't crash my machine during testing under 10.10. You have been warned.

### Local Install
~~~bash
$ git clone https://github.com/asmagill/hammerspoon_asm.undocumented
$ cd hammerspoon_asm.undocumented/bluetooth
$ [PREFIX=/usr/local/share/lua/5.2/] [TARGET=`Hammerspoon|Mjolnir`] make install
~~~

Note that if you do not provide `TARGET`, then it defaults to `Hammerspoon`, and if you do not provide `PREFIX`, then it defaults to your particular environments home directory (~/.hammerspoon or ~/.mjolnir).

### Require

~~~lua
bluetooth = require("`base`._asm.undocumented.bluetooth")
~~~

Where `base` is `hs` for Hammerspoon, and `mjolnir` for Mjolnir.

### Functions
~~~lua
bluetooth.available() -> bool
~~~
Returns `true` or `false`, indicating whether bluetooth is available on this machine.

~~~lua
bluetooth.power([bool]) -> bool
~~~
If an argument is provided, set bluetooth power state to on (`true`) or off (`false`) and returns the (possibly new) status. If no argument is provided, then this function returns `true` or `false`, indicating whether bluetooth is currently enabled for this machine.

### License

> Released under MIT license.
>
> Copyright (c) 2014 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
> THE SOFTWARE.
