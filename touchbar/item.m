#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

// TODO:
//    Documentation
//    Toolbar creation (see bar.m)
//    More item types
//    any way to detect when removed from system tray by another assignment?
//    what happens with multiple applications using the same method to add an item to system tray?

// Example:
// tb = require("hs._asm.undocumented.touchbar")
// a = tb.item.newImageButton(hs.image.imageFromName(hs.image.systemImageNames.ApplicationIcon)):callback(function(obj) print("woohoo!") end):systemTray(true)

@import Cocoa ;
@import LuaSkin ;

#import "TouchBar.h"

static const char * const USERDATA_TAG = "hs._asm.undocumented.touchbar.item" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))
// #define get_structFromUserdata(objType, L, idx, tag) ((objType *)luaL_checkudata(L, idx, tag))
// #define get_cfobjectFromUserdata(objType, L, idx, tag) *((objType *)luaL_checkudata(L, idx, tag))

typedef NS_ENUM(NSUInteger, TB_ItemTypes) {
    TBIT_imageButton = 0,
    TBIT_textButton,
} ;

#pragma mark - Support Functions and Classes

@interface HSASMTouchBarItem : NSObject
@property int            callbackRef ;
@property int            selfRefCount ;
@property NSTouchBarItem *item ;
@property TB_ItemTypes   itemType ;
@end

@implementation HSASMTouchBarItem

- (instancetype)initItemType:(TB_ItemTypes)itemType {
    self = [super init] ;
    if (self) {
        _callbackRef  = LUA_NOREF ;
        _selfRefCount = 0 ;
        _item         = nil ;
        _itemType     = itemType ;
    }
    return self ;
}

- (void)performCallback:(id)sender {
    if (_callbackRef != LUA_NOREF) {
        dispatch_async(dispatch_get_main_queue(), ^{
            LuaSkin *skin = [LuaSkin shared] ;
            [skin pushLuaRef:refTable ref:self->_callbackRef] ;
            [skin pushNSObject:self] ;
            [skin logDebug:[NSString stringWithFormat:@"%s:callback sender == %@", USERDATA_TAG, sender]] ;
            if (![skin protectedCallAndTraceback:1 nresults:0]) {
                [skin logError:[NSString stringWithFormat:@"%s:callback error:%s", USERDATA_TAG, lua_tostring(skin.L, -1)]] ;
                lua_pop(skin.L, 1) ;
            }
        }) ;
    }
}

@end

#pragma mark - Module Functions

static int touchbaritem_newImageButton(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, "hs.image", LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBarItem *obj = [[HSASMTouchBarItem alloc] initItemType:TBIT_imageButton] ;
    if (obj) {
        NSImage  *image          = [skin toNSObjectAtIndex:1] ;
        NSString *identifier     = (lua_gettop(L) == 2) ? [skin toNSObjectAtIndex:2] : [[NSUUID UUID] UUIDString] ;
        NSButton *button         = [NSButton buttonWithImage:image target:obj action:@selector(performCallback:)] ;
        obj.item                 = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier] ;
        ((NSCustomTouchBarItem *)obj.item).view            = button ;
//         obj.item.view.appearance = [NSAppearance appearanceNamed:@"NSAppearanceNameControlStrip"] ;

        [skin pushNSObject:obj] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int touchbaritem_newTextButton(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBarItem *obj = [[HSASMTouchBarItem alloc] initItemType:TBIT_textButton] ;
    if (obj) {
        NSString *text           = [skin toNSObjectAtIndex:1] ;
        NSString *identifier     = (lua_gettop(L) == 2) ? [skin toNSObjectAtIndex:2] : [[NSUUID UUID] UUIDString] ;
        NSButton *button         = [NSButton buttonWithTitle:text target:obj action:@selector(performCallback:)] ;
        obj.item                 = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier] ;
        ((NSCustomTouchBarItem *)obj.item).view = button ;
//         obj.item.view.appearance = [NSAppearance appearanceNamed:@"NSAppearanceNameControlStrip"] ;

        [skin pushNSObject:obj] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

static int touchbaritem_customizationLabel(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        [skin pushNSObject:obj.item.customizationLabel] ;
    } else {
        ((NSCustomTouchBarItem *)obj.item).customizationLabel = [skin toNSObjectAtIndex:2] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int touchbaritem_image(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;
    if (obj.itemType == TBIT_imageButton) {
        if (lua_gettop(L) == 1) {
            [skin pushNSObject:((NSButton *)obj.item.view).image] ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.image", LS_TBREAK] ;
            ((NSButton *)obj.item.view).image = [skin toNSObjectAtIndex:2] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        return luaL_argerror(L, 1, "method only valid for image button types") ;
    }
    return 1 ;
}

static int touchbaritem_title(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;
    if (obj.itemType == TBIT_textButton) {
        if (lua_gettop(L) == 1) {
            [skin pushNSObject:((NSButton *)obj.item.view).title] ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
            ((NSButton *)obj.item.view).title = [skin toNSObjectAtIndex:2] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        return luaL_argerror(L, 1, "method only valid for text button types") ;
    }
    return 1 ;
}

static int touchbaritem_identifier(__unused lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:obj.item.identifier] ;
    return 1 ;
}

static int touchbaritem_visibilityPriority(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, (lua_Number)obj.item.visibilityPriority) ;
    } else {
        obj.item.visibilityPriority = (float)lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int touchbaritem_systemTray(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN, LS_TBREAK] ;
    HSASMTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (lua_toboolean(L, 2)) {
        if ([NSTouchBarItem respondsToSelector:NSSelectorFromString(@"addSystemTrayItem:")]) {
            [NSTouchBarItem addSystemTrayItem:obj.item] ;
            DFRElementSetControlStripPresenceForIdentifier(obj.item.identifier, YES) ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:systemTray - NSTouchBarItem addSystemTrayItem: selector not found; notify developers", USERDATA_TAG]] ;
        }
    } else {
        if ([NSTouchBarItem respondsToSelector:NSSelectorFromString(@"removeSystemTrayItem:")]) {
            DFRElementSetControlStripPresenceForIdentifier(obj.item.identifier, NO);
            [NSTouchBarItem removeSystemTrayItem:obj.item];
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:systemTray - NSTouchBarItem removeSystemTrayItem: selector not found; notify developers", USERDATA_TAG]] ;
        }
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int touchbaritem_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        obj.callbackRef = [skin luaUnref:refTable ref:obj.callbackRef] ;
        if (lua_type(L, 2) == LUA_TFUNCTION) {
            lua_pushvalue(L, 2) ;
            obj.callbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (obj.callbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:obj.callbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

#pragma mark - Module Constants

static int push_visibilityPriorities(lua_State *L) {
    lua_newtable(L) ;
    lua_pushnumber(L, (lua_Number)NSTouchBarItemPriorityHigh) ;   lua_setfield(L, -2, "high") ;
    lua_pushnumber(L, (lua_Number)NSTouchBarItemPriorityNormal) ; lua_setfield(L, -2, "normal") ;
    lua_pushnumber(L, (lua_Number)NSTouchBarItemPriorityLow) ;    lua_setfield(L, -2, "low") ;
    return 1 ;
}

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSASMTouchBarItem(lua_State *L, id obj) {
    HSASMTouchBarItem *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMTouchBarItem *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMTouchBarItemFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMTouchBarItem *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMTouchBarItem, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMTouchBarItem *obj = [skin luaObjectAtIndex:1 toClass:"HSASMTouchBarItem"] ;
    NSString *title = obj.item.identifier ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSASMTouchBarItem *obj1 = [skin luaObjectAtIndex:1 toClass:"HSASMTouchBarItem"] ;
        HSASMTouchBarItem *obj2 = [skin luaObjectAtIndex:2 toClass:"HSASMTouchBarItem"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMTouchBarItem *obj = get_objectFromUserdata(__bridge_transfer HSASMTouchBarItem, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin shared] ;
            obj.callbackRef = [skin luaUnref:refTable ref:obj.callbackRef] ;
            if ([NSTouchBarItem respondsToSelector:NSSelectorFromString(@"removeSystemTrayItem:")]) {
                DFRElementSetControlStripPresenceForIdentifier(obj.item.identifier, NO);
                [NSTouchBarItem removeSystemTrayItem:obj.item];
            }
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
    {"customizationLabel", touchbaritem_customizationLabel},
    {"image",              touchbaritem_image},
    {"title",              touchbaritem_title},
    {"identifier",         touchbaritem_identifier},
    {"visibilityPriority", touchbaritem_visibilityPriority},
    {"systemTray",         touchbaritem_systemTray},
    {"callback",           touchbaritem_callback},

    {"__tostring",         userdata_tostring},
    {"__eq",               userdata_eq},
    {"__gc",               userdata_gc},
    {NULL,                 NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"newImageButton", touchbaritem_newImageButton},
    {"newTextButton",  touchbaritem_newTextButton},
    {NULL, NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_undocumented_touchbar_item(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;

    if (NSClassFromString(@"NSTouchBarItem")) {
        refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                         functions:moduleLib
                                     metaFunctions:nil    // or module_metaLib
                                   objectFunctions:userdata_metaLib];

        push_visibilityPriorities(L) ; lua_setfield(L, -2, "visibilityPriorities") ;

        [skin registerPushNSHelper:pushHSASMTouchBarItem         forClass:"HSASMTouchBarItem"];

        [skin registerLuaObjectHelper:toHSASMTouchBarItemFromLua forClass:"HSASMTouchBarItem"
                                                      withUserdataMapping:USERDATA_TAG];
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s requires NSTouchBarItem which is only available in 10.12.2 and later", USERDATA_TAG]] ;
        lua_newtable(L) ;
    }
    return 1;
}

#pragma clang diagnostic pop
