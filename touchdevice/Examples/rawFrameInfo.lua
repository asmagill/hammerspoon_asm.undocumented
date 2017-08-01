local touchdevice = require("hs._asm.undocumented.touchdevice")
local canvas      = require("hs.canvas")
local eventtap    = require("hs.eventtap")
local mouse       = require("hs.mouse")
local events      = eventtap.event.types
local screen      = require("hs.screen")

local module = {}

-- calculate how many total presses we can display

local touchFrames = {}
local infoBoxSize = { h = 340, w = 340 }
local screenFrame = screen.mainScreen():frame()
local rows = math.floor(screenFrame.h / infoBoxSize.h)
local cols = math.floor(screenFrame.w / infoBoxSize.w)
local hPad = math.min(20, (screenFrame.h - (infoBoxSize.h * rows)) / 2)
local wPad = math.min(20, (screenFrame.w - (infoBoxSize.w * cols)) / 2)

for r = 1, rows, 1 do
    for c = 1, cols, 1 do
        table.insert(touchFrames, {
            x = wPad + ( c - 1 ) * infoBoxSize.w,
            y = hPad + ( r - 1 ) * infoBoxSize.h + 30,
            h = infoBoxSize.h,
            w = infoBoxSize.w,
        })
    end
end

-- create the display panel -- hopefully this adjust to your screen size reasonably well

local closeButtonCenter = { x = 15, y = 15 }
local closeButtonRadius = 6

local canvasFrame = {
    x = screenFrame.x + (screenFrame.w - (wPad * 2 + infoBoxSize.w * cols)) / 2,
    y = screenFrame.y + (screenFrame.h - (hPad * 2 + infoBoxSize.h * rows)) / 2 + 30,
    h = hPad * 2 + infoBoxSize.h * rows + 30,
    w = wPad * 2 + infoBoxSize.w * cols,
}

module._display = canvas.new(canvasFrame)
                        :level("floating")
                        :mouseCallback(
                            function(c, m, id, x, y)
                        -- allow moving the canvas by clicking in it and dragging
                                if id == "_canvas_" then
                                    module._mouseMoveTracker = eventtap.new({ events.leftMouseDragged, events.leftMouseUp }, function(e)
                                        if e:getType() == events.leftMouseUp then
                                            module._mouseMoveTracker:stop()
                                            module._mouseMoveTracker = nil
                                        else
                                            local mousePosition = mouse.getAbsolutePosition()
                                            module._display:topLeft({ x = mousePosition.x - x, y = mousePosition.y - y })
                                        end
                                    end, false):start()
                        -- allow stopping the callback and closing the display by clicking in the close circle
                                elseif id == "close" then
                                    if m == "mouseEnter" then
                                        module._display.closeX.action = "fill"
                                    elseif m == "mouseExit" then
                                        module._display.closeX.action = "skip"
                                    elseif m == "mouseUp" then
                                        module.stop()
                                    end
                                end
                            end)
                        :canvasMouseEvents(true)

module._display[#module._display + 1] = {
    id               = "background",
    type             = "rectangle",
    roundedRectRadii = { xRadius = 20, yRadius = 20 },
    fillColor        = { white = .35, alpha = .85  },
    strokeColor      = { white = .25, alpha = .85 },
    strokeWidth      = 6,
    clipToPath       = true,
}

module._display[#module._display + 1] = {
    id        = "output",
    type      = "text",
    frame     = { x = 30, y = 15, h = 30, w = wPad * 2 + infoBoxSize.w * cols - 40},
    textColor = { white = 1 },
    textSize  = 10,
    textFont  = "Menlo",
}

for i, v in ipairs(touchFrames) do
    module._display[#module._display + 1] = {
        id        = "touch" .. tostring(i),
        type      = "text",
        frame     = {
            x = v.x + 5,
            y = v.y + 5,
            h = v.h - 10,
            w = v.w - 10,
        },
        textColor = { white = 1 },
        textSize  = 10,
        textFont  = "Menlo",
    }
    module._display[#module._display + 1] = {
        id        = "touchFrame" .. tostring(i),
        type      = "rectangle",
        frame     = v,
        action    = "stroke",
        strokeColor = { blue = 1 },
    }
end

module._display[#module._display + 1] = {
    id                  = "close",
    type                = "circle",
    fillColor           = { red = 1 },
    strokeColor         = { white = 0 },
    center              = closeButtonCenter,
    radius              = closeButtonRadius,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
    clipToPath          = true,
}
module._display[#module._display + 1] = {
    id          = "closeX",
    type        = "circle",
    action      = "skip",
    fillColor   = { white = 0 },
    center      = closeButtonCenter,
    radius      = closeButtonRadius / 2,
    clipToPath  = true,
}

-- this is where the touchdevice object is created and the callback assigned

local generateTouchOutput = function(touch)
    local output = ""
    output = output .. string.format("frame            %d\n", touch.frame)
    output = output .. string.format("timestamp        %f\n", touch.timestamp)
    output = output .. string.format("pathIndex        %d\n", touch.pathIndex)
    output = output .. string.format("stage            %s\n", touch.stage)
    output = output .. string.format("fingerID        % d\n", touch.fingerID)
    output = output .. string.format("handID          % d\n", touch.handID)
    output = output .. string.format("normalizedVector {\n")
    output = output .. string.format("                    P = { % f, % f },\n", touch.normalizedVector.position.x, touch.normalizedVector.position.y)
    output = output .. string.format("                    V = { % f, % f }\n",  touch.normalizedVector.velocity.x, touch.normalizedVector.velocity.y)
    output = output .. string.format("                 }\n")
    output = output .. string.format("zTotal          % f\n", touch.zTotal)
    output = output .. string.format("zPressure       % f\n", touch.zPressure)
    output = output .. string.format("angle           % f\n", touch.angle)
    output = output .. string.format("majorAxis       % f\n", touch.majorAxis)
    output = output .. string.format("minorAxis       % f\n", touch.minorAxis)
    output = output .. string.format("absoluteVector   {\n")
    output = output .. string.format("                    P = { % 11.6f, % 11.6f },\n", touch.absoluteVector.position.x, touch.absoluteVector.position.y)
    output = output .. string.format("                    V = { % 11.6f, % 11.6f }\n",  touch.absoluteVector.velocity.x, touch.absoluteVector.velocity.y)
    output = output .. string.format("                 }\n")
    output = output .. string.format("zDensity        % f\n", touch.zDensity)
    output = output .. "\n"
--     output = output .. string.format("_field9          %d <-- unknown purpose\n", touch._field9)
    output = output .. string.format("_field14         %d <-- unknown purpose\n", touch._field14)
    output = output .. string.format("_field15         %d <-- unknown purpose\n", touch._field15)
    return output
end

module.start = function(idx)
    idx = idx or 1
    if touchdevice.available() then
        local devID = touchdevice.devices()[idx] or touchdevice.devices()[1]
        module._display.output.text = "<waiting>"
        module._display:show()
        module._touchdevice = touchdevice.forDeviceID(devID):frameCallback(function(self, touches, time, frame)
            local output = "Frame Callback Example for frame: " .. tostring(frame) .. " with " .. tostring(#touches) .. " " .. ((#touches == 1) and "touch  " or "touches") .. " at time " .. tostring(time) .. "\n"
            output = output .. "Device ID " .. tostring(self:deviceID()) .. "\n"
            module._display.output.text = output

            for i, v in ipairs(touchFrames) do
                module._display["touch" .. tostring(i)].text = touches[i] and generateTouchOutput(touches[i]) or ""
            end
        end):start()
    else
        print("+++ This example requires a multi-touch device; call start() once you have attached your device.")
    end
end

module.stop = function()
    module._touchdevice:stop()
    module._display:hide()
end

module.start()

-- cleanup after ourselves... probably unnecessary, but a good habit

return setmetatable(module, {
    __gc = function(self)
        module._touchdevice():stop()
        module._display:delete()
    end
})
