-- quick and dirty example -- I'll put up a better one shortly
-- note that not all of the methods used here have an effect since we only support modal touch bars atm

tb = require("hs._asm.undocumented.touchbar")

bar = tb.bar.new()

items, allowed, required, default = {}, {}, {}, {}
for i = 1, 10, 1 do
    local label = "item" .. tostring(i)
    table.insert(items, tb.item.newButton(label, hs.image.imageFromName(hs.image.systemImageNames.Bonjour), label):callback(function(item)
        print("Button " .. tostring(i) .. " was pressed")
        if i == 1 then bar:minimizeModalBar() end -- will return icon to system tray
        if i == 2 then bar:dismissModalBar() end  -- will *NOT* return icon to system tray
    end))
    if i < 3 then table.insert(required, label) end
    if i < 5 then table.insert(default, label) end
    table.insert(allowed, label)
end

for k, v in pairs(tb.bar.builtInIdentifiers) do table.insert(allowed, v) end

bar:templateItems(items)
   :customizableIdentifiers(allowed)
   :requiredIdentifiers(required)
   :defaultIdentifiers(default)
   :customizationLabel("sample")
   :escapeKeyReplacement("item3")
--    :principleItem("item3")

closeBox = true

sampleCallback = function(self)
    self:presentModalBar(bar, closeBox)
end

sysTrayIcon = tb.item.newButton(hs.image.imageFromName(hs.image.systemImageNames.ApplicationIcon), "HSSystemButton")
                     :callback(sampleCallback)
                     :addToSystemTray(true)
