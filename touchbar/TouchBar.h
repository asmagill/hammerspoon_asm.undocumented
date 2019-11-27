#import <AppKit/AppKit.h>

// Undocumented functions to display mock touchbar for non-touchbar equipped systems

// Part of SkyLight private Framework
extern CGDisplayStreamRef SLSDFRDisplayStreamCreate(void *, dispatch_queue_t, CGDisplayStreamFrameAvailableHandler) ;
// part of DFRFoundation private framework
extern BOOL   DFRSetStatus(int) ;
extern int    DFRGetStatus() ;
extern BOOL   DFRFoundationPostEventWithMouseActivity(NSEventType type, NSPoint p) ;
extern CGSize DFRGetScreenSize() ;

// Undocumented functions and methods to access the system touchbar

extern void DFRElementSetControlStripPresenceForIdentifier(NSTouchBarItemIdentifier, BOOL);

// Limited to built-in items; can't detect ones we inject; reads ~/Library/Preferences/com.apple.controlstrip.plist
extern BOOL DFRElementGetControlStripPresenceForIdentifier(NSString *identifier) ;
//   Per http://blog.eriknicolasgomez.com/2016/11/28/managing-or-setting-the-mini-touchbar-control-strip/
//     com.apple.system.brightness
//     com.apple.system.dashboard
//     com.apple.system.dictation
//     com.apple.system.do-not-disturb
//     com.apple.system.input-menu
//     com.apple.system.launchpad
//     com.apple.system.media-play-pause
//     com.apple.system.mission-control
//     com.apple.system.mute
//     com.apple.system.notification-center
//     com.apple.system.screen-lock
//     com.apple.system.screen-saver
//     com.apple.system.screencapture
//     com.apple.system.search
//     com.apple.system.show-desktop
//     com.apple.system.siri
//     com.apple.system.sleep
//     com.apple.system.volume

extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL flag) ;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

@protocol NSFunctionBarSystemTray
+ (void)addSystemTrayItem:(NSTouchBarItem *)item ;
+ (void)removeSystemTrayItem:(NSTouchBarItem *)item ;
@end
@interface NSTouchBarItem (NSFunctionBarSystemTray)
+ (void)addSystemTrayItem:(NSTouchBarItem *)item ;
+ (void)removeSystemTrayItem:(NSTouchBarItem *)item ;
@end

@protocol NSTouchBarSystemTray

// macOS 10.14 and above
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_AVAILABLE_MAC(10.14);
+ (void)minimizeSystemModalTouchBar:(NSTouchBar *)touchBar NS_AVAILABLE_MAC(10.14);
+ (void)dismissSystemModalTouchBar:(NSTouchBar *)touchBar NS_AVAILABLE_MAC(10.14);

// macOS 10.13 and below
+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_DEPRECATED_MAC(10.12.2, 10.14);
+ (void)minimizeSystemModalFunctionBar:(NSTouchBar *)touchBar NS_DEPRECATED_MAC(10.12.2, 10.14);
+ (void)dismissSystemModalFunctionBar:(NSTouchBar *)touchBar NS_DEPRECATED_MAC(10.12.2, 10.14);

@end

@interface NSTouchBar (NSTouchBarSystemTray)

// macOS 10.14 and above
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_AVAILABLE_MAC(10.14);
+ (void)minimizeSystemModalTouchBar:(NSTouchBar *)touchBar NS_AVAILABLE_MAC(10.14);
+ (void)dismissSystemModalTouchBar:(NSTouchBar *)touchBar NS_AVAILABLE_MAC(10.14);

// macOS 10.13 and below
+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_DEPRECATED_MAC(10.12.2, 10.14);
+ (void)minimizeSystemModalFunctionBar:(NSTouchBar *)touchBar NS_DEPRECATED_MAC(10.12.2, 10.14);
+ (void)dismissSystemModalFunctionBar:(NSTouchBar *)touchBar NS_DEPRECATED_MAC(10.12.2, 10.14);

@end

#pragma clang diagnostic pop
