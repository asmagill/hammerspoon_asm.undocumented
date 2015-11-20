#import <Cocoa/Cocoa.h>
#import <LuaSkin/LuaSkin.h>
#import "CGSCursor.h"

extern CGSConnectionID _CGSDefaultConnection(void) ;
#define CGSDefaultConnection _CGSDefaultConnection()

// #define USERDATA_TAG        "hs.module"
int refTable ;

// #define get_objectFromUserdata(objType, L, idx) (objType*)*((void**)luaL_checkudata(L, idx, USERDATA_TAG))
// #define get_structFromUserdata(objType, L, idx) ((objType *)luaL_checkudata(L, idx, USERDATA_TAG))

static int showCursor(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;
    CGError state = CGSShowCursor(CGSDefaultConnection) ;
    if (state != kCGErrorSuccess) return luaL_error(L, "showCursor:error %d", state) ;
    return 0 ;
}

static int hideCursor(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;
    CGError state = CGSHideCursor(CGSDefaultConnection) ;
    if (state != kCGErrorSuccess) return luaL_error(L, "hideCursor:error %d", state) ;
    return 0 ;
}

static int obscureCursor(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;
    CGError state = CGSObscureCursor(CGSDefaultConnection) ;
    if (state != kCGErrorSuccess) return luaL_error(L, "obscureCursor:error %d", state) ;
    return 0 ;
}

static int revealCursor(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;
    CGError state = CGSRevealCursor(CGSDefaultConnection) ;
    if (state != kCGErrorSuccess) return luaL_error(L, "revealCursor:error %d", state) ;
    return 0 ;
}

static int waitCursor(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TBOOLEAN, LS_TBREAK] ;
    CGError state = CGSForceWaitCursorActive(CGSDefaultConnection, lua_toboolean(L, 1)) ;
    if (state != kCGErrorSuccess) return luaL_error(L, "waitCursor:error %d", state) ;
    return 0 ;
}

static int cursorSeed(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;
    lua_pushinteger(L, CGSCurrentCursorSeed()) ;
    return 1 ;
}

static int systemCursorName(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TNUMBER, LS_TBREAK] ;
    lua_pushstring(L, CGSCursorNameForSystemCursor(luaL_checkinteger(L, 1))) ;
    return 1 ;
}

static int cursorScale(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    if (lua_type(L, 1) == LUA_TNUMBER) {
        CGError state = CGSSetCursorScale(CGSDefaultConnection, lua_tonumber(L, 1)) ;
        if (state != kCGErrorSuccess) return luaL_error(L, "cursorScale:set error %d", state) ;
    }
    CGFloat scale ;
    CGError state = CGSGetCursorScale(CGSDefaultConnection, &scale) ;
    if (state != kCGErrorSuccess) return luaL_error(L, "cursorScale:get error %d", state) ;
    lua_pushnumber(L, scale) ;
    return 1 ;
}

static int pushSystemCursorTable(lua_State *L) {
    lua_newtable(L) ;
      lua_pushinteger(L, CGSCursorArrow) ;        lua_setfield(L, -2, "arrow") ;
      lua_pushinteger(L, CGSCursorIBeam) ;        lua_setfield(L, -2, "iBeam") ;
      lua_pushinteger(L, CGSCursorIBeamXOR) ;     lua_setfield(L, -2, "iBeamXOR") ;
      lua_pushinteger(L, CGSCursorAlias) ;        lua_setfield(L, -2, "alias") ;
      lua_pushinteger(L, CGSCursorCopy) ;         lua_setfield(L, -2, "copy") ;
      lua_pushinteger(L, CGSCursorMove) ;         lua_setfield(L, -2, "move") ;
      lua_pushinteger(L, CGSCursorArrowContext) ; lua_setfield(L, -2, "arrowContext") ;
      lua_pushinteger(L, CGSCursorWait) ;         lua_setfield(L, -2, "wait") ;
      lua_pushinteger(L, CGSCursorEmpty) ;        lua_setfield(L, -2, "empty") ;
    return 1 ;
}

// static int userdata_tostring(lua_State* L) {
// }

// static int userdata_eq(lua_State* L) {
// }

// static int userdata_gc(lua_State* L) {
//     return 0 ;
// }

// static int meta_gc(lua_State* __unused L) {
//     return 0 ;
// }

// Metatable for userdata objects
// static const luaL_Reg userdata_metaLib[] = {
//     {"__tostring", userdata_tostring},
//     {"__eq",       userdata_eq},
//     {"__gc",       userdata_gc},
//     {NULL,         NULL}
// };

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"showCursor",       showCursor},
    {"hideCursor",       hideCursor},
    {"obscureCursor",    obscureCursor},
    {"revealCursor",     revealCursor},
    {"waitCursor",       waitCursor},
    {"cursorSeed",       cursorSeed},
    {"systemCursorName", systemCursorName},
    {"cursorScale",      cursorScale},

    {NULL, NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

// NOTE: ** Make sure to change luaopen_..._internal **
int luaopen_hs__asm_undocumented_cursor_internal(lua_State* __unused L) {
// Use this if your module doesn't have a module specific object that it returns.
   refTable = [[LuaSkin shared] registerLibrary:moduleLib metaFunctions:nil] ; // or module_metaLib
// Use this some of your functions return or act on a specific object unique to this module
//     refTable = [[LuaSkin shared] registerLibraryWithObject:USERDATA_TAG
//                                                  functions:moduleLib
//                                              metaFunctions:nil    // or module_metaLib
//                                            objectFunctions:userdata_metaLib];

    pushSystemCursorTable(L) ; lua_setfield(L, -2, "systemCursors") ;
    return 1;
}
