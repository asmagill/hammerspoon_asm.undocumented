@import Cocoa ;
@import LuaSkin ;
@import IOBluetooth ;

static LSRefTable refTable = LUA_NOREF ;

// private methods
extern int IOBluetoothPreferencesAvailable(void) __attribute__((weak_import));

extern int IOBluetoothPreferenceGetControllerPowerState(void) __attribute__((weak_import));
extern void IOBluetoothPreferenceSetControllerPowerState(int state) __attribute__((weak_import));

extern int IOBluetoothPreferenceGetDiscoverableState(void) __attribute__((weak_import));
extern void IOBluetoothPreferenceSetDiscoverableState(int state) __attribute__((weak_import));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"

/// hs._asm.undocumented.bluetooth.available() -> bool
/// Function
/// Returns true or false, indicating whether bluetooth is available on this machine.
///
/// Parameters:
///  * None
///
/// Returns:
///  * true if bluetooth is available on this machine, false if it is not; returns nil if bluetooth framework unavailable (this has been observed in some virtual machines)
static int bt_available(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBREAK] ;

    if (IOBluetoothPreferencesAvailable != NULL) {
        if (IOBluetoothPreferencesAvailable()) {
            lua_pushboolean(L, YES) ;
        } else {
            lua_pushboolean(L, NO) ;
        }
    } else {
        lua_pushnil(L) ;
    }

    return 1;
}


/// hs._asm.undocumented.bluetooth.power([state]) -> bool
/// Function
/// Get or set bluetooth power state.
///
/// Parameters:
///  * state - an optional boolean value indicating whether bluetooth power should be turned on (true) or off (false)
///
/// Returns:
///  * the (possibly changed) current value; returns nil if bluetooth framework unavailable (this has been observed in some virtual machines)
static int bt_power(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;

    if (IOBluetoothPreferenceGetControllerPowerState != NULL && IOBluetoothPreferenceSetControllerPowerState != NULL) {
        if (!lua_isnone(L, 1)) {
            IOBluetoothPreferenceSetControllerPowerState((Boolean) lua_toboolean(L, -1));
            usleep(1000000); // Apparently it doesn't like being re-queried too quickly
        }

        if (IOBluetoothPreferenceGetControllerPowerState()) {
            lua_pushboolean(L, YES) ;
        } else {
            lua_pushboolean(L, NO) ;
        }
    } else {
        lua_pushnil(L) ;
    }
    return 1;
}

/// hs._asm.undocumented.bluetooth.discoverable([state]) -> bool
/// Function
/// Get or set bluetooth discoverable state.
///
/// Parameters:
///  * state - an optional boolean value indicating whether bluetooth the machine should be discoverable (true) or not (false)
///
/// Returns:
///  * the (possibly changed) current value; returns nil if bluetooth framework unavailable (this has been observed in some virtual machines)
///
/// Notes:
///  * use of this method to change discoverability has been observed to cause connected devices to disconnect in rare cases; use at your own risk.
///  * Opening the Bluetooth preference pane always turns on discoverability if bluetooth power is on or if it is switched on when preference pane is open; this change of discoverability is *not* reported by the API function used by this function.
static int bt_discoverable(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;

    if (IOBluetoothPreferenceSetDiscoverableState != NULL && IOBluetoothPreferenceGetDiscoverableState != NULL) {
        if (!lua_isnone(L, 1)) {
            IOBluetoothPreferenceSetDiscoverableState((Boolean) lua_toboolean(L, -1));
            usleep(1000000);  // Apparently it doesn't like being re-queried too quickly
        }

        if (IOBluetoothPreferenceGetDiscoverableState()) {
            lua_pushboolean(L, YES) ;
        } else {
            lua_pushboolean(L, NO) ;
        }
    } else {
        lua_pushnil(L) ;
    }
    return 1;
}

#pragma clang diagnostic pop

static const luaL_Reg moduleLib[] = {
    {"available",           bt_available},
    {"power",               bt_power},
    {"discoverable",        bt_discoverable},
    {NULL, NULL}
};

int luaopen_hs__asm_undocumented_bluetooth_internal(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    refTable = [skin registerLibrary:"hs._asm.undocumented.bluetooth" functions:moduleLib metaFunctions:nil] ;

    return 1;
}
