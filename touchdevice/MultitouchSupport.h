// Tested against 10.12.6

// Portions gleaned from
//  * https://github.com/INRIA/libpointing/blob/master/pointing/input/osx/osxPrivateMultitouchSupport.h
//  * https://github.com/calftrail/Touch
//  * https://github.com/jnordberg/FingerMgmt

typedef CFTypeRef MTDeviceRef ;

typedef struct {
    float x ;
    float y ;
} MTPoint ;

typedef struct {
    MTPoint position ;
    MTPoint velocity ;
} MTVector ;

typedef NS_OPTIONS(int32_t, MTRunMode) {
    MTRunModeVerbose      = 0,
    MTRunModeLessVerbose  = 0x10000000,
//     MTRunModeUNKNOWN      = 0x00000001, // disassembly of MTDeviceStart shows that setting this prevents an instance variable
//                                         // (not sure what) from being cleared and skips the runloop check
//     MTRunModeNoRunLoop    = 0x20000000, // prevents it from being added to a runloop
} ;

typedef enum {
    MTPathStageNotTracking = 0,
    MTPathStageStartInRange,
    MTPathStageHoverInRange,
    MTPathStageMakeTouch,
    MTPathStageTouching,
    MTPathStageBreakTouch,
    MTPathStageLingerInRange,
    MTPathStageOutOfRange,
} MTPathStage ;

// gives human readable labels for the above; undefined if out of range
extern char* MTGetPathStageName(MTPathStage pathstage) ;

typedef struct {
    int32_t     frame ;
    double      timestamp ;
    int32_t     pathIndex ;        // "P" (~transducerIndex)
    MTPathStage stage ;
    int32_t     fingerID ;         // "F" (~identity)
    int32_t     handID ;           // "H" (always 1)
    MTVector    normalizedVector ;
    float       zTotal ;           // "ZTot" (~quality, multiple of 1/8 between 0 and 1)
//     int32_t     field9 ;           // always 0
    float       zPressure ;        // uncertain; on my external force touch trackpad, this tracks as pressure
                                   //            on my builtin non-force touch trackpad, it remains 0
    float       angle ;
    float       majorAxis ;
    float       minorAxis ;
    MTVector    absoluteVector ;   // in "mm"
    int32_t     field14 ;          // always 0
    int32_t     field15 ;          // always 0
    float       zDensity ;         // "ZDen" (~density)
} MTTouch ;

typedef void (*MTFrameCallbackFunction)(MTDeviceRef device,
                                        MTTouch *touches, size_t numTouches,
                                        double timestamp, size_t frame, void* refCon) ;

typedef void (*MTPathCallbackFunction)(MTDeviceRef device, long pathID, long stage, MTTouch* touch) ;
typedef void (*MTPathCallbackFunctionWithRefcon)(MTDeviceRef device, long pathID, long stage, MTTouch* touch, void* refCon) ;

extern CFTypeID           MTDeviceGetTypeID() ;

extern double             MTAbsoluteTimeGetCurrent() ;
extern BOOL               MTDeviceIsAvailable() ;

extern CFArrayRef         MTDeviceCreateList() ;
extern MTDeviceRef        MTDeviceCreateDefault() ;
extern MTDeviceRef        MTDeviceCreateFromDeviceID(uint64_t) ;
extern void               MTDeviceRelease(MTDeviceRef) ;

extern OSStatus           MTDeviceStart(MTDeviceRef, MTRunMode) ;
extern OSStatus           MTDeviceStop(MTDeviceRef) ;

extern io_service_t       MTDeviceGetService(MTDeviceRef) ;

// These return true or false indicating success/failure
extern BOOL               MTRegisterContactFrameCallback(MTDeviceRef, MTFrameCallbackFunction) ;
extern BOOL               MTRegisterContactFrameCallbackWithRefcon(MTDeviceRef, MTFrameCallbackFunction, void*) ;
extern BOOL               MTUnregisterContactFrameCallback(MTDeviceRef, MTFrameCallbackFunction) ;

// Make sure to use the correct unregistration function -- the callback is stored in a different location in the object's
// instance data depending upon the callback type
extern BOOL               MTRegisterPathCallback(MTDeviceRef, MTPathCallbackFunction) ;
extern BOOL               MTUnregisterPathCallback(MTDeviceRef, MTPathCallbackFunction) ;
extern BOOL               MTRegisterPathCallbackWithRefcon(MTDeviceRef, MTPathCallbackFunctionWithRefcon, void*) ;
extern BOOL               MTUnregisterPathCallbackWithRefcon(MTDeviceRef, MTPathCallbackFunctionWithRefcon) ;

// Not sure how useful some of these are, but they seem to work reliably
extern BOOL               MTDeviceIsRunning(MTDeviceRef) ;
extern BOOL               MTDeviceIsAlive(MTDeviceRef) ;
extern BOOL               MTDeviceIsMTHIDDevice(MTDeviceRef) ;
extern BOOL               MTDeviceIsBuiltIn(MTDeviceRef) ;
extern BOOL               MTDeviceSupportsForce(MTDeviceRef) ;
extern BOOL               MTDeviceSupportsActuation(MTDeviceRef) ;
extern BOOL               MTDeviceIsOpaqueSurface(MTDeviceRef) ;
extern BOOL               MTDeviceDriverIsReady(MTDeviceRef) ;
extern BOOL               MTDevicePowerControlSupported(MTDeviceRef) ;

extern OSStatus           MTDeviceGetFamilyID(MTDeviceRef, int32_t*) ;
extern OSStatus           MTDeviceGetVersion(MTDeviceRef, int32_t*) ;
extern OSStatus           MTDeviceGetDeviceID(MTDeviceRef, uint64_t*) ;
extern OSStatus           MTDeviceGetDriverType(MTDeviceRef, int32_t*) ;
extern OSStatus           MTDeviceGetSensorSurfaceDimensions(MTDeviceRef, int32_t*, int32_t*) ;
extern OSStatus           MTDeviceGetSensorDimensions(MTDeviceRef, int32_t*, int32_t*) ;
extern OSStatus           MTDeviceGetGUID(MTDeviceRef, uuid_t*) ;

// Hopper disassembly shows that this searches for the key "Multitouch Serial Number" and returns an empty string if it's
// not present... The built in non-force touch trackpad in my laptop works with this, but my newer "Magic Trackpad 2"
// returns a more useful value with:
//     CFStringRef SN = (CFStringRef)IORegistryEntrySearchCFProperty(MTDeviceGetService(device),
//                                                                   kIOServicePlane,
//                                                                   CFSTR(kIOHIDSerialNumberKey),
//                                                                   kCFAllocatorDefault,
//                                                                   kIORegistryIterateRecursively) ;
extern OSStatus           MTDeviceGetSerialNumber(MTDeviceRef, CFStringRef*) ;

// for force touch trackpads, allows disabling ability to accept clicks; still responds to touches and gestures, though
// always false for non force touch trackpads
extern BOOL               MTDeviceGetSystemForceResponseEnabled(MTDeviceRef) ;
extern void               MTDeviceSetSystemForceResponseEnabled(MTDeviceRef, BOOL) ;

// Always true for non force touch trackpads
extern OSStatus           MTDeviceSupportsSilentClick(MTDeviceRef, BOOL*) ;

#pragma mark - Untested/Problematic

extern MTDeviceRef        MTDeviceCreateFromService(io_service_t) ;

// Doesn't work -- one source believes that this compares by ptr and not the actual contents of the GUID
extern MTDeviceRef        MTDeviceCreateFromGUID(uuid_t) ;

// Unless you're messing with the flags to MTDeviceStart, the runloop is handled by MTDeviceStart and shouldn't
// be required to be invoked directly
extern CFRunLoopSourceRef MTDeviceCreateMultitouchRunLoopSource(MTDeviceRef) ;
extern OSStatus           MTDeviceScheduleOnRunLoop(MTDeviceRef, CFRunLoopRef, CFStringRef) ;

// Can't test with my devices, so prototype is a best guess atm
extern OSStatus           MTDevicePowerSetEnabled(MTDeviceRef, BOOL) ;
extern void               MTDevicePowerGetEnabled(MTDeviceRef, BOOL*) ;
extern OSStatus           MTDeviceSetUILocked(MTDeviceRef, BOOL) ;

// always 0 for my devices (non force touch laptop and external force touch trackpad), so not sure if useful or return type is correct
extern int32_t            MTDeviceGetMinDigitizerPressureValue(MTDeviceRef) ;
extern int32_t            MTDeviceGetMaxDigitizerPressureValue(MTDeviceRef) ;
extern int32_t            MTDeviceGetDigitizerPressureDynamicRange(MTDeviceRef) ;

// Enables predefined callbacks for device for path and image callbacks (with various parameters for each BOOL after
// the first (which is for path callback) that output via printf; presumably for internal debugging purposes
//
// Online example shows this with one BOOL flag, but Hopper disassembly shows all 6 and shows that the additional
// flags are for enabling image callbacks with various paramters.  Preliminary tests never show output from the
// image callbacks so either my devices don't support these or I don't understand them well enough -- likely both
//    MTRegisterPathCallback(MTDeviceRef, MTPathPrintCallback) ;
//    MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImagePrintCallback, 0x7ffffffe, 0x2, NULL) ;
//    MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImagePrintCallback, 0x2, 0x10, NULL) ;
//    MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImagePrintCallback, 0x2, 0x10000, NULL) ;
//    MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImagePrintCallback, 0x2, 0x100000, NULL) ;
//    MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImagePrintCallback, 0x2, 0x800000, NULL ) ;
extern void MTEasyInstallPrintCallbacks(MTDeviceRef, BOOL, BOOL, BOOL, BOOL, BOOL, BOOL) ;

// // If I can ever get useful info out of the test callbacks, then I might try to identify these further...
//
typedef void (*MTImageCallbackFunction)(MTDeviceRef, void*, void*, void*) ;

extern BOOL MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImageCallbackFunction, int32_t, int32_t, void*) ;
extern BOOL MTRegisterImageCallback(MTDeviceRef, MTImageCallbackFunction, int32_t, int32_t) ;
extern BOOL MTUnregisterImageCallback(MTDeviceRef, MTImageCallbackFunction) ;

// Shorthand for MTRegisterImageCallbackWithRefcon(MTDeviceRef, MTImageCallbackFunction, 0x2, 0x10000, NULL) ;
extern BOOL MTRegisterMultitouchImageCallback(MTDeviceRef, MTImageCallbackFunction);

// predefined callbacks for testing. uses printf to stdout
extern MTPathCallbackFunction MTPathPrintCallback ;
extern MTImageCallbackFunction MTImagePrintCallback ;
