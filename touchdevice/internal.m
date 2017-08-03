@import Cocoa ;
@import LuaSkin ;
@import IOKit.hid ;

// include methods which don't seem to be useful (or at least I haven't found one yet) or can't be verified at present
// #define INCLUDE_QUESTIONABLE_METHODS

#import "MultitouchSupport.h"

static const char * const USERDATA_TAG = "hs._asm.undocumented.touchdevice" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))
// #define get_structFromUserdata(objType, L, idx, tag) ((objType *)luaL_checkudata(L, idx, tag))
// #define get_cfobjectFromUserdata(objType, L, idx, tag) *((objType *)luaL_checkudata(L, idx, tag))

#pragma mark - Support Functions and Classes

@interface ASMTouchDevice : NSObject
@property (readonly) MTDeviceRef touchDevice ;
@property            int         frameCallbackRef ;
@property            int         pathCallbackRef ;
@property            int         selfRefCount ;
@end

@implementation ASMTouchDevice
- (instancetype)initWithDevice:(MTDeviceRef)device {
    self = [super init] ;
    if (self) {
        _touchDevice      = device ;
        _frameCallbackRef = LUA_NOREF ;
        _pathCallbackRef  = LUA_NOREF ;
        _selfRefCount     = 0 ;
    }
    return self ;
}

@end

static const NSArray *pathStageNames ;

/// hs._asm.undocumented.touchdevice.touchData
/// Field
/// The table representing a touch as returned by the callback functions.  Because this module relies on an undocumented framework, these descriptions are based on the collection of observations made by a variety of people and shared on the internet -- nothing in here is guaranteed.  If you have corrected information or observe something in variance with what is documented here, please submit an issue with as much detail as possible.
///
/// The table will contain the following key-value pairs:
///   * `frame`            - an integer specifying the observation frame this touch belongs to
///   * `timestamp`        - a number representing the timestamp for the touch data in seconds; the epoch (0.0 point) is uncertain, but for a given device, the number will always be increasing throughout the detection of touches for the device.
///   * `pathIndex`        - an integer representing the path through the various stages for a touch; as long as a specific touch has not been broken (i.e. reached the "notTracking" stage), it's path ID will remain constant even though it's relative position in the table of touches returned in a frame callback may differ.
///   * `stage`            - a string representing the stage of the touch.  May be one of the following values:
///     * `notTracking`   - The touch has completed and no further path updates with this pathIndex will occur
///     * `startInRange`  - This is a newly detected touch
///     * `hoverInRange`  - The touch is hovering slightly above the touch device; not always observed in a full touch path.
///     * `makeTouch`     - The touch has actually made full contact with the touch device; not always observed in a full touch path.
///     * `touching`      - The touch is established. The touch will be in this stage for the majority of its lifetime.
///     * `breakTouch`    - The touch has been lifted from the touch device.
///     * `lingerInRange` - The touch has been lifted but is still within the range of hover detection.
///     * `outOfRange`    - The touch has moved out of range; This may occur because the touch has ended and will be followed by a `notTracking` message or it can occur if the touch moves out of the touch sensitive area of the device; if the touch returns to the touch sensitive area quickly enough, the touch may continue with `touching` messages.  Otherwise a new touch with a new `pathIndex` and `fingerID` will be generated if the touch returns.
///   * `fingerID`         - an integer which appears to be related to the location of the touch device where the touch was first detected; however this is not known for certain.  Like pathIndex, this number will remain constant through the lifetime of a specific touch.
///   * `handID`           - an integer, usually 1, of uncertain purpose; it appears to have to do with finger grouping, but has not been observed consistently enough with a differing value to determine conclusively
///   * `normalizedVector` - a table representing the current postion and velocity of the touch normalized so that all values are numbers between 0.0 and 1.0
///     * `position` - a table representing the position of the touch
///       * `x` - a number from 0.0 (the left) to 1.0 (the right) indicating the horizontal position of the touch relative to the touch sensitive surface area of the touch device.
///       * `y` - a number from 0.0 (the bottom) to 1.0 (the top) indicating the vertical position of the touch relative to the touch sensitive surface area of the touch device.
///     * `velocity` - a table representing the current velocity of the changes to the touch
///       * `x` - a number from -1.0 to 1.0 representing the rate and direction of change to the horizontal position of the touch
///       * `y` - a number from -1.0 to 1.0 representing the rate and direction of change to the vertical position of the touch
///   * `zTotal`           - a number between 0.0 and 1.0 representing a general measure of the surface area covered by the touch; this can be used as an approximation of pressure as more of the finger will be touching as pressure increases.
///   * `zPressure`        - on force touch devices, this number appears to represent the relative pressure being applied with the touch; on non-force touch devices this number is 0.0.
///   * `angle`            - a number representing the angle of the touch ellipse
///   * `majorAxis`        - a number representing the major axis of the touch ellipse
///   * `minorAxis`        - a number representing the minor axis of the touch ellipse
///   * `absoluteVector`   - a table representing the current position and velocity of the touch.  Note that the possible range for the values available in this table appears to be device dependent and does not appear to be related in an obvious way to the devices surface dimensions as returned by [hs._asm.undocumented.touchdevice:surfaceDimensions](#surfaceDimensions).
///     * `position` - a table representing the position of the touch
///       * `x` - a number indicating the horizontal position of the touch. This number will be negative if the touch is in the left half of the touch sensitive surface area and positive if it is in the right half.
///       * `y` - a number indicating the vertical position of the touch.  This number starts at 0 at the bottom of the device and increases positively as the touch approaches the top.
///     * `velocity` - a table representing the current velocity of the changes to the touch
///       * `x` - a number representing the rate and direction of change to the horizontal position of the touch
///       * `y` - a number representing the rate and direction of change to the vertical position of the touch
///   * `zDensity`         - a number representing the density of the touch; in my observations this will fluctuate greatly for fingers but be more constant for a stylus, so it may be useful for gauging what the source of the touch is from.
///
///   * `_field14`         - an integer; currently the purpose of this field in the touch structure is unknown; at present only a value of 0 has been observed.
///   * `_field15`         - an integer; currently the purpose of this field in the touch structure is unknown; at present only a value of 0 has been observed.

static int pushMTTouch(lua_State *L, MTTouch *touch) {
    LuaSkin *skin = [LuaSkin shared] ;
    lua_newtable(L) ;
    lua_pushinteger(L, touch->frame) ;     lua_setfield(L, -2, "frame") ;
    lua_pushnumber(L, touch->timestamp) ;  lua_setfield(L, -2, "timestamp") ;
    lua_pushinteger(L, touch->pathIndex) ; lua_setfield(L, -2, "pathIndex") ;
    if ((NSUInteger)touch->stage < pathStageNames.count) {
        [skin pushNSObject:pathStageNames[(NSUInteger)touch->stage]] ;
    } else {
        [skin pushNSObject:[NSString stringWithFormat:@"* unrecognized stage: %u", touch->stage]] ;
    }
    lua_setfield(L, -2, "stage") ;
    lua_pushinteger(L, touch->fingerID) ;  lua_setfield(L, -2, "fingerID") ;
    lua_pushinteger(L, touch->handID) ;    lua_setfield(L, -2, "handID") ;
    lua_newtable(L) ;
    lua_newtable(L) ;
    lua_pushnumber(L, (lua_Number)touch->normalizedVector.position.x) ; lua_setfield(L, -2, "x") ;
    lua_pushnumber(L, (lua_Number)touch->normalizedVector.position.y) ; lua_setfield(L, -2, "y") ;
    lua_setfield(L, -2, "position") ;
    lua_newtable(L) ;
    lua_pushnumber(L, (lua_Number)touch->normalizedVector.velocity.x) ; lua_setfield(L, -2, "x") ;
    lua_pushnumber(L, (lua_Number)touch->normalizedVector.velocity.y) ; lua_setfield(L, -2, "y") ;
    lua_setfield(L, -2, "velocity") ;
    lua_setfield(L, -2, "normalizedVector") ;
    lua_pushnumber(L, (lua_Number)touch->zTotal) ;     lua_setfield(L, -2, "zTotal") ;
//     lua_pushinteger(L, touch->field9) ;    lua_setfield(L, -2, "_field9") ;
    lua_pushnumber(L, (lua_Number)touch->zPressure) ;  lua_setfield(L, -2, "zPressure") ;
    lua_pushnumber(L, (lua_Number)touch->angle) ;      lua_setfield(L, -2, "angle") ;
    lua_pushnumber(L, (lua_Number)touch->majorAxis) ;  lua_setfield(L, -2, "majorAxis") ;
    lua_pushnumber(L, (lua_Number)touch->minorAxis) ;  lua_setfield(L, -2, "minorAxis") ;
    lua_newtable(L) ;
    lua_newtable(L) ;
    lua_pushnumber(L, (lua_Number)touch->absoluteVector.position.x) ; lua_setfield(L, -2, "x") ;
    lua_pushnumber(L, (lua_Number)touch->absoluteVector.position.y) ; lua_setfield(L, -2, "y") ;
    lua_setfield(L, -2, "position") ;
    lua_newtable(L) ;
    lua_pushnumber(L, (lua_Number)touch->absoluteVector.velocity.x) ; lua_setfield(L, -2, "x") ;
    lua_pushnumber(L, (lua_Number)touch->absoluteVector.velocity.y) ; lua_setfield(L, -2, "y") ;
    lua_setfield(L, -2, "velocity") ;
    lua_setfield(L, -2, "absoluteVector") ;
    lua_pushinteger(L, touch->field14) ;   lua_setfield(L, -2, "_field14") ;
    lua_pushinteger(L, touch->field15) ;   lua_setfield(L, -2, "_field15") ;
    lua_pushnumber(L, (lua_Number)touch->zDensity) ;   lua_setfield(L, -2, "zDensity") ;
    return 1 ;
}

static void frameCallbackFunction(MTDeviceRef device, MTTouch *touches, size_t numTouches, double timestamp, size_t frame, void* refcon) {
    uint64_t deviceID ;
    MTDeviceGetDeviceID(device, &deviceID) ;
    ASMTouchDevice *self = (__bridge ASMTouchDevice *)refcon ;
    if (self && self.frameCallbackRef != LUA_NOREF) {
    // Because we're dispatching asynchronously, it's posible for the touches to be released before the callback actually runs
        MTTouch *heldTouches = malloc(sizeof(MTTouch) * numTouches) ;
        memcpy(heldTouches, touches, sizeof(MTTouch) * numTouches) ;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.frameCallbackRef != LUA_NOREF) {
    // Because we're dispatching asynchronously, it's posible the callback ref has gone away before the callback actually runs
                LuaSkin   *skin = [LuaSkin shared] ;
                lua_State *L    = [skin L] ;
                [skin pushLuaRef:refTable ref:self.frameCallbackRef] ;
                [skin pushNSObject:self] ;
                lua_newtable(L) ;
                for (NSUInteger i = 0 ; i < numTouches ; i++) {
                    pushMTTouch(L, &heldTouches[i]) ;
                    lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
                }
                lua_pushnumber(L, timestamp) ;
                lua_pushinteger(L, (lua_Integer)frame) ;
                if (![skin protectedCallAndTraceback:4 nresults:0]) {
                    [skin logError:[NSString stringWithFormat:@"%s:frameCallback - callback error: %@", USERDATA_TAG, [skin toNSObjectAtIndex:-1]]] ;
                    lua_pop(L, 1) ;
                }
            }
            free(heldTouches) ;
        }) ;
    } else if (!self) {
        [LuaSkin logError:[NSString stringWithFormat:@"%s:frameCallback - device with id %lld is not registered; stopping watcher", USERDATA_TAG, deviceID]] ;
        MTDeviceStop(device) ;
    }
}

static void pathCallbackFunction(MTDeviceRef device, long pathID, long stage, MTTouch* touch, void* refcon) {
    uint64_t deviceID ;
    MTDeviceGetDeviceID(device, &deviceID) ;
    ASMTouchDevice *self = (__bridge ASMTouchDevice *)refcon ;
    if (self && self.pathCallbackRef != LUA_NOREF) {
        dispatch_async(dispatch_get_main_queue(), ^{
    // Because we're dispatching asynchronously, it's posible the callback ref has gone away before the callback actually runs
            if (self.pathCallbackRef != LUA_NOREF) {
                LuaSkin   *skin = [LuaSkin shared] ;
                lua_State *L    = [skin L] ;
                [skin pushLuaRef:refTable ref:self.pathCallbackRef] ;
                [skin pushNSObject:self] ;
                lua_pushinteger(L, pathID) ;
                if ((NSUInteger)stage < pathStageNames.count) {
                    [skin pushNSObject:pathStageNames[(NSUInteger)stage]] ;
                } else {
                    [skin pushNSObject:[NSString stringWithFormat:@"* unrecognized stage: %ld", stage]] ;
                }
                pushMTTouch(L, touch) ;
                if (![skin protectedCallAndTraceback:4 nresults:0]) {
                    [skin logError:[NSString stringWithFormat:@"%s:pathCallback - callback error: %@", USERDATA_TAG, [skin toNSObjectAtIndex:-1]]] ;
                    lua_pop(L, 1) ;
                }
            }
        }) ;
    } else if (!self) {
        [LuaSkin logError:[NSString stringWithFormat:@"%s:pathCallback - device with id %lld is not registered; stopping watcher", USERDATA_TAG, deviceID]] ;
        MTDeviceStop(device) ;
    }
}

#pragma mark - Module Functions

/// hs._asm.undocumented.touchdevice.absoluteTime() -> number
/// Function
/// Returns a number specifying the time in seconds since the last system reboot.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a number specifying the time in seconds since the last system reboot
static int touchdevice_absoluteTime(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBREAK] ;
    lua_pushnumber(L, MTAbsoluteTimeGetCurrent()) ;
    return 1 ;
}

/// hs._asm.undocumented.touchdevice.available() -> boolean
/// Function
/// Returns whether or not a multi-touch device is currently attached to the system.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean value indicating whether or not a multi-touch device is currently attached to the system
///
/// Notes:
///  * multi-touch devices include the built-in trackpad found on any modern Mac laptop, the Magic Mouse, and the Magic Trackpad.
static int touchdevice_isAvailable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBREAK] ;
    lua_pushboolean(L, MTDeviceIsAvailable()) ;
    return 1 ;
}

/// hs._asm.undocumented.touchdevice.devices() -> table
/// Function
/// Returns a list of the device id's for all currently available multi-touch devices
///
/// Parameters:
///  * None
///
/// Returns:
///  * a table as an array containing the device id's of all currently attached/available multi-touch devices
static int touchdevice_devices(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBREAK] ;
    CFArrayRef mtdevices = MTDeviceCreateList() ;
    if (mtdevices) {
        lua_newtable(L) ;
        for (CFIndex i = 0 ; i < CFArrayGetCount(mtdevices) ; i++) {
            MTDeviceRef device = CFArrayGetValueAtIndex(mtdevices, i) ;
            if (CFGetTypeID(device) == MTDeviceGetTypeID()) {
                uint64_t deviceID ;
                if (MTDeviceGetDeviceID(device, &deviceID) == 0) {
                    lua_pushinteger(L, (lua_Integer)deviceID) ;
                    lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
                } else {
                    [skin logWarn:[NSString stringWithFormat:@"%s:devices - unable to get device ID for device; skipping", USERDATA_TAG]] ;
                }
            } else {
                [skin logWarn:[NSString stringWithFormat:@"%s.devices - unrecognized device at index %ld; skipping", USERDATA_TAG, i + 1]] ;
            }
        }
        CFRelease(mtdevices) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"%s.devices - unable to get multi-touch device list", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchdevice.default() -> touchdeviceObject
/// Constructor
/// Returns the touchdevice object for the default multi-touch device attached to the system
///
/// Parameters:
///  * None
///
/// Returns:
///  * a touchdeviceObject or nil if no multi-touch devices are currently available
///
/// Notes:
///  * on a laptop, the default multi-touch device will be the built in trackpad; on a desktop, the default device will be the first multi-touch device detected
static int touchdevice_default(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBREAK] ;
    MTDeviceRef device = MTDeviceCreateDefault() ;
    if (device) {
        [skin pushNSObject:[[ASMTouchDevice alloc] initWithDevice:device]] ;
    } else {
        [skin logError:[NSString stringWithFormat:@"%s.default - unable to get default device", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchdevice.forDeviceID(idNumber) -> touchdeviceObject
/// Constructor
/// Returns the touchdevice object for the specified device id
///
/// Parameters:
///  * `idNumber` - an integer specifying the id number of the multi-touch device to create the touchdeviceObject for
///
/// Returns:
///  * a touchdeviceObject or nil if no multi-touch devices with the specified id is available
///
/// Notes:
///  * You can get a list of currently available device ids with [hs._asm.undocumented.touchdevice.devices](#devices) or get the device id for an existing object with [hs._asm.undocumented.touchdevice:deviceID](#deviceID).
static int touchdevice_forDeviceID(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TNUMBER | LS_TINTEGER, LS_TBREAK] ;
    uint64_t deviceID = (uint64_t)lua_tointeger(L, 1) ;

    MTDeviceRef device = MTDeviceCreateFromDeviceID(deviceID) ;
    if (device) {
        [skin pushNSObject:[[ASMTouchDevice alloc] initWithDevice:device]] ;
    } else {
        [skin logError:[NSString stringWithFormat:@"%s.forDeviceID - unable to get device for specified id: %lld", USERDATA_TAG, deviceID]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.undocumented.touchdevice:deviceID() -> integer
/// Method
/// Returns the device ID for the multi-touch device
///
/// Parameters:
///  * None
///
/// Returns:
///  * an integer specifying the device id for the multi-touch device represented by the touchdeviceObject
static int touchdevice_deviceID(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    uint64_t deviceID ;
    if (MTDeviceGetDeviceID(device, &deviceID) == 0) {
        lua_pushinteger(L, (lua_Integer)deviceID) ;
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s:deviceID - unable to get device ID for device", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:serialNumber() -> string
/// Method
/// Returns the serial number for the multi-touch device
///
/// Parameters:
///  * None
///
/// Returns:
///  * a string specifying the serial number of the multi-touch device represented by the touchdeviceObject
///
/// Notes:
///  * not all devices have a serial number so this value may be "None" or an empty string
static int touchdevice_serialNumber(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    CFStringRef serialNumber = NULL ;
    MTDeviceGetSerialNumber(device, &serialNumber) ;
    // The undocumented function looks for the key "Multitouch Serial Number", but apparently some devices use the label defined in IOKit/hid.h
    if (!serialNumber || CFStringGetLength(serialNumber) == 0) {
        if (serialNumber) CFRelease(serialNumber) ;
        serialNumber = (CFStringRef)IORegistryEntrySearchCFProperty(MTDeviceGetService(device), kIOServicePlane, CFSTR(kIOHIDSerialNumberKey), kCFAllocatorDefault, kIORegistryIterateRecursively) ;
    }
    if (serialNumber) {
        [skin pushNSObject:(__bridge NSString *)serialNumber] ;
        CFRelease(serialNumber) ;
    } else {
        lua_pushstring(L, "") ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:builtin() -> boolean
/// Method
/// Returns a boolean indicating whether or not the multi-touch device is built in
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is a built in device
///
/// Notes:
///  * This will be true for the trackpad built in to Mac laptops and false for any external device
static int touchdevice_builtin(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushboolean(L, MTDeviceIsBuiltIn(device)) ;
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:supportsForce() -> boolean
/// Method
/// Returns a boolean indicating whether or not the multi-touch device is a force touch device.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is a force touch device
///
/// Notes:
///  * Force touch devices provide haptic feedback indicating mouse clicks rather than use an actual mechanical switch to detect mouse clicks.
static int touchdevice_supportsForce(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushboolean(L, MTDeviceSupportsForce(device)) ;
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:supportsActuation() -> boolean
/// Method
/// Returns a boolean indicating whether or not the multi-touch device contains an actuator
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject contains an actuator
///
/// Notes:
///  * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
///
///  * The MultitouchSupport framework does provide undocumented functions for accessing the actuator directly, but so far I've found no examples to start experimenting with.  Further investigation is being considered but is not currently underway.
static int touchdevice_supportsActuation(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushboolean(L, MTDeviceSupportsActuation(device)) ;
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:opaqueSurface() -> boolean
/// Method
/// Returns a boolean indicating whether or not the multi-touch device is an opaque surface
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is an opaque surface
///
/// Notes:
///  * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
///
///  * This value appears to always be false unless the device is being watched for touch callbacks.
static int touchdevice_isOpaqueSurface(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushboolean(L, MTDeviceIsOpaqueSurface(device)) ;
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:running() -> boolean
/// Method
/// Returns a boolean indicating whether or not the multi-touch device is being monitored and generates callbacks for touch activity
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is being monitored and generates callbacks for touch activity
///
/// Notes:
///  * See [hs._asm.undocumented.touchdevice:start](#start) and [hs._asm.undocumented.touchdevice:stop](#stop)
static int touchdevice_isRunning(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushboolean(L, MTDeviceIsRunning(device)) ;
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:alive() -> boolean
/// Method
/// Returns a boolean indicating whether or not the multi-touch device is alive
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is alive
///
/// Notes:
///  * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
///  * I have only observed this as returning false; please submit details if you observe a different value.
static int touchdevice_isAlive(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushboolean(L, MTDeviceIsAlive(device)) ;
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:MTHIDDevice() -> boolean
/// Method
/// Returns a boolean indicating whether or not the multi-touch device is a HID device
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject is a HID device
///
/// Notes:
///  * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
static int touchdevice_isMTHIDDevice(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushboolean(L, MTDeviceIsMTHIDDevice(device)) ;
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:driverReady() -> boolean
/// Method
/// Returns a boolean indicating whether or not the multi-touch device driver is ready
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean indicating whether or not the driver for the multi-touch device represented by the touchdeviceObject is ready
///
/// Notes:
///  * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
static int touchdevice_driverReady(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushboolean(L, MTDeviceDriverIsReady(device)) ;
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:supportsPowerControl() -> boolean
/// Method
/// Returns a boolean indicating whether or not the multi-touch device supports power control
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean indicating whether or not the multi-touch device represented by the touchdeviceObject supports power control
///
/// Notes:
///  * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
///  * I have only observed this as returning false; please submit details if you observe a different value.
static int touchdevice_powerControlSupported(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushboolean(L, MTDevicePowerControlSupported(device)) ;
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:productName() -> string
/// Method
/// Returns the product name for the touch device as it is registered with the IOKit HID subsystem
///
/// Parameters:
///  * None
///
/// Returns:
///  * a string specifying the product name for the touch device represented by the touchdeviceObject as registered with the IOKit HID subsystem.
///
/// Notes:
///  * this information is purely informational and may be useful in differentiating multiple devices attached to the same machine
///  * some devices return a name corresponding to the marketting name for the device while others return a name created by the macOS generated when the device is first paired with the machine, usually the user's login name followed by "Mouse" or "Trackpad".  At this time, it is unknown if there is an independant way to determine which pattern a given device's product name will follow or if there is a way to return the marketting name for an otherwise named device; if someone more familiar with IOKit, especially with regards to HID devices has any thoughts on the matter, please submit an issue for consideration.
static int touchdevice_productName(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;

    CFStringRef deviceName = (CFStringRef)IORegistryEntrySearchCFProperty(MTDeviceGetService(device), kIOServicePlane, CFSTR(kIOHIDProductKey), kCFAllocatorDefault, kIORegistryIterateRecursively) ;

    if (deviceName) {
        [skin pushNSObject:(__bridge NSString *)deviceName] ;
        CFRelease(deviceName) ;
    } else {
        lua_pushstring(L, "") ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:sensorDimensions([inHmm]) -> sizeTable
/// Method
/// Returns the dimensions of the space on the touch device that can detect a touch
///
/// Parameters:
///  * `inHmm` - a boolean, default true, specifying whether the dimensions should be returned in hundredths of a millimeter (true) or as rows and columns (false)
///
/// Returns:
///  * a size table containing the sensor area dimensions where the height is the value assigned to the `h` key and the width is assigned to the `w` key.
///
/// Notes:
///  * At present, the usefulness of the row/column dimension values is currently unknown and it is being provided for information purposes only
///    * The row/column values seem to correspond to a grid used by the MultitouchSupport framework to differentiate between nearby touches and the exact size of each "cell" appears to be device dependent as the ratios between rows and columns versus the height and width as returned in hundredths of a millimeter is not consistent across devices.
static int touchdevice_sensorDimensions(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    BOOL inHmm = (lua_gettop(L) == 2) ? (BOOL)lua_toboolean(L, 2) : YES ;
    int width, height ;
    OSStatus s = inHmm ? MTDeviceGetSensorSurfaceDimensions(device, &width, &height) :
                         MTDeviceGetSensorDimensions(device, &width, &height) ;
    if (s == 0) {
        lua_newtable(L) ;
        lua_pushinteger(L, width)  ; lua_setfield(L, -2, "w") ;
        lua_pushinteger(L, height) ; lua_setfield(L, -2, "h") ;
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s:dimensions - unable to get surface dimensions for device", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:familyID() -> integer
/// Method
/// Returns an integer specifying the device family id for the touch device represented by the touchdeviceObject
///
/// Parameters:
///  * None
///
/// Returns:
///  * an integer specifying the device family id for the touch device represented by the touchdeviceObject
///
/// Notes:
///  * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
static int touchdevice_familyID(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    int familyID ;
    if (MTDeviceGetFamilyID(device, &familyID) == 0) {
        lua_pushinteger(L, familyID) ;
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s:familyID - unable to get family ID for device", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:version() -> integer
/// Method
/// Returns an integer specifying the bcdVersion for the touch device represented by the touchdeviceObject
///
/// Parameters:
///  * None
///
/// Returns:
///  * an integer specifying the bcdVersion for the touch device represented by the touchdeviceObject
///
/// Notes:
///  * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
static int touchdevice_version(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    int version ;
    if (MTDeviceGetVersion(device, &version) == 0) {
        lua_pushinteger(L, version) ;
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s:version - unable to get version for device", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:driverType() -> integer
/// Method
/// Returns an integer specifying the driver type for the touch device represented by the touchdeviceObject
///
/// Parameters:
///  * None
///
/// Returns:
///  * an integer specifying the driver type for the touch device represented by the touchdeviceObject
///
/// Notes:
///  * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
static int touchdevice_driverType(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    int driverType ;
    if (MTDeviceGetDriverType(device, &driverType) == 0) {
        lua_pushinteger(L, driverType) ;
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s:driverType - unable to get driver type for device", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:supportsSilentClick() -> boolean
/// Method
/// Returns a boolean specifying whether or not the touch device represented by the touchdeviceObject supports silent click
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean specifying whether or not the touch device represented by the touchdeviceObject supports silent click
///
/// Notes:
///  * This method will return true for non force-touch devices -- they do not have a simulated click sound associated with mouse clicks so they are considered "silent" by the MultitouchSupport framework already.
///  * Some force touch devices do not support disabling this simulated sound and will return false with this method; this seems to mostly apply to newer Mac Pro laptops, though an exhaustive list is beyond the scope of this documentation.  If you are uncertain about your force touch device, check Trackpad in System Preferences -- if you see an option for "Silent clicking" then this method should return true for your force touch device.
static int touchdevice_supportsSilentClick(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    BOOL silent ;
    if (MTDeviceSupportsSilentClick(device, &silent) == 0) {
        lua_pushboolean(L, silent) ;
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s:supportsSilentClick - unable to get silent click support for device", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:GUID() -> string
/// Method
/// Returns a string specifying the GUID for the touch device represented by the touchdeviceObject
///
/// Parameters:
///  * None
///
/// Returns:
///  * a string specifying the GUID for the touch device represented by the touchdeviceObject
///
/// Notes:
///  * At present, the usefulness of this information is currently unknown and it is being provided for information purposes only.
static int touchdevice_GUID(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    uuid_t guid ;
    if (MTDeviceGetGUID(device, &guid) == 0) {
        NSUUID *asUUID = [[NSUUID alloc] initWithUUIDBytes:guid] ;
        if (asUUID) {
            [skin pushNSObject:[asUUID UUIDString]] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:details - unable to parse GUID for device", USERDATA_TAG]] ;
            lua_pushnil(L) ;
        }
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s:details - unable to get GUID for device", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchdevice:forceResponseEnabled([state]) -> touchdeviceObject | boolean
/// Method
/// Get or set whether applying pressure to a force touch capable device will generate a mouse click or force touch
///
/// Parameters:
///  * `state` - an optional boolean specifying whether the force touch capable touch device will generate mouse clicks and force touches (true) or not (false).
///
/// Returns:
///  * if an argument is provided, returns the touchdeviceObject, otherwise returns the current value
///
/// Notes:
///  * When used with a non force touch device, the results of using this method are undefined - some will apparently change their value in response to this method while others will not; however the mouse click ability of the touch device will not be affected.
///
///  * When used with a force touch capable device, setting this value to false will prevent the device from being able to generate mouse clicks; multi touch gestures and mouse movement is unaffected however.
///  * This can be used to make such a device act more like a drawing tablet where the pressure can be used as a Z-axis without fear that a mouse click will change application focus or have other effects.
///  * ***WARNING*** - if you disable mouse clicks for a device with this method, it is re-enabled upon garbage collection of the userdata representing the touch device. This means:
///    * You must retain the userdata in a global variable (or local variable with an upvalue reference within a global function or table) for at least as long as you wish for mouse clicks to be suppressed.
///    * If you have multiple userdata objects for the *same* touch device created independently (with separate [hs._asm.undocumented.touchdevice.default](#default) or [hs._asm.undocumented.touchdevice.forDeviceID](#forDeviceID) function invocations), when any of them go out of scope and is garbage collected, mouse clicks will be re-enabled for the device.
///    * If Hammerspoon crashes or exits unexpectedly, it is likely that garbage collection will not occur.  In this case, you will have to restart Hammerspoon and use this method to re-enable mouse clicks or disconnect and reconnect your device (if it is external) or restart your machine (if it is not) to return the device to normal functionality.
///  * For these reasons, it is recommended that you only disable force response for as short a period as you require and the re-enable them so that everything remains in a predictable state.
///
///  * If you wish to suspend mouse gestures as well, you can use `hs.execute("killall -STOP Dock")`.  Note however that this disables gestures for *ALL* touch devices and also disables application switching from the keyboard as well (you can still click on an another applications windows with another mouse device though). You can resume normal operation of the gestures and keyboard shortcuts with `hs.execute("killall -CONT Dock")`. It is unknown what other processes suspending the Dock in this way may cause, so do so at your own risk.
static int touchdevice_forceResponseEnabled(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, MTDeviceGetSystemForceResponseEnabled(device)) ;
    } else {
        MTDeviceSetSystemForceResponseEnabled(device, (BOOL)lua_toboolean(L, 2)) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int touchdevice_frameCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;

    if (lua_gettop(L) == 2) {
        obj.frameCallbackRef = [skin luaUnref:refTable ref:obj.frameCallbackRef] ;
        MTUnregisterContactFrameCallback(device, frameCallbackFunction) ;
        if (lua_type(L, 2) == LUA_TFUNCTION) {
            if (MTRegisterContactFrameCallbackWithRefcon(device, frameCallbackFunction, (__bridge void *)obj)) {
                lua_pushvalue(L, 2) ;
                obj.frameCallbackRef = [skin luaRef:refTable] ;
                lua_pushvalue(L, 1) ;
            } else {
                [skin logWarn:[NSString stringWithFormat:@"%s:frameCallback - unable to register callback for device", USERDATA_TAG]] ;
                lua_pushnil(L) ;
            }
        }
    } else {
        if (obj.frameCallbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:obj.frameCallbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

static int touchdevice_pathCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;

    if (lua_gettop(L) == 2) {
        obj.pathCallbackRef = [skin luaUnref:refTable ref:obj.pathCallbackRef] ;
        MTUnregisterPathCallbackWithRefcon(device, pathCallbackFunction) ;
        if (lua_type(L, 2) == LUA_TFUNCTION) {
            if (MTRegisterPathCallbackWithRefcon(device, pathCallbackFunction, (__bridge void *)obj)) {
                lua_pushvalue(L, 2) ;
                obj.pathCallbackRef = [skin luaRef:refTable] ;
                lua_pushvalue(L, 1) ;
            } else {
                [skin logWarn:[NSString stringWithFormat:@"%s:pathCallback - unable to register callback for device", USERDATA_TAG]] ;
                lua_pushnil(L) ;
            }
        }
    } else {
        if (obj.pathCallbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:obj.pathCallbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

static int touchdevice_start(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    MTRunMode runMode = (lua_gettop(L) == 2) ? (lua_toboolean(L, 2) ? MTRunModeLessVerbose : MTRunModeVerbose) : MTRunModeVerbose ;
    if (obj.frameCallbackRef == LUA_NOREF && obj.pathCallbackRef == LUA_NOREF) {
        [skin logWarn:[NSString stringWithFormat:@"%s:start - no callback function has been assigned", USERDATA_TAG]] ;
    }
    if (MTDeviceIsRunning(device)) {
        [skin logDebug:[NSString stringWithFormat:@"%s:start - device already being watched", USERDATA_TAG]] ;
    } else {
        if (MTDeviceStart(device, runMode) != 0) {
            [skin logError:[NSString stringWithFormat:@"%s:start - error starting watcher", USERDATA_TAG]] ;
        }
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int touchdevice_stop(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    if (MTDeviceIsRunning(device)) {
        if (MTDeviceStop(device) != 0) {
            [skin logError:[NSString stringWithFormat:@"%s:stop - error stopping watcher", USERDATA_TAG]] ;
        }
    } else {
        [skin logDebug:[NSString stringWithFormat:@"%s:stop - device is not being watched", USERDATA_TAG]] ;
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

#if defined(INCLUDE_QUESTIONABLE_METHODS)

static int touchdevice_enableDebugCallbacks(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TBOOLEAN | LS_TOPTIONAL,
                    LS_TBOOLEAN | LS_TOPTIONAL,
                    LS_TBOOLEAN | LS_TOPTIONAL,
                    LS_TBOOLEAN | LS_TOPTIONAL,
                    LS_TBOOLEAN | LS_TOPTIONAL,
                    LS_TBOOLEAN | LS_TOPTIONAL,
                    LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    BOOL arg1 = (lua_gettop(L) > 1) ? (BOOL)lua_toboolean(L, 2) : NO ; // MTRegisterPathCallback(MTDeviceRef, MTPathPrintCallback) ;
    BOOL arg2 = (lua_gettop(L) > 2) ? (BOOL)lua_toboolean(L, 3) : NO ; // MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImagePrintCallback, 0x7ffffffe, 0x2, NULL) ;
    BOOL arg3 = (lua_gettop(L) > 3) ? (BOOL)lua_toboolean(L, 4) : NO ; // MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImagePrintCallback, 0x2, 0x10, NULL) ;
    BOOL arg4 = (lua_gettop(L) > 4) ? (BOOL)lua_toboolean(L, 5) : NO ; // MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImagePrintCallback, 0x2, 0x10000, NULL) ;
    BOOL arg5 = (lua_gettop(L) > 5) ? (BOOL)lua_toboolean(L, 6) : NO ; // MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImagePrintCallback, 0x2, 0x100000, NULL) ;
    BOOL arg6 = (lua_gettop(L) > 6) ? (BOOL)lua_toboolean(L, 7) : NO ; // MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImagePrintCallback, 0x2, 0x800000, NULL ) ;
    MTEasyInstallPrintCallbacks(device, arg1, arg2, arg3, arg4, arg5, arg6) ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int touchdevice_minDigitizerPressure(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushnumber(L, MTDeviceGetMinDigitizerPressureValue(device)) ;
    return 1 ;
}

static int touchdevice_maxDigitizerPressure(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushnumber(L, MTDeviceGetMaxDigitizerPressureValue(device)) ;
    return 1 ;
}

static int touchdevice_digitizerPressureRange(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    lua_pushnumber(L, MTDeviceGetDigitizerPressureDynamicRange(device)) ;
    return 1 ;
}

static int touchdevice_powerEnabled(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    ASMTouchDevice *obj = [skin toNSObjectAtIndex:1] ;
    MTDeviceRef device = obj.touchDevice ;
    if (lua_gettop(L) == 1) {
        BOOL state = NO ;
        MTDevicePowerGetEnabled(device, &state) ;
        lua_pushboolean(L, state) ;
    } else {
        if (MTDevicePowerSetEnabled(device, (BOOL)lua_toboolean(L, 2))) {
            lua_pushvalue(L, 1) ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:powerEnabled - unable to set power enabled for device", USERDATA_TAG]] ;
        }
    }
    return 1 ;
}

#endif

#pragma mark - Module Constants

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushASMTouchDevice(lua_State *L, id obj) {
    ASMTouchDevice *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(ASMTouchDevice *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toASMTouchDeviceFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    ASMTouchDevice *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge ASMTouchDevice, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    ASMTouchDevice *obj = [skin luaObjectAtIndex:1 toClass:"ASMTouchDevice"] ;
    MTDeviceRef device = obj.touchDevice ;
    NSString *deviceIDString = @"<unknown>" ;
    uint64_t deviceID ;
    if (MTDeviceGetDeviceID(device, &deviceID) == 0) {
        deviceIDString = [NSString stringWithFormat:@"%llu", deviceID] ;
    }
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, deviceIDString, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        ASMTouchDevice *obj1 = [skin luaObjectAtIndex:1 toClass:"ASMTouchDevice"] ;
        ASMTouchDevice *obj2 = [skin luaObjectAtIndex:2 toClass:"ASMTouchDevice"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    ASMTouchDevice *obj = get_objectFromUserdata(__bridge_transfer ASMTouchDevice, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin shared] ;
            obj.frameCallbackRef = [skin luaUnref:refTable ref:obj.frameCallbackRef] ;
            obj.pathCallbackRef = [skin luaUnref:refTable ref:obj.pathCallbackRef] ;
            MTUnregisterPathCallbackWithRefcon(obj.touchDevice, pathCallbackFunction) ;
            MTUnregisterContactFrameCallback(obj.touchDevice, frameCallbackFunction) ;
            if (MTDeviceIsRunning(obj.touchDevice)) MTDeviceStop(obj.touchDevice) ;
            if (!MTDeviceGetSystemForceResponseEnabled(obj.touchDevice)) {
                MTDeviceSetSystemForceResponseEnabled(obj.touchDevice, YES) ;
            }
            MTDeviceRelease(obj.touchDevice) ;
            obj = nil ;
        }
    }

    // Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;
    return 0 ;
}

// static int meta_gc(lua_State* __unused L) {
//     return 0 ;
// }

// Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
//     {"details",               touchdevice_details},
    {"frameCallback",         touchdevice_frameCallback},
    {"pathCallback",          touchdevice_pathCallback},
    {"start",                 touchdevice_start},
    {"stop",                  touchdevice_stop},
    {"deviceID",              touchdevice_deviceID},
    {"builtin",               touchdevice_builtin},
    {"supportsForce",         touchdevice_supportsForce},
    {"supportsActuation",     touchdevice_supportsActuation},
    {"opaqueSurface",         touchdevice_isOpaqueSurface},
    {"running",               touchdevice_isRunning},
    {"alive",                 touchdevice_isAlive},
    {"MTHIDDevice",           touchdevice_isMTHIDDevice},
    {"supportsPowerControl",  touchdevice_powerControlSupported},
    {"sensorDimensions",      touchdevice_sensorDimensions},
    {"familyID",              touchdevice_familyID},
    {"driverType",            touchdevice_driverType},
    {"GUID",                  touchdevice_GUID},
    {"driverReady",           touchdevice_driverReady},
    {"serialNumber",          touchdevice_serialNumber},
    {"version",               touchdevice_version},
    {"supportsSilentClick",   touchdevice_supportsSilentClick},
    {"forceResponseEnabled",  touchdevice_forceResponseEnabled},
    {"productName",           touchdevice_productName},

#if defined(INCLUDE_QUESTIONABLE_METHODS)
    {"enableDebugCallbacks",  touchdevice_enableDebugCallbacks},
    {"powerEnabled",          touchdevice_powerEnabled},
    {"minDigitizerPressure",  touchdevice_minDigitizerPressure},
    {"maxDigitizerPressure",  touchdevice_maxDigitizerPressure},
    {"digitizerPressureRange", touchdevice_digitizerPressureRange},
#endif

    {"__tostring",            userdata_tostring},
    {"__eq",                  userdata_eq},
    {"__gc",                  userdata_gc},
    {NULL,                    NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"absoluteTime", touchdevice_absoluteTime},
    {"available",   touchdevice_isAvailable},
    {"devices",     touchdevice_devices},
    {"default",     touchdevice_default},
    {"forDeviceID", touchdevice_forDeviceID},
    {NULL, NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_undocumented_touchdevice_internal(lua_State* __unused L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil // module_metaLib
                               objectFunctions:userdata_metaLib];

    // we use this instead of MTGetPathStageName because the camel casing follows HS convention and
    // we can more easily determine if it's out of range
    pathStageNames = @[
        @"notTracking",
        @"startInRange",
        @"hoverInRange",
        @"makeTouch",
        @"touching",
        @"breakTouch",
        @"lingerInRange",
        @"outOfRange",
    ] ;

    [skin registerPushNSHelper:pushASMTouchDevice         forClass:"ASMTouchDevice"];
    [skin registerLuaObjectHelper:toASMTouchDeviceFromLua forClass:"ASMTouchDevice"
                                               withUserdataMapping:USERDATA_TAG];

    return 1;
}
