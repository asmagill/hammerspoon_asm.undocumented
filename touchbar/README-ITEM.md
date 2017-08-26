hs._asm.undocumented.touchbar.item
==================================

This module is used to create and manipulate touchbar item objects which can added to `hs._asm.undocumented.touchbar.bar` objects and displayed in the Touch Bar of new Macintosh Pro laptops or with the virtual Touch Bar provided by `hs._asm.undocumented.touchbar`.

At present, only simple button type items are supported.

This module requires macOS 10.12.2 or later. Some of the methods (identified in their notes) in this module use undocumented functions and/or framework methods and are not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.

This module is very experimental and is still under development, so the exact functions and methods are subject to change without notice.

TODO:
 * More item types
 * `isVisible` is KVO, so add a watcher

See [Examples/quickanddirtyBarExample.lua](Examples/quickanddirtyBarExample.lua) for a *very* basic example.

### Usage
~~~lua
item = require("hs._asm.undocumented.touchbar.item")
~~~

### Contents


##### Module Constructors
* <a href="#newButton">item.newButton([title], [image], [identifier]) -> touchbarItemObject</a>

##### Module Methods
* <a href="#addToSystemTray">item:addToSystemTray(state) -> touchbarItemObject</a>
* <a href="#callback">item:callback([fn | nil]) -> touchbarItemObject | fn</a>
* <a href="#customizationLabel">item:customizationLabel([label]) -> touchbarItemObject | string</a>
* <a href="#identifier">item:identifier() -> string</a>
* <a href="#image">item:image([image]) -> touchbarItemObject | hs.image object</a>
* <a href="#isVisible">item:isVisible() -> boolean</a>
* <a href="#presentModalBar">item:presentModalBar(touchbar, [dismissButton]) -> touchbarItemObject</a>
* <a href="#title">item:title([title]) -> touchbarItemObject | string</a>
* <a href="#visibilityPriority">item:visibilityPriority([priority]) -> touchbarItemObject | number</a>

##### Module Constants
* <a href="#visibilityPriorities">item.visibilityPriorities[]</a>

- - -

### Module Constructors

<a name="newButton"></a>
~~~lua
item.newButton([title], [image], [identifier]) -> touchbarItemObject
~~~
Create a new button touchbarItem object.

Parameters:
 * `title`      - A string specifying the title for the button. Optional if `image` is specified.
 * `image`      - An `hs.image` object specifying the image for the button.  Optional is `title` is specified.
 * `identifier` - An optional string specifying the identifier for this touchbar item. Must be unique within the bar the item will be assigned to if specified. If not specified, a new UUID is generated for the item.

Returns:
 * a touchbarItemObject or nil if an error occurs

Notes:
 * You can change the button's title with [hs._asm.undocumented.touchbar.item:title](#title) only if you initially assign one with this constructor.
 * You can change the button's image with [hs._asm.undocumented.touchbar.item:image](#title) only if you initially assign one with this constructor.
 * If you intend to allow customization of the touch bar, it is highly recommended that you specify an identifier, since the UUID will change each time the item is regenerated (when Hammerspoon reloads or restarts).

### Module Methods

<a name="addToSystemTray"></a>
~~~lua
item:addToSystemTray(state) -> touchbarItemObject
~~~
Add or remove the touchbar item from the System Tray in the touch bar display.

Parameters:
 * `state` - a boolean specifying if the item should be displayed in the System Tray (true) or not (false).

Returns:
 * the touchbarItem object

Notes:
 * The item will only be visible in the System Tray if you have "Touch Bar Shows" set to "App Controls With Control Strip" set in the Keyboard System Preferences.

 * Initial experiments suggest that only one item *from any macOS application currently running* may be added to the System Tray at a time.
 * Adding a new item will hide any previous item assigned; however they do appear to stack, so removing an existing item with this method, or if it has bar object attached with [hs._asm.undocumented.touchbar.item:presentModalBar](#presentModalBar) and you dismiss the bar with `hs._asm.undocumented.touchbar.bar:dismissModalBar`, the previous item should become visible again.

 * At present, there is no known way to determine which item is currently displayed in the System Tray or detect when a specific item is replaced ([hs._asm.undocumented.touchbar.item:isVisible](#isVisible) returns false). Please submit an issue if you know of a solution.

 * This method uses undocumented functions and/or framework methods and is not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.

- - -

<a name="callback"></a>
~~~lua
item:callback([fn | nil]) -> touchbarItemObject | fn
~~~
Get or set the callback function for the touchbar item.

Parameters:
 * `fn` - an optional function, or explicit nil to remove, specifying the callback to be invoked when the item is pressed.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * The callback function should expect one argument, the touchbarItemObject, and return none.

- - -

<a name="customizationLabel"></a>
~~~lua
item:customizationLabel([label]) -> touchbarItemObject | string
~~~
Get or set the label displayed for the item when the customization panel is being displayed for the touch bar.

Parameters:
 * `label` - an optional string, or explicit nil to reset to an empty string, specifying the label to be displayed with the item when the customization panel is being displayed for the touch bar.  Defaults to an empty string.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

- - -

<a name="identifier"></a>
~~~lua
item:identifier() -> string
~~~
Returns the identifier for the touchbarItem object

Parameters:
 * None

Returns:
 * the identifier for the item as a string

- - -

<a name="image"></a>
~~~lua
item:image([image]) -> touchbarItemObject | hs.image object
~~~
Get or set the image for a button item which was initially given an image when created.

Parameters:
 * `image` - an optional `hs.image` object, or explicit nil, specifying the image for the button item.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if an image was not provided when the object was created.
 * Setting the image to nil will remove the image and shrink the button, but not as tightly as the button would appear if it had been initially created without an image at all.

- - -

<a name="isVisible"></a>
~~~lua
item:isVisible() -> boolean
~~~
Returns a boolean indicating whether or not the item is currently visible in the bar that it is assigned to.

Parameters:
 * None

Returns:
 * a boolean specifying whether or not the item is currently visible in the bar that it is assigned to.

Notes:
 * If the bar that the item is assigned to has been visible at some point in the past, and the item was visible at that time, this method will return true even if the bar is not currently visible. If you want to know if the item is visible in the touch bar display *right now*, you should use `reallyVisible = bar:isVisible() and item:isVisible()`

- - -

<a name="presentModalBar"></a>
~~~lua
item:presentModalBar(touchbar, [dismissButton]) -> touchbarItemObject
~~~
Presents a bar in the touch bar display modally and hides this item if it is present in the System Tray of the touch bar display.

Parameters:
 * `touchbar` - An `hs._asm.undocumented.touchbar.bar` object of the bar to display modally in the touch bar display.
 * `dismissButton` - an optional boolean, default true, specifying whether or not the system escape (or its current replacement) button should be replaced by a button to remove the modal bar from the touch bar display when pressed.

Returns:
 * the touchbarItem object

Notes:
 * If you specify `dismissButton` as false, then you must use `hs._asm.undocumented.touchbar.bar:minimizeModalBar` or `hs._asm.undocumented.touchbar.bar:dismissModalBar` to remove the modal bar from the touch bar display.
   * Use `hs._asm.undocumented.touchbar.bar:minimizeModalBar` if you want the item to reappear in the System Tray (if it was present before displaying the bar).

 * If you do not have "Touch Bar Shows" set to "App Controls With Control Strip" set in the Keyboard System Preferences, the modal bar will only be displayed when the Hammerspoon application is the frontmost application.

 * This method is actually a wrapper to `hs._asm.undocumented.touchbar.bar:presentModalBar` provided for convenience.

 * This method uses undocumented functions and/or framework methods and is not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.

- - -

<a name="title"></a>
~~~lua
item:title([title]) -> touchbarItemObject | string
~~~
Get or set the title for a button item which was initially given a title when created.

Parameters:
 * `title` - an optional string, or explicit nil, specifying the title for the button item.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if a title was not provided when the object was created.
 * Setting the title to nil will remove the title and shrink the button, but not as tightly as the button would appear if it had been initially created without a title at all.

- - -

<a name="visibilityPriority"></a>
~~~lua
item:visibilityPriority([priority]) -> touchbarItemObject | number
~~~
Get or set the visibility priority for the touchbar item.

Parameters:
 * `priority` - an optional number specifying the visibility priority for the item.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * If their are more items to be presented in the touch bar display than space permits, items with a lower visibility priority will be hidden first.
 * Some predefined visibility values are defined in [hs._asm.undocumented.touchbar.item.visibilityPriorities](#visibilityPriorities), though others are allowed. The default priority for an item object is `hs._asm.undocumented.touchbar.item.visibilityPriorities.normal`.

### Module Constants

<a name="visibilityPriorities"></a>
~~~lua
item.visibilityPriorities[]
~~~
Predefined visibility priorities for use with [hs._asm.undocumented.touchbar.item:visibilityPriority](#visibilityPriority)

A table containing key-value pairs of predefined visibility priorities used when the touch bar isn't large enough to display all of the items which are eligible for presentation. Items with lower priorities are hidden first. These numbers are only suggestions and other numbers are also valid for use with [hs._asm.undocumented.touchbar.item:visibilityPriority](#visibilityPriority).

Predefined values are as follows:
 * `low`   - -1000.0
 * `normal`-     0.0 (this is the default value assigned to an item when it is first created)
 * `high`  -  1000.0

- - -

### License

>     The MIT License (MIT)
>
> Copyright (c) 2017 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
>


