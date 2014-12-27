#import <Cocoa/Cocoa.h>
#import <lauxlib.h>
#import "coredock.h"

/// {PATH}.{MODULE}.tileSize([float]) -> float
/// Function
/// If an argument is provided, set the Dock icon tile size to a number between 0.0 and 1.0 and return the (possibly new) tile size.  If no argument is provided, then this function returns the current tile size as a number between 0.0 and 1.0.
static int coredock_tilesize(lua_State* L) {
    if (!lua_isnone(L, 1)) {
        float tileSize = (float) luaL_checknumber(L, -1);
        if (tileSize >= 0 && tileSize <= 1)
            CoreDockSetTileSize(tileSize);
        else
            return luaL_error(L,"tilesize must be a number between 0.0 and 1.0");
    }
    lua_pushnumber(L, (float) CoreDockGetTileSize());
    return 1;
}

/// {PATH}.{MODULE}.magnificationSize([float]) -> float
/// Function
/// If an argument is provided, set the Dock icon magnification size to a number between 0.0 and 1.0 and return the (possibly new) magnification size.  If no argument is provided, then this function returns the current magnification size as a number between 0.0 and 1.0.
static int coredock_magnification_size(lua_State* L) {
    if (!lua_isnone(L, 1)) {
        float magSize = (float) luaL_checknumber(L, -1);
        if (magSize >= 0 && magSize <= 1)
            CoreDockSetMagnificationSize(magSize);
        else
            return luaL_error(L,"magnification_size must be a number between 0.0 and 1.0");
    }
    lua_pushnumber(L, (float) CoreDockGetMagnificationSize());
    return 1;
}

// /// {PATH}.{MODULE}.oandp(orientation, pinning)
// /// Function
// /// Sets the Dock orientation and pinning simultaneously to the placement indicated by orientation and pinning.
// static int coredock_oandp(lua_State* L) {
//     CoreDockOrientation ourOrientation = luaL_checkinteger(L, -2);
//     CoreDockPinning     ourPinning = luaL_checkinteger(L, -1);
//
//     CoreDockSetOrientationAndPinning(ourOrientation, ourPinning);
//     return 0;
// }

/// {PATH}.{MODULE}.orientation([orientation]) -> orientation
/// Function
/// If an argument is provided, set the Dock orientation to the position indicated by orientation number and return the (possibly new) orientation number.  If no argument is provided, then this function returns the current orientation number. You can reference `{PATH}.{MODULE}.options.orientation` to select the appropriate number for the desired orientation or dereference the result.
static int coredock_orientation(lua_State* L) {
    if (!lua_isnone(L, 1)) {
        CoreDockOrientation ourOrientation = luaL_checkinteger(L, -1);
        CoreDockPinning     ourPinning = 0;
        CoreDockSetOrientationAndPinning(ourOrientation, ourPinning);
    }
    CoreDockOrientation ourOrientation;
    CoreDockPinning     ourPinning;
    CoreDockGetOrientationAndPinning(&ourOrientation, &ourPinning);
    lua_pushnumber(L, (int) ourOrientation);
    return 1;
}

/// {PATH}.{MODULE}.pinning([pinning]) -> pinning
/// Function
/// If an argument is provided, set the Dock pinning to the position indicated by pinning number and return the (possibly new) pinning number.  If no argument is provided, then this function returns the current pinning number. You can reference `{PATH}.{MODULE}.options.pinning` to select the appropriate number for the desired pinning or dereference the result.
static int coredock_pinning(lua_State* L) {
    if (!lua_isnone(L, 1)) {
        CoreDockOrientation ourOrientation = 0;
        CoreDockPinning     ourPinning = luaL_checkinteger(L, -1);
        CoreDockSetOrientationAndPinning(ourOrientation, ourPinning);
    }
    CoreDockOrientation ourOrientation;
    CoreDockPinning     ourPinning;
    CoreDockGetOrientationAndPinning(&ourOrientation, &ourPinning);
    lua_pushnumber(L, (int) ourPinning);
    return 1;
}


/// {PATH}.{MODULE}.magnification([bool]) -> bool
/// Function
/// If an argument is provided, set the Dock Magnification state to on or off and return the (possibly new) magnification state.  If no argument is provided, then this function returns the current magnification state.
static int coredock_magnification(lua_State* L) {
    if (!lua_isnone(L, 1)) {
        CoreDockSetMagnificationEnabled((Boolean) lua_toboolean(L, -1));
    }
    if (CoreDockIsMagnificationEnabled()) lua_pushboolean(L, YES); else lua_pushboolean(L, NO);
    return 1;
}

/// {PATH}.{MODULE}.autoHide([bool]) -> bool
/// Function
/// If an argument is provided, set the Dock Hiding state to on or off and return the (possibly new) hiding state.  If no argument is provided, then this function returns the current hiding state.
static int coredock_autohide(lua_State* L) {
    if (!lua_isnone(L, 1)) {
        CoreDockSetAutoHideEnabled((Boolean) lua_toboolean(L, -1));
    }
    if (CoreDockGetAutoHideEnabled()) lua_pushboolean(L, YES); else lua_pushboolean(L, NO);
    return 1;
}

/// {PATH}.{MODULE}.animationEffect([effect]) -> effect
/// Function
/// If an argument is provided, set the Dock hiding animation effect to the effect indicated by effect number and return the (possibly new) effect number.  If no argument is provided, then this function returns the current effect number. You can reference `{PATH}.{MODULE}.options.effect` to select the appropriate number for the desired effect or dereference the result.
static int coredock_animationeffect(lua_State* L) {
    if (!lua_isnone(L, 1)) {
        CoreDockEffect  ourEffect = luaL_checkinteger(L, -1);
        CoreDockSetEffect(ourEffect);
    }
    CoreDockEffect  ourEffect;
    CoreDockGetEffect(&ourEffect);
    lua_pushnumber(L, (int) ourEffect);
    return 1;
}

static const luaL_Reg coredock_lib[] = {
    {"tileSize",            coredock_tilesize},
    {"orientation",         coredock_orientation},
    {"pinning",             coredock_pinning},
    {"animationEffect",     coredock_animationeffect},
    {"autoHide",            coredock_autohide},
    {"magnification",       coredock_magnification},
    {"magnificationSize",   coredock_magnification_size},
    {NULL,                  NULL}
};

/// {PATH}.{MODULE}.options[]
/// Variable
/// Connivence array of all currently defined coredock options.
/// ~~~lua
///     Note that the top orientation has not been supported even within the private APIs for some time and may disappear from here in a future release unless another solution can be found.
///
///     options.orientation[]  -- an array of the orientation options available for `orientation`
///         top         -- put the dock at the top of the monitor
///         bottom      -- put the dock at the bottom of the monitor
///         left        -- put the dock at the left of the monitor
///         right       -- put the dock at the right of the monitor
///
///     Note that dock pinning has not been supported even within the private APIs for some time and may disappear from here in a future release unless another solution can be found.
///
///     options.pinning[]  -- an array of the pinning options available for `pinning`
///         start       -- pin the dock at the start of its orientation
///         middle      -- pin the dock at the middle of its orientation
///         end         -- pin the dock at the end of its orientation
///
///     Note that the suck animation is not displayed in the System Preferences panel correctly, but does remain in effect as long as you do not change this specific field while in the Preferences panel for the Dock.
///
///     options.effect[]   -- an array of the dock animation options for  `animation_effect`
///         genie       -- use the genie animation
///         scale       -- use the scale animation
///         suck        -- use the suck animation
/// ~~~
static void coredock_options (lua_State *L) {
    lua_newtable(L) ;
        lua_newtable(L) ;
            lua_pushinteger(L, kCoreDockOrientationTop);    lua_setfield(L, -2, "top") ;
            lua_pushinteger(L, kCoreDockOrientationBottom); lua_setfield(L, -2, "bottom") ;
            lua_pushinteger(L, kCoreDockOrientationLeft);   lua_setfield(L, -2, "left") ;
            lua_pushinteger(L, kCoreDockOrientationRight);  lua_setfield(L, -2, "right") ;
        lua_setfield(L, -2, "orientation");
        lua_newtable(L) ;
            lua_pushinteger(L, kCoreDockPinningStart);  lua_setfield(L, -2, "start") ;
            lua_pushinteger(L, kCoreDockPinningMiddle); lua_setfield(L, -2, "middle") ;
            lua_pushinteger(L, kCoreDockPinningEnd);    lua_setfield(L, -2, "end") ;
        lua_setfield(L, -2, "pinning");
        lua_newtable(L) ;
            lua_pushinteger(L, kCoreDockEffectGenie);   lua_setfield(L, -2, "genie") ;
            lua_pushinteger(L, kCoreDockEffectScale);   lua_setfield(L, -2, "scale") ;
            lua_pushinteger(L, kCoreDockEffectSuck);    lua_setfield(L, -2, "suck") ;
        lua_setfield(L, -2, "effect");
}

int luaopen_{MODULE}(lua_State* L) {
    luaL_newlib(L, coredock_lib);
    coredock_options(L) ;
    lua_setfield(L, -2, "options") ;
    return 1;
}
