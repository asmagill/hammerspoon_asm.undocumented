hs._asm.undocumented.touchbar.item
==================================

This module is used to create and manipulate touchbar item objects which can added to `hs._asm.undocumented.touchbar.bar` objects and displayed in the Touch Bar of new Macintosh Pro laptops or with the virtual Touch Bar provided by `hs._asm.undocumented.touchbar`.

At present, only simple button type items are supported.

This module requires macOS 10.12.2 or later. Some of the methods (identified in their notes) in this module use undocumented functions and/or framework methods and are not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.

This module is very experimental and is still under development, so the exact functions and methods are subject to change without notice.

TODO:
 * More item types
 * more functions to modify button style/appearance? attributed string support? background color? width?
   * Why does popover fail to show expanded items?  I think fixing this will also allow colorPicker and sharingService to work
   * try minimizing while popover is supposed to show, maybe because we're already a "pop over" and it would work with "Hammerspoon application" touchbars?
 * get canvas max width ala `canvasItem("view")("window")("frame").w`... can we get without creating canvas item first?

See [Examples/quickanddirtyBarExample.lua](Examples/quickanddirtyBarExample.lua) for a *very* basic example.

### Usage
~~~lua
item = require("hs._asm.undocumented.touchbar.item")
~~~

### Contents


##### Module Constructors
* <a href="#newButton">item.newButton([title], [image], [identifier]) -> touchbarItemObject</a>
* <a href="#newCanvas">item.newCanvas(canvas, [identifier]) -> touchbarItemObject</a>
* <a href="#newGroup">item.newGroup([title], [image], [identifier]) -> touchbarItemObject</a>
* <a href="#newSlider">item.newSlider([identifier]) -> touchbarItemObject</a>

##### Module Methods
* <a href="#addToSystemTray">item:addToSystemTray(state) -> touchbarItemObject</a>
* <a href="#buttonImage">item:buttonImage([image]) -> touchbarItemObject | hs.image object</a>
* <a href="#buttonSize">item:buttonSize([size]) -> touchbarItemObject | current value</a>
* <a href="#buttonTitle">item:buttonTitle([title]) -> touchbarItemObject | current value</a>
* <a href="#callback">item:callback([fn | nil]) -> touchbarItemObject | current value</a>
* <a href="#canvasClickColor">item:canvasClickColor([color]) -> touchbarItemObject | current value</a>
* <a href="#canvasWidth">item:canvasWidth([width]) -> touchbarItemObject | current value</a>
* <a href="#customizationLabel">item:customizationLabel([label]) -> touchbarItemObject | current value</a>
* <a href="#enabled">item:enabled([state]) -> touchbarItemObject | current value</a>
* <a href="#groupItems">item:groupItems([itemsTable]) -> touchbarItemObject | current value</a>
* <a href="#groupTouchbar">item:groupTouchbar([touchbar]) -> touchbarItemObject | current value</a>
* <a href="#identifier">item:identifier() -> string</a>
* <a href="#isVisible">item:isVisible() -> boolean</a>
* <a href="#itemType">item:itemType() -> string</a>
* <a href="#presentModalBar">item:presentModalBar(touchbar, [dismissButton]) -> touchbarItemObject</a>
* <a href="#sliderMax">item:sliderMax([value]) -> touchbarItemObject | current value</a>
* <a href="#sliderMaxImage">item:sliderMaxImage([image]) -> touchbarItemObject | current value</a>
* <a href="#sliderMin">item:sliderMin([value]) -> touchbarItemObject | current value</a>
* <a href="#sliderMinImage">item:sliderMinImage([image]) -> touchbarItemObject | current value</a>
* <a href="#sliderValue">item:sliderValue([value]) -> touchbarItemObject | current value</a>
* <a href="#visibilityCallback">item:visibilityCallback([fn | nil]) -> touchbarItemObject | current value</a>
* <a href="#visibilityPriority">item:visibilityPriority([priority]) -> touchbarItemObject | current value</a>

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

- - -

<a name="newCanvas"></a>
~~~lua
item.newCanvas(canvas, [identifier]) -> touchbarItemObject
~~~
Create a new touchbarItem object from an `hs.canvas` object..

Parameters:
 * `canvas`     - The `hs.canvas` object to use as a touchbar item.
 * `identifier` - An optional string specifying the identifier for this touchbar item. Must be unique within the bar the item will be assigned to if specified. If not specified, a new UUID is generated for the item.

Returns:
 * a touchbarItemObject or nil if an error occurs

Notes:
 * The touch bar object will be proportionally resized so that it has a height of 30 if it does not already.
 * If canvas callbacks for `mouseDown`, `mouseUp`, `mouseEnterExit`, and `mouseMove` are enabled, the canvas callback will be invoked as if the left mouse button had been used.

- - -

<a name="newGroup"></a>
~~~lua
item.newGroup([title], [image], [identifier]) -> touchbarItemObject
~~~
Create a new group touchbarItem object which can contain other touchbar items.

Parameters:
 * `identifier` - An optional string specifying the identifier for this touchbar item. Must be unique within the bar the item will be assigned to if specified. If not specified, a new UUID is generated for the item.

Returns:
 * a touchbarItemObject or nil if an error occurs

- - -

<a name="newSlider"></a>
~~~lua
item.newSlider([identifier]) -> touchbarItemObject
~~~
Create a new slider touchbarItem object.

Parameters:
 * `identifier` - An optional string specifying the identifier for this touchbar item. Must be unique within the bar the item will be assigned to if specified. If not specified, a new UUID is generated for the item.

Returns:
 * a touchbarItemObject or nil if an error occurs

Notes:
 * The slider object will expand to fill as much space as it can within the touchbar.

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

<a name="buttonImage"></a>
~~~lua
item:buttonImage([image]) -> touchbarItemObject | hs.image object
~~~
Get or set the image for a button item which was initially given an image when created.

Parameters:
 * `image` - an optional `hs.image` object, or explicit nil, specifying the image for the button item.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newButton](#newButton) constructor.
 * This method will generate an error if an image was not provided when the object was created.
 * Setting the image to nil will remove the image and shrink the button, but not as tightly as the button would appear if it had been initially created without an image at all.

- - -

<a name="buttonSize"></a>
~~~lua
item:buttonSize([size]) -> touchbarItemObject | current value
~~~
Get or set the button touchbar item's button size.

Parameters:
 * `size` - an optional string, default "regular", specifying the button touchbar button size.  Must be one of "regular", "small", or "mini".

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newButton](#newButton) or [hs._asm.undocumented.touchbar.item.newCanvas](#newCanvas) constructors.
 * The button sizes are defined by the macOS operating system and under macOS 10.12 have the following visual effects (this may change with future macOS updates):
   * `regular` - presents the button as a rounded grey rectangle with the image and/or title inside of the grey area.
   * `mini`    - presents the image and/or title of the button without a rounded rectangle background. Takes up less space then `regular`.
   * `small`   - presents the image and/or title of the button without a rounded rectangle background. Takes up less space in the touchbar then `mini`.

- - -

<a name="buttonTitle"></a>
~~~lua
item:buttonTitle([title]) -> touchbarItemObject | current value
~~~
Get or set the title for a button item which was initially given a title when created.

Parameters:
 * `title` - an optional string, or explicit nil, specifying the title for the button item.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newButton](#newButton) constructor.
 * This method will generate an error if a title was not provided when the object was created.
 * Setting the title to nil will remove the title and shrink the button, but not as tightly as the button would appear if it had been initially created without a title at all.

- - -

<a name="callback"></a>
~~~lua
item:callback([fn | nil]) -> touchbarItemObject | current value
~~~
Get or set the callback function for the touchbar item.

Parameters:
 * `fn` - an optional function, or explicit nil to remove, specifying the callback to be invoked when the item is pressed.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * The callback function should return nothing. The arguments provided are type dependent, described here:
   * Items constructed with [hs._asm.undocumented.touchbar.item.newButton](#newButton):
     * the touchbar item itself

   * Items constructed with [hs._asm.undocumented.touchbar.item.newCanvas](#newCanvas):
     * the touchbar item itself
   * Note that if you use `hs.canvas:canvasMouseEvents` and `hs.canvas:mouseCallback` on the canvas object, you can get `mouseDown`, `mouseUp`, `mouseEntered`, `mouseExited`, and `mouseMove` callbacks as if they were generated by the left mouse button.  You do not need to set a touchbar item callback to take advantage of the canvas callbacks.

   * Items constructed with [hs._asm.undocumented.touchbar.item.newGroup](#newGroup):
   * A callback assigned to a group touchbar item will never be invoked; instead if the items within the group have a callback assigned, the specific item within the group will have its callback invoked.

   * Items constructed with [hs._asm.undocumented.touchbar.item.newSlider](#newSlider):
     * the touchbar item itself
     * a number or string as follows:
       * if the image assigned with [hs._asm.undocumented.touchbar.item:sliderMinImage](#sliderMinImage) is touched, the string "minimum".
       * if the image assigned with [hs._asm.undocumented.touchbar.item:sliderMaxImage](#sliderMaxImage) is touched, the string "maximum".
       * if the slider knob is moved to a new position, returns a number between [hs._asm.undocumented.touchbar.item:sliderMin](#sliderMin) and [hs._asm.undocumented.touchbar.item:sliderMax](#sliderMax) indicating the new position.

- - -

<a name="canvasClickColor"></a>
~~~lua
item:canvasClickColor([color]) -> touchbarItemObject | current value
~~~
Get or set the background color displayed when a canvas touchbar item is currently being touched.

Parameters:
 * `color` - an optional table specifying a color as defined in the `hs.drawing.color` module, or an explicit nil to reset it to the default. Defaults to the macOS System Selected Control Color (`hs.drawing.color.colorsFor("System")["selectedControlColor"]`).

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newCanvas](#newCanvas) constructor.
 * To specify that no background color should be displayed when the canvas touchbar item is in an active state, specify a color with an alpha value of 0, e.g. `{ alpha = 0 }`.

- - -

<a name="canvasWidth"></a>
~~~lua
item:canvasWidth([width]) -> touchbarItemObject | current value
~~~
Get or set the width of a canvas touchbar item in the touchbar.

Parameters:
 * `width` - an optional number specifying the width of the canvas touchbar item in the touchbar.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newCanvas](#newCanvas) constructor.

- - -

<a name="customizationLabel"></a>
~~~lua
item:customizationLabel([label]) -> touchbarItemObject | current value
~~~
Get or set the label displayed for the item when the customization panel is being displayed for the touch bar.

Parameters:
 * `label` - an optional string, or explicit nil to reset to an empty string, specifying the label to be displayed with the item when the customization panel is being displayed for the touch bar.  Defaults to an empty string.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

- - -

<a name="enabled"></a>
~~~lua
item:enabled([state]) -> touchbarItemObject | current value
~~~
Get or set whether the touchbar item is enabled (accepting touches) or disabled.

Parameters:
 * `state` - an optional boolean, default true, specifying whether or not the touchbar item is currently enabled.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newButton](#newButton) or [hs._asm.undocumented.touchbar.item.newCanvas](#newCanvas) constructors.

- - -

<a name="groupItems"></a>
~~~lua
item:groupItems([itemsTable]) -> touchbarItemObject | current value
~~~
Get or set the touchbar item objects which belong to this group touchbar item.

Parameters:
 * `itemsTable` - an optional table as an array of touchbar item objects to display when this group touchbar item is present in the touchbar.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newGroup](#newGroup) constructor.
 * The group touchbar item's callback, if set, is never invoked; instead the callback for the items within the group item is invoked when the item is touched.
 * This is a convenience method which creates an `hs._asm.undocumented.touchbar.bar` object and uses [hs._asm.undocumented.touchbar.item:groupTouchbar](#groupTouchbar) to assign the items to the group item.

- - -

<a name="groupTouchbar"></a>
~~~lua
item:groupTouchbar([touchbar]) -> touchbarItemObject | current value
~~~
Get or set the bar object which contains the touchbar items that belong to the group touchbar item.

Parameters:
 * `touchbar` - an optional `hs._asm.undocumented.touchbar.bar` object containing the touchbar items to display when this group touchbar item is present in the touchbar.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newGroup](#newGroup) constructor.
 * The group touchbar item's callback, if set, is never invoked; instead the callback for the items within the group item is invoked when the item is touched.
 * See also [hs._asm.undocumented.touchbar.item:groupItems](#groupItems)

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

<a name="itemType"></a>
~~~lua
item:itemType() -> string
~~~
Returns the type of the touchbar item as a string.

Parameters:
 * None

Returns:
 * the type of the touchbar item as one of the following strings: "buttonWithText", "buttonWithImage", "buttonWithImageAndText", "group", "slider", or "canvas".

Notes:
 * other types may be added in future updates.

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

<a name="sliderMax"></a>
~~~lua
item:sliderMax([value]) -> touchbarItemObject | current value
~~~
Get or set the maximum value for a slider touchbar item.

Parameters:
 * `value` - an optional number specifying the maximum value for a slider touchbar item. This represents the slider's value when the knob of the slider is all the way to the right. Defaults to 1.0.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newSlider](#newSlider) constructor.

- - -

<a name="sliderMaxImage"></a>
~~~lua
item:sliderMaxImage([image]) -> touchbarItemObject | current value
~~~
Get or set the image displayed at the right side of a slider touchbar item.

Parameters:
 * `image` - an optional image, or explicit nil to remove, specifying the image to be displayed at the right side of a slider touchbar item.  Defaults to nil.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newSlider](#newSlider) constructor.
 * When this image is clicked on, the touchbar item's callback, if set, will receive the string "maximum" as it's second argument.

- - -

<a name="sliderMin"></a>
~~~lua
item:sliderMin([value]) -> touchbarItemObject | current value
~~~
Get or set the minimum value for a slider touchbar item.

Parameters:
 * `value` - an optional number specifying the minimum value for a slider touchbar item. This represents the slider's value when the knob of the slider is all the way to the left. Defaults to 0.0.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newSlider](#newSlider) constructor.

- - -

<a name="sliderMinImage"></a>
~~~lua
item:sliderMinImage([image]) -> touchbarItemObject | current value
~~~
Get or set the image displayed at the left side of a slider touchbar item.

Parameters:
 * `image` - an optional image, or explicit nil to remove, specifying the image to be displayed at the left side of a slider touchbar item.  Defaults to nil.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newSlider](#newSlider) constructor.
 * When this image is clicked on, the touchbar item's callback, if set, will receive the string "minimum" as it's second argument.

- - -

<a name="sliderValue"></a>
~~~lua
item:sliderValue([value]) -> touchbarItemObject | current value
~~~
Get or set the current value for a slider touchbar item.

Parameters:
 * `value` - an optional number specifying the value to set for the slider. This value will be automatically constrained to the current minimum and maximum as set by [hs._asm.undocumented.touchbar.item:sliderMin](#sliderMin) and [hs._asm.undocumented.touchbar.item:sliderMax](#sliderMax).

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newSlider](#newSlider) constructor.
 * The slider touchbar items callback, if set, will not be invoked if you use this method to change the slider's value.

- - -

<a name="visibilityCallback"></a>
~~~lua
item:visibilityCallback([fn | nil]) -> touchbarItemObject | current value
~~~
Get or set the visibility callback function for the touchbar item object.

Parameters:
 * `fn` - an optional function, or explicit nil to remove, specifying the visibility callback for the touchbar item object.

Returns:
 * if an argument is provided, returns the touchbarItem object; otherwise returns the current value

Notes:
 * The callback function should expect two arguments, the touchbarItem itself and a boolean indicating the new visibility of the item.  It should return none.

 * See also the notes for [hs._asm.undocumented.touchbar.item:isVisible](#isVisible) and `hs._asm.undocumented.touchbar.bar.visibilityCallback`.

- - -

<a name="visibilityPriority"></a>
~~~lua
item:visibilityPriority([priority]) -> touchbarItemObject | current value
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


