@import Cocoa ;
@import LuaSkin ;
#import "coredock.h"

static const char *USERDATA_TAG = "hs._asm.undocumented.coredock" ;

static LSRefTable refTable = LUA_NOREF ;

/// hs._asm.undocumented.coredock.tileSize([size]) -> float
/// Function
/// Get or set the Dock icon tile size as a number between 0.0 and 1.0.
///
/// Parameters:
///  * size - an optional number between 0.0 and 1.0 to set the Dock icon tile size to.
///
/// Returns:
///  * the (possibly changed) current value
static int coredock_tilesize(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;

    if (!lua_isnone(L, 1)) {
        float tileSize = (float) luaL_checknumber(L, -1) ;
        if (tileSize >= 0 && tileSize <= 1)
            CoreDockSetTileSize(tileSize) ;
        else
            return luaL_error(L,"tilesize must be a number between 0.0 and 1.0") ;
    }
    lua_pushnumber(L, (lua_Number)CoreDockGetTileSize()) ;
    return 1 ;
}

/// hs._asm.undocumented.coredock.magnificationSize([size]) -> float
/// Function
/// Get or set the Dock icon magnification size as a number between 0.0 and 1.0.
///
/// Parameters:
///  * size - an optional number between 0.0 and 1.0 to set the Dock icon magnification size to.
///
/// Returns:
///  * the (possibly changed) current value
static int coredock_magnification_size(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;

    if (!lua_isnone(L, 1)) {
        float magSize = (float) luaL_checknumber(L, -1) ;
        if (magSize >= 0 && magSize <= 1)
            CoreDockSetMagnificationSize(magSize) ;
        else
            return luaL_error(L,"magnification_size must be a number between 0.0 and 1.0") ;
    }
    lua_pushnumber(L, (lua_Number)CoreDockGetMagnificationSize()) ;
    return 1 ;
}

// /// hs._asm.undocumented.coredock.oandp(orientation, pinning)
// /// Function
// /// Sets the Dock orientation and pinning simultaneously to the placement indicated by orientation and pinning.
// static int coredock_oandp(lua_State* L) {
//     CoreDockOrientation ourOrientation = luaL_checkinteger(L, -2) ;
//     CoreDockPinning     ourPinning = luaL_checkinteger(L, -1) ;
//
//     CoreDockSetOrientationAndPinning(ourOrientation, ourPinning) ;
//     return 0 ;
// }

/// hs._asm.undocumented.coredock.orientation([orientation]) -> orientation
/// Function
/// Get or set the Dock orientation.
///
/// Parameters:
///  * orientation - an integer as specified in `hs._asm.undocumented.coredock.options.orientation`
///
/// Returns:
///  * the (possibly changed) current value
///
/// Notes:
///  * the top orientation and dock pinning has not been supported even within the private APIs for some time and may disappear from here in a future release unless another solution can be found.  It is provided here for testing and to encourage suggestions if someone is aware of a solution that has not yet been tried.
static int coredock_orientation(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;

    if (!lua_isnone(L, 1)) {
        CoreDockOrientation ourOrientation = (CoreDockOrientation)(luaL_checkinteger(L, -1)) ;
        CoreDockPinning ourPinning = kCoreDockPinningIgnore ;
        CoreDockSetOrientationAndPinning(ourOrientation, ourPinning) ;
    }
    CoreDockOrientation ourOrientation ;
    CoreDockPinning     ourPinning ;
    CoreDockGetOrientationAndPinning(&ourOrientation, &ourPinning) ;
    lua_pushinteger(L, (int) ourOrientation) ;
    return 1 ;
}

/// hs._asm.undocumented.coredock.pinning([pinning]) -> pinning
/// Function
/// Get or set the Dock pinning.
///
/// Parameters:
///  * pinning - an integer as specified in `hs._asm.undocumented.coredock.options.pinning`
///
/// Returns:
///  * the (possibly changed) current value
///
/// Notes:
///  * the top orientation and dock pinning has not been supported even within the private APIs for some time and may disappear from here in a future release unless another solution can be found.  It is provided here for testing and to encourage suggestions if someone is aware of a solution that has not yet been tried.
static int coredock_pinning(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;

    if (!lua_isnone(L, 1)) {
        CoreDockOrientation ourOrientation = kCoreDockOrientationIgnore ;
        CoreDockPinning ourPinning = (CoreDockPinning)(luaL_checkinteger(L, -1)) ;
        CoreDockSetOrientationAndPinning(ourOrientation, ourPinning) ;
    }
    CoreDockOrientation ourOrientation ;
    CoreDockPinning     ourPinning ;
    CoreDockGetOrientationAndPinning(&ourOrientation, &ourPinning) ;
    lua_pushinteger(L, (int) ourPinning) ;
    return 1 ;
}


/// hs._asm.undocumented.coredock.magnification([state]) -> bool
/// Function
/// Get or set whether or not the Dock Magnification is enabled.
///
/// Parameters:
///  * state - an optional boolean value specifying whether or not Dock Magnification should be enabled.
///
/// Returns:
///  * the (possibly changed) current value
static int coredock_magnification(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;

    if (!lua_isnone(L, 1)) {
        CoreDockSetMagnificationEnabled((Boolean) lua_toboolean(L, -1)) ;
    }
    if (CoreDockIsMagnificationEnabled()) lua_pushboolean(L, YES) ; else lua_pushboolean(L, NO) ;
    return 1 ;
}

/// hs._asm.undocumented.coredock.autoHide([state]) -> bool
/// Function
/// Get or set whether or not Dock Hiding is enabled.
///
/// Parameters:
///  * state - an optional boolean value specifying whether or not Dock Hiding should be enabled.
///
/// Returns:
///  * the (possibly changed) current value
static int coredock_autohide(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;

    if (!lua_isnone(L, 1)) {
        CoreDockSetAutoHideEnabled((Boolean) lua_toboolean(L, -1)) ;
    }
    if (CoreDockGetAutoHideEnabled()) lua_pushboolean(L, YES) ; else lua_pushboolean(L, NO) ;
    return 1 ;
}

/// hs._asm.undocumented.coredock.animationEffect([effect]) -> effect
/// Function
/// Get or set the Dock pinning.
///
/// Parameters:
///  * effect - an integer as specified in `hs._asm.undocumented.coredock.options.effect`
///
/// Returns:
///  * the (possibly changed) current value
static int coredock_animationeffect(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;

    if (!lua_isnone(L, 1)) {
        CoreDockEffect ourEffect = (CoreDockEffect)(luaL_checkinteger(L, -1)) ;
        CoreDockSetEffect(ourEffect) ;
    }
    CoreDockEffect  ourEffect ;
    CoreDockGetEffect(&ourEffect) ;
    lua_pushinteger(L, (int) ourEffect) ;
    return 1 ;
}

/// hs._asm.undocumented.coredock.options[]
/// Variable
/// Connivence array of all currently defined coredock options.
///
///  Note that the top orientation has not been supported even within the private APIs for some time and may disappear from here in a future release unless another solution can be found.
///  * options.orientation[]  -- an array of the orientation options available for `orientation`
///    * top         -- put the dock at the top of the monitor
///    * bottom      -- put the dock at the bottom of the monitor
///    * left        -- put the dock at the left of the monitor
///    * right       -- put the dock at the right of the monitor
///
///  Note that dock pinning has not been supported even within the private APIs for some time and may disappear from here in a future release unless another solution can be found.
///  * options.pinning[]  -- an array of the pinning options available for `pinning`
///    * start       -- pin the dock at the start of its orientation
///    * middle      -- pin the dock at the middle of its orientation
///    * end         -- pin the dock at the end of its orientation
///
///     Note that the suck animation is not displayed in the System Preferences panel correctly, but does remain in effect as long as you do not change this specific field while in the Preferences panel for the Dock.
///  * options.effect[]   -- an array of the dock animation options for  `animation_effect`
///    * genie       -- use the genie animation
///    * scale       -- use the scale animation
///    * suck        -- use the suck animation
///
/// Notes:
///  * the top orientation and dock pinning has not been supported even within the private APIs for some time and may disappear from here in a future release unless another solution can be found.  It is provided here for testing and to encourage suggestions if someone is aware of a solution that has not yet been tried.
static void coredock_options (lua_State *L) {
    lua_newtable(L) ;
        lua_newtable(L) ;
            lua_pushinteger(L, kCoreDockOrientationTop) ;    lua_setfield(L, -2, "top") ;
            lua_pushinteger(L, kCoreDockOrientationBottom) ; lua_setfield(L, -2, "bottom") ;
            lua_pushinteger(L, kCoreDockOrientationLeft) ;   lua_setfield(L, -2, "left") ;
            lua_pushinteger(L, kCoreDockOrientationRight) ;  lua_setfield(L, -2, "right") ;
        lua_setfield(L, -2, "orientation") ;
        lua_newtable(L) ;
            lua_pushinteger(L, kCoreDockPinningStart) ;  lua_setfield(L, -2, "start") ;
            lua_pushinteger(L, kCoreDockPinningMiddle) ; lua_setfield(L, -2, "middle") ;
            lua_pushinteger(L, kCoreDockPinningEnd) ;    lua_setfield(L, -2, "end") ;
        lua_setfield(L, -2, "pinning") ;
        lua_newtable(L) ;
            lua_pushinteger(L, kCoreDockEffectGenie) ;   lua_setfield(L, -2, "genie") ;
            lua_pushinteger(L, kCoreDockEffectScale) ;   lua_setfield(L, -2, "scale") ;
            lua_pushinteger(L, kCoreDockEffectSuck) ;    lua_setfield(L, -2, "suck") ;
        lua_setfield(L, -2, "effect") ;
}

static const luaL_Reg moduleLib[] = {
    {"tileSize",            coredock_tilesize},
    {"orientation",         coredock_orientation},
    {"pinning",             coredock_pinning},
    {"animationEffect",     coredock_animationeffect},
    {"autoHide",            coredock_autohide},
    {"magnification",       coredock_magnification},
    {"magnificationSize",   coredock_magnification_size},
    {NULL,                  NULL}
} ;

int luaopen_hs__asm_undocumented_coredock_internal(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    refTable = [skin registerLibrary:USERDATA_TAG functions:moduleLib metaFunctions:nil] ;

    coredock_options(L) ; lua_setfield(L, -2, "options") ;
    return 1 ;
}
