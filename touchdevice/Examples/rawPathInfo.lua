local touchdevice = require("hs._asm.undocumented.touchdevice")
local canvas      = require("hs.canvas")
local eventtap    = require("hs.eventtap")
local mouse       = require("hs.mouse")
local events      = eventtap.event.types

local module = {}

-- create the display panel

local closeButtonCenter = { x = 15, y = 15 }
local closeButtonRadius = 6

module._display = canvas.new{ x = 100, y = 100, h = 410, w = 400 }
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
    frame     = { x = "5%", y = "5%", h = "90%", w = "90%" },
    textColor = { white = 1 },
    textSize  = 10,
    textFont  = "Menlo",
}
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

module.start = function(idx)
    idx = idx or 1
    if touchdevice.available() then
        local devID = touchdevice.devices()[idx] or touchdevice.devices()[1]
        module._display.output.text = "<waiting>"
        module._display:show()
        module._touchdevice = touchdevice.forDeviceID(devID):pathCallback(function(self, pathID, stage, touch)
            local output = "Path Callback Example for pathID: " .. tostring(pathID) .. " in stage " .. stage .. "\n"
            output = output .. "Device ID " .. tostring(self:deviceID()) .. "\n\n"

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
--             output = output .. string.format("_field9          %d <-- unknown purpose\n", touch._field9)
            output = output .. string.format("_field14         %d <-- unknown purpose\n", touch._field14)
            output = output .. string.format("_field15         %d <-- unknown purpose\n", touch._field15)
            module._display.output.text = output
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
