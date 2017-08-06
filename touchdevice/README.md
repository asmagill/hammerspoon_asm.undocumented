hs._asm.undocumented.touchdevice
================================

This modules provides functionality for detecting and using touch information from Multi-Touch devices attached to your Mac.

Most of the functions and methods provided here rely on undocumented or private functionality provided by the MultitouchSupport framework.  As such thi module is considered experimental and may break at any time should Apple make changes to the framework.

Portions of this module have been influenced or inspired by code found at the following addresses:
 * https://github.com/INRIA/libpointing/blob/master/pointing/input/osx/osxPrivateMultitouchSupport.h
 * https://github.com/calftrail/Touch
 * https://github.com/jnordberg/FingerMgmt
 * ...and I'm sure others that have slipped my mind.

If you feel that I have missed a particular site that should be referenced, or know of a site with additional information that can clarify or expand this module or any of its functions -- many of the informational methods are not fully understood and clarification would be greatly appreciated -- please do not hesitate to submit an issue or pull request at https://github.com/asmagill/hammerspoon_asm.undocumented for consideration.

Because this module relies on an undocumented framework, this documentation is based on the collection of observations made by a variety of people and shared on the internet and is a best guess -- nothing in here is guaranteed.  If you have more accurate information or observe something in variance with what is documented here, please submit an issue with as much detail as possible.


### Installation

A precompiled version of this module can be found in this directory with a name along the lines of `touchdevice-v0.x.tar.gz`. This can be installed by downloading the file and then expanding it as follows:

~~~sh
$ cd ~/.hammerspoon # or wherever your Hammerspoon init.lua file is located
$ tar -xzf ~/Downloads/touchdevice-v0.x.tar.gz # or wherever your downloads are located
~~~

If you wish to build this module yourself, and have XCode installed on your Mac, the best way (you are welcome to clone the entire repository if you like, but no promises on the current state of anything else) is to download `init.lua`, `internal.m`, `forcetouch.m`, `MultitouchSupport.h`, and `Makefile` (at present, nothing else is required) into a directory of your choice and then do the following:

~~~sh
$ cd wherever-you-downloaded-the-files
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make docs install
~~~

If your Hammerspoon application is located in `/Applications`, you can leave out the `HS_APPLICATION` environment variable, and if your Hammerspoon files are located in their default location, you can leave out the `PREFIX` environment variable.  For most people it will be sufficient to just type `make docs install`.

As always, whichever method you chose, if you are updating from an earlier version it is recommended to fully quit and restart Hammerspoon after installing this module to ensure that the latest version of the module is loaded into memory.

### Usage
~~~lua
touchdevice = require("hs._asm.undocumented.touchdevice")
~~~

### Contents


##### Module Constructors
* <a href="#default">touchdevice.default() -> touchdeviceObject</a>
* <a href="#forDeviceID">touchdevice.forDeviceID(idNumber) -> touchdeviceObject</a>

##### Module Functions
* <a href="#absoluteTime">touchdevice.absoluteTime() -> number</a>
* <a href="#available">touchdevice.available() -> boolean</a>
* <a href="#devices">touchdevice.devices() -> table</a>

##### Module Methods
* <a href="#GUID">touchdevice:GUID() -> string</a>
* <a href="#MTHIDDevice">touchdevice:MTHIDDevice() -> boolean</a>
* <a href="#alive">touchdevice:alive() -> boolean</a>
* <a href="#builtin">touchdevice:builtin() -> boolean</a>
* <a href="#details">touchdevice:details() -> table</a>
* <a href="#deviceID">touchdevice:deviceID() -> integer</a>
* <a href="#driverReady">touchdevice:driverReady() -> boolean</a>
* <a href="#driverType">touchdevice:driverType() -> integer</a>
* <a href="#familyID">touchdevice:familyID() -> integer</a>
* <a href="#forceResponseEnabled">touchdevice:forceResponseEnabled([state]) -> touchdeviceObject | boolean</a>
* <a href="#frameCallback">touchdevice:frameCallback([fn]) -> touchdeviceObject | fn</a>
* <a href="#opaqueSurface">touchdevice:opaqueSurface() -> boolean</a>
* <a href="#pathCallback">touchdevice:pathCallback([fn]) -> touchdeviceObject | fn</a>
* <a href="#productName">touchdevice:productName() -> string</a>
* <a href="#running">touchdevice:running() -> boolean</a>
* <a href="#sensorDimensions">touchdevice:sensorDimensions([inHmm]) -> sizeTable</a>
* <a href="#serialNumber">touchdevice:serialNumber() -> string</a>
* <a href="#start">touchdevice:start() -> touchdeviceObject</a>
* <a href="#stop">touchdevice:stop() -> touchdeviceObject</a>
* <a href="#supportsActuation">touchdevice:supportsActuation() -> boolean</a>
* <a href="#supportsForce">touchdevice:supportsForce() -> boolean</a>
* <a href="#supportsPowerControl">touchdevice:supportsPowerControl() -> boolean</a>
* <a href="#supportsSilentClick">touchdevice:supportsSilentClick() -> boolean</a>
* <a href="#version">touchdevice:version() -> integer</a>

##### Module Fields
* <a href="#touchData">touchdevice.touchData</a>

- - -

### Module Constructors

<a name="default"></a>
~~~lua
touchdevice.default() -> touchdeviceObject
~~~
Returns the touchdevice object for the default multi-touch device attached to the system

Parameters:
 * None

Returns:
 * a touchdeviceObject or nil if no multi-touch devices are currently available

Notes:
 * on a laptop, the default multi-touch device will be the built in trackpad; on a desktop, the default device will be the first multi-touch device detected

- - -

<a name="forDeviceID"></a>
~~~lua
touchdevice.forDeviceID(idNumber) -> touchdeviceObject
~~~
Returns the touchdevice object for the specified device id

Parameters:
 * `idNumber` - an integer specifying the id number of the multi-touch device to create the touchdeviceObject for

Returns:
 * a touchdeviceObject or nil if no multi-touch devices with the specified id is available

Notes:
 * You can get a list of currently available device ids with [hs._asm.undocumented.touchdevice.devices](#devices) or get the device id for an existing object with [hs._asm.undocumented.touchdevice:deviceID](#deviceID).

### Module Functions

<a name="absoluteTime"></a>
~~~lua
touchdevice.absoluteTime() -> number
~~~
Returns a number specifying the time in seconds since the last system reboot.

Parameters:
 * None

Returns:
 * a number specifying the time in seconds since the last system reboot

- - -

<a name="available"></a>
~~~lua
touchdevice.available() -> boolean
~~~
Returns whether or not a multi-touch device is currently attached to the system.

Parameters:
 * None

Returns:
 * a boolean value indicating whether or not a multi-touch device is currently attached to the system

Notes:
 * multi-touch devices include the built-in trackpad found on any modern Mac laptop, the Magic Mouse, and the Magic Trackpad.

- - -

<a name="devices"></a>
~~~lua
touchdevice.devices() -> table
~~~
Returns a list of the device id's for all currently available multi-touch devices

Parameters:
 * None

Returns:
 * a table as an array containing the device id's of all currently attached/available multi-touch devices

### Module Methods

<a name="GUID"></a>
~~~lua
touchdevice:GUID() -> string
~~~
Returns a string specifying the GUID for the touch device represented by the touchdeviceObject

Parameters:
 * None

Returns:
 * a string specifying the GUID for the touch device represented by the touchdeviceObject

Notes:
 * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.

- - -

<a name="MTHIDDevice"></a>
~~~lua
touchdevice:MTHIDDevice() -> boolean
~~~
Returns a boolean indicating whether or not the multi-touch device is a HID device

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is a HID device

Notes:
 * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.

- - -

<a name="alive"></a>
~~~lua
touchdevice:alive() -> boolean
~~~
Returns a boolean indicating whether or not the multi-touch device is alive

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is alive

Notes:
 * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
 * I have only observed this as returning false; please submit details if you observe a different value.

- - -

<a name="builtin"></a>
~~~lua
touchdevice:builtin() -> boolean
~~~
Returns a boolean indicating whether or not the multi-touch device is built in

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is a built in device

Notes:
 * This will be true for the trackpad built in to Mac laptops and false for any external device

- - -

<a name="details"></a>
~~~lua
touchdevice:details() -> table
~~~
Returns a table containing a summary of the information provided by the informational methods of this module for the the multi-touch device

Parameters:
 * None

Returns:
 * a table containing key-value pairs corresponding to most of the informational methods provided by this module for the multi-touch device represented by the touchdeviceObject.

Notes:
 * The returned table uses the `hs.inspect` module as a `__tostring` metamethod allowing you to display it easily in the Hammerspoon console.
 * This method is provided as a convenience -- because it invokes a method for each key in the table, when speed is a concern, you should invoke the individual methods for the specific information that you require.

- - -

<a name="deviceID"></a>
~~~lua
touchdevice:deviceID() -> integer
~~~
Returns the device ID for the multi-touch device

Parameters:
 * None

Returns:
 * an integer specifying the device id for the multi-touch device represented by the touchdeviceObject

- - -

<a name="driverReady"></a>
~~~lua
touchdevice:driverReady() -> boolean
~~~
Returns a boolean indicating whether or not the multi-touch device driver is ready

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the driver for the multi-touch device represented by the touchdeviceObject is ready

Notes:
 * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.

- - -

<a name="driverType"></a>
~~~lua
touchdevice:driverType() -> integer
~~~
Returns an integer specifying the driver type for the touch device represented by the touchdeviceObject

Parameters:
 * None

Returns:
 * an integer specifying the driver type for the touch device represented by the touchdeviceObject

Notes:
 * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.

- - -

<a name="familyID"></a>
~~~lua
touchdevice:familyID() -> integer
~~~
Returns an integer specifying the device family id for the touch device represented by the touchdeviceObject

Parameters:
 * None

Returns:
 * an integer specifying the device family id for the touch device represented by the touchdeviceObject

Notes:
 * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.

- - -

<a name="forceResponseEnabled"></a>
~~~lua
touchdevice:forceResponseEnabled([state]) -> touchdeviceObject | boolean
~~~
Get or set whether applying pressure to a force touch capable device will generate a mouse click or force touch

Parameters:
 * `state` - an optional boolean specifying whether the force touch capable touch device will generate mouse clicks and force touches (true) or not (false).

Returns:
 * if an argument is provided, returns the touchdeviceObject, otherwise returns the current value

Notes:
 * When used with a non force touch device, the results of using this method are undefined - some will apparently change their value in response to this method while others will not; however the mouse click ability of the touch device will not be affected.

 * When used with a force touch capable device, setting this value to false will prevent the device from being able to generate mouse clicks; multi touch gestures and mouse movement is unaffected however.
 * This can be used to make such a device act more like a drawing tablet where the pressure can be used as a Z-axis without fear that a mouse click will change application focus or have other effects.
 * ***WARNING*** - if you disable mouse clicks for a device with this method, it is re-enabled upon garbage collection of the userdata representing the touch device. This means:
   * You must retain the userdata in a global variable (or local variable with an upvalue reference within a global function or table) for at least as long as you wish for mouse clicks to be suppressed.
   * If you have multiple userdata objects for the *same* touch device created independently (with separate [hs._asm.undocumented.touchdevice.default](#default) or [hs._asm.undocumented.touchdevice.forDeviceID](#forDeviceID) function invocations), when any of them go out of scope and is garbage collected, mouse clicks will be re-enabled for the device.
   * If Hammerspoon crashes or exits unexpectedly, it is likely that garbage collection will not occur.  In this case, you will have to restart Hammerspoon and use this method to re-enable mouse clicks or disconnect and reconnect your device (if it is external) or restart your machine (if it is not) to return the device to normal functionality.
 * For these reasons, it is recommended that you only disable force response for as short a period as you require and the re-enable them so that everything remains in a predictable state.

 * If you wish to suspend mouse gestures as well, you can use `hs.execute("killall -STOP Dock")`.  Note however that this disables gestures for *ALL* touch devices and also disables application switching from the keyboard as well (you can still click on an another applications windows with another mouse device though). You can resume normal operation of the gestures and keyboard shortcuts with `hs.execute("killall -CONT Dock")`. It is unknown what other processes suspending the Dock in this way may cause, so do so at your own risk.

- - -

<a name="frameCallback"></a>
~~~lua
touchdevice:frameCallback([fn]) -> touchdeviceObject | fn
~~~
Get or set the frame callback function for the touch device represented by the touchdevice object

Parameters:
 * `fn` - an optional function or nil to set (or remove) the frame callback function for the touch device.

Returns:
 * if an argument is provided, returns the touchdeviceObject; otherwise returns the current value which may be a function or nil if no frame callback is currently assigned.

Notes:
 * The frame callback appears to represent a point in time and contains touch data for all touches currently active for the device

 * the callback function should expect 4 arguments and return none.  The arguments will be as follows:
   * `self`      - the touch device object for which the callback is being invoked for
   * `touch`     - a table containing an array of touch tables as described in [hs._asm.undocumented.touchdevice.touchData](#touchData) for each of the current touches detected by the touch device.
   * `timestamp` - a number specifying the timestamp for the frame.
   * `frame`     - an integer specifying the frame ID

- - -

<a name="opaqueSurface"></a>
~~~lua
touchdevice:opaqueSurface() -> boolean
~~~
Returns a boolean indicating whether or not the multi-touch device is an opaque surface

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is an opaque surface

Notes:
 * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.

 * This value appears to always be false unless the device is being watched for touch callbacks.

- - -

<a name="pathCallback"></a>
~~~lua
touchdevice:pathCallback([fn]) -> touchdeviceObject | fn
~~~
Get or set the path callback function for the touch device represented by the touchdevice object

Parameters:
 * `fn` - an optional function or nil to set (or remove) the path callback function for the touch device.

Returns:
 * if an argument is provided, returns the touchdeviceObject; otherwise returns the current value which may be a function or nil if no path callback is currently assigned.

Notes:
 * The path callback appears to represent the changing data for a specific touch.  Use the `pathIndex` and `stage` as described in [hs._asm.undocumented.touchdevice.touchData](#touchData) to link callbacks when tracking a specific touch.

 * the callback function should expect 4 arguments and return none.  The arguments will be as follows:
   * `self`      - the touch device object for which the callback is being invoked for
   * `pathIndex` - an integer specifying the pathIndex for the touch.
   * `stage`     - a string representing the current stage of the touch. Will be one of "notTracking", "startInRange", "hoverInRange", "makeTouch", "touching", "breakTouch", "lingerInRange", or "outOfRange".
   * `touch`     - a touch tables as described in [hs._asm.undocumented.touchdevice.touchData](#touchData) for the specific touch

- - -

<a name="productName"></a>
~~~lua
touchdevice:productName() -> string
~~~
Returns the product name for the touch device as it is registered with the IOKit HID subsystem

Parameters:
 * None

Returns:
 * a string specifying the product name for the touch device represented by the touchdeviceObject as registered with the IOKit HID subsystem.

Notes:
 * this information is purely informational and may be useful in differentiating multiple devices attached to the same machine
 * some devices return a name corresponding to the marketting name for the device while others return a name created by the macOS generated when the device is first paired with the machine, usually the user's login name followed by "Mouse" or "Trackpad".  At this time, it is unknown if there is an independant way to determine which pattern a given device's product name will follow or if there is a way to return the marketting name for an otherwise named device; if someone more familiar with IOKit, especially with regards to HID devices has any thoughts on the matter, please submit an issue for consideration.

- - -

<a name="running"></a>
~~~lua
touchdevice:running() -> boolean
~~~
Returns a boolean indicating whether or not the multi-touch device is being monitored and generates callbacks for touch activity

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is being monitored and generates callbacks for touch activity

Notes:
 * See [hs._asm.undocumented.touchdevice:start](#start) and [hs._asm.undocumented.touchdevice:stop](#stop)

- - -

<a name="sensorDimensions"></a>
~~~lua
touchdevice:sensorDimensions([inHmm]) -> sizeTable
~~~
Returns the dimensions of the space on the touch device that can detect a touch

Parameters:
 * `inHmm` - a boolean, default true, specifying whether the dimensions should be returned in hundredths of a millimeter (true) or as rows and columns (false)

Returns:
 * a size table containing the sensor area dimensions where the height is the value assigned to the `h` key and the width is assigned to the `w` key.

Notes:
 * At present, the usefulness of the row/column dimension values is currently unknown and it is being provided for information purposes only
   * The row/column values seem to correspond to a grid used by the MultitouchSupport framework to differentiate between nearby touches and the exact size of each "cell" appears to be device dependent as the ratios between rows and columns versus the height and width as returned in hundredths of a millimeter is not consistent across devices.

- - -

<a name="serialNumber"></a>
~~~lua
touchdevice:serialNumber() -> string
~~~
Returns the serial number for the multi-touch device

Parameters:
 * None

Returns:
 * a string specifying the serial number of the multi-touch device represented by the touchdeviceObject

Notes:
 * not all devices have a serial number so this value may be "None" or an empty string

- - -

<a name="start"></a>
~~~lua
touchdevice:start() -> touchdeviceObject
~~~
Begin tracking touch data from the touch device.

Parameters:
 * None

Returns:
 * the touchdeviceObject

- - -

<a name="stop"></a>
~~~lua
touchdevice:stop() -> touchdeviceObject
~~~
Stop tracking touch data from the touch device.

Parameters:
 * None

Returns:
 * the touchdeviceObject

- - -

<a name="supportsActuation"></a>
~~~lua
touchdevice:supportsActuation() -> boolean
~~~
Returns a boolean indicating whether or not the multi-touch device contains an actuator

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject contains an actuator

Notes:
 * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.

 * The MultitouchSupport framework does provide undocumented functions for accessing the actuator directly, but so far I've found no examples to start experimenting with.  Further investigation is being considered but is not currently underway.

- - -

<a name="supportsForce"></a>
~~~lua
touchdevice:supportsForce() -> boolean
~~~
Returns a boolean indicating whether or not the multi-touch device is a force touch device.

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is a force touch device

Notes:
 * Force touch devices provide haptic feedback indicating mouse clicks rather than use an actual mechanical switch to detect mouse clicks.

- - -

<a name="supportsPowerControl"></a>
~~~lua
touchdevice:supportsPowerControl() -> boolean
~~~
Returns a boolean indicating whether or not the multi-touch device supports power control

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject supports power control

Notes:
 * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
 * I have only observed this as returning false; please submit details if you observe a different value.

- - -

<a name="supportsSilentClick"></a>
~~~lua
touchdevice:supportsSilentClick() -> boolean
~~~
Returns a boolean specifying whether or not the touch device represented by the touchdeviceObject supports silent click

Parameters:
 * None

Returns:
 * a boolean specifying whether or not the touch device represented by the touchdeviceObject supports silent click

Notes:
 * This method will return true for non force-touch devices -- they do not have a simulated click sound associated with mouse clicks so they are considered "silent" by the MultitouchSupport framework already.
 * Some force touch devices do not support disabling this simulated sound and will return false with this method; this seems to mostly apply to newer Mac Pro laptops, though an exhaustive list is beyond the scope of this documentation.  If you are uncertain about your force touch device, check Trackpad in System Preferences -- if you see an option for "Silent clicking" then this method should return true for your force touch device.

- - -

<a name="version"></a>
~~~lua
touchdevice:version() -> integer
~~~
Returns an integer specifying the bcdVersion for the touch device represented by the touchdeviceObject

Parameters:
 * None

Returns:
 * an integer specifying the bcdVersion for the touch device represented by the touchdeviceObject

Notes:
 * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.

### Module Fields

<a name="touchData"></a>
~~~lua
touchdevice.touchData
~~~
The table representing a touch as returned by the callback functions.  Because this module relies on an undocumented framework, these descriptions are based on the collection of observations made by a variety of people and shared on the internet -- nothing in here is guaranteed.  If you have corrected information or observe something in variance with what is documented here, please submit an issue with as much detail as possible.

The table will contain the following key-value pairs:
  * `frame`            - an integer specifying the observation frame this touch belongs to
  * `timestamp`        - a number representing the timestamp for the touch data in seconds; the epoch (0.0 point) is uncertain, but for a given device, the number will always be increasing throughout the detection of touches for the device.
  * `pathIndex`        - an integer representing the path through the various stages for a touch; as long as a specific touch has not been broken (i.e. reached the "notTracking" stage), it's path ID will remain constant even though it's relative position in the table of touches returned in a frame callback may differ.
  * `stage`            - a string representing the stage of the touch.  May be one of the following values:
    * `notTracking`   - The touch has completed and no further path updates with this pathIndex will occur
    * `startInRange`  - This is a newly detected touch
    * `hoverInRange`  - The touch is hovering slightly above the touch device; not always observed in a full touch path.
    * `makeTouch`     - The touch has actually made full contact with the touch device; not always observed in a full touch path.
    * `touching`      - The touch is established. The touch will be in this stage for the majority of its lifetime.
    * `breakTouch`    - The touch has been lifted from the touch device.
    * `lingerInRange` - The touch has been lifted but is still within the range of hover detection.
    * `outOfRange`    - The touch has moved out of range; This may occur because the touch has ended and will be followed by a `notTracking` message or it can occur if the touch moves out of the touch sensitive area of the device; if the touch returns to the touch sensitive area quickly enough, the touch may continue with `touching` messages.  Otherwise a new touch with a new `pathIndex` and `fingerID` will be generated if the touch returns.
  * `fingerID`         - an integer which appears to be related to the location of the touch device where the touch was first detected; however this is not known for certain.  Like pathIndex, this number will remain constant through the lifetime of a specific touch.
  * `handID`           - an integer, usually 1, of uncertain purpose; it appears to have to do with finger grouping, but has not been observed consistently enough with a differing value to determine conclusively
  * `normalizedVector` - a table representing the current postion and velocity of the touch normalized so that all values are numbers between 0.0 and 1.0
    * `position` - a table representing the position of the touch
      * `x` - a number from 0.0 (the left) to 1.0 (the right) indicating the horizontal position of the touch relative to the touch sensitive surface area of the touch device.
      * `y` - a number from 0.0 (the bottom) to 1.0 (the top) indicating the vertical position of the touch relative to the touch sensitive surface area of the touch device.
    * `velocity` - a table representing the current velocity of the changes to the touch
      * `x` - a number from -1.0 to 1.0 representing the rate and direction of change to the horizontal position of the touch
      * `y` - a number from -1.0 to 1.0 representing the rate and direction of change to the vertical position of the touch
  * `zTotal`           - a number between 0.0 and 1.0 representing a general measure of the surface area covered by the touch; this can be used as an approximation of pressure as more of the finger will be touching as pressure increases.
  * `zPressure`        - on force touch devices, this number appears to represent the relative pressure being applied with the touch; on non-force touch devices this number is 0.0.
  * `angle`            - a number representing the angle of the touch ellipse
  * `majorAxis`        - a number representing the major axis of the touch ellipse
  * `minorAxis`        - a number representing the minor axis of the touch ellipse
  * `absoluteVector`   - a table representing the current position and velocity of the touch.  Note that the possible range for the values available in this table appears to be device dependent and does not appear to be related in an obvious way to the devices surface dimensions as returned by [hs._asm.undocumented.touchdevice:surfaceDimensions](#surfaceDimensions).
    * `position` - a table representing the position of the touch
      * `x` - a number indicating the horizontal position of the touch. This number will be negative if the touch is in the left half of the touch sensitive surface area and positive if it is in the right half.
      * `y` - a number indicating the vertical position of the touch.  This number starts at 0 at the bottom of the device and increases positively as the touch approaches the top.
    * `velocity` - a table representing the current velocity of the changes to the touch
      * `x` - a number representing the rate and direction of change to the horizontal position of the touch
      * `y` - a number representing the rate and direction of change to the vertical position of the touch
  * `zDensity`         - a number representing the density of the touch; in my observations this will fluctuate greatly for fingers but be more constant for a stylus, so it may be useful for gauging what the source of the touch is from.

  * `_field14`         - an integer; currently the purpose of this field in the touch structure is unknown; at present only a value of 0 has been observed.
  * `_field15`         - an integer; currently the purpose of this field in the touch structure is unknown; at present only a value of 0 has been observed.

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

hs._asm.undocumented.touchdevice.forcetouch
===========================================

Some experimentation with force touch devices.

Requires 10.11 or later.
Based in part on code from https://eternalstorms.wordpress.com/2015/11/16/how-to-detect-force-touch-capable-devices-on-the-mac/ and https://github.com/eternalstorms/NSBeginAlertSheet-using-Blocks


### Installation

A precompiled version of this module can be found in this directory with a name along the lines of `forcetouch-v0.x.tar.gz`. This can be installed by downloading the file and then expanding it as follows:

~~~sh
$ cd ~/.hammerspoon # or wherever your Hammerspoon init.lua file is located
$ tar -xzf ~/Downloads/forcetouch-v0.x.tar.gz # or wherever your downloads are located
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
forcetouch = require("hs._asm.undocumented.touchdevice.forcetouch")
~~~

### Contents


##### Module Functions
* <a href="#deviceAttached">forcetouch.deviceAttached() -> boolean</a>
* <a href="#feedback">forcetouch.feedback(type, [immediate]) -> boolean</a>

- - -

### Module Functions

<a name="deviceAttached"></a>
~~~lua
forcetouch.deviceAttached() -> boolean
~~~
Returns a boolean indicating whether or not a force touch capable device is currently attached to the system.

Parameters:
 * None

Returns:
 * a boolean value indicating whether or not a force touch capable device is currently attached to the system.

Notes:
 * Based in part on code from https://eternalstorms.wordpress.com/2015/11/16/how-to-detect-force-touch-capable-devices-on-the-mac/

- - -

<a name="feedback"></a>
~~~lua
forcetouch.feedback(type, [immediate]) -> boolean
~~~
Generate haptic feedback on the currently active force touch device.

Parameters:
 * type - a string which must be one of the following values:
   * "generic"   - A general haptic feedback pattern. Use this when no other feedback patterns apply.
   * "alignment" - A haptic feedback pattern to be used in response to the alignment of an object the user is dragging around. For example, this pattern of feedback could be used in a drawing app when the user drags a shape into alignment with with another shape. Other scenarios where this type of feedback could be used might include scaling an object to fit within specific dimensions, positioning an object at a preferred location, or reaching the beginning/minimum or end/maximum of something, such as a track view in an audio/video app.
   * "level"     - A haptic feedback pattern to be used as the user moves between discrete levels of pressure. This pattern of feedback is used by multilevel accelerator buttons.
 * immediate - an optional boolean, default false, indicating whether the feedback should occur immediately (true) or when the screen has finished updating (false)

Returns:
 * true if a feedback performer object exists within the current system, or false if it does not.

Notes:
 * The existence of a feedback performer object is dependent upon the OS X version and not necessarily on the hardware available -- laptops with a trackpad which predates force touch will return true, even though this function does nothing on such systems.
 * Even on systems with a force touch device, this function will only generate feedback when the device is active or being touched -- from the Apple docs: "In some cases, the system may override a call to this method. For example, a Force Touch trackpad won’t provide haptic feedback if the user isn’t touching the trackpad."

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


