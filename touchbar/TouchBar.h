
// Undocumented functions to display mock touchbar for non-touchbar equipped systems

// Part of SkyLight private Framework
extern CGDisplayStreamRef SLSDFRDisplayStreamCreate(void *, dispatch_queue_t, CGDisplayStreamFrameAvailableHandler) ;
// part of DFRFoundation private framework
extern BOOL   DFRSetStatus(int) ;
extern int    DFRGetStatus() ;
extern BOOL   DFRFoundationPostEventWithMouseActivity(NSEventType type, NSPoint p) ;
extern CGSize DFRGetScreenSize() ;

// Undocumented functions and methods to access the system touchbar

extern void DFRElementSetControlStripPresenceForIdentifier(NSString *identifier, BOOL display) ;

// always returns false for our identifiers. Based upon disassembly with Hopper, I think it may be limited to
// the items which can "officially" be in the system tray since it looks in an array that the set function doesn't
// update, and I haven't found a way to programmatically trigger an update of the array either.
extern BOOL DFRElementGetControlStripPresenceForIdentifier(NSString *identifier) ;

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
+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSString *)identifier ;
+ (void)minimizeSystemModalFunctionBar:(NSTouchBar *)touchBar ;
+ (void)dismissSystemModalFunctionBar:(NSTouchBar *)touchBar ;
@end
@interface NSTouchBar (NSTouchBarSystemTray)
+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSString *)identifier ;
+ (void)minimizeSystemModalFunctionBar:(NSTouchBar *)touchBar ;
+ (void)dismissSystemModalFunctionBar:(NSTouchBar *)touchBar ;
@end

#pragma clang diagnostic pop
