#import <Cocoa/Cocoa.h>
// #import <Carbon/Carbon.h>
#import <LuaSkin/LuaSkin.h>

int refTable ;

// private methods
int IOBluetoothPreferencesAvailable();

int IOBluetoothPreferenceGetControllerPowerState();
void IOBluetoothPreferenceSetControllerPowerState(int state);

int IOBluetoothPreferenceGetDiscoverableState();
void IOBluetoothPreferenceSetDiscoverableState(int state);

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
///  * None
static int bt_available(lua_State* L) {
   [[LuaSkin shared] checkArgs:LS_TBREAK] ;

   if (IOBluetoothPreferencesAvailable != NULL) {
        if (IOBluetoothPreferencesAvailable())
            lua_pushboolean(L, YES) ;
        else
            lua_pushboolean(L, NO) ;
    } else
        lua_pushboolean(L, NO) ;

    return 1;
}


/// hs._asm.undocumented.bluetooth.power([bool]) -> bool
/// Function
/// If an argument is provided, set bluetooth power state to on (true) or off (false) and returns the (possibly new) status. If no argument is provided, then this function returns true or false, indicating whether bluetooth is currently enabled for this machine.
///
/// Parameters:
///  * state - an optional boolean value indicating whether bluetooth should be turned on (true) or off (false)
///
/// Returns:
///  * the (possibly changed) current value
static int bt_power(lua_State* L) {
   [[LuaSkin shared] checkArgs:LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;

    if (IOBluetoothPreferenceGetControllerPowerState != NULL && IOBluetoothPreferenceSetControllerPowerState != NULL) {
        if (!lua_isnone(L, 1)) {
            IOBluetoothPreferenceSetControllerPowerState((Boolean) lua_toboolean(L, -1));
            usleep(1000000); // Apparently it doesn't like being re-queried too quickly
        }
        if (IOBluetoothPreferenceGetControllerPowerState())
            lua_pushboolean(L, YES) ;
        else
            lua_pushboolean(L, NO) ;
    } else
        lua_pushboolean(L, NO) ;

    return 1;
}

// This has provided too unreliable and can actually cause some devices (my Magic mouse) to occasionally drop off,
// so I disable it.  Add it back, if you like and can fix it, and I'll either update the module or you can take over!

// /// hs._asm.undocumented.bluetooth.discoverable([bool]) -> bool
// /// Function
// /// If an argument is provided, set bluetooth discoverable state to on (true) or off (false) and return the (possibly new) state. If no argument is provided, then this function returns true or false, indicating whether this machine is currently discoverable via bluetooth.
// static int bt_discoverable(lua_State* L) {
//     if (!lua_isnone(L, 1)) {
//         IOBluetoothPreferenceSetDiscoverableState((Boolean) lua_toboolean(L, -1));
//         usleep(1000000);  // Apparently it doesn't like being re-queried too quickly
//     }
//     if (IOBluetoothPreferenceGetDiscoverableState())
//         lua_pushboolean(L, YES) ;
//     else
//         lua_pushboolean(L, NO) ;
//     return 1;
// }

#pragma clang diagnostic pop

static const luaL_Reg moduleLib[] = {
    {"available",           bt_available},
    {"power",               bt_power},
//    {"discoverable",        bt_discoverable},
    {NULL, NULL}
};

int luaopen_hs__asm_undocumented_bluetooth_internal(__unused lua_State* L) {
    refTable = [[LuaSkin shared] registerLibrary:moduleLib metaFunctions:nil] ;

    return 1;
}
