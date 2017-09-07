hs._asm.undocumented.touchbar.bar
=================================

This module is used to create and manipulate bar objects which can be displayed in the Touch Bar of new Macintosh Pro laptops or with the virtual Touch Bar provided by `hs._asm.undocumented.touchbar`.

At present, bar objects can be presented modally under Hammerspoon control but cannot be attached directly to the Hammerspoon console or webview objects to dynamically appear as application focus changes; this is expected to change in the future.

This module requires macOS 10.12.2 or later. Some of the methods (identified in their notes) in this module use undocumented functions and/or framework methods and are not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.

This module is very experimental and is still under development, so the exact functions and methods are subject to change without notice.

TODO:
 * touch bars for the console and webviews
 * rework orginization so bar in root, current root in `virtual`

See [Examples/quickanddirtyBarExample.lua](Examples/quickanddirtyBarExample.lua) for a *very* basic example.

### Usage
~~~lua
bar = require("hs._asm.undocumented.touchbar.bar")
~~~

### Contents


##### Module Constructors
* <a href="#new">bar.new() -> barObject</a>

##### Module Functions
* <a href="#toggleCustomization">bar.toggleCustomization() -> None</a>

##### Module Methods
* <a href="#customizableIdentifiers">bar:customizableIdentifiers([identifiersTable]) -> barObject | table</a>
* <a href="#customizationLabel">bar:customizationLabel([label]) -> barObject | string</a>
* <a href="#defaultIdentifiers">bar:defaultIdentifiers([identifiersTable]) -> barObject | table</a>
* <a href="#dismissModalBar">bar:dismissModalBar() -> barObject</a>
* <a href="#escapeKeyReplacement">bar:escapeKeyReplacement([identifier]) -> barObject | string</a>
* <a href="#isVisible">bar:isVisible() -> boolean</a>
* <a href="#itemForIdentifier">bar:itemForIdentifier([identifier]) -> touchbarItemObject | nil</a>
* <a href="#itemIdentifiers">bar:itemIdentifiers() -> table</a>
* <a href="#minimizeModalBar">bar:minimizeModalBar() -> barObject</a>
* <a href="#presentModalBar">bar:presentModalBar([itemObject], [dismissButton]) -> barObject</a>
* <a href="#principleItem">bar:principleItem([identifier]) -> barObject | string</a>
* <a href="#requiredIdentifiers">bar:requiredIdentifiers([identifiersTable]) -> barObject | table</a>
* <a href="#templateItems">bar:templateItems([itemsTable]) -> barObject | table</a>
* <a href="#visibilityCallback">bar:visibilityCallback([fn | nil]) -> barObject | fn</a>

##### Module Constants
* <a href="#builtInIdentifiers">bar.builtInIdentifiers[]</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
bar.new() -> barObject
~~~
Creates a new bar object

Parameters:
 * None

Returns:
 * a new bar object

### Module Functions

<a name="toggleCustomization"></a>
~~~lua
bar.toggleCustomization() -> None
~~~
(See Notes) Toggle's the Touch Bar customization panel for the Hammerspoon application

Parameters:
 * None

Returns:
 * None

Notes:
 * At present this function is not useful; it is expected to be more useful when Hammerspoon specific views can provide their own touchbars.

 * The customization panel allows modification of the current bar visible for the macOS application triggering the request within that applications resolver chain -- as such, it can only modify touchbar's attached to the Hammerspoon console or webview objects.
 * The customization panel cannot modify modally displayed bar objects.

### Module Methods

<a name="customizableIdentifiers"></a>
~~~lua
bar:customizableIdentifiers([identifiersTable]) -> barObject | table
~~~
Get or set an array of strings specifying the identifiers of the touchbar items that can be added or removed from the bar object through user customization.

Parameters:
 * `identifiersTable` - an optional table containing strings specifying the identifiers of touchbar items that can be added or removed from the bar object through user customization.

Returns:
 * If an argument is provided, returns the barObject; otherwise returns the current value.

Notes:
 * the identifiers specified must belong to touchbar items already assigned to the bar object with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems) or one of the built in identifier values defined in [hs._asm.undocumented.touchbar.bar.builtInIdentifiers](#builtInIdentifiers).

- - -

<a name="customizationLabel"></a>
~~~lua
bar:customizationLabel([label]) -> barObject | string
~~~
Get or set the customization label for saving and restoring user customizations for the bar.

Parameters:
 * `label` - an optional string, or explicit nil to disable, specifying the customization label for saving and restoring user customizations for the bar; defaults to nil.

Returns:
 * If an argument is provided, returns the barObject; otherwise returns the current value.

- - -

<a name="defaultIdentifiers"></a>
~~~lua
bar:defaultIdentifiers([identifiersTable]) -> barObject | table
~~~
Get or set an array of strings specifying the identifiers of the touchbar items added to the bar object by default, before any user customization.

Parameters:
 * `identifiersTable` - an optional table containing strings specifying the identifiers of touchbar items added to the bar object by default, before any user customization.

Returns:
 * If an argument is provided, returns the barObject; otherwise returns the current value.

Notes:
 * the identifiers specified must belong to touchbar items already assigned to the bar object with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems) or one of the built in identifier values defined in [hs._asm.undocumented.touchbar.bar.builtInIdentifiers](#builtInIdentifiers).

- - -

<a name="dismissModalBar"></a>
~~~lua
bar:dismissModalBar() -> barObject
~~~
Dismiss the bar from the touch bar display by removing it if it is currently being displayed modally.

Parameters:
 * None

Returns:
 * the barObject

Notes:
 * If an `itemObject` was specified with [hs._asm.undocumented.touchbar.bar:presentModalBar](#presentModalBar) or if the bar was displayed with `hs._asm.undocumented.touchbar.item:presentModalBar`, this method will ***not*** restore the item to the system tray.

 * This method uses undocumented functions and/or framework methods and is not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.

- - -

<a name="escapeKeyReplacement"></a>
~~~lua
bar:escapeKeyReplacement([identifier]) -> barObject | string
~~~
Get or set the item which replaces the system escape key for the bar.

Parameters:
 * `identifer` - an optional string, or explicit nil to disable, specifying the item which replaces the system escape key for the bar; defaults to nil.

Returns:
 * If an argument is provided, returns the barObject; otherwise returns the current value.

Notes:
 * This method has no effect on modally displayed bars.

 * the identifier specified must belong to a touchbar items already assigned to the bar object with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems).

- - -

<a name="isVisible"></a>
~~~lua
bar:isVisible() -> boolean
~~~
Returns a boolean indicating whether the bar object is currently visible in the laptop or virtual Touch Bar.

Parameters:
 * None

Returns:
 * a boolean value indicating whether or not the touchbar represented by the object is currently being displayed in the laptop or virtual Touch Bar.

Notes:
 * The value returned by this method changes as expected when the [hs._asm.undocumented.touchbar.bar:dismissModalBar](#dismissModalBar) or [hs._asm.undocumented.touchbar.bar:minimizeModalBar](#minimizeModalBar) methods are used.
 * It does *NOT* reliably change when when the system dismiss button is used (when the second argument to [hs._asm.undocumented.touchbar.bar:presentModalBar](#presentModalBar) or `hs._asm.undocumented.touchbar.item:presentModalBar` is true (or not present)).  This is being investigated but at present no workaround is known.

- - -

<a name="itemForIdentifier"></a>
~~~lua
bar:itemForIdentifier([identifier]) -> touchbarItemObject | nil
~~~
Returns the touchbarItemObject for the identifier specified.

Parameters:
 * `identifier` - a string specifying the touchbarItem object to get from the items assigned to the bar with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems).

Returns:
 * the touchbarItem object for the item specified or nil if no such item has been assigned to the bar.

- - -

<a name="itemIdentifiers"></a>
~~~lua
bar:itemIdentifiers() -> table
~~~
Returns an array of strings specifying the identifiers of the touchbar items currently presented by the bar object.

Parameters:
 * None

Returns:
 * an array of strings specifying the identifiers of the touchbar items currently presented by the bar object.

Notes:
 * If the user has not customized the bar, the list of identifiers will match the list provided by [hs._asm.undocumented.touchbar.bar:defaultIdentifiers()](#defaultIdentifiers).

- - -

<a name="minimizeModalBar"></a>
~~~lua
bar:minimizeModalBar() -> barObject
~~~
Dismiss the bar from the touch bar display by minimizing it if it is currently being displayed modally.

Parameters:
 * None

Returns:
 * the barObject

Notes:
 * If an `itemObject` was specified with [hs._asm.undocumented.touchbar.bar:presentModalBar](#presentModalBar) or if the bar was displayed with `hs._asm.undocumented.touchbar.item:presentModalBar`, this method ***will*** restore the item to the system tray.

 * This method is the same as pressing the `dismissButton` if it was not set to false when [hs._asm.undocumented.touchbar.bar:presentModalBar](#presentModalBar) or `hs._asm.undocumented.touchbar.item:presentModalBar` was invoked.

 * This method uses undocumented functions and/or framework methods and is not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.

- - -

<a name="presentModalBar"></a>
~~~lua
bar:presentModalBar([itemObject], [dismissButton]) -> barObject
~~~
Presents the bar in the touch bar display modally.

Parameters:
 * `itemObject`    - an optional `hs._asm.undocumented.touchbar.item` object which, if currently attached to the system tray, will be hidden while the bar is visible modally.
 * `dismissButton` - an optional boolean, default true, specifying whether or not the system escape (or its current replacement) button should be replaced by a button to remove the modal bar from the touch bar display when pressed.

Returns:
 * the barObject

Notes:
 * If you specify `dismissButton` as false, then you must use [hs._asm.undocumented.touchbar.bar:minimizeModalBar](#minimizeModalBar) or [hs._asm.undocumented.touchbar.bar:dismissModalBar](#dismissModalBar) to remove the modal bar from the touch bar display.

 * If you do not have "Touch Bar Shows" set to "App Controls With Control Strip" set in the Keyboard System Preferences, the modal bar will only be displayed when the Hammerspoon application is the frontmost application.

 * If you specify `itemObject` and the object is not currently attached to the system tray (see `hs._asm.undocumented.touchbar.item:addToSystemTray)`, or if you do not have "Touch Bar Shows" set to "App Controls With Control Strip" set in the Keyboard System Preferences, providing this argument has no effect.

 * This method uses undocumented functions and/or framework methods and is not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.

- - -

<a name="principleItem"></a>
~~~lua
bar:principleItem([identifier]) -> barObject | string
~~~
Get or set the principle item for the bar.

Parameters:
 * `identifer` - an optional string, or explicit nil to disable, specifying the principle item for the bar; defaults to nil.

Returns:
 * If an argument is provided, returns the barObject; otherwise returns the current value.

Notes:
 * the principle item will be centered in the displayed portion of the bar.

 * the identifier specified must belong to a touchbar items already assigned to the bar object with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems) or one of the built in identifier values defined in [hs._asm.undocumented.touchbar.bar.builtInIdentifiers](#builtInIdentifiers).

- - -

<a name="requiredIdentifiers"></a>
~~~lua
bar:requiredIdentifiers([identifiersTable]) -> barObject | table
~~~
Get or set an array of strings specifying the identifiers of the touchbar items that cannot be removed from the bar object through user customization.

Parameters:
 * `identifiersTable` - an optional table containing strings specifying the identifiers of touchbar items that cannot be removed from the bar object through user customization.

Returns:
 * If an argument is provided, returns the barObject; otherwise returns the current value.

Notes:
 * the identifiers specified must belong to touchbar items already assigned to the bar object with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems) or one of the built in identifier values defined in [hs._asm.undocumented.touchbar.bar.builtInIdentifiers](#builtInIdentifiers).

- - -

<a name="templateItems"></a>
~~~lua
bar:templateItems([itemsTable]) -> barObject | table
~~~
Get or set an array of `hs._asm.undocumented.touchbar.item` objects that can be presented by the bar object.

Parameters:
 * `itemsTable` - an optional table containing `hs._asm.undocumented.touchbar.item` objects that can be presented by the bar object.

Returns:
 * If an argument is provided, returns the barObject; otherwise returns the current value.

Notes:
 * only the identifiers of items assigned by this method can be used by the other methods in this module that use string identifiers in their arguments.

- - -

<a name="visibilityCallback"></a>
~~~lua
bar:visibilityCallback([fn | nil]) -> barObject | fn
~~~
Get or set the visibility callback function for the touch bar object.

Parameters:
 * `fn` - an optional function, or explicit nil to remove, specifying the visibility callback for the touch bar object.

Returns:
 * if an argument is provided, returns the barObject; otherwise returns the current value

Notes:
 * The callback function should expect two arguments, the barObject itself and a boolean indicating the new visibility of the touch bar.  It should return none.

 * This callback is invoked when the [hs._asm.undocumented.touchbar.bar:dismissModalBar](#dismissModalBar) or [hs._asm.undocumented.touchbar.bar:minimizeModalBar](#minimizeModalBar) methods are used.
 * This callback is *NOT* invoked when the system dismiss button is used (when the second argument to [hs._asm.undocumented.touchbar.bar:presentModalBar](#presentModalBar) or `hs._asm.undocumented.touchbar.item:presentModalBar` is true (or not present)). This is being investigated but at present no workaround is known.

### Module Constants

<a name="builtInIdentifiers"></a>
~~~lua
bar.builtInIdentifiers[]
~~~
A table of key-value pairs whose values represent built in touch bar items which can be used to adjust the layout of the bar object when it is being presented.

Currently the following keys are defined:
 * smallSpace      - provides a small space between items
 * largeSpace      - provides a larger space between items
 * flexibleSpace   - provides an expanding/contracting space between items

The following is ignored for modally displayed bars, so it's effects are still being evaluated; documentation will be updated when nested bars can be tested and more fully understood within the context of the Hammerspoon console and webview.
 * otherItemsProxy - provides a place for nested bars to display items

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


