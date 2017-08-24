#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

/// === hs._asm.undocumented.touchbar.item ===
///
/// This module is used to create and manipulate touchbar item objects which can added to `hs._asm.undocumented.touchbar.bar` objects and displayed in the Touch Bar of new Macintosh Pro laptops or with the virtual Touch Bar provided by `hs._asm.undocumented.touchbar`.
///
/// At present, only simple button type items are supported.
///
/// This module requires macOS 10.12.2 or later. Some of the methods (identified in their notes) in this module use undocumented functions and/or framework methods and are not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.
///
/// This module is very experimental and is still under development, so the exact functions and methods are subject to change without notice.
///
/// TODO:
///  * More item types
///  * `isVisible` is KVO, so add a watcher

@import Cocoa ;
@import LuaSkin ;

#import "TouchBar.h"

static const char * const USERDATA_TAG = "hs._asm.undocumented.touchbar.item" ;
// static const char * const BAR_UD_TAG   = "hs._asm.undocumented.touchbar.bar" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))
// #define get_structFromUserdata(objType, L, idx, tag) ((objType *)luaL_checkudata(L, idx, tag))
// #define get_cfobjectFromUserdata(objType, L, idx, tag) *((objType *)luaL_checkudata(L, idx, tag))

typedef NS_ENUM(NSUInteger, TB_ItemTypes) {
    TBIT_buttonWithText = 0,
    TBIT_buttonWithImage,
    TBIT_buttonWithImageAndText,
} ;

#pragma mark - Support Functions and Classes

@interface HSASMButtonTouchBarItem : NSCustomTouchBarItem
@property int          callbackRef ;
@property int          selfRefCount ;
@property TB_ItemTypes itemType ;
@end

@implementation HSASMButtonTouchBarItem

- (instancetype)initItemType:(TB_ItemTypes)itemType withIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier] ;
    if (self) {
        _callbackRef  = LUA_NOREF ;
        _selfRefCount = 0 ;
        _itemType     = itemType ;
    }
    return self ;
}

- (void)performCallback:(id)sender {
    if (_callbackRef != LUA_NOREF) {
        dispatch_async(dispatch_get_main_queue(), ^{
            LuaSkin   *skin = [LuaSkin shared] ;
            lua_State *L    = skin.L ;
            [skin pushLuaRef:refTable ref:self->_callbackRef] ;
            [skin pushNSObject:self] ;
            [skin logDebug:[NSString stringWithFormat:@"%s:callback sender == %@ (waiting to see if this is useful as more types are added)", USERDATA_TAG, sender]] ;
            if (![skin protectedCallAndTraceback:1 nresults:0]) {
                [skin logError:[NSString stringWithFormat:@"%s:callback error:%s", USERDATA_TAG, lua_tostring(L, -1)]] ;
                lua_pop(L, 1) ;
            }
        }) ;
    }
}

@end

#pragma mark - Module Functions

/// hs._asm.undocumented.touchbar.item.newButton([title], [image], [identifier]) -> touchbarItemObject
/// Constructor
/// Create a new button touchbarItem object.
///
/// Parameters:
///  * `title`      - A string specifying the title for the button. Optional if `image` is specified.
///  * `image`      - An `hs.image` object specifying the image for the button.  Optional is `title` is specified.
///  * `identifier` - An optional string specifying the identifier for this touchbar item. Must be unique within the bar the item will be assigned to if specified. If not specified, a new UUID is generated for the item.
///
/// Returns:
///  * a touchbarItemObject or nil if an error occurs
///
/// Notes:
///  * You can change the button's title with [hs._asm.undocumented.touchbar.item:title](#title) only if you initially assign one with this constructor.
///  * You can change the button's image with [hs._asm.undocumented.touchbar.item:image](#title) only if you initially assign one with this constructor.
///  * If you intend to allow customization of the touch bar, it is highly recommended that you specify an identifier, since the UUID will change each time the item is regenerated (when Hammerspoon reloads or restarts).
static int touchbaritem_newButton(lua_State *L) {
    LuaSkin      *skin       = [LuaSkin shared] ;
    NSString     *title      = nil ;
    NSImage      *image      = nil ;
    NSString     *identifier = [[NSUUID UUID] UUIDString] ;
    TB_ItemTypes itemType ;

    switch(lua_gettop(L)) {
        case 1: {
            if (lua_type(L, 1) == LUA_TSTRING) {
                title = [skin toNSObjectAtIndex:1] ;
                itemType   = TBIT_buttonWithText ;
            } else {
                [skin checkArgs:LS_TUSERDATA, "hs.image", LS_TBREAK] ;
                image    = [skin toNSObjectAtIndex:1] ;
                itemType = TBIT_buttonWithImage ;
            }
        } break ;
        case 2: {
            if (lua_type(L, 1) == LUA_TSTRING && lua_type(L, 2) == LUA_TSTRING) {
                title      = [skin toNSObjectAtIndex:1] ;
                identifier = [skin toNSObjectAtIndex:2] ;
                itemType   = TBIT_buttonWithText ;
            } else if (lua_type(L, 1) == LUA_TSTRING) {
                [skin checkArgs:LS_TSTRING, LS_TUSERDATA, "hs.image", LS_TBREAK] ;
                title    = [skin toNSObjectAtIndex:1] ;
                image    = [skin toNSObjectAtIndex:2] ;
                itemType = TBIT_buttonWithImageAndText ;
            } else {
                [skin checkArgs:LS_TUSERDATA, "hs.image", LS_TSTRING, LS_TBREAK] ;
                image      = [skin toNSObjectAtIndex:1] ;
                identifier = [skin toNSObjectAtIndex:2] ;
                itemType   = TBIT_buttonWithImage ;
            }
        } break ;
        default: {
            [skin checkArgs:LS_TSTRING, LS_TUSERDATA, "hs.image", LS_TSTRING, LS_TBREAK] ;
            title      = [skin toNSObjectAtIndex:1] ;
            image      = [skin toNSObjectAtIndex:2] ;
            identifier = [skin toNSObjectAtIndex:3] ;
            itemType   = TBIT_buttonWithImageAndText ;
        }
    }

    HSASMButtonTouchBarItem *obj = [[HSASMButtonTouchBarItem alloc] initItemType:itemType withIdentifier:identifier] ;

    if (obj) {
    NSButton *button ;
        switch(itemType) {
            case TBIT_buttonWithText: {
                button = [NSButton buttonWithTitle:title target:obj action:@selector(performCallback:)] ;
            } break ;
            case TBIT_buttonWithImage: {
                button = [NSButton buttonWithImage:image target:obj action:@selector(performCallback:)] ;
            } break ;
            case TBIT_buttonWithImageAndText: {
                button = [NSButton buttonWithTitle:title image:image target:obj action:@selector(performCallback:)] ;
            } break ;
        }
        obj.view            = button ;
//         obj.view.appearance = [NSAppearance appearanceNamed:@"NSAppearanceNameControlStrip"] ;

        [skin pushNSObject:obj] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.undocumented.touchbar.item:customizationLabel([label]) -> touchbarItemObject | string
/// Method
/// Get or set the label displayed for the item when the customization panel is being displayed for the touch bar.
///
/// Parameters:
///  * `label` - an optional string, or explicit nil to reset to an empty string, specifying the label to be displayed with the item when the customization panel is being displayed for the touch bar.  Defaults to an empty string.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
static int touchbaritem_customizationLabel(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    NSCustomTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:obj.customizationLabel] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            obj.customizationLabel = nil ;
        } else {
            obj.customizationLabel = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:image([image]) -> touchbarItemObject | hs.image object
/// Method
/// Get or set the image for a button item which was initially given an image when created.
///
/// Parameters:
///  * `image` - an optional `hs.image` object, or explicit nil, specifying the image for the button item.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if an image was not provided when the object was created.
///  * Setting the image to nil will remove the image and shrink the button, but not as tightly as the button would appear if it had been initially created without an image at all.
static int touchbaritem_image(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMButtonTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (obj.itemType == TBIT_buttonWithImage || obj.itemType == TBIT_buttonWithImageAndText) {
        if (lua_gettop(L) == 1) {
            [skin pushNSObject:((NSButton *)obj.view).image] ;
        } else {
            if (lua_type(L, 2) == LUA_TNIL) {
                ((NSButton *)obj.view).image = nil ;
            } else {
                [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.image", LS_TBREAK] ;
                ((NSButton *)obj.view).image = [skin toNSObjectAtIndex:2] ;
            }
            lua_pushvalue(L, 1) ;
        }
    } else {
        return luaL_argerror(L, 1, "method only valid for button types initialized with an image") ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:title([title]) -> touchbarItemObject | string
/// Method
/// Get or set the title for a button item which was initially given a title when created.
///
/// Parameters:
///  * `title` - an optional string, or explicit nil, specifying the title for the button item.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if a title was not provided when the object was created.
///  * Setting the title to nil will remove the title and shrink the button, but not as tightly as the button would appear if it had been initially created without a title at all.
static int touchbaritem_title(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMButtonTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (obj.itemType == TBIT_buttonWithText || obj.itemType == TBIT_buttonWithImageAndText) {
        if (lua_gettop(L) == 1) {
            [skin pushNSObject:((NSButton *)obj.view).title] ;
        } else {
            if (lua_type(L, 2) == LUA_TNIL) {
                ((NSButton *)obj.view).title = @"" ;
            } else {
                ((NSButton *)obj.view).title = [skin toNSObjectAtIndex:2] ;
            }
            lua_pushvalue(L, 1) ;
        }
    } else {
        return luaL_argerror(L, 1, "method only valid for button types initialized with a title") ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:identifier() -> string
/// Method
/// Returns the identifier for the touchbarItem object
///
/// Parameters:
///  * None
///
/// Returns:
///  * the identifier for the item as a string
static int touchbaritem_identifier(__unused lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    [skin pushNSObject:obj.identifier] ;
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:isVisible() -> boolean
/// Method
/// Returns a boolean indicating whether or not the item is currently visible in the bar that it is assigned to.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean specifying whether or not the item is currently visible in the bar that it is assigned to.
///
/// Notes:
///  * If the bar that the item is assigned to has been visible at some point in the past, and the item was visible at that time, this method will return true even if the bar is not currently visible. If you want to know if the item is visible in the touch bar display *right now*, you should use `bar:isVisible() and item:isVisible()`
static int touchbaritem_isVisible(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    lua_pushboolean(L, obj.visible) ;
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:visibilityPriority([priority]) -> touchbarItemObject | number
/// Method
/// Get or set the visibility priority for the touchbar item.
///
/// Parameters:
///  * `priority` - an optional number specifying the visibility priority for the item.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * If their are more items to be presented in the touch bar display than space permits, items with a lower visibility priority will be hidden first.
///  * Some predefined visibility values are defined in [hs._asm.undocumented.touchbar.item.visibilityPriorities](#visibilityPriorities), though others are allowed. The default priority for an item object is `hs._asm.undocumented.touchbar.item.visibilityPriorities.normal`.
static int touchbaritem_visibilityPriority(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    NSTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, (lua_Number)obj.visibilityPriority) ;
    } else {
        obj.visibilityPriority = (float)lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:callback([fn | nil]) -> touchbarItemObject | fn
/// Method
/// Get or set the callback function for the touchbar item.
///
/// Parameters:
///  * `fn` - an optional function, or explicit nil to remove, specifying the callback to be invoked when the item is pressed.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * The callback function should expect one argument, the touchbarItemObject, and return none.
static int touchbaritem_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMButtonTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

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

/// hs._asm.undocumented.touchbar.item:addToSystemTray(state) -> touchbarItemObject
/// Method
/// Add or remove the touchbar item from the System Tray in the touch bar display.
///
/// Parameters:
///  * `state` - a boolean specifying if the item should be displayed in the System Tray (true) or not (false).
///
/// Returns:
///  * the touchbarItem object
///
/// Notes:
///  * The item will only be visible in the System Tray if you have "Touch Bar Shows" set to "App Controls With Control Strip" set in the Keyboard System Preferences.
///
///  * Initial experiments suggest that only one item *from any macOS application currently running* may be added to the System Tray at a time.
///  * Adding a new item will hide any previous item assigned; however they do appear to stack, so removing an existing item with this method, or if it has bar object attached with [hs._asm.undocumented.touchbar.item:presentModalBar](#presentModalBar) and you dismiss the bar with `hs._asm.undocumented.touchbar.bar:dismissModalBar`, the previous item should become visible again.
///
///  * At present, there is no known way to determine which item is currently displayed in the System Tray or detect when a specific item is replaced ([hs._asm.undocumented.touchbar.item:isVisible](#isVisible) returns false). Please submit an issue if you know of a solution.
///
///  * This method uses undocumented functions and/or framework methods and is not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.
static int touchbaritem_systemTray(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN, LS_TBREAK] ;
    NSTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (lua_toboolean(L, 2)) {
        if ([NSTouchBarItem respondsToSelector:NSSelectorFromString(@"addSystemTrayItem:")]) {
            [NSTouchBarItem addSystemTrayItem:obj] ;
            DFRElementSetControlStripPresenceForIdentifier(obj.identifier, YES) ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:systemTray - NSTouchBarItem addSystemTrayItem: selector not found; notify developers", USERDATA_TAG]] ;
        }
    } else {
        if ([NSTouchBarItem respondsToSelector:NSSelectorFromString(@"removeSystemTrayItem:")]) {
            DFRElementSetControlStripPresenceForIdentifier(obj.identifier, NO);
            [NSTouchBarItem removeSystemTrayItem:obj];
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:systemTray - NSTouchBarItem removeSystemTrayItem: selector not found; notify developers", USERDATA_TAG]] ;
        }
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

#pragma mark - Module Constants

/// hs._asm.undocumented.touchbar.item.visibilityPriorities[]
/// Constant
/// Predefined visibility priorities for use with [hs._asm.undocumented.touchbar.item:visibilityPriority](#visibilityPriority)
///
/// A table containing key-value pairs of predefined visibility priorities used when the touch bar isn't large enough to display all of the items which are eligible for presentation. Items with lower priorities are hidden first. These numbers are only suggestions and other numbers are also valid for use with [hs._asm.undocumented.touchbar.item:visibilityPriority](#visibilityPriority).
///
/// Predefined values are as follows:
///  * `low`   - -1000.0
///  * `normal`-     0.0 (this is the default value assigned to an item when it is first created)
///  * `high`  -  1000.0
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

static int pushHSASMButtonTouchBarItem(lua_State *L, id obj) {
    HSASMButtonTouchBarItem *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMButtonTouchBarItem *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMButtonTouchBarItemFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMButtonTouchBarItem *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMButtonTouchBarItem, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    NSTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;
    NSString *title = obj.identifier ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        NSTouchBarItem *obj1 = [skin toNSObjectAtIndex:1] ;
        NSTouchBarItem *obj2 = [skin toNSObjectAtIndex:2] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMButtonTouchBarItem *obj = get_objectFromUserdata(__bridge_transfer HSASMButtonTouchBarItem, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin shared] ;
            obj.callbackRef = [skin luaUnref:refTable ref:obj.callbackRef] ;
            if ([NSTouchBarItem respondsToSelector:NSSelectorFromString(@"removeSystemTrayItem:")]) {
                DFRElementSetControlStripPresenceForIdentifier(obj.identifier, NO);
                [NSTouchBarItem removeSystemTrayItem:obj];
            }
            obj = nil ;
        }
    }

    // Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;
    return 0 ;
}

// Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
    {"customizationLabel", touchbaritem_customizationLabel},
    {"image",              touchbaritem_image},
    {"title",              touchbaritem_title},
    {"identifier",         touchbaritem_identifier},
    {"isVisible",          touchbaritem_isVisible},
    {"visibilityPriority", touchbaritem_visibilityPriority},
    {"callback",           touchbaritem_callback},

    {"addToSystemTray",    touchbaritem_systemTray},

    {"__tostring",         userdata_tostring},
    {"__eq",               userdata_eq},
    {"__gc",               userdata_gc},
    {NULL,                 NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"newButton", touchbaritem_newButton},
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

        [skin registerPushNSHelper:pushHSASMButtonTouchBarItem         forClass:"HSASMButtonTouchBarItem"] ;
        [skin registerLuaObjectHelper:toHSASMButtonTouchBarItemFromLua forClass:"HSASMButtonTouchBarItem"
                                                            withUserdataMapping:USERDATA_TAG] ;
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s requires NSTouchBarItem which is only available in 10.12.2 and later", USERDATA_TAG]] ;
        lua_newtable(L) ;
    }
    return 1;
}

#pragma clang diagnostic pop
