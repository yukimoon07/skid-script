-- ============================================
-- MODULE: Raid
-- ============================================
-- Mô tả: Hệ thống Auto Raid
-- ============================================

local Raid = {}
local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)
local Combat = require(script.Parent.Combat)
local Movement = require(script.Parent.Movement)

Raid.Core = Core
Raid.Utils = Utils
Raid.Combat = Combat
Raid.Movement = Movement

-- CONFIGURATION
Raid.Config = {
    Enabled = false,
    RaidType = "Flame",
    AutoBuyChip = true,
    AutoAwake = false,
    HopServer = false,
    MultiRaid = false,
    SelectedPlayers = {},
}

-- RAID DATA
Raid.RaidData = {
    ["Flame"] = {Name = "Flame", Level = 1100, NPC = "Raids Npc", Location = CFrame.new(-5500, 314, -2855), Chip = "Special Microchip"},
    ["Ice"] = {Name = "Ice", Level = 1150, NPC = "Raids Npc", Location = CFrame.new(-5500, 314, -2855), Chip = "Special Microchip"},
    ["Dark"] = {Name = "Dark", Level = 1200, NPC = "Raids Npc", Location = CFrame.new(-5500, 314, -2855), Chip = "Special Microchip"},
    ["Light"] = {Name = "Light", Level = 1250, NPC = "Raids Npc", Location = CFrame.new(-5500, 314, -2855), Chip = "Special Microchip"},
    ["Phoenix"] = {Name = "Phoenix", Level = 1300, NPC = "Raids Npc", Location = CFrame.new(-5500, 314, -2855), Chip = "Special Microchip"},
}

local isRunning = false
local raidThread = nil

function Raid:Start()
    if isRunning then return end
    isRunning = true
    
    raidThread = task.spawn(function()
        while isRunning and self.Config.Enabled do
            task.wait(0.1)
            
            if not self.Core:IsAlive() then
                task.wait(2)
                continue
            end
            
            if self:IsInRaid() then
                self:DoRaid()
            else
                self:PrepareRaid()
            end
        end
    end)
end

function Raid:Stop()
    isRunning = false
    if raidThread then
        task.cancel(raidThread)
        raidThread = nil
    end
end

function Raid:IsInRaid()
    local mainGui = self.Core.PlayerGui:FindFirstChild("Main")
    if not mainGui then return false end
    
    local topHUD = mainGui:FindFirstChild("TopHUDList")
    if not topHUD then return false end
    
    local raidTimer = topHUD:FindFirstChild("RaidTimer")
    if not raidTimer then return false end
    
    return raidTimer.Visible
end

function Raid:HasChip()
    local backpack = self.Core.LocalPlayer.Backpack
    local character = self.Core.Character
    
    for _, item in pairs(backpack:GetChildren()) do
        if item.Name == self.RaidData[self.Config.RaidType].Chip then
            return true
        end
    end
    
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item.Name == self.RaidData[self.Config.RaidType].Chip then
                return true
            end
        end
    end
    
    return false
end

function Raid:PrepareRaid()
    local raidData = self.RaidData[self.Config.RaidType]
    if not raidData then return end
    
    local level = self.Core.LocalPlayer.Data.Level.Value
    if level < raidData.Level then return end
    
    if not self:HasChip() and self.Config.AutoBuyChip then
        self:BuyChip()
        return
    end
    
    if self:HasChip() then
        self:StartRaid()
    end
end

function Raid:BuyChip()
    local remote = self.Core:GetRemote("CommF_")
    if not remote then return end
    
    self.Movement:MoveToNpc("Raids Npc", 4, 300, function()
        remote:InvokeServer("RaidsNpc", "Check")
        remote:InvokeServer("RaidsNpc", "BuyChip")
        task.wait(0.5)
        remote:InvokeServer("RaidsNpc", "Select", self.Config.RaidType)
        task.wait(0.5)
        
        if self.Config.MultiRaid then
            remote:InvokeServer("RaidsNpc", "StartMulti")
        else
            remote:InvokeServer("RaidsNpc", "Start")
        end
    end)
end

function Raid:StartRaid()
    self.Movement:MoveTo(self.RaidData[self.Config.RaidType].Location, 300, function()
        local clickDetector = workspace:FindFirstChild("ClickDetector")
        if clickDetector then
            fireclickdetector(clickDetector)
        end
    end)
end

function Raid:DoRaid()
    local mob = self:FindRaidMob()
    
    if mob then
        self.Combat:AttackM1(mob)
        self.Combat:UseAutoSkill()
        self.Movement:MoveToMob(mob, 5, 300)
    else
        self.Movement:MoveToSpawnPoint(300)
    end
    
    if self:IsRaidComplete() then
        self:CompleteRaid()
    end
end

function Raid:FindRaidMob()
    local nearest = nil
    local nearestDist = math.huge
    local root = self.Core:GetRootPart()
    
    if not root then return nil end
    
    for _, enemy in pairs(self.Core.Services.Workspace.Enemies:GetChildren()) do
        if self.Combat:IsMobAlive(enemy) then
            local hrp = enemy:FindFirstChild("HumanoidRootPart")
            if hrp then
                local raidPos = self.RaidData[self.Config.RaidType].Location.Position
                local distToRaid = Utils:Distance(hrp.Position, raidPos)
                if distToRaid < 1000 then
                    local dist = Utils:Distance(hrp.Position, root.Position)
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = enemy
                    end
                end
            end
        end
    end
    
    return nearest
end

function Raid:IsRaidComplete()
    return not self:IsInRaid()
end

function Raid:CompleteRaid()
    if self.Config.AutoAwake then
        local remote = self.Core:GetRemote("CommF_")
        if remote then
            remote:InvokeServer("Awakener", "Check")
            remote:InvokeServer("Awakener", "Awaken")
        end
    end
    
    self.Movement:Teleport(CFrame.new(-5543, 313, -2964))
    task.wait(2)
end

return Raid
