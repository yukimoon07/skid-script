-- ============================================
-- MODULE: Craft
-- ============================================
-- Mô tả: Hệ thống Auto Craft
-- ============================================

local Craft = {}
local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)
local Combat = require(script.Parent.Combat)
local Movement = require(script.Parent.Movement)

Craft.Core = Core
Craft.Utils = Utils
Craft.Combat = Combat
Craft.Movement = Movement

-- CONFIGURATION
Craft.Config = {
    Enabled = false,
    Items = {
        ["Shark Anchor"] = true,
        ["Volcanic Magnet"] = false,
        ["Soul Guitar"] = false,
        ["CDK"] = false,
    },
    AutoFarmMaterials = true,
}

-- CRAFT DATA
Craft.CraftData = {
    ["Shark Anchor"] = {
        Name = "Shark Anchor",
        Materials = {
            {Name = "Monster Magnet", Count = 1},
            {Name = "Shark Tooth Necklace", Count = 1},
            {Name = "Terror Jaw", Count = 1},
            {Name = "Terror Eyes", Count = 2},
            {Name = "Shark Tooth", Count = 10},
            {Name = "Electric Wing", Count = 10},
            {Name = "Fool's Gold", Count = 20},
        },
        NPC = "Crafting NPC",
    },
    ["Volcanic Magnet"] = {
        Name = "Volcanic Magnet",
        Materials = {
            {Name = "Scrap Metal", Count = 10},
            {Name = "Blaze Ember", Count = 15},
        },
        NPC = "Crafting NPC",
    },
    ["Soul Guitar"] = {
        Name = "Soul Guitar",
        Materials = {
            {Name = "Ectoplasm", Count = 250},
            {Name = "Bones", Count = 500},
            {Name = "Dark Fragment", Count = 1},
        },
        NPC = "Soul Guitar NPC",
    },
    ["CDK"] = {
        Name = "CDK",
        Materials = {
            {Name = "Tushita", Count = 1},
            {Name = "Yama", Count = 1},
            {Name = "Mastery", Count = 350},
        },
        NPC = "CDK NPC",
    },
}

local isRunning = false
local craftThread = nil

function Craft:Start()
    if isRunning then return end
    isRunning = true
    
    craftThread = task.spawn(function()
        while isRunning and self.Config.Enabled do
            task.wait(0.5)
            
            if not self.Core:IsAlive() then
                task.wait(2)
                continue
            end
            
            for itemName, enabled in pairs(self.Config.Items) do
                if enabled then
                    self:CraftItem(itemName)
                end
            end
        end
    end)
end

function Craft:Stop()
    isRunning = false
    if craftThread then
        task.cancel(craftThread)
        craftThread = nil
    end
end

function Craft:CraftItem(itemName)
    local craftData = self.CraftData[itemName]
    if not craftData then return end
    
    if self:HasItem(itemName) then
        print("[Craft] Already have", itemName)
        return
    end
    
    if not self:HasMaterials(craftData.Materials) then
        if self.Config.AutoFarmMaterials then
            self:FarmMaterials(craftData.Materials)
        else
            print("[Craft] Missing materials for", itemName)
        end
        return
    end
    
    self:DoCraft(itemName, craftData)
end

function Craft:HasItem(itemName)
    local backpack = self.Core.LocalPlayer.Backpack
    local character = self.Core.Character
    
    if backpack:FindFirstChild(itemName) then return true end
    if character and character:FindFirstChild(itemName) then return true end
    
    return false
end

function Craft:HasMaterials(materials)
    for _, mat in pairs(materials) do
        local count = self:CountItem(mat.Name)
        if count < mat.Count then
            return false
        end
    end
    return true
end

function Craft:CountItem(itemName)
    local count = 0
    local backpack = self.Core.LocalPlayer.Backpack
    
    for _, item in pairs(backpack:GetChildren()) do
        if item.Name == itemName then
            local quantity = item:FindFirstChild("Quantity")
            if quantity then
                count = count + quantity.Value
            else
                count = count + 1
            end
        end
    end
    
    return count
end

function Craft:FarmMaterials(materials)
    for _, mat in pairs(materials) do
        local count = self:CountItem(mat.Name)
        if count < mat.Count then
            self:FarmMaterial(mat.Name, mat.Count - count)
        end
    end
end

function Craft:FarmMaterial(materialName, neededCount)
    local mobNames = {
        ["Scrap Metal"] = {"Jungle Pirate"},
        ["Blaze Ember"] = {"Hydra Enforcer", "Venomous Assailant"},
        ["Ectoplasm"] = {"Reborn Skeleton", "Living Zombie"},
        ["Bones"] = {"Reborn Skeleton", "Living Zombie"},
        ["Dark Fragment"] = {"Darkbeard", "Soul Reaper"},
    }
    
    local names = mobNames[materialName]
    if not names then return end
    
    while self:CountItem(materialName) < neededCount do
        task.wait(0.1)
        
        local mob = self.Combat:FindMobByNames(names)
        if mob then
            self.Combat:AttackM1(mob)
            self.Combat:UseAutoSkill()
            self.Movement:MoveToMob(mob, 5, 300)
        else
            self.Movement:MoveToSpawnPoint(300)
        end
    end
end

function Craft:DoCraft(itemName, craftData)
    self.Movement:MoveToNpc(craftData.NPC, 4, 300, function()
        local remote = self.Core:GetRemote("CommF_")
        if remote then
            remote:InvokeServer("Craft", itemName)
            task.wait(1)
        end
    end)
end

return Craft
