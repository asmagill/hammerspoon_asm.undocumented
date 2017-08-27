
--- === hs._asm.undocumented.touchbar ===
---
--- A module to display an on-screen representation of the Apple Touch Bar, even on machines which do not have the touch bar.
---
--- This code is based heavily on code found at https://github.com/bikkelbroeders/TouchBarDemoApp.  Unlike the code found at the provided link, this module only supports displaying the touch bar window on your computer screen - it does not support display on an attached iDevice.
---
--- This module requires that you are running macOS 10.12.1 build 16B2657 or greater.  Most people who have received the 10.12.1 update have an earlier build, which you can check by selecting "About this Mac" from the Apple menu and then clicking the mouse pointer on the version number displayed in the dialog box.  If you require an update, you can find it at https://support.apple.com/kb/dl1897.
---
--- If you wish to use this module in an environment where the end-user's machine may not have the correct macOS release version, you should always check the value of `hs._asm.undocumented.touchbar.supported` before trying to create the Touch Bar and provide your own fallback or message.  Failure to do so will cause your code to break to the Hammerspoon Console when you attempt to create and use the Touch Bar.

local USERDATA_TAG = "hs._asm.undocumented.touchbar"
local wrapper      = require(USERDATA_TAG .. ".supported")
if not wrapper.supported() then return wrapper end

local module     = require(USERDATA_TAG .. ".internal")
module.supported = wrapper.supported
module.item      = require(USERDATA_TAG .. ".item")
module.bar       = require(USERDATA_TAG .. ".bar")

local basePath = package.searchpath(USERDATA_TAG, package.path)
if basePath then
    basePath = basePath:match("^(.+)/init.lua$")
    if require"hs.fs".attributes(basePath .. "/docs.json") then
        require"hs.doc".registerJSONFile(basePath .. "/docs.json")
    end
end

local objectMT     = hs.getObjectMetatable(USERDATA_TAG)
local itemMT       = hs.getObjectMetatable(USERDATA_TAG .. ".item")
local barMT        = hs.getObjectMetatable(USERDATA_TAG .. ".bar")

local mouse        = require("hs.mouse")
local screen       = require("hs.screen")

require("hs.drawing.color")
require("hs.image")

-- private variables and methods -----------------------------------------

local itemTypeStrings = setmetatable({
    [-1] = "unknown",
    [0]  = "buttonWithText",
           "buttonWithImage",
           "buttonWithImageAndText",
           "candidateList",
           "colorPicker",
           "group",
           "popover",
           "sharingServicePicker",
           "slider",
           "canvas",
}, {
    __index = function(self, key) return "invalid:" .. tostring(key) .. ", notify developers" end,
    __newindex = function(self, key, value) end,
})

-- Public interface ------------------------------------------------------

--- hs._asm.undocumented.touchbar:toggle([duration]) -> touchbarObject
--- Method
--- Toggle's the visibility of the touch bar window.
---
--- Parameters:
---  * `duration` - an optional number, default 0.0, specifying the fade-in/out time when changing the visibility of the touch bar window.
---
--- Returns:
---  * the touchbarObject
objectMT.toggle = function(self, ...)
    return self:isVisible() and self:hide(...) or self:show(...)
end

--- hs._asm.undocumented.touchbar:atMousePosition() -> touchbarObject
--- Method
--- Moves the touch bar window so that it is centered directly underneath the mouse pointer.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the touchbarObject
---
--- Notes:
---  * This method mimics the display location as set by the sample code this module is based on.  See https://github.com/bikkelbroeders/TouchBarDemoApp for more information.
---  * The touch bar position will be adjusted so that it is fully visible on the screen even if this moves it left or right from the mouse's current position.
objectMT.atMousePosition = function(self)
    local origin    = mouse.getAbsolutePosition()
    local tbFrame   = self:getFrame()
    local scFrame   = mouse.getCurrentScreen():fullFrame()
    local scRight   = scFrame.x + scFrame.w
    local scBottom  = scFrame.y + scFrame.h

    origin.x = origin.x - tbFrame.w * 0.5
--     origin.y = origin.y - tbFrame.h -- Hammerspoon's 0,0 is the topLeft

    if origin.x < scFrame.x then origin.x = scFrame.x end
    if origin.x + tbFrame.w > scRight then origin.x = scRight - tbFrame.w end
    if origin.y + tbFrame.h > scBottom then origin.y = scBottom - tbFrame.h end
    return self:topLeft(origin)
end

--- hs._asm.undocumented.touchbar:centered([top]) -> touchbarObject
--- Method
--- Moves the touch bar window to the top or bottom center of the main screen.
---
--- Parameters:
---  * `top` - an optional boolean, default false, specifying whether the touch bar should be centered at the top (true) of the screen or at the bottom (false).
---
--- Returns:
---  * the touchbarObject
objectMT.centered = function(self, top)
    top = top or false

    local origin    = {}
    local tbFrame   = self:getFrame()
    local scFrame   = screen.mainScreen():fullFrame()
--     local scRight   = scFrame.x + scFrame.w
    local scBottom  = scFrame.y + scFrame.h

    origin.x = scFrame.x + (scFrame.w - tbFrame.w) / 2
    origin.y = top and scFrame.y or (scBottom - tbFrame.h)
    return self:topLeft(origin)
end

module.item.visibilityPriorities = ls.makeConstantsTable(module.item.visibilityPriorities)
module.bar.builtInIdentifiers    = ls.makeConstantsTable(module.bar.builtInIdentifiers)

--- hs._asm.undocumented.touchbar.item:presentModalBar(touchbar, [dismissButton]) -> touchbarItemObject
--- Method
--- Presents a bar in the touch bar display modally and hides this item if it is present in the System Tray of the touch bar display.
---
--- Parameters:
---  * `touchbar` - An `hs._asm.undocumented.touchbar.bar` object of the bar to display modally in the touch bar display.
---  * `dismissButton` - an optional boolean, default true, specifying whether or not the system escape (or its current replacement) button should be replaced by a button to remove the modal bar from the touch bar display when pressed.
---
--- Returns:
---  * the touchbarItem object
---
--- Notes:
---  * If you specify `dismissButton` as false, then you must use `hs._asm.undocumented.touchbar.bar:minimizeModalBar` or `hs._asm.undocumented.touchbar.bar:dismissModalBar` to remove the modal bar from the touch bar display.
---    * Use `hs._asm.undocumented.touchbar.bar:minimizeModalBar` if you want the item to reappear in the System Tray (if it was present before displaying the bar).
---
---  * If you do not have "Touch Bar Shows" set to "App Controls With Control Strip" set in the Keyboard System Preferences, the modal bar will only be displayed when the Hammerspoon application is the frontmost application.
---
---  * This method is actually a wrapper to `hs._asm.undocumented.touchbar.bar:presentModalBar` provided for convenience.
---
---  * This method uses undocumented functions and/or framework methods and is not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.
itemMT.presentModalBar = function(self, touchbar, ...)
    barMT.presentModalBar(touchbar, self, ...)
    return self
end

itemMT.itemTypeString = function(self, ...) return itemTypeStrings[self:itemType(...)] end

itemMT.groupItems = function(self, ...)
    if self:itemTypeString() == "group" then
        local args = table.pack(...)
        if args.n == 0 then
            local itemsArray = {}
            for i,v in ipairs(self:groupTouchbar():itemIdentifiers()) do
                table.insert(itemsArray, self:groupTouchbar():itemForIdentifier(v))
            end
            return itemsArray
        else
            if args.n == 1 and type(args[1]) == "table" then
                args = args[1]
            else
                args.n = nil
            end
            local itemsIdentifiers = {}
            for i,v in ipairs(args) do
                local s, r = pcall(itemMT.identifier, v)
                if s then
                    table.insert(itemsIdentifiers, r)
                else
                    return error("expected " .. USERDATA_TAG .. " object at index " .. tostring(i), 2)
                end
            end
            return self:groupTouchbar(module.bar.new():templateItems(args):defaultIdentifiers(itemsIdentifiers))
        end
    else
        return error("method only valid for group type", 2)
    end
end

-- Return Module Object --------------------------------------------------

return module
