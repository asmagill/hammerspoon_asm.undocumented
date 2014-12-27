--- === {PATH}.{MODULE} ===
---
--- This module provides access to CoreDock related features.  This allows you to adjust the Dock's position, pinning, hiding, magnification and animation settings.
---
--- This module utilizes undocumented or unpublished functions to manipulate options and features within OS X.  These are from "private" api's for Mac OS X and are not guaranteed to work with any particular version of OS X or at all.This code was based primarily on code samples and segments found at (https://code.google.com/p/undocumented-goodness/) and (https://code.google.com/p/iterm2/source/browse/branches/0.10.x/CGSInternal/CGSDebug.h?r=2).
---
--- I make no promises that these will work for you or work at all with any, past, current, or future versions of OS X.  I can confirm only that they didn't crash my machine during testing under 10.10. You have been warned.
---
--- Note that the top orientation and dock pinning has not been supported even within the private APIs for some time and may disappear from here in a future release unless another solution can be found.  It is provided here for testing and to encourage suggestions if someone is aware of a solution that has not yet been tried.

local module = require("{PATH}.{MODULE}.internal-{MODULE}")

-- private variables and methods -----------------------------------------

    local options_reverse = {}
    for i,v in pairs(module.options.orientation) do options_reverse[v] = i end
    for i,v in pairs(options_reverse) do module.options.orientation[i] = v end
    local options_reverse = {}
    for i,v in pairs(module.options.pinning) do options_reverse[v] = i end
    for i,v in pairs(options_reverse) do module.options.pinning[i] = v end
    local options_reverse = {}
    for i,v in pairs(module.options.effect) do options_reverse[v] = i end
    for i,v in pairs(options_reverse) do module.options.effect[i] = v end

-- Public interface ------------------------------------------------------

--- {PATH}.{MODULE}.restartDock()
--- Function
--- This function restarts the user's Dock instance.  This is not required for any of the functionality of this module, but does come in handy if your dock gets "misplaced" when you change monitor resolution or detach an external monitor (I've seen this occasionally when the Dock is on the left or right.)
function module.restartDock()
    os.execute("/usr/bin/killall Dock")
end

-- Return Module Object --------------------------------------------------

return module
