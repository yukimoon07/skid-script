-- ============================================
-- BANANA HUB V2.0 - MAIN SCRIPT
-- ============================================
-- Tác giả: [Tên mày]
-- Phiên bản: 2.0
-- ============================================

print("🍌 Loading Banana Hub v2.0...")

-- Load modules
local Modules = {
    Utils = require(script.Modules.Utils),
    Core = require(script.Modules.Core),
    Combat = require(script.Modules.Combat),
    Movement = require(script.Modules.Movement),
    Farm = require(script.Modules.Farm),
    Raid = require(script.Modules.Raid),
    SeaEvent = require(script.Modules.SeaEvent),
    Trial = require(script.Modules.Trial),
    Craft = require(script.Modules.Craft),
    Config = require(script.Modules.Config),
    GUI = require(script.Modules.GUI),
}

-- Initialize
local Core = Modules.Core
local Combat = Modules.Combat
local Movement = Modules.Movement
local Farm = Modules.Farm
local Raid = Modules.Raid
local SeaEvent = Modules.SeaEvent
local Trial = Modules.Trial
local Craft = Modules.Craft
local Config = Modules.Config
local GUI = Modules.GUI

-- Connect modules
Combat.Core = Core
Movement.Core = Core
Farm.Core = Core
Farm.Combat = Combat
Farm.Movement = Movement
Raid.Core = Core
Raid.Combat = Combat
Raid.Movement = Movement
SeaEvent.Core = Core
SeaEvent.Combat = Combat
SeaEvent.Movement = Movement
Trial.Core = Core
Trial.Combat = Combat
Trial.Movement = Movement
Craft.Core = Core
Craft.Combat = Combat
Craft.Movement = Movement
Config.Core = Core
GUI.Core = Core

-- Load config
Config:AutoLoad()
Config:AutoSave(30)

-- Create GUI
local gui = GUI:Create()

-- Keybind: LeftControl to toggle GUI
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftControl then
        if guiInstance then
            guiInstance.Enabled = not guiInstance.Enabled
        end
    end
end)

-- Character respawn handler
Core.LocalPlayer.CharacterAdded:Connect(function(char)
    Core.Character = char
    Core:OnCharacterAdded(char)
    
    -- Stop all features
    Farm:Stop()
    Raid:Stop()
    SeaEvent:Stop()
    Trial:Stop()
    Craft:Stop()
    
    task.wait(2)
    
    -- Auto restart if enabled
    if Farm.Config.Enabled then Farm:Start() end
    if Raid.Config.Enabled then Raid:Start() end
    if SeaEvent.Config.Enabled then SeaEvent:Start() end
    if Trial.Config.Enabled then Trial:Start() end
    if Craft.Config.Enabled then Craft:Start() end
end)

-- Start enabled features
if Farm.Config.Enabled then Farm:Start() end
if Raid.Config.Enabled then Raid:Start() end
if SeaEvent.Config.Enabled then SeaEvent:Start() end
if Trial.Config.Enabled then Trial:Start() end
if Craft.Config.Enabled then Craft:Start() end

print("🍌 Banana Hub v2.0 loaded successfully!")
print("🔹 Use LeftControl to toggle GUI")
print("🔹 Enjoy!")
