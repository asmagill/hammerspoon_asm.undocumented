#import <Cocoa/Cocoa.h>
// #import <Carbon/Carbon.h>
#import <LuaSkin/LuaSkin.h>
#import "spaces.h"

int refTable ;

static NSNumber* getcurrentspace(lua_State *L) {
    @try {
        NSArray* spaces = (__bridge_transfer NSArray*)CGSCopySpaces(_CGSDefaultConnection(), kCGSSpaceCurrent);
        return [spaces objectAtIndex:0];
    }
    @catch ( NSException *theException ) {
        luaL_error(L, "%s, %s", [[theException name] UTF8String], [[theException reason] UTF8String]) ;
        return nil ;
    }
}

static NSArray* getspaces(lua_State *L) {
    @try {
        NSArray* spaces = (__bridge_transfer NSArray*)CGSCopySpaces(_CGSDefaultConnection(), kCGSSpaceAll);
        NSMutableArray* userSpaces = [NSMutableArray array];

        for (NSNumber* space in [spaces reverseObjectEnumerator]) {
            if (CGSSpaceGetType(_CGSDefaultConnection(), [space unsignedLongLongValue]) != kCGSSpaceSystem)
                [userSpaces addObject:space];
        }

        return userSpaces;
    }
    @catch ( NSException *theException ) {
        luaL_error(L, "%s, %s", [[theException name] UTF8String], [[theException reason] UTF8String]) ;
        return nil ;
    }
}

/// hs._asm.undocumented.spaces.count() -> number
/// Function
/// The number of spaces you currently have.
static int spaces_count(lua_State* L) {
    @try {
        lua_pushinteger(L, (lua_Integer)[getspaces(L) count]);
        return 1;
    }
    @catch ( NSException *theException ) {
        return luaL_error(L, "%s, %s", [[theException name] UTF8String], [[theException reason] UTF8String]) ;
    }
}

/// hs._asm.undocumented.spaces.currentSpace() -> number
/// Function
/// The index of the space you're currently on, 1-indexed (as usual).
static int spaces_currentspace(lua_State* L) {
    @try {
        NSUInteger idx = [getspaces(L) indexOfObject:getcurrentspace(L)];

        if (idx == NSNotFound)
            lua_pushnil(L);
        else
            lua_pushinteger(L, (lua_Integer)idx + 1);

        return 1;
    }
    @catch ( NSException *theException ) {
        return luaL_error(L, "%s, %s", [[theException name] UTF8String], [[theException reason] UTF8String]) ;
    }
}

/// hs._asm.undocumented.spaces.moveToSpace(number)
/// Function
/// Switches to the space at the given index, 1-indexed (as usual).
static int spaces_movetospace(lua_State* L) {
    @try {
        NSArray* spaces = getspaces(L);

        NSInteger toidx = luaL_checkinteger(L, 1) - 1;
        NSInteger fromidx = (NSInteger)[spaces indexOfObject:getcurrentspace(L)];

        BOOL worked = NO;

        if (toidx < 0 || fromidx == NSNotFound || toidx == fromidx || toidx >= (NSInteger) [spaces count])
            goto finish;

        NSUInteger from = [[spaces objectAtIndex:(NSUInteger)fromidx] unsignedLongLongValue];
        NSUInteger to = [[spaces objectAtIndex:(NSUInteger)toidx] unsignedLongLongValue];

        CGSHideSpaces(_CGSDefaultConnection(), @[@(from)]);
        CGSShowSpaces(_CGSDefaultConnection(), @[@(to)]);
        CGSManagedDisplaySetCurrentSpace(_CGSDefaultConnection(), kCGSPackagesMainDisplayIdentifier, to);

        worked = YES;

    finish:

        lua_pushboolean(L, worked);
        return 1;
    }
    @catch ( NSException *theException ) {
        return luaL_error(L, "%s, %s", [[theException name] UTF8String], [[theException reason] UTF8String]) ;
    }
}

// static int screenUUIDs(lua_State *L) {
//     lua_newtable(L) ;
//     for (NSScreen *theScreen in [NSScreen screens]) {
//         CGDirectDisplayID cgID = [[[theScreen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue] ;
//         CFUUIDRef   theUUID    = CGDisplayCreateUUIDFromDisplayID(cgID) ;
//         CFStringRef UUIDString = CFUUIDCreateString(kCFAllocatorDefault, theUUID) ;
//         lua_pushinteger(L, cgID) ;
//         [[LuaSkin shared] pushNSObject:(__bridge NSString *)UUIDString] ;
//         lua_settable(L, -3) ;
//         CFRelease(UUIDString) ;
//         CFRelease(theUUID) ;
//     }
//
//     return 1 ;
// }

/// hs._asm.undocumented.spaces.screensHaveSeparateSpaces() -> bool
/// Function
/// Determine if the user has enabled the "Displays Have Separate Spaces" option within Mission Control.
///
/// Parameters:
///  * None
///
/// Returns:
///  * true or false representing the status of the "Displays Have Separate Spaces" option within Mission Control.
///
/// Notes:
///  * This function uses standard OS X APIs and is not likely to be affected by updates or patches.
static int screensHaveSeparateSpaces(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;

    lua_pushboolean(L, [NSScreen screensHaveSeparateSpaces]) ;
    return 1 ;
}

/// hs._asm.undocumented.spaces.animating([screen]) -> bool
/// Function
/// Returns the state of space changing animation for the specified monitor, or for any monitor if no parameter is specified.
///
/// Parameters:
///  * screen - an optional hs.screen object specifying the specific monitor to check the animation status for.
///
/// Returns:
///  * a boolean value indicating whether or not a space changing animation is currently active.
///
/// Notes:
///  * This function can be used in `hs.eventtap` based space changing functions to determine when to release the mouse and key events.
static int managedDisplayIsAnimating(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA | LS_TOPTIONAL, "hs.screen", LS_TBREAK] ;

    BOOL isAScreenAnimating = NO ;

    if (lua_gettop(L) == 0) {
        for (NSScreen *screen in [NSScreen screens]) {
            CGDirectDisplayID cgID = [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue] ;
            CFUUIDRef   theUUID    = CGDisplayCreateUUIDFromDisplayID(cgID) ;
            CFStringRef UUIDString = CFUUIDCreateString(kCFAllocatorDefault, theUUID) ;
            // this function requires a UUID and crashes if any other string value is used, so it's
            // safest to just lump all of them together rather than take an argument and have to validate it
            isAScreenAnimating |= CGSManagedDisplayIsAnimating(CGSDefaultConnection, UUIDString) ;
            CFRelease(UUIDString) ;
            CFRelease(theUUID) ;
        }
    } else {
        NSScreen *screen = (__bridge NSScreen*)*((void**)luaL_checkudata(L, 1, "hs.screen")) ;
        CGDirectDisplayID cgID = [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue] ;
        CFUUIDRef   theUUID    = CGDisplayCreateUUIDFromDisplayID(cgID) ;
        CFStringRef UUIDString = CFUUIDCreateString(kCFAllocatorDefault, theUUID) ;
        // this function requires a UUID and crashes if any other string value is used, so it's
        // safest to just lump all of them together rather than take an argument and have to validate it
        isAScreenAnimating |= CGSManagedDisplayIsAnimating(CGSDefaultConnection, UUIDString) ;
        CFRelease(UUIDString) ;
        CFRelease(theUUID) ;
    }

    lua_pushboolean(L, isAScreenAnimating) ;
    return 1 ;
}



static luaL_Reg moduleLib[] = {
    {"screensHaveSeparateSpaces", screensHaveSeparateSpaces},
    {"animating",                 managedDisplayIsAnimating},
    {"count",                     spaces_count},
    {"currentSpace",              spaces_currentspace},
    {"moveToSpace",               spaces_movetospace},
    {NULL, NULL},
};

int luaopen_hs__asm_undocumented_spaces_internal(__unused lua_State* L) {
    refTable = [[LuaSkin shared] registerLibrary:moduleLib metaFunctions:nil] ;

    return 1;
}
