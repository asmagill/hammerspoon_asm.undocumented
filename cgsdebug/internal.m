#import <Cocoa/Cocoa.h>
// #import <Carbon/Carbon.h>
#import <LuaSkin/LuaSkin.h>
#import "cgsdebug.h"

int refTable ;

/// hs._asm.undocumented.cgsdebug.cgsdebug.get(option) -> boolean
/// Function
/// Returns the current state of the CGSDebug option specified by `option`
///
/// Parameters:
///  * option - a number corresponding to a label defined in `hs._asm.undocumented.cgsdebug.cgsdebug.options[]`.
///
/// Returns:
///  * the current state as a boolean
static int cgsdebug_get(lua_State* L) {
    [[LuaSkin shared] checkArgs:LS_TNUMBER, LS_TBREAK] ;

    CGSDebugOption the_option = (CGSDebugOption)luaL_checkinteger(L, 1);
    CGSDebugOption actual_options;
    CGSGetDebugOptions(&actual_options) ;

    if (actual_options & the_option)
        lua_pushboolean(L, YES);
    else
        lua_pushboolean(L, NO);
    return 1;
}

/// hs._asm.undocumented.cgsdebug.cgsdebug.set(option, value) -> none
/// Function
/// Enable or disable the CGSDebug option specified
///
/// Parameters:
///  * option - a number corresponding to a label defined in `hs._asm.undocumented.cgsdebug.cgsdebug.options[]`.
///  * value  - a boolean value indicating whether the option should be enabled (true) or disabled (false)
///
/// Returns:
///  * None
static int cgsdebug_set(lua_State* L) {
    [[LuaSkin shared] checkArgs:LS_TNUMBER, LS_TBOOLEAN, LS_TBREAK] ;

    CGSDebugOption the_option = (CGSDebugOption)luaL_checkinteger(L, 1);
    BOOL on = (BOOL)lua_toboolean(L, 2);

    CGSDebugOption actual_options;
    CGSGetDebugOptions(&actual_options) ;
    actual_options = on ? (actual_options | the_option) : (actual_options & ~the_option);
    CGSSetDebugOptions(actual_options);
    return 0;
}

/// hs._asm.undocumented.cgsdebug.cgsdebug.clear() -> none
/// Function
/// Clears (disables) all of the CGSDebug option flags.
///
/// Parameters:
///  * None
///
/// Returns:
///  * None
static int cgsdebug_clear(lua_State* __unused L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;

    CGSSetDebugOptions(kCGSDebugOptionNone);
    return 0;
}

/// hs._asm.undocumented.cgsdebug.cgsdebug.getMask() -> bitmask
/// Function
/// Returns the integer value representing the bitmask of all currently enabled CGSDebug options.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the integer value representing the bitmask of all currently enabled CGSDebug options
static int cgsdebug_mask(lua_State* L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;

    CGSDebugOption options;
    CGSGetDebugOptions(&options) ;

    lua_pushinteger(L, options) ;
    return 1;
}

/// hs._asm.undocumented.cgsdebug.cgsdebug.shadow(state) -> none
/// Function
/// Enable or disable whether or not OSX Applications have shadows.
///
/// Parameters:
///  * state - a boolean value indicating whether or not OS X windows should have shadows
///
/// Returns:
///  * None
static int cgsdebug_shadow(lua_State* L) {
   [[LuaSkin shared] checkArgs:LS_TBOOLEAN, LS_TBREAK] ;

   BOOL on = (BOOL)lua_toboolean(L, 1);

    CGSDebugOption options;
    CGSGetDebugOptions(&options);
    options = on ? (options & ~(unsigned int)kCGSDebugOptionNoShadows) : (options | kCGSDebugOptionNoShadows);
    CGSSetDebugOptions(options);
    return 0;
}

/// hs._asm.undocumented.cgsdebug.cgsdebug.options[]
/// Variable
/// Connivence array of all currently known debug options.
///
///  * flashScreenUpdates       - All screen updates are flashed in yellow. Regions under a DisableUpdate are flashed in orange. Regions that are hardware accellerated are painted green.
///  * colorByAcceleration      - Colors windows green if they are accellerated, otherwise red. Doesn't cause things to refresh properly - leaves excess rects cluttering the screen.
///  * noShadows                - Disables shadows on all windows.
///  * noDelayAfterFlash        - Setting this disables the pause after a flash when using FlashScreenUpdates or FlashIdenticalUpdates.
///  * autoflushDrawing         - Flushes the contents to the screen after every drawing operation.
///  * showMouseTrackingAreas   - Highlights mouse tracking areas. Doesn't cause things to refresh correctly - leaves excess rectangles cluttering the screen.
///  * flashIdenticalUpdates    - Flashes identical updates in red.
///  * dumpWindowListToFile     - Dumps a list of windows to /tmp/WindowServer.winfo.out. This is what Quartz Debug uses to get the window list.
///  * dumpConnectionListToFile - Dumps a list of connections to /tmp/WindowServer.cinfo.out.
///  * verboseLogging           - Dumps a very verbose debug log of the WindowServer to /tmp/CGLog_WinServer_PID.
///  * verboseLoggingAllApps    - Dumps a very verbose debug log of all processes to /tmp/CGLog_NAME_PID.
///  * dumpHotKeyListToFile     - Dumps a list of hotkeys to /tmp/WindowServer.keyinfo.out.
///  * dumpSurfaceInfo          - Dumps SurfaceInfo? to /tmp/WindowServer.sinfo.out
///  * dumpOpenGLInfoToFile     - Dumps information about OpenGL extensions, etc to /tmp/WindowServer.glinfo.out.
///  * dumpShadowListToFile     - Dumps a list of shadows to /tmp/WindowServer.shinfo.out.
///  * dumpWindowListToPlist    - Dumps a list of windows to `/tmp/WindowServer.winfo.plist`. This is what Quartz Debug on 10.5 uses to get the window list.
///  * dumpResourceUsageToFiles - Dumps information about an application's resource usage to `/tmp/CGResources_NAME_PID`.
static void cgsdebug_options (lua_State *L) {
    lua_newtable(L) ;
//    lua_pushinteger(L, kCGSDebugOptionNone);                        lua_setfield(L, -2, "none") ;
    lua_pushinteger(L, kCGSDebugOptionFlashScreenUpdates);          lua_setfield(L, -2, "flashScreenUpdates") ;
    lua_pushinteger(L, kCGSDebugOptionColorByAccelleration);        lua_setfield(L, -2, "colorByAcceleration") ;
    lua_pushinteger(L, kCGSDebugOptionNoShadows);                   lua_setfield(L, -2, "noShadows") ;
    lua_pushinteger(L, kCGSDebugOptionNoDelayAfterFlash);           lua_setfield(L, -2, "noDelayAfterFlash") ;
    lua_pushinteger(L, kCGSDebugOptionAutoflushDrawing);            lua_setfield(L, -2, "autoFlushDrawing") ;
    lua_pushinteger(L, kCGSDebugOptionShowMouseTrackingAreas);      lua_setfield(L, -2, "showMouseTrackingAreas") ;
    lua_pushinteger(L, kCGSDebugOptionFlashIdenticalUpdates);       lua_setfield(L, -2, "flashIdenticalUpdates") ;
    lua_pushinteger(L, kCGSDebugOptionDumpWindowListToFile);        lua_setfield(L, -2, "dumpWindowListToFile") ;
    lua_pushinteger(L, kCGSDebugOptionDumpConnectionListToFile);    lua_setfield(L, -2, "dumpConnectionListToFile") ;
    lua_pushinteger(L, kCGSDebugOptionVerboseLogging);              lua_setfield(L, -2, "verboseLogging") ;
    lua_pushinteger(L, kCGSDebugOptionVerboseLoggingAllApps);       lua_setfield(L, -2, "verboseLoggingAllApps") ;
    lua_pushinteger(L, kCGSDebugOptionDumpHotKeyListToFile);        lua_setfield(L, -2, "dumpHotKeyListToFile") ;
    lua_pushinteger(L, kCGSDebugOptionDumpSurfaceInfo);             lua_setfield(L, -2, "dumpSurfaceInfo") ;
    lua_pushinteger(L, kCGSDebugOptionDumpOpenGLInfoToFile);        lua_setfield(L, -2, "dumpOpenGLInfoToFile") ;
    lua_pushinteger(L, kCGSDebugOptionDumpShadowListToFile);        lua_setfield(L, -2, "dumpShadowListToFile") ;
    lua_pushinteger(L, kCGSDebugOptionDumpWindowListToPlist);       lua_setfield(L, -2, "dumpWindowListToPlist") ;
    lua_pushinteger(L, kCGSDebugOptionDumpResourceUsageToFiles);    lua_setfield(L, -2, "dumpResourceUsageToFiles") ;
}

static const luaL_Reg moduleLib[] = {
    {"get",     cgsdebug_get},
    {"set",     cgsdebug_set},
    {"clear",   cgsdebug_clear},
    {"getMask", cgsdebug_mask},
    {"shadow",  cgsdebug_shadow},
    {NULL, NULL}
};

int luaopen_hs__asm_undocumented_cgsdebug_internal(lua_State* L) {
    refTable = [[LuaSkin shared] registerLibrary:moduleLib metaFunctions:nil] ;

    cgsdebug_options(L) ; lua_setfield(L, -2, "options") ;
    return 1;
}
