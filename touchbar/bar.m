#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"


/// === hs._asm.undocumented.touchbar.bar ===
///
/// This module is used to create and manipulate bar objects which can be displayed in the Touch Bar of new Macintosh Pro laptops or with the virtual Touch Bar provided by `hs._asm.undocumented.touchbar`.
///
/// At present, bar objects can be presented modally under Hammerspoon control but cannot be attached directly to the Hammerspoon console or webview objects to dynamically appear as application focus changes; this is expected to change in the future.
///
/// This module requires macOS 10.12.2 or later. Some of the methods (identified in their notes) in this module use undocumented functions and/or framework methods and are not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.
///
/// This module is very experimental and is still under development, so the exact functions and methods are subject to change without notice.
///

// TODO:
//  * touch bars for the console and webviews
//  * rework orginization so bar in root, current root in `virtual`

@import Cocoa ;
@import LuaSkin ;

#import "TouchBar.h"

static const char * const USERDATA_TAG = "hs._asm.undocumented.touchbar.bar" ;
static const char * const ITEM_UD_TAG  = "hs._asm.undocumented.touchbar.item" ;
static int refTable = LUA_NOREF;

// establish a unique context for identifying our observers
static void *myKVOContext = &myKVOContext ; // See http://nshipster.com/key-value-observing/

static NSDictionary *builtInIdentifiers ;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))
// #define get_structFromUserdata(objType, L, idx, tag) ((objType *)luaL_checkudata(L, idx, tag))
// #define get_cfobjectFromUserdata(objType, L, idx, tag) *((objType *)luaL_checkudata(L, idx, tag))

#pragma mark - Support Functions and Classes

@interface HSASMTouchBar : NSTouchBar <NSTouchBarDelegate>
@property int selfRefCount ;
@property int visibilityCallbackRef ;
@end

@implementation HSASMTouchBar

- (instancetype)init {
    self = [super init] ;
    if (self) {
        _selfRefCount = 0 ;
        _visibilityCallbackRef  = LUA_NOREF ;
        self.delegate = self ;
    }
    return self ;
}

// override this so we can adjust item selfRefCounts in one place rather than everywhere it might be set
- (void)setTemplateItems:(NSSet<NSTouchBarItem *> *)templateItems {
    NSSet *currentItems = self.templateItems ;

// This is because we want to access a property in another custom subclass but because both this class and
// the one we want to access are in separate shared libraries, we can't access them directly at runtime.
//
// Another solution is to merge the libraries together into one shared library, but this is also a proof of
// concept to prove to myself that this is starting to make sense to me :-)

    // returns int, 16 byte frame: id at offset 0, selector at offset 8
    NSMethodSignature *getSignature  = [NSMethodSignature signatureWithObjCTypes:"i16@0:8"] ;
    NSInvocation      *getInvocation = [NSInvocation invocationWithMethodSignature:getSignature] ;
    [getInvocation setSelector:NSSelectorFromString(@"selfRefCount")] ;

    // returns void, 20 byte frame: id at offset 0, selector at offset 8, int at offset 16
    NSMethodSignature *setSignature  = [NSMethodSignature signatureWithObjCTypes:"v20@0:8i16"] ;
    NSInvocation      *setInvocation = [NSInvocation invocationWithMethodSignature:setSignature] ;
    [setInvocation setSelector:NSSelectorFromString(@"setSelfRefCount:")] ;

    // decrease the selfRefCount for the current items
    [currentItems enumerateObjectsUsingBlock:^(NSTouchBarItem *item, __unused BOOL *stop) {
        if ([item respondsToSelector:NSSelectorFromString(@"selfRefCount")]) {
            int currentCount ;
            [getInvocation invokeWithTarget:item] ;
            [getInvocation getReturnValue:&currentCount] ;
            currentCount-- ;
            [setInvocation setArgument:&currentCount atIndex:2] ; // 0 is the object itself and 1 is the selector
            [setInvocation invokeWithTarget:item] ;
        } else {
            [LuaSkin logWarn:[NSString stringWithFormat:@"%s:setTemplateItems (decreasing) - item %@ does not recognize selfRefCount", USERDATA_TAG, item]] ;
        }
    }] ;

    [super setTemplateItems:templateItems] ;

    // increase the selfRefCount for the ones we've just set
    [templateItems enumerateObjectsUsingBlock:^(NSTouchBarItem *item, __unused BOOL *stop) {
        if ([item respondsToSelector:NSSelectorFromString(@"selfRefCount")]) {
            int currentCount ;
            [getInvocation invokeWithTarget:item] ;
            [getInvocation getReturnValue:&currentCount] ;
            currentCount++ ;
            [setInvocation setArgument:&currentCount atIndex:2] ; // 0 is the object itself and 1 is the selector
            [setInvocation invokeWithTarget:item] ;
        } else {
            [LuaSkin logWarn:[NSString stringWithFormat:@"%s:setTemplateItems (increasing) - item %@ does not recognize selfRefCount", USERDATA_TAG, item]] ;
        }
    }] ;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == myKVOContext && [keyPath isEqualToString:@"visible"]) {
        if (_visibilityCallbackRef != LUA_NOREF) {
            LuaSkin *skin = [LuaSkin shared] ;
            lua_State *L  = [skin L] ;
            // KVO seems to be slow and may not invoke the callback until after gc during a reload
            if ([skin pushLuaRef:refTable ref:_visibilityCallbackRef] != LUA_TNIL) {
                [skin pushNSObject:self] ;
                lua_pushboolean(L, self.visible) ;
                if (![skin protectedCallAndTraceback:2 nresults:0]) {
                    [skin logError:[NSString stringWithFormat:@"%s:visibilityCallback error:%s", USERDATA_TAG, lua_tostring(L, -1)]] ;
                    lua_pop(L, 1) ;
                }
            } else {
                lua_pop(L, 1) ;
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context] ;
    }
}

// - (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier {
//
// }

@end

static BOOL itemWithIdentifierExists(NSTouchBar *bar, NSString *identifier, BOOL includeBuiltIn) {
    __block BOOL found = includeBuiltIn && (builtInIdentifiers && [builtInIdentifiers.allValues containsObject:identifier]) ;
    if (!found) {
        found = [[bar.templateItems.allObjects valueForKey:@"identifier"] containsObject:identifier] ;
    }
    return found ;
}

static NSArray *validateIdentifierArray(lua_State *L, NSTouchBar *bar, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    NSArray *identifiers = [skin toNSObjectAtIndex:idx] ;
    __block NSString *errMsg = nil ;
    if ([identifiers isKindOfClass:[NSArray class]]) {
        [identifiers enumerateObjectsUsingBlock:^(NSString *item, NSUInteger idx2, BOOL *stop) {
            if ([item isKindOfClass:[NSString class]]) {
                if (!itemWithIdentifierExists(bar, item, YES)) {
                    errMsg = [NSString stringWithFormat:@"item %@ at index %lu is not assigned to the touchbar", item, (idx2 + 1)] ;
                    *stop = YES ;
                }
            } else {
                errMsg = [NSString stringWithFormat:@"expected string at index %lu", (idx2 + 1)] ;
            }
        }] ;
    } else {
        errMsg = @"expected an array of string identifiers" ;
    }
    if (errMsg) {
        luaL_argerror(L, idx, errMsg.UTF8String) ;
        return nil ;
    } else {
        return identifiers ;
    }
}

#pragma mark - Module Functions

/// hs._asm.undocumented.touchbar.bar.new() -> barObject
/// Constructor
/// Creates a new bar object
///
/// Parameters:
///  * None
///
/// Returns:
///  * a new bar object
static int touchbar_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBREAK] ;
    HSASMTouchBar *obj = [[HSASMTouchBar alloc] init] ;
    if (obj) {
        [skin pushNSObject:obj] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar.toggleCustomization() -> None
/// Function
/// (See Notes) Toggle's the Touch Bar customization panel for the Hammerspoon application
///
/// Parameters:
///  * None
///
/// Returns:
///  * None
///
/// Notes:
///  * At present this function is not useful; it is expected to be more useful when Hammerspoon specific views can provide their own touchbars.
///
///  * The customization panel allows modification of the current bar visible for the macOS application triggering the request within that applications resolver chain -- as such, it can only modify touchbar's attached to the Hammerspoon console or webview objects.
///  * The customization panel cannot modify modally displayed bar objects.
static int touchbar_toggleCustomization(__unused lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBREAK] ;
    [NSApp toggleTouchBarCustomizationPalette:nil] ;
    return 0 ;
}

#pragma mark - Module Methods

/// hs._asm.undocumented.touchbar.bar:isVisible() -> boolean
/// Method
/// Returns a boolean indicating whether the bar object is currently visible in the laptop or virtual Touch Bar.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean value indicating whether or not the touchbar represented by the object is currently being displayed in the laptop or virtual Touch Bar.
///
/// Notes:
///  * The value returned by this method changes as expected when the [hs._asm.undocumented.touchbar.bar:dismissModalBar](#dismissModalBar) or [hs._asm.undocumented.touchbar.bar:minimizeModalBar](#minimizeModalBar) methods are used.
///  * It does *NOT* reliably change when when the system dismiss button is used (when the second argument to [hs._asm.undocumented.touchbar.bar:presentModalBar](#presentModalBar) or `hs._asm.undocumented.touchbar.item:presentModalBar` is true (or not present)).  This is being investigated but at present no workaround is known.

static int touchbar_isVisible(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMTouchBar *obj = [skin toNSObjectAtIndex:1] ;
    lua_pushboolean(L, obj.visible) ;
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:itemIdentifiers() -> table
/// Method
/// Returns an array of strings specifying the identifiers of the touchbar items currently presented by the bar object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * an array of strings specifying the identifiers of the touchbar items currently presented by the bar object.
///
/// Notes:
///  * If the user has not customized the bar, the list of identifiers will match the list provided by [hs._asm.undocumented.touchbar.bar:defaultIdentifiers()](#defaultIdentifiers).
static int touchbar_itemIdentifiers(__unused lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMTouchBar *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:obj.itemIdentifiers] ;
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:customizationLabel([label]) -> barObject | string
/// Method
/// Get or set the customization label for saving and restoring user customizations for the bar.
///
/// Parameters:
///  * `label` - an optional string, or explicit nil to disable, specifying the customization label for saving and restoring user customizations for the bar; defaults to nil.
///
/// Returns:
///  * If an argument is provided, returns the barObject; otherwise returns the current value.
static int touchbar_customizationIdentifier(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBar *obj = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        [skin pushNSObject:obj.customizationIdentifier] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            obj.customizationIdentifier = nil ;
        } else {
            obj.customizationIdentifier = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:principleItem([identifier]) -> barObject | string
/// Method
/// Get or set the principle item for the bar.
///
/// Parameters:
///  * `identifer` - an optional string, or explicit nil to disable, specifying the principle item for the bar; defaults to nil.
///
/// Returns:
///  * If an argument is provided, returns the barObject; otherwise returns the current value.
///
/// Notes:
///  * the principle item will be centered in the displayed portion of the bar.
///
///  * the identifier specified must belong to a touchbar items already assigned to the bar object with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems) or one of the built in identifier values defined in [hs._asm.undocumented.touchbar.bar.builtInIdentifiers](#builtInIdentifiers).
static int touchbar_principalItemIdentifier(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBar *obj = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        [skin pushNSObject:obj.principalItemIdentifier] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            obj.principalItemIdentifier = nil ;
        } else {
            NSString *identifier = [skin toNSObjectAtIndex:2] ;
            if (itemWithIdentifierExists(obj, identifier, YES)) {
                obj.principalItemIdentifier = identifier ;
            } else {
                return luaL_argerror(L, 2, [[NSString stringWithFormat:@"item %@ is not assigned to the touchbar", identifier] UTF8String]) ;
            }
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:escapeKeyReplacement([identifier]) -> barObject | string
/// Method
/// Get or set the item which replaces the system escape key for the bar.
///
/// Parameters:
///  * `identifer` - an optional string, or explicit nil to disable, specifying the item which replaces the system escape key for the bar; defaults to nil.
///
/// Returns:
///  * If an argument is provided, returns the barObject; otherwise returns the current value.
///
/// Notes:
///  * This method has no effect on modally displayed bars.
///
///  * the identifier specified must belong to a touchbar items already assigned to the bar object with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems).
static int touchbar_escapeKeyReplacementItemIdentifier(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBar *obj = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        [skin pushNSObject:obj.escapeKeyReplacementItemIdentifier] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            obj.escapeKeyReplacementItemIdentifier = nil ;
        } else {
            NSString *identifier = [skin toNSObjectAtIndex:2] ;
            if (itemWithIdentifierExists(obj, identifier, NO)) {
                obj.escapeKeyReplacementItemIdentifier = identifier ;
            } else {
                return luaL_argerror(L, 2, [[NSString stringWithFormat:@"item %@ is not assigned to the touchbar", identifier] UTF8String]) ;
            }
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:customizableIdentifiers([identifiersTable]) -> barObject | table
/// Method
/// Get or set an array of strings specifying the identifiers of the touchbar items that can be added or removed from the bar object through user customization.
///
/// Parameters:
///  * `identifiersTable` - an optional table containing strings specifying the identifiers of touchbar items that can be added or removed from the bar object through user customization.
///
/// Returns:
///  * If an argument is provided, returns the barObject; otherwise returns the current value.
///
/// Notes:
///  * the identifiers specified must belong to touchbar items already assigned to the bar object with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems) or one of the built in identifier values defined in [hs._asm.undocumented.touchbar.bar.builtInIdentifiers](#builtInIdentifiers).
static int touchbar_customizationAllowedItemIdentifiers(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBar *obj = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        [skin pushNSObject:obj.customizationAllowedItemIdentifiers] ;
    } else {
        obj.customizationAllowedItemIdentifiers = validateIdentifierArray(L, obj, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:requiredIdentifiers([identifiersTable]) -> barObject | table
/// Method
/// Get or set an array of strings specifying the identifiers of the touchbar items that cannot be removed from the bar object through user customization.
///
/// Parameters:
///  * `identifiersTable` - an optional table containing strings specifying the identifiers of touchbar items that cannot be removed from the bar object through user customization.
///
/// Returns:
///  * If an argument is provided, returns the barObject; otherwise returns the current value.
///
/// Notes:
///  * the identifiers specified must belong to touchbar items already assigned to the bar object with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems) or one of the built in identifier values defined in [hs._asm.undocumented.touchbar.bar.builtInIdentifiers](#builtInIdentifiers).
static int touchbar_customizationRequiredItemIdentifiers(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBar *obj = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        [skin pushNSObject:obj.customizationRequiredItemIdentifiers] ;
    } else {
        obj.customizationRequiredItemIdentifiers = validateIdentifierArray(L, obj, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:defaultIdentifiers([identifiersTable]) -> barObject | table
/// Method
/// Get or set an array of strings specifying the identifiers of the touchbar items added to the bar object by default, before any user customization.
///
/// Parameters:
///  * `identifiersTable` - an optional table containing strings specifying the identifiers of touchbar items added to the bar object by default, before any user customization.
///
/// Returns:
///  * If an argument is provided, returns the barObject; otherwise returns the current value.
///
/// Notes:
///  * the identifiers specified must belong to touchbar items already assigned to the bar object with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems) or one of the built in identifier values defined in [hs._asm.undocumented.touchbar.bar.builtInIdentifiers](#builtInIdentifiers).
static int touchbar_defaultItemIdentifiers(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBar *obj = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        [skin pushNSObject:obj.defaultItemIdentifiers] ;
    } else {
        obj.defaultItemIdentifiers = validateIdentifierArray(L, obj, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:templateItems([itemsTable]) -> barObject | table
/// Method
/// Get or set an array of `hs._asm.undocumented.touchbar.item` objects that can be presented by the bar object.
///
/// Parameters:
///  * `itemsTable` - an optional table containing `hs._asm.undocumented.touchbar.item` objects that can be presented by the bar object.
///
/// Returns:
///  * If an argument is provided, returns the barObject; otherwise returns the current value.
///
/// Notes:
///  * only the identifiers of items assigned by this method can be used by the other methods in this module that use string identifiers in their arguments.
static int touchbar_templateItems(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBar *obj = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        [skin pushNSObject:obj.templateItems] ;
    } else {
        NSArray *itemArray = [skin toNSObjectAtIndex:2] ;
        __block NSString *errMsg = nil ;
        if ([itemArray isKindOfClass:[NSArray class]]) {
            __block NSMutableArray *identifiers   = [[NSMutableArray alloc] init] ;
            __block NSMutableSet   *touchbarItems = [[NSMutableSet alloc] init] ;
            [itemArray enumerateObjectsUsingBlock:^(id obj2, NSUInteger idx, BOOL *stop) {
                if ([obj2 isKindOfClass:[NSTouchBarItem class]]) {
                    NSTouchBarItem *theItem = obj2 ;
                    [touchbarItems addObject:theItem] ;
                    [identifiers   addObject:theItem.identifier] ;
                } else {
                    errMsg = [NSString stringWithFormat:@"expected %s object at index %lu", ITEM_UD_TAG, (idx + 1)] ;
                    *stop = YES ;
                }
            }] ;
            if (!errMsg) {
                  [identifiers addObjectsFromArray:builtInIdentifiers.allValues] ;

                  NSPredicate *identifiersFilter = [NSPredicate predicateWithFormat: @"SELF IN %@", identifiers] ;

                  obj.customizationAllowedItemIdentifiers  = [obj.customizationAllowedItemIdentifiers
                                                                      filteredArrayUsingPredicate:identifiersFilter] ;
                  obj.customizationRequiredItemIdentifiers = [obj.customizationRequiredItemIdentifiers
                                                                      filteredArrayUsingPredicate:identifiersFilter] ;
                  obj.defaultItemIdentifiers               = [obj.defaultItemIdentifiers
                                                                      filteredArrayUsingPredicate:identifiersFilter] ;

                  obj.templateItems = touchbarItems ;
            }
        } else {
            errMsg = [NSString stringWithFormat:@"expected array of %s objects", ITEM_UD_TAG] ;
        }
        if (errMsg) {
            return luaL_argerror(L, 2, errMsg.UTF8String) ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:itemForIdentifier([identifier]) -> touchbarItemObject | nil
/// Method
/// Returns the touchbarItemObject for the identifier specified.
///
/// Parameters:
///  * `identifier` - a string specifying the touchbarItem object to get from the items assigned to the bar with [hs._asm.undocumented.touchbar.bar:templateItems](#templateItems).
///
/// Returns:
///  * the touchbarItem object for the item specified or nil if no such item has been assigned to the bar.
static int touchbar_itemForIdentifier(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    NSTouchBar *obj        = [skin toNSObjectAtIndex:1] ;
    NSString   *identifier = [skin toNSObjectAtIndex:2] ;

    NSTouchBarItem *item = [obj itemForIdentifier:identifier] ;
    if (item) {
        if ([item respondsToSelector:NSSelectorFromString(@"selfRefCount")]) {
            [skin pushNSObject:item withOptions:LS_NSDescribeUnknownTypes] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:itemForIdentifier(%@) does not refer to an %s object", USERDATA_TAG, identifier, ITEM_UD_TAG]] ;
            lua_pushnil(L) ;
        }
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:visibilityCallback([fn | nil]) -> barObject | fn
/// Method
/// Get or set the visibility callback function for the touch bar object.
///
/// Parameters:
///  * `fn` - an optional function, or explicit nil to remove, specifying the visibility callback for the touch bar object.
///
/// Returns:
///  * if an argument is provided, returns the barObject; otherwise returns the current value
///
/// Notes:
///  * The callback function should expect two arguments, the barObject itself and a boolean indicating the new visibility of the touch bar.  It should return none.
///
///  * This callback is invoked when the [hs._asm.undocumented.touchbar.bar:dismissModalBar](#dismissModalBar) or [hs._asm.undocumented.touchbar.bar:minimizeModalBar](#minimizeModalBar) methods are used.
///  * This callback is *NOT* invoked when the system dismiss button is used (when the second argument to [hs._asm.undocumented.touchbar.bar:presentModalBar](#presentModalBar) or `hs._asm.undocumented.touchbar.item:presentModalBar` is true (or not present)). This is being investigated but at present no workaround is known.
static int touchbar_visibilityCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMTouchBar *obj = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        if (obj.visibilityCallbackRef != LUA_NOREF) {
            obj.visibilityCallbackRef = [skin luaUnref:refTable ref:obj.visibilityCallbackRef] ;
            [obj removeObserver:obj forKeyPath:@"visible" context:myKVOContext] ;
        }
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            obj.visibilityCallbackRef = [skin luaRef:refTable] ;
            [obj addObserver:obj forKeyPath:@"visible" options:NSKeyValueObservingOptionNew context:myKVOContext] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (obj.visibilityCallbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:obj.visibilityCallbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:presentModalBar([itemObject], [dismissButton]) -> barObject
/// Method
/// Presents the bar in the touch bar display modally.
///
/// Parameters:
///  * `itemObject`    - an optional `hs._asm.undocumented.touchbar.item` object which, if currently attached to the system tray, will be hidden while the bar is visible modally.
///  * `dismissButton` - an optional boolean, default true, specifying whether or not the system escape (or its current replacement) button should be replaced by a button to remove the modal bar from the touch bar display when pressed.
///
/// Returns:
///  * the barObject
///
/// Notes:
///  * If you specify `dismissButton` as false, then you must use [hs._asm.undocumented.touchbar.bar:minimizeModalBar](#minimizeModalBar) or [hs._asm.undocumented.touchbar.bar:dismissModalBar](#dismissModalBar) to remove the modal bar from the touch bar display.
///
///  * If you do not have "Touch Bar Shows" set to "App Controls With Control Strip" set in the Keyboard System Preferences, the modal bar will only be displayed when the Hammerspoon application is the frontmost application.
///
///  * If you specify `itemObject` and the object is not currently attached to the system tray (see `hs._asm.undocumented.touchbar.item:addToSystemTray)`, or if you do not have "Touch Bar Shows" set to "App Controls With Control Strip" set in the Keyboard System Preferences, providing this argument has no effect.
///
///  * This method uses undocumented functions and/or framework methods and is not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.
static int touchbar_presentSystemModalFunctionBar(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK | LS_TVARARG] ;
    NSTouchBar *obj        = [skin toNSObjectAtIndex:1] ;
    BOOL       closeBox    = YES ;
    NSString   *identifier = nil ;

    if (lua_type(L, -1) == LUA_TBOOLEAN) {
        closeBox = (BOOL)lua_toboolean(L, -1) ;
        lua_pop(L, 1) ;
    }
    if (lua_gettop(L) > 1) {
        [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, ITEM_UD_TAG, LS_TBREAK] ;
        NSTouchBarItem *item = [skin toNSObjectAtIndex:2] ;
        identifier = item.identifier ;
    }

    DFRSystemModalShowsCloseBoxWhenFrontMost(closeBox) ;
    [NSTouchBar presentSystemModalFunctionBar:obj systemTrayItemIdentifier:identifier] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:dismissModalBar() -> barObject
/// Method
/// Dismiss the bar from the touch bar display by removing it if it is currently being displayed modally.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the barObject
///
/// Notes:
///  * If an `itemObject` was specified with [hs._asm.undocumented.touchbar.bar:presentModalBar](#presentModalBar) or if the bar was displayed with `hs._asm.undocumented.touchbar.item:presentModalBar`, this method will ***not*** restore the item to the system tray.
///
///  * This method uses undocumented functions and/or framework methods and is not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.
static int touchbar_dismissSystemModalFunctionBar(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSTouchBar *obj = [skin toNSObjectAtIndex:1] ;

    [NSTouchBar dismissSystemModalFunctionBar:obj] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.undocumented.touchbar.bar:minimizeModalBar() -> barObject
/// Method
/// Dismiss the bar from the touch bar display by minimizing it if it is currently being displayed modally.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the barObject
///
/// Notes:
///  * If an `itemObject` was specified with [hs._asm.undocumented.touchbar.bar:presentModalBar](#presentModalBar) or if the bar was displayed with `hs._asm.undocumented.touchbar.item:presentModalBar`, this method ***will*** restore the item to the system tray.
///
///  * This method is the same as pressing the `dismissButton` if it was not set to false when [hs._asm.undocumented.touchbar.bar:presentModalBar](#presentModalBar) or `hs._asm.undocumented.touchbar.item:presentModalBar` was invoked.
///
///  * This method uses undocumented functions and/or framework methods and is not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.
static int touchbar_minimizeSystemModalFunctionBar(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSTouchBar *obj = [skin toNSObjectAtIndex:1] ;

    [NSTouchBar minimizeSystemModalFunctionBar:obj] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

#pragma mark - Module Constants

/// hs._asm.undocumented.touchbar.bar.builtInIdentifiers[]
/// Constant
/// A table of key-value pairs whose values represent built in touch bar items which can be used to adjust the layout of the bar object when it is being presented.
///
/// Currently the following keys are defined:
///  * smallSpace      - provides a small space between items
///  * largeSpace      - provides a larger space between items
///  * flexibleSpace   - provides an expanding/contracting space between items
///
/// The following is ignored for modally displayed bars, so it's effects are still being evaluated; documentation will be updated when nested bars can be tested and more fully understood within the context of the Hammerspoon console and webview.
///  * otherItemsProxy - provides a place for nested bars to display items
static int push_builtInTouchBarItems(__unused lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    builtInIdentifiers = @{
        @"smallSpace"      : NSTouchBarItemIdentifierFixedSpaceSmall,
        @"largeSpace"      : NSTouchBarItemIdentifierFixedSpaceLarge,
        @"flexibleSpace"   : NSTouchBarItemIdentifierFlexibleSpace,
        @"otherItemsProxy" : NSTouchBarItemIdentifierOtherItemsProxy,
    } ;
    [skin pushNSObject:builtInIdentifiers] ;
    return 1 ;
}

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSASMTouchBar(lua_State *L, id obj) {
    HSASMTouchBar *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMTouchBar *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMTouchBarFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMTouchBar *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMTouchBar, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
//     HSASMTouchBar *obj = [skin luaObjectAtIndex:1 toClass:"HSASMTouchBar"] ;
//     NSString *title = ... ;
//     [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: (%p)", USERDATA_TAG, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSASMTouchBar *obj1 = [skin luaObjectAtIndex:1 toClass:"HSASMTouchBar"] ;
        HSASMTouchBar *obj2 = [skin luaObjectAtIndex:2 toClass:"HSASMTouchBar"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMTouchBar *obj = get_objectFromUserdata(__bridge_transfer HSASMTouchBar, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin shared] ;
            if (obj.visibilityCallbackRef != LUA_NOREF) {
                obj.visibilityCallbackRef = [skin luaUnref:refTable ref:obj.visibilityCallbackRef] ;
                [obj removeObserver:obj forKeyPath:@"visible" context:myKVOContext] ;
            }
            obj.delegate = nil ; // it's weak, so not necessary, but lets be explicit... not all delegates *are* weak
            obj.templateItems = [NSSet set] ;
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

// // Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
    {"customizationLabel",      touchbar_customizationIdentifier},
    {"escapeKeyReplacement",    touchbar_escapeKeyReplacementItemIdentifier},
    {"isVisible",               touchbar_isVisible},
    {"itemIdentifiers",         touchbar_itemIdentifiers},
    {"principleItem",           touchbar_principalItemIdentifier},
    {"customizableIdentifiers", touchbar_customizationAllowedItemIdentifiers},
    {"requiredIdentifiers",     touchbar_customizationRequiredItemIdentifiers},
    {"defaultIdentifiers",      touchbar_defaultItemIdentifiers},
    {"templateItems",           touchbar_templateItems},
    {"itemForIdentifier",       touchbar_itemForIdentifier},
    {"visibilityCallback",      touchbar_visibilityCallback},

    {"presentModalBar",         touchbar_presentSystemModalFunctionBar},
    {"minimizeModalBar",        touchbar_minimizeSystemModalFunctionBar},
    {"dismissModalBar",         touchbar_dismissSystemModalFunctionBar},

    {"__tostring",              userdata_tostring},
    {"__eq",                    userdata_eq},
    {"__gc",                    userdata_gc},
    {NULL,                      NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new",                 touchbar_new},
    {"toggleCustomization", touchbar_toggleCustomization},
    {NULL,                  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_undocumented_touchbar_bar(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;

    if (NSClassFromString(@"NSTouchBar")) {
        refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                         functions:moduleLib
                                     metaFunctions:nil    // or module_metaLib
                                   objectFunctions:userdata_metaLib];

        push_builtInTouchBarItems(L) ; lua_setfield(L, -2, "builtInIdentifiers") ;

        [skin registerPushNSHelper:pushHSASMTouchBar         forClass:"HSASMTouchBar"];
        [skin registerLuaObjectHelper:toHSASMTouchBarFromLua forClass:"HSASMTouchBar"
                                                  withUserdataMapping:USERDATA_TAG];

//         [skin registerPushNSHelper:pushNSTouchBar            forClass:"NSTouchBar"];

    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s requires NSTouchBar which is only available in 10.12.2 and later", USERDATA_TAG]] ;
        lua_newtable(L) ;
    }
    return 1;
}

#pragma clang diagnostic pop
