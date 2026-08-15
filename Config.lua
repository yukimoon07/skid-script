-- ============================================
-- MODULE: Config
-- ============================================
-- Mô tả: Hệ thống Save/Load Config
-- ============================================

local Config = {}
local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)

Config.Core = Core
Config.Utils = Utils

Config.ConfigFile = "BananaHub_Config.json"
Config.DefaultConfig = {
    Version = "2.0",
    Farm = {Enabled = false, Method = "Level Farm", Distance = 300, AutoQuest = true, BringMob = true, BringMobCount = 3, UseSkill = true, UseFruitM1 = false},
    Combat = {AttackRadius = 80, AutoSkill = true, SkillHoldTime = 0.5, UseFruitM1 = false},
    Movement = {TweenSpeed = 300, UseTeleport = false, TeleportDistance = 1000},
    Raid = {Enabled = false, RaidType = "Flame", AutoBuyChip = true, AutoAwake = false, HopServer = false, MultiRaid = false},
    SeaEvent = {Enabled = false, Events = {SeaBeast = true, Terrorshark = true, Ship = true, Piranha = false}, Boat = "PirateBrigade", AutoBuyBoat = true, UseDragonstorm = false, UseSkullGuitar = false, UseFruitM1 = false, DodgeSkill = true, TweenSpeed = 350},
    Trial = {Enabled = false, Race = "Human", AutoChooseGear = true, AutoBuyGear = true, AutoTurnOnV4 = true, HopServer = false},
    Craft = {Enabled = false, Items = {["Shark Anchor"] = true, ["Volcanic Magnet"] = false, ["Soul Guitar"] = false, ["CDK"] = false}, AutoFarmMaterials = true},
    GUI = {Position = UDim2.new(0.5, -190, 0.5, -260), LastTab = "Farm"},
}

function Config:Save()
    if not writefile then return false end
    
    local configData = self:CollectConfig()
    
    local success, err = pcall(function()
        writefile(self.ConfigFile, self.Core.Services.HttpService:JSONEncode(configData))
    end)
    
    if success then
        print("[Config] Saved successfully!")
        return true
    else
        print("[Config] Save failed:", err)
        return false
    end
end

function Config:CollectConfig()
    local configData = self.DefaultConfig
    
    local farm = require(script.Parent.Farm)
    if farm and farm.Config then
        configData.Farm = Utils:TableMerge(configData.Farm, farm.Config)
    end
    
    local combat = require(script.Parent.Combat)
    if combat and combat.Config then
        configData.Combat = Utils:TableMerge(configData.Combat, combat.Config)
    end
    
    local movement = require(script.Parent.Movement)
    if movement and movement.Config then
        configData.Movement = Utils:TableMerge(configData.Movement, movement.Config)
    end
    
    local raid = require(script.Parent.Raid)
    if raid and raid.Config then
        configData.Raid = Utils:TableMerge(configData.Raid, raid.Config)
    end
    
    local seaEvent = require(script.Parent.SeaEvent)
    if seaEvent and seaEvent.Config then
        configData.SeaEvent = Utils:TableMerge(configData.SeaEvent, seaEvent.Config)
    end
    
    local trial = require(script.Parent.Trial)
    if trial and trial.Config then
        configData.Trial = Utils:TableMerge(configData.Trial, trial.Config)
    end
    
    local craft = require(script.Parent.Craft)
    if craft and craft.Config then
        configData.Craft = Utils:TableMerge(configData.Craft, craft.Config)
    end
    
    return configData
end

function Config:Load()
    if not readfile then return false end
    
    local success, data = pcall(function()
        return readfile(self.ConfigFile)
    end)
    
    if not success or not data then
        print("[Config] No config file found, using defaults")
        return false
    end
    
    local configData
    success, configData = pcall(function()
        return self.Core.Services.HttpService:JSONDecode(data)
    end)
    
    if not success or not configData then
        print("[Config] Failed to parse config file")
        return false
    end
    
    self:ApplyConfig(configData)
    print("[Config] Loaded successfully!")
    return true
end

function Config:ApplyConfig(configData)
    local farm = require(script.Parent.Farm)
    if farm and farm.Config and configData.Farm then
        farm.Config = Utils:TableMerge(farm.Config, configData.Farm)
    end
    
    local combat = require(script.Parent.Combat)
    if combat and combat.Config and configData.Combat then
        combat.Config = Utils:TableMerge(combat.Config, configData.Combat)
    end
    
    local movement = require(script.Parent.Movement)
    if movement and movement.Config and configData.Movement then
        movement.Config = Utils:TableMerge(movement.Config, configData.Movement)
    end
    
    local raid = require(script.Parent.Raid)
    if raid and raid.Config and configData.Raid then
        raid.Config = Utils:TableMerge(raid.Config, configData.Raid)
    end
    
    local seaEvent = require(script.Parent.SeaEvent)
    if seaEvent and seaEvent.Config and configData.SeaEvent then
        seaEvent.Config = Utils:TableMerge(seaEvent.Config, configData.SeaEvent)
    end
    
    local trial = require(script.Parent.Trial)
    if trial and trial.Config and configData.Trial then
        trial.Config = Utils:TableMerge(trial.Config, configData.Trial)
    end
    
    local craft = require(script.Parent.Craft)
    if craft and craft.Config and configData.Craft then
        craft.Config = Utils:TableMerge(craft.Config, configData.Craft)
    end
end

function Config:AutoSave(interval)
    interval = interval or 30
    
    task.spawn(function()
        while true do
            task.wait(interval)
            self:Save()
        end
    end)
end

function Config:AutoLoad()
    self:Load()
end

function Config:Reset()
    self:SaveDefaultConfig()
    self:Load()
end

function Config:SaveDefaultConfig()
    if not writefile then return false end
    
    local success, err = pcall(function()
        writefile(self.ConfigFile, self.Core.Services.HttpService:JSONEncode(self.DefaultConfig))
    end)
    
    return success
end

return Config
