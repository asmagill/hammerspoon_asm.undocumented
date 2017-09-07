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

// TODO:
//  * more functions to modify button style/appearance? attributed string support? background color? width?
//  * Why does popover fail to show expanded items?  I think fixing this will also allow colorPicker and sharingService to work
//    * try minimizing while popover is supposed to show, maybe because we're already a "pop over" and it would work with "Hammerspoon application" touchbars?
//
//  * get canvas max width ala `canvasItem("view")("window")("frame").w`... can we get without creating canvas item first?

@import Cocoa ;
@import LuaSkin ;

#import "TouchBar.h"

static const char * const USERDATA_TAG = "hs._asm.undocumented.touchbar.item" ;
static const char * const BAR_UD_TAG   = "hs._asm.undocumented.touchbar.bar" ;
static int refTable = LUA_NOREF;

static NSInteger virtualMouseEventCounter = 0 ;

// establish a unique context for identifying our observers
static void *myKVOContext = &myKVOContext ; // See http://nshipster.com/key-value-observing/

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

// see also init.lua itemTypeStrings if you change this
typedef NS_ENUM(NSInteger, TB_ItemTypes) {
    TBIT_unknown = -1,
    TBIT_buttonWithText = 0,
    TBIT_buttonWithImage,
    TBIT_buttonWithImageAndText,
    TBIT_candidateList,
    TBIT_colorPicker,
    TBIT_group,
    TBIT_popover,
    TBIT_sharingServicePicker,
    TBIT_slider,
    TBIT_canvas,
    TBIT_button,
} ;

static NSDictionary *itemTypeStrings ; // assigned in luaopen_hs__asm_undocumented_touchbar_item
#define TB_ItemTypeStrings @{                                   \
    @(TBIT_unknown)                : @"unknown",                \
    @(TBIT_buttonWithText)         : @"buttonWithText",         \
    @(TBIT_buttonWithImage)        : @"buttonWithImage",        \
    @(TBIT_buttonWithImageAndText) : @"buttonWithImageAndText", \
    @(TBIT_candidateList)          : @"candidateList",          \
    @(TBIT_colorPicker)            : @"colorPicker",            \
    @(TBIT_group)                  : @"group",                  \
    @(TBIT_popover)                : @"popover",                \
    @(TBIT_sharingServicePicker)   : @"sharingServicePicker",   \
    @(TBIT_slider)                 : @"slider",                 \
    @(TBIT_canvas)                 : @"canvas",                 \
    @(TBIT_button)                 : @"button",                 \
}

#pragma mark - Support Functions and Classes

@interface CanvasWrapper : NSControl
@end

@interface CanvasActionCell : NSActionCell
@property NSColor *clickColor ;
@end

@interface HSASMCustomTouchBarItem : NSCustomTouchBarItem
@property            int          callbackRef ;
@property            int          selfRefCount ;
@property            int          visibilityCallbackRef ;
@property (readonly) TB_ItemTypes itemType ;
@end

@interface HSASMGroupTouchBarItem : NSGroupTouchBarItem
@property            int          callbackRef ;
@property            int          selfRefCount ;
@property            int          visibilityCallbackRef ;
@property (readonly) TB_ItemTypes itemType ;
@end

@interface HSASMSliderTouchBarItem : NSSliderTouchBarItem
@property            int          callbackRef ;
@property            int          selfRefCount ;
@property            int          visibilityCallbackRef ;
@property (readonly) TB_ItemTypes itemType ;
@end

// @interface HSASMPopoverTouchBarItem : NSPopoverTouchBarItem
// @property            int          callbackRef ;
// @property            int          selfRefCount ;
// @property            int          visibilityCallbackRef ;
// @property (readonly) TB_ItemTypes itemType ;
// @end

// @interface HSASMCandidateListTouchBarItem : NSCandidateListTouchBarItem
// @property            int          callbackRef ;
// @property            int          selfRefCount ;
// @property            int          visibilityCallbackRef ;
// @property (readonly) TB_ItemTypes itemType ;
// @end

// @interface HSASMSharingServicePickerTouchBarItem : NSSharingServicePickerTouchBarItem
// @property            int          callbackRef ;
// @property            int          selfRefCount ;
// @property            int          visibilityCallbackRef ;
// @property (readonly) TB_ItemTypes itemType ;
// @end

// @interface HSASMColorPickerTouchBarItem : NSCandidateListTouchBarItem
// @property            int          callbackRef ;
// @property            int          selfRefCount ;
// @property            int          visibilityCallbackRef ;
// @property (readonly) TB_ItemTypes itemType ;
// @end

// NSScrubber ?

@implementation CanvasActionCell

- (instancetype)init {
    self = [super init] ;
    if (self) {
        _clickColor = nil ;
    }
    return self ;
}

- (NSColor *)highlightColorWithFrame:(__unused NSRect)cellFrame inView:(__unused NSView *)controlView {
    if(_clickColor) {
        return _clickColor ;
    } else {
        return [NSColor selectedControlColor] ;
    }
}

@end

@implementation CanvasWrapper

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect] ;
    if (self) {
        self.cell   = [[CanvasActionCell alloc] init] ;
    }
    return self ;
}

- (void)touchesBeganWithEvent:(NSEvent *)event {
    [super touchesBeganWithEvent:event] ;
    NSSet *touchSet = [event touchesMatchingPhase:NSTouchPhaseBegan inView:self] ;
    NSUInteger touchCount = touchSet.count ;
    if (touchCount != 1) {
        [LuaSkin logDebug:[NSString stringWithFormat:@"%s:touchesBegan - touchSet count == %lu", USERDATA_TAG, touchCount]] ;
    }
    if (touchCount > 0) {
        NSTouch *touch = touchSet.anyObject ;
        NSPoint touchPoint = [touch locationInView:self] ;

//         [LuaSkin logInfo:[NSString stringWithFormat:@"began: %@", NSStringFromPoint(touchPoint)]] ;
        NSEvent *virtualEvent = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
                                                   location:[self convertPoint:touchPoint toView:nil]
                                              modifierFlags:event.modifierFlags
                                                  timestamp:event.timestamp
                                               windowNumber:event.windowNumber
                                                    context:event.context
                                                eventNumber:(virtualMouseEventCounter++)
                                                 clickCount:1
                                                   pressure:1.0] ;
        [self.subviews.firstObject mouseDown:virtualEvent] ;
    }
}

- (void)touchesMovedWithEvent:(NSEvent *)event {
    [super touchesMovedWithEvent:event] ;
    NSSet *touchSet = [event touchesMatchingPhase:NSTouchPhaseMoved inView:self] ;
    NSUInteger touchCount = touchSet.count ;
    if (touchCount != 1) {
        [LuaSkin logDebug:[NSString stringWithFormat:@"%s:touchesMoved - touchSet count == %lu", USERDATA_TAG, touchCount]] ;
    }
    if (touchCount > 0) {
        NSRect  frame = self.frame ;
        NSTouch *touch = touchSet.anyObject ;
        NSPoint touchPoint = [touch locationInView:self] ;
        NSPoint lastPoint  = [touch previousLocationInView:self] ;
        NSEventType eventType = NSEventTypeMouseMoved ;
        if ((touchPoint.x < frame.origin.x) || (touchPoint.x > (frame.origin.x + frame.size.width))) {
            if ((lastPoint.x >= frame.origin.x) && (lastPoint.x <= (frame.origin.x + frame.size.width))) {
                eventType = NSEventTypeMouseExited ;
            } else {
                return ;
            }
        } else if ((lastPoint.x < frame.origin.x) || (lastPoint.x > (frame.origin.x + frame.size.width))) {
            if ((touchPoint.x >= frame.origin.x) && (touchPoint.x <= (frame.origin.x + frame.size.width))) {
                eventType = NSEventTypeMouseEntered ;
            } else {
                return ;
            }
        }

//         [LuaSkin logInfo:[NSString stringWithFormat:@"moved: %@ -> %@", NSStringFromPoint(lastPoint), NSStringFromPoint(touchPoint)]] ;
        if (eventType == NSEventTypeMouseMoved) {
            NSEvent *virtualEvent = [NSEvent mouseEventWithType:eventType
                                                       location:[self convertPoint:touchPoint toView:nil]
                                                  modifierFlags:event.modifierFlags
                                                      timestamp:event.timestamp
                                                   windowNumber:event.windowNumber
                                                        context:event.context
                                                    eventNumber:(virtualMouseEventCounter++)
                                                     clickCount:1
                                                       pressure:1.0] ;
            [self.subviews.firstObject mouseMoved:virtualEvent] ;
        } else {
            NSEvent *virtualEvent = [NSEvent enterExitEventWithType:eventType
                                                           location:[self convertPoint:touchPoint toView:nil]
                                                      modifierFlags:event.modifierFlags
                                                          timestamp:event.timestamp
                                                       windowNumber:event.windowNumber
                                                            context:event.context
                                                        eventNumber:(virtualMouseEventCounter++)
                                                     trackingNumber:0
                                                           userData:nil] ;
            if (eventType == NSEventTypeMouseEntered) {
                [self.subviews.firstObject mouseEntered:virtualEvent] ;
            } else if (eventType == NSEventTypeMouseExited) {
                [self.subviews.firstObject mouseExited:virtualEvent] ;
            }
        }
    }
}

- (void)touchesEndedWithEvent:(NSEvent *)event {
    [super touchesEndedWithEvent:event] ;
    NSSet *touchSet = [event touchesMatchingPhase:NSTouchPhaseEnded inView:self] ;
    NSUInteger touchCount = touchSet.count ;
    if (touchCount != 1) {
        [LuaSkin logDebug:[NSString stringWithFormat:@"%s:touchesEnded - touchSet count == %lu", USERDATA_TAG, touchCount]] ;
    }
    if (touchCount > 0) {
        NSRect  frame = self.frame ;
        NSTouch *touch = touchSet.anyObject ;
        NSPoint touchPoint = [touch locationInView:self] ;
        if ((touchPoint.x < frame.origin.x) || (touchPoint.x > (frame.origin.x + frame.size.width))) return ;

//         [LuaSkin logInfo:[NSString stringWithFormat:@"ended: %@", NSStringFromPoint(touchPoint)]] ;
        NSEvent *virtualEvent = [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp
                                                   location:[self convertPoint:touchPoint toView:nil]
                                              modifierFlags:event.modifierFlags
                                                  timestamp:event.timestamp
                                               windowNumber:event.windowNumber
                                                    context:event.context
                                                eventNumber:(virtualMouseEventCounter++)
                                                 clickCount:0
                                                   pressure:0.0] ;
        [self.subviews.firstObject mouseUp:virtualEvent] ;
    }
}

@end

@implementation HSASMCustomTouchBarItem

- (instancetype)initItemType:(TB_ItemTypes)itemType withIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier] ;
    if (self) {
        _callbackRef           = LUA_NOREF ;
        _visibilityCallbackRef = LUA_NOREF ;
        _selfRefCount          = 0 ;
        _itemType              = itemType ;
    }
    return self ;
}

- (void)dealloc {
    if (_visibilityCallbackRef != LUA_NOREF) {
        _visibilityCallbackRef = LUA_NOREF ;
        [self removeObserver:self forKeyPath:@"visible" context:myKVOContext] ;
    }
}

- (void)performCallback:(id)sender {
//     [LuaSkin logInfo:[NSString stringWithFormat:@"%s:performCallback: %@", USERDATA_TAG, [NSThread callStackSymbols]]] ;
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

@end

@implementation HSASMGroupTouchBarItem

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier] ;
    if (self) {
        _callbackRef           = LUA_NOREF ;
        _visibilityCallbackRef = LUA_NOREF ;
        _selfRefCount          = 0 ;
        _itemType              = TBIT_group ;
    }
    return self ;
}

- (void)dealloc {
    if (_visibilityCallbackRef != LUA_NOREF) {
        _visibilityCallbackRef = LUA_NOREF ;
        [self removeObserver:self forKeyPath:@"visible" context:myKVOContext] ;
    }
}

// override this so we can adjust toolbar selfRefCounts in one place rather than everywhere it might be set
- (void)setGroupTouchBar:(NSTouchBar *)groupTouchBar {
    NSTouchBar *currentTouchBar = self.groupTouchBar ;

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

    if (currentTouchBar && [currentTouchBar isKindOfClass:NSClassFromString(@"HSASMTouchBar")]) {
        // decrease the selfRefCount for the current touchbar
        if ([currentTouchBar respondsToSelector:NSSelectorFromString(@"selfRefCount")]) {
            int currentCount ;
            [getInvocation invokeWithTarget:currentTouchBar] ;
            [getInvocation getReturnValue:&currentCount] ;
            currentCount-- ;
            [setInvocation setArgument:&currentCount atIndex:2] ; // 0 is the object itself and 1 is the selector
            [setInvocation invokeWithTarget:currentTouchBar] ;
        } else {
            [LuaSkin logWarn:[NSString stringWithFormat:@"%s:setGroupTouchBar (decreasing) - touchbar %@ does not recognize selfRefCount", USERDATA_TAG, currentTouchBar]] ;
        }
    }

    [super setGroupTouchBar:groupTouchBar] ;

    if (groupTouchBar && [groupTouchBar isKindOfClass:NSClassFromString(@"HSASMTouchBar")]) {
        // increase the selfRefCount for the new touchbar
        if ([groupTouchBar respondsToSelector:NSSelectorFromString(@"selfRefCount")]) {
            int currentCount ;
            [getInvocation invokeWithTarget:groupTouchBar] ;
            [getInvocation getReturnValue:&currentCount] ;
            currentCount++ ;
            [setInvocation setArgument:&currentCount atIndex:2] ; // 0 is the object itself and 1 is the selector
            [setInvocation invokeWithTarget:groupTouchBar] ;
        } else {
            [LuaSkin logWarn:[NSString stringWithFormat:@"%s:setGroupTouchBar (increasing) - touchbar %@ does not recognize selfRefCount", USERDATA_TAG, currentTouchBar]] ;
        }
    }
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

@end

@implementation HSASMSliderTouchBarItem

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier] ;
    if (self) {
        _callbackRef           = LUA_NOREF ;
        _visibilityCallbackRef = LUA_NOREF ;
        _selfRefCount          = 0 ;
        _itemType              = TBIT_slider ;
        self.target            = self ;
        self.action            = @selector(performSlideCallback:) ;
    }
    return self ;
}

- (void)dealloc {
    if (_visibilityCallbackRef != LUA_NOREF) {
        _visibilityCallbackRef = LUA_NOREF ;
        [self removeObserver:self forKeyPath:@"visible" context:myKVOContext] ;
    }
}

- (void)performCallbackWithValue:(id)value {
    if (_callbackRef != LUA_NOREF) {
        dispatch_async(dispatch_get_main_queue(), ^{
            LuaSkin   *skin = [LuaSkin shared] ;
            lua_State *L    = skin.L ;
            [skin pushLuaRef:refTable ref:self->_callbackRef] ;
            [skin pushNSObject:self] ;
            [skin pushNSObject:value] ;
            if (![skin protectedCallAndTraceback:2 nresults:0]) {
                [skin logError:[NSString stringWithFormat:@"%s:sliderCallback error:%s", USERDATA_TAG, lua_tostring(L, -1)]] ;
                lua_pop(L, 1) ;
            }
        }) ;
    }
}

- (void)performSlideCallback:(HSASMSliderTouchBarItem *)sender {
    [self performCallbackWithValue:@(sender.slider.doubleValue)] ;
}

- (void)performMinCallback:(id)sender {
    [LuaSkin logDebug:[NSString stringWithFormat:@"%s:sliderCallback (min accessory) sender == %@ (waiting to see if this is useful as more types are added)", USERDATA_TAG, sender]] ;
    [self performCallbackWithValue:@"minimum"] ;
}

- (void)performMaxCallback:(id)sender {
    [LuaSkin logDebug:[NSString stringWithFormat:@"%s:sliderCallback (max accessory) sender == %@ (waiting to see if this is useful as more types are added)", USERDATA_TAG, sender]] ;
    [self performCallbackWithValue:@"maximum"] ;
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

@end

#pragma mark - Module Functions

/// hs._asm.undocumented.touchbar.item.newGroup([title], [image], [identifier]) -> touchbarItemObject
/// Constructor
/// Create a new group touchbarItem object which can contain other touchbar items.
///
/// Parameters:
///  * `identifier` - An optional string specifying the identifier for this touchbar item. Must be unique within the bar the item will be assigned to if specified. If not specified, a new UUID is generated for the item.
///
/// Returns:
///  * a touchbarItemObject or nil if an error occurs
static int grouptouchbaritem_newGroup(lua_State *L) {
    LuaSkin      *skin       = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    NSString *identifier = (lua_gettop(L) == 1) ? [skin toNSObjectAtIndex:1] : [[NSUUID UUID] UUIDString] ;

    HSASMGroupTouchBarItem *obj = [[HSASMGroupTouchBarItem alloc] initWithIdentifier:identifier] ;
    if (obj) {
        [skin pushNSObject:obj] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item.newSlider([identifier]) -> touchbarItemObject
/// Constructor
/// Create a new slider touchbarItem object.
///
/// Parameters:
///  * `identifier` - An optional string specifying the identifier for this touchbar item. Must be unique within the bar the item will be assigned to if specified. If not specified, a new UUID is generated for the item.
///
/// Returns:
///  * a touchbarItemObject or nil if an error occurs
///
/// Notes:
///  * The slider object will expand to fill as much space as it can within the touchbar.
static int slidertouchbaritem_newSlider(lua_State *L) {
    LuaSkin      *skin       = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    NSString *identifier = (lua_gettop(L) == 1) ? [skin toNSObjectAtIndex:1] : [[NSUUID UUID] UUIDString] ;

    HSASMSliderTouchBarItem *obj = [[HSASMSliderTouchBarItem alloc] initWithIdentifier:identifier] ;
    if (obj) {
        [skin pushNSObject:obj] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item.newCanvas(canvas, [identifier]) -> touchbarItemObject
/// Constructor
/// Create a new touchbarItem object from an `hs.canvas` object..
///
/// Parameters:
///  * `canvas`     - The `hs.canvas` object to use as a touchbar item.
///  * `identifier` - An optional string specifying the identifier for this touchbar item. Must be unique within the bar the item will be assigned to if specified. If not specified, a new UUID is generated for the item.
///
/// Returns:
///  * a touchbarItemObject or nil if an error occurs
///
/// Notes:
///  * The touch bar object will be proportionally resized so that it has a height of 30 if it does not already.
///  * If canvas callbacks for `mouseDown`, `mouseUp`, `mouseEnterExit`, and `mouseMove` are enabled, the canvas callback will be invoked as if the left mouse button had been used.
static int customtouchbaritem_newCanvas(lua_State *L) {
    LuaSkin      *skin       = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, "hs.canvas", LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;

    NSView   *canvas     = [skin toNSObjectAtIndex:1] ;
    NSString *identifier = (lua_gettop(L) == 2) ? [skin toNSObjectAtIndex:2] : [[NSUUID UUID] UUIDString] ;

    HSASMCustomTouchBarItem *obj = [[HSASMCustomTouchBarItem alloc] initItemType:TBIT_canvas withIdentifier:identifier] ;

    if (obj) {
        NSRect canvasFrame = canvas.frame ;
        NSRect itemFrame   = NSMakeRect(0, 0, canvasFrame.size.width * 30 / canvasFrame.size.height, 30) ;

        CanvasWrapper *itemWrapper = [[CanvasWrapper alloc] initWithFrame:itemFrame] ;
        itemWrapper.target = obj ;
        itemWrapper.action = @selector(performCallback:) ;
        obj.view = itemWrapper ;

        canvas.frame = itemFrame ;
        [obj.view addSubview:canvas] ;
        [obj.view addConstraint:[NSLayoutConstraint constraintWithItem:obj.view
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:canvas
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:1.0
                                                              constant:0.0]] ;
        canvas.needsDisplay = YES ;

        [skin pushNSObject:obj] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

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
static int customtouchbaritem_newButton(lua_State *L) {
    LuaSkin      *skin       = [LuaSkin shared] ;
    NSString     *title      = nil ;
    NSImage      *image      = nil ;
    NSString     *identifier = [[NSUUID UUID] UUIDString] ;
    TB_ItemTypes itemType    = TBIT_unknown ;

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

    HSASMCustomTouchBarItem *obj = [[HSASMCustomTouchBarItem alloc] initItemType:itemType withIdentifier:identifier] ;

    if (obj) {
        NSButton *button ;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
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
            default:
                return luaL_error(L, "unknown item type %l; this should not happen, contact developers", itemType) ;
        }
#pragma clang diagnostic pop

        obj.view            = button ;
//         obj.view.appearance = [NSAppearance appearanceNamed:@"NSAppearanceNameControlStrip"] ;

        [skin pushNSObject:obj] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.undocumented.touchbar.item:visibilityCallback([fn | nil]) -> touchbarItemObject | current value
/// Method
/// Get or set the visibility callback function for the touchbar item object.
///
/// Parameters:
///  * `fn` - an optional function, or explicit nil to remove, specifying the visibility callback for the touchbar item object.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * The callback function should expect two arguments, the touchbarItem itself and a boolean indicating the new visibility of the item.  It should return none.
///
///  * See also the notes for [hs._asm.undocumented.touchbar.item:isVisible](#isVisible) and `hs._asm.undocumented.touchbar.bar.visibilityCallback`.
static int touchbaritem_visibilityCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMCustomTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

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

/// hs._asm.undocumented.touchbar.item:sliderMinImage([image]) -> touchbarItemObject | current value
/// Method
/// Get or set the image displayed at the left side of a slider touchbar item.
///
/// Parameters:
///  * `image` - an optional image, or explicit nil to remove, specifying the image to be displayed at the left side of a slider touchbar item.  Defaults to nil.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newSlider](#newSlider) constructor.
///  * When this image is clicked on, the touchbar item's callback, if set, will receive the string "minimum" as it's second argument.
static int slidertouchbaritem_minImage(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY, LS_TBREAK] ;
    HSASMSliderTouchBarItem *obj   = [skin toNSObjectAtIndex:1] ;
    NSImage                 *image = nil ;

    if (lua_type(L, 2) != LUA_TNIL) {
        [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.image", LS_TBREAK] ;
        image = [skin toNSObjectAtIndex:2] ;
    }

    if (obj.itemType == TBIT_slider) {
        NSSliderAccessory *accessory = nil ;
        if (image) {
            accessory = [NSSliderAccessory accessoryWithImage:image] ;
            accessory.behavior = [NSSliderAccessoryBehavior behaviorWithTarget:obj action:@selector(performMinCallback:)] ;
        }
        obj.minimumValueAccessory = accessory ;
        lua_pushvalue(L, 1) ;
    } else {
        return luaL_argerror(L, 1, "method only valid for slider type") ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:sliderMaxImage([image]) -> touchbarItemObject | current value
/// Method
/// Get or set the image displayed at the right side of a slider touchbar item.
///
/// Parameters:
///  * `image` - an optional image, or explicit nil to remove, specifying the image to be displayed at the right side of a slider touchbar item.  Defaults to nil.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newSlider](#newSlider) constructor.
///  * When this image is clicked on, the touchbar item's callback, if set, will receive the string "maximum" as it's second argument.
static int slidertouchbaritem_maxImage(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY, LS_TBREAK] ;
    HSASMSliderTouchBarItem *obj   = [skin toNSObjectAtIndex:1] ;
    NSImage                 *image = nil ;

    if (lua_type(L, 2) != LUA_TNIL) {
        [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.image", LS_TBREAK] ;
        image = [skin toNSObjectAtIndex:2] ;
    }

    if (obj.itemType == TBIT_slider) {
        NSSliderAccessory *accessory = nil ;
        if (image) {
            accessory = [NSSliderAccessory accessoryWithImage:image] ;
            accessory.behavior = [NSSliderAccessoryBehavior behaviorWithTarget:obj action:@selector(performMaxCallback:)] ;
        }
        obj.maximumValueAccessory = accessory ;
        lua_pushvalue(L, 1) ;
    } else {
        return luaL_argerror(L, 1, "method only valid for slider type") ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:sliderMin([value]) -> touchbarItemObject | current value
/// Method
/// Get or set the minimum value for a slider touchbar item.
///
/// Parameters:
///  * `value` - an optional number specifying the minimum value for a slider touchbar item. This represents the slider's value when the knob of the slider is all the way to the left. Defaults to 0.0.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newSlider](#newSlider) constructor.
static int slidertouchbaritem_minValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMSliderTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (obj.itemType == TBIT_slider) {
        if (lua_gettop(L) == 1) {
            lua_pushnumber(L, obj.slider.minValue) ;
        } else {
            obj.slider.minValue = lua_tonumber(L, 2) ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        return luaL_argerror(L, 1, "method only valid for slider type") ;
    }
    return  1 ;
}

/// hs._asm.undocumented.touchbar.item:sliderMax([value]) -> touchbarItemObject | current value
/// Method
/// Get or set the maximum value for a slider touchbar item.
///
/// Parameters:
///  * `value` - an optional number specifying the maximum value for a slider touchbar item. This represents the slider's value when the knob of the slider is all the way to the right. Defaults to 1.0.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newSlider](#newSlider) constructor.
static int slidertouchbaritem_maxValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMSliderTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (obj.itemType == TBIT_slider) {
        if (lua_gettop(L) == 1) {
            lua_pushnumber(L, obj.slider.maxValue) ;
        } else {
            obj.slider.maxValue = lua_tonumber(L, 2) ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        return luaL_argerror(L, 1, "method only valid for slider type") ;
    }
    return  1 ;
}

/// hs._asm.undocumented.touchbar.item:sliderValue([value]) -> touchbarItemObject | current value
/// Method
/// Get or set the current value for a slider touchbar item.
///
/// Parameters:
///  * `value` - an optional number specifying the value to set for the slider. This value will be automatically constrained to the current minimum and maximum as set by [hs._asm.undocumented.touchbar.item:sliderMin](#sliderMin) and [hs._asm.undocumented.touchbar.item:sliderMax](#sliderMax).
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newSlider](#newSlider) constructor.
///  * The slider touchbar items callback, if set, will not be invoked if you use this method to change the slider's value.
static int slidertouchbaritem_currentValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMSliderTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (obj.itemType == TBIT_slider) {
        if (lua_gettop(L) == 1) {
            lua_pushnumber(L, obj.slider.doubleValue) ;
        } else {
            obj.slider.doubleValue = lua_tonumber(L, 2) ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        return luaL_argerror(L, 1, "method only valid for slider type") ;
    }
    return  1 ;
}

/// hs._asm.undocumented.touchbar.item:groupTouchbar([touchbar]) -> touchbarItemObject | current value
/// Method
/// Get or set the bar object which contains the touchbar items that belong to the group touchbar item.
///
/// Parameters:
///  * `touchbar` - an optional `hs._asm.undocumented.touchbar.bar` object containing the touchbar items to display when this group touchbar item is present in the touchbar.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newGroup](#newGroup) constructor.
///  * The group touchbar item's callback, if set, is never invoked; instead the callback for the items within the group item is invoked when the item is touched.
///  * See also [hs._asm.undocumented.touchbar.item:groupItems](#groupItems)
static int grouptouchbaritem_groupTouchBar(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK | LS_TVARARG] ;
    HSASMGroupTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (obj.itemType == TBIT_group) {
        if (lua_gettop(L) == 1) {
            [skin pushNSObject:obj.groupTouchBar] ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, BAR_UD_TAG, LS_TBREAK] ;
            obj.groupTouchBar = [skin toNSObjectAtIndex:2] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        return luaL_argerror(L, 1, "method only valid for group type") ;
    }
    return  1 ;
}

/// hs._asm.undocumented.touchbar.item:customizationLabel([label]) -> touchbarItemObject | current value
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

/// hs._asm.undocumented.touchbar.item:buttonImage([image]) -> touchbarItemObject | hs.image object
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
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newButton](#newButton) constructor.
///  * This method will generate an error if an image was not provided when the object was created.
///  * Setting the image to nil will remove the image and shrink the button, but not as tightly as the button would appear if it had been initially created without an image at all.
static int customtouchbaritem_image(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMCustomTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

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
        return luaL_argerror(L, 1, "method only valid for buttons initialized with a title or slider types") ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:buttonTitle([title]) -> touchbarItemObject | current value
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
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newButton](#newButton) constructor.
///  * This method will generate an error if a title was not provided when the object was created.
///  * Setting the title to nil will remove the title and shrink the button, but not as tightly as the button would appear if it had been initially created without a title at all.
static int customtouchbaritem_title(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMCustomTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

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
    } else if (obj.itemType == TBIT_slider) {
        HSASMSliderTouchBarItem *slider = (HSASMSliderTouchBarItem *)obj ;
        if (lua_gettop(L) == 1) {
            [skin pushNSObject:slider.label] ;
        } else {
            if (lua_type(L, 2) == LUA_TNIL) {
                slider.label = nil ;
            } else {
                slider.label = [skin toNSObjectAtIndex:2] ;
            }
            lua_pushvalue(L, 1) ;
        }
    } else {
        return luaL_argerror(L, 1, "method only valid for button initialized with a title or slider types") ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:canvasWidth([width]) -> touchbarItemObject | current value
/// Method
/// Get or set the width of a canvas touchbar item in the touchbar.
///
/// Parameters:
///  * `width` - an optional number specifying the width of the canvas touchbar item in the touchbar.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newCanvas](#newCanvas) constructor.
static int customtouchbaritem_canvasWidth(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMCustomTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (obj.itemType == TBIT_canvas) {
        if (lua_gettop(L) == 1) {
            lua_pushnumber(L, obj.view.subviews.firstObject.frame.size.width) ;
        } else {
            NSRect itemRect = obj.view.subviews.firstObject.frame ;
            itemRect.size.width = lua_tonumber(L, 2) ;
            obj.view.subviews.firstObject.frame = itemRect ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        return luaL_argerror(L, 1, "method only valid for canvas type") ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:canvasClickColor([color]) -> touchbarItemObject | current value
/// Method
/// Get or set the background color displayed when a canvas touchbar item is currently being touched.
///
/// Parameters:
///  * `color` - an optional table specifying a color as defined in the `hs.drawing.color` module, or an explicit nil to reset it to the default. Defaults to the macOS System Selected Control Color (`hs.drawing.color.colorsFor("System")["selectedControlColor"]`).
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newCanvas](#newCanvas) constructor.
///  * To specify that no background color should be displayed when the canvas touchbar item is in an active state, specify a color with an alpha value of 0, e.g. `{ alpha = 0 }`.
static int customtouchbaritem_canvasHighlightColor(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMCustomTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (obj.itemType == TBIT_canvas) {
        CanvasActionCell *cell = ((CanvasWrapper *)obj.view).cell ;
        if (lua_gettop(L) == 1) {
            NSColor *result = cell.clickColor ;
            if (result) {
                [skin pushNSObject:result] ;
            } else {
                [skin pushNSObject:[NSColor selectedControlColor]] ;
            }
        } else {
            if (lua_type(L, 2) == LUA_TNIL) {
                cell.clickColor = nil ;
            } else {
                cell.clickColor = [skin luaObjectAtIndex:2 toClass:"NSColor"] ;
            }
            lua_pushvalue(L, 1) ;
        }
    } else {
        return luaL_argerror(L, 1, "method only valid for canvas type") ;
    }
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:enabled([state]) -> touchbarItemObject | current value
/// Method
/// Get or set whether the touchbar item is enabled (accepting touches) or disabled.
///
/// Parameters:
///  * `state` - an optional boolean, default true, specifying whether or not the touchbar item is currently enabled.
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newButton](#newButton) or [hs._asm.undocumented.touchbar.item.newCanvas](#newCanvas) constructors.
static int customtouchbaritem_enabled(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMCustomTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
    switch(obj.itemType) {
        case TBIT_buttonWithImage:
        case TBIT_buttonWithText:
        case TBIT_buttonWithImageAndText:
        case TBIT_canvas: {
            if (lua_gettop(L) == 1) {
                lua_pushboolean(L, ((NSButton *)obj.view).enabled) ;
            } else {
                ((NSButton *)obj.view).enabled = (BOOL)lua_toboolean(L, 2) ;
                lua_pushvalue(L, 1) ;
            }
        } break ;
        default:
            return luaL_argerror(L, 1, "method only valid for button and canvas types") ;
    }
#pragma clang diagnostic pop
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:buttonSize([size]) -> touchbarItemObject | current value
/// Method
/// Get or set the button touchbar item's button size.
///
/// Parameters:
///  * `size` - an optional string, default "regular", specifying the button touchbar button size.  Must be one of "regular", "small", or "mini".
///
/// Returns:
///  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
///
/// Notes:
///  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newButton](#newButton) or [hs._asm.undocumented.touchbar.item.newCanvas](#newCanvas) constructors.
///  * The button sizes are defined by the macOS operating system and under macOS 10.12 have the following visual effects (this may change with future macOS updates):
///    * `regular` - presents the button as a rounded grey rectangle with the image and/or title inside of the grey area.
///    * `mini`    - presents the image and/or title of the button without a rounded rectangle background. Takes up less space then `regular`.
///    * `small`   - presents the image and/or title of the button without a rounded rectangle background. Takes up less space in the touchbar then `mini`.
static int customtouchbaritem_size(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMCustomTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
    switch(obj.itemType) {
        case TBIT_buttonWithImage:
        case TBIT_buttonWithText:
        case TBIT_buttonWithImageAndText: {
            if (lua_gettop(L) == 1) {
                NSControlSize size = ((NSButton *)obj.view).controlSize ;
                switch (size) {
                    case NSControlSizeMini:    lua_pushstring(L, "mini") ; break ;
                    case NSControlSizeSmall:   lua_pushstring(L, "small") ; break ;
                    case NSControlSizeRegular: lua_pushstring(L, "regular") ; break ;
                    default:
                        [skin pushNSObject:[NSString stringWithFormat:@"unrcognized control size: %lu", size]] ;
                }
            } else {
                NSString *sizeString = [skin toNSObjectAtIndex:2] ;
                NSControlSize size = ((NSButton *)obj.view).controlSize ;

                if      ([sizeString isEqualToString:@"mini"])    { size = NSControlSizeMini ; }
                else if ([sizeString isEqualToString:@"small"])   { size = NSControlSizeSmall ; }
                else if ([sizeString isEqualToString:@"regular"]) { size = NSControlSizeRegular ; }
                else {
                    return luaL_argerror(L, 2, "must be one of mini, small, or regular") ;
                }
                ((NSButton *)obj.view).controlSize = size ;
                lua_pushvalue(L, 1) ;
            }
        } break ;
        default:
            return luaL_argerror(L, 1, "method only valid for button types") ;
    }
#pragma clang diagnostic pop
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


/// hs._asm.undocumented.touchbar.item:itemType() -> string
/// Method
/// Returns the type of the touchbar item as a string.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the type of the touchbar item as one of the following strings: "buttonWithText", "buttonWithImage", "buttonWithImageAndText", "group", "slider", or "canvas".
///
/// Notes:
///  * other types may be added in future updates.
static int touchbaritem_itemType(__unused lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMCustomTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:itemTypeStrings[@(obj.itemType)]] ;
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
///  * If the bar that the item is assigned to has been visible at some point in the past, and the item was visible at that time, this method will return true even if the bar is not currently visible. If you want to know if the item is visible in the touch bar display *right now*, you should use `reallyVisible = bar:isVisible() and item:isVisible()`
static int touchbaritem_isVisible(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    lua_pushboolean(L, obj.visible) ;
    return 1 ;
}

/// hs._asm.undocumented.touchbar.item:visibilityPriority([priority]) -> touchbarItemObject | current value
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

/// hs._asm.undocumented.touchbar.item:callback([fn | nil]) -> touchbarItemObject | current value
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
///  * The callback function should return nothing. The arguments provided are type dependent, described here:
///    * Items constructed with [hs._asm.undocumented.touchbar.item.newButton](#newButton):
///      * the touchbar item itself
///
///    * Items constructed with [hs._asm.undocumented.touchbar.item.newCanvas](#newCanvas):
///      * the touchbar item itself
///    * Note that if you use `hs.canvas:canvasMouseEvents` and `hs.canvas:mouseCallback` on the canvas object, you can get `mouseDown`, `mouseUp`, `mouseEntered`, `mouseExited`, and `mouseMove` callbacks as if they were generated by the left mouse button.  You do not need to set a touchbar item callback to take advantage of the canvas callbacks.
///
///    * Items constructed with [hs._asm.undocumented.touchbar.item.newGroup](#newGroup):
///    * A callback assigned to a group touchbar item will never be invoked; instead if the items within the group have a callback assigned, the specific item within the group will have its callback invoked.
///
///    * Items constructed with [hs._asm.undocumented.touchbar.item.newSlider](#newSlider):
///      * the touchbar item itself
///      * a number or string as follows:
///        * if the image assigned with [hs._asm.undocumented.touchbar.item:sliderMinImage](#sliderMinImage) is touched, the string "minimum".
///        * if the image assigned with [hs._asm.undocumented.touchbar.item:sliderMaxImage](#sliderMaxImage) is touched, the string "maximum".
///        * if the slider knob is moved to a new position, returns a number between [hs._asm.undocumented.touchbar.item:sliderMin](#sliderMin) and [hs._asm.undocumented.touchbar.item:sliderMax](#sliderMax) indicating the new position.
static int touchbaritem_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMCustomTouchBarItem *obj = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        obj.callbackRef = [skin luaUnref:refTable ref:obj.callbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
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

static int pushHSASMCustomTouchBarItem(lua_State *L, id obj) {
    HSASMCustomTouchBarItem *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMCustomTouchBarItem *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMCustomTouchBarItemFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMCustomTouchBarItem *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMCustomTouchBarItem, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

static int pushHSASMGroupTouchBarItem(lua_State *L, id obj) {
    HSASMGroupTouchBarItem *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMGroupTouchBarItem *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMGroupTouchBarItemFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGroupTouchBarItem *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMGroupTouchBarItem, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

static int pushHSASMSliderTouchBarItem(lua_State *L, id obj) {
    HSASMSliderTouchBarItem *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMSliderTouchBarItem *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMSliderTouchBarItemFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMSliderTouchBarItem *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMSliderTouchBarItem, L, idx, USERDATA_TAG) ;
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
    HSASMCustomTouchBarItem *obj = get_objectFromUserdata(__bridge_transfer HSASMCustomTouchBarItem, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin shared] ;
            obj.callbackRef = [skin luaUnref:refTable ref:obj.callbackRef] ;
            if (obj.visibilityCallbackRef != LUA_NOREF) {
                obj.visibilityCallbackRef = [skin luaUnref:refTable ref:obj.visibilityCallbackRef] ;
                [obj removeObserver:obj forKeyPath:@"visible" context:myKVOContext] ;
            }
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
    {"customizationLabel",  touchbaritem_customizationLabel},
    {"identifier",          touchbaritem_identifier},
    {"isVisible",           touchbaritem_isVisible},
    {"visibilityPriority",  touchbaritem_visibilityPriority},
    {"callback",            touchbaritem_callback},
    {"itemType",            touchbaritem_itemType},
    {"visibilityCallback",  touchbaritem_visibilityCallback},

    {"buttonImage",         customtouchbaritem_image},
    {"buttonTitle",         customtouchbaritem_title},
    {"buttonSize",          customtouchbaritem_size},


    {"enabled",             customtouchbaritem_enabled},

    {"canvasWidth",         customtouchbaritem_canvasWidth},
    {"canvasClickColor",    customtouchbaritem_canvasHighlightColor},

    {"groupTouchbar",       grouptouchbaritem_groupTouchBar},

    {"sliderMin",           slidertouchbaritem_minValue},
    {"sliderMax",           slidertouchbaritem_maxValue},
    {"sliderValue",         slidertouchbaritem_currentValue},
    {"sliderMinImage",      slidertouchbaritem_minImage},
    {"sliderMaxImage",      slidertouchbaritem_maxImage},

    {"addToSystemTray",     touchbaritem_systemTray},

    {"__tostring",          userdata_tostring},
    {"__eq",                userdata_eq},
    {"__gc",                userdata_gc},
    {NULL,                  NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"newButton",  customtouchbaritem_newButton},
//     {"newButton2", customtouchbaritem_newButton2},
    {"newCanvas",  customtouchbaritem_newCanvas},
    {"newGroup",   grouptouchbaritem_newGroup},
    {"newSlider",  slidertouchbaritem_newSlider},
    {NULL,         NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_undocumented_touchbar_item(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    itemTypeStrings = TB_ItemTypeStrings ;

    if (NSClassFromString(@"NSTouchBarItem")) {
        refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                         functions:moduleLib
                                     metaFunctions:nil    // or module_metaLib
                                   objectFunctions:userdata_metaLib];

        push_visibilityPriorities(L) ; lua_setfield(L, -2, "visibilityPriorities") ;

        [skin registerPushNSHelper:pushHSASMCustomTouchBarItem         forClass:"HSASMCustomTouchBarItem"] ;
        [skin registerLuaObjectHelper:toHSASMCustomTouchBarItemFromLua forClass:"HSASMCustomTouchBarItem"
                                                            withUserdataMapping:USERDATA_TAG] ;

        [skin registerPushNSHelper:pushHSASMGroupTouchBarItem         forClass:"HSASMGroupTouchBarItem"] ;
        [skin registerLuaObjectHelper:toHSASMGroupTouchBarItemFromLua forClass:"HSASMGroupTouchBarItem"] ;

        [skin registerPushNSHelper:pushHSASMSliderTouchBarItem         forClass:"HSASMSliderTouchBarItem"] ;
        [skin registerLuaObjectHelper:toHSASMSliderTouchBarItemFromLua forClass:"HSASMSliderTouchBarItem"] ;

    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s requires NSTouchBarItem which is only available in 10.12.2 and later", USERDATA_TAG]] ;
        lua_newtable(L) ;
    }
    return 1;
}

#pragma clang diagnostic pop
