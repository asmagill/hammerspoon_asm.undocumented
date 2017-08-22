//
// CoreDockPrivate.h
// Header file for undocumented Dock SPI
//
// Arranged by Tony Arnold
// Based on CoreDockPrivate.h from http://www.cocoadev.com/index.pl?DockPrefsPrivate
//
// Contributors:
//   Alacatia Labs: Initial version posted at http://www.cocoadev.com/index.pl?DockPrefsPrivate
//   Tony Arnold: CoreDockGetWorkspacesEnabled, CoreDockSetWorkspacesEnabled, CoreDockSetWorkspacesCount
//   Steve Voida: CoreDockGetWorkspacesCount
//
// Changes:
//   1.1 - Added attribution for Alacatia labs as originator
//       - Removed unnecessary reliance on CGSPrivate.h
//   1.0 - Initial release

typedef enum {
  kCoreDockOrientationIgnore = 0,
  kCoreDockOrientationTop = 1,
  kCoreDockOrientationBottom = 2,
  kCoreDockOrientationLeft = 3,
  kCoreDockOrientationRight = 4
} CoreDockOrientation;

typedef enum {
  kCoreDockPinningIgnore = 0,
  kCoreDockPinningStart = 1,
  kCoreDockPinningMiddle = 2,
  kCoreDockPinningEnd = 3
} CoreDockPinning;

typedef enum {
  kCoreDockEffectGenie = 1,
  kCoreDockEffectScale = 2,
  kCoreDockEffectSuck = 3
} CoreDockEffect;

// Tile size ranges from 0.0 to 1.0.
extern float CoreDockGetTileSize(void);
extern void CoreDockSetTileSize(float tileSize);

extern void CoreDockGetOrientationAndPinning(CoreDockOrientation *outOrientation, CoreDockPinning *outPinning);
// If you only want to set one, use 0 for the other.
extern void CoreDockSetOrientationAndPinning(CoreDockOrientation orientation, CoreDockPinning pinning);

extern void CoreDockGetEffect(CoreDockEffect *outEffect);
extern void CoreDockSetEffect(CoreDockEffect effect);

extern Boolean CoreDockGetAutoHideEnabled(void);
extern void CoreDockSetAutoHideEnabled(Boolean flag);

extern Boolean CoreDockIsMagnificationEnabled(void);
extern void CoreDockSetMagnificationEnabled(Boolean flag);

// Magnification ranges from 0.0 to 1.0.
extern float CoreDockGetMagnificationSize(void);
extern void CoreDockSetMagnificationSize(float newSize);

extern Boolean CoreDockGetWorkspacesEnabled(void);
extern void CoreDockSetWorkspacesEnabled(Boolean); // This works, but wipes out all of the other spaces prefs. An alternative is to use the ScriptingBridge which works just fine.

extern void CoreDockGetWorkspacesCount(int *rows, int *cols);
extern void CoreDockSetWorkspacesCount(int rows, int cols);
