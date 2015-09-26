#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <lauxlib.h>
#import "spaces.h"

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

/// {PATH}.{MODULE}.count() -> number
/// Function
/// The number of spaces you currently have.
static int spaces_count(lua_State* L) {
    @try {
        lua_pushnumber(L, [getspaces(L) count]);
        return 1;
    }
    @catch ( NSException *theException ) {
        return luaL_error(L, "%s, %s", [[theException name] UTF8String], [[theException reason] UTF8String]) ;
    }
}

/// {PATH}.{MODULE}.currentSpace() -> number
/// Function
/// The index of the space you're currently on, 1-indexed (as usual).
static int spaces_currentspace(lua_State* L) {
    @try {
        NSUInteger idx = [getspaces(L) indexOfObject:getcurrentspace(L)];

        if (idx == NSNotFound)
            lua_pushnil(L);
        else
            lua_pushnumber(L, idx + 1);

        return 1;
    }
    @catch ( NSException *theException ) {
        return luaL_error(L, "%s, %s", [[theException name] UTF8String], [[theException reason] UTF8String]) ;
    }
}

/// {PATH}.{MODULE}.moveToSpace(number)
/// Function
/// Switches to the space at the given index, 1-indexed (as usual).
static int spaces_movetospace(lua_State* L) {
    @try {
        NSArray* spaces = getspaces(L);

        NSInteger toidx = luaL_checknumber(L, 1) - 1;
        NSInteger fromidx = [spaces indexOfObject:getcurrentspace(L)];

        BOOL worked = NO;

        if (toidx < 0 || fromidx == NSNotFound || toidx == fromidx || toidx >= (NSInteger) [spaces count])
            goto finish;

        NSUInteger from = [[spaces objectAtIndex:fromidx] unsignedLongLongValue];
        NSUInteger to = [[spaces objectAtIndex:toidx] unsignedLongLongValue];

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

static luaL_Reg spaceslib[] = {
    {"count",        spaces_count},
    {"currentSpace", spaces_currentspace},
    {"moveToSpace",  spaces_movetospace},
    {NULL, NULL},
};

int luaopen_{MODULE}(lua_State* L) {
    luaL_newlib(L, spaceslib);
    return 1;
}
