-- ============================================
-- MODULE: Trial
-- ============================================
-- Mô tả: Hệ thống Auto Trial V4
-- ============================================

local Trial = {}
local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)
local Combat = require(script.Parent.Combat)
local Movement = require(script.Parent.Movement)

Trial.Core = Core
Trial.Utils = Utils
Trial.Combat = Combat
Trial.Movement = Movement

-- CONFIGURATION
Trial.Config = {
    Enabled = false,
    Race = "Human",
    AutoChooseGear = true,
    AutoBuyGear = true,
    AutoTurnOnV4 = true,
    HopServer = false,
}

-- TRIAL DATA
Trial.TrialData = {
    ["Human"] = {Name = "Trial of Strength", Location = CFrame.new(28282.57, 14896.85, 105.1), Door = "HumanCorridor"},
    ["Skypiea"] = {Name = "Trial of the King", Location = CFrame.new(28282.57, 14896.85, 105.1), Door = "SkypieaCorridor"},
    ["Fishman"] = {Name = "Trial of Water", Location = CFrame.new(28282.57, 14896.85, 105.1), Door = "FishmanCorridor"},
    ["Mink"] = {Name = "Trial of Speed", Location = CFrame.new(28282.57, 14896.85, 105.1), Door = "MinkCorridor"},
    ["Ghoul"] = {Name = "Trial of Carnage", Location = CFrame.new(28282.57, 14896.85, 105.1), Door = "GhoulCorridor"},
    ["Cyborg"] = {Name = "Trial of the Machine", Location = CFrame.new(28282.57, 14896.85, 105.1), Door = "CyborgCorridor"},
}

local isRunning = false
local trialThread = nil

function Trial:Start()
    if isRunning then return end
    isRunning = true
    
    trialThread = task.spawn(function()
        while isRunning and self.Config.Enabled do
            task.wait(0.1)
            
            if not self.Core:IsAlive() then
                task.wait(2)
                continue
            end
            
            local status = self:CheckV4Status()
            
            if status == "Done" then
                print("[Trial] V4 already unlocked!")
                self:Stop()
                break
            elseif status == "Can Buy Gear" then
                if self.Config.AutoBuyGear then
                    self:BuyGear()
                end
            elseif status == "Ready For Trial" then
                self:DoTrial()
            else
                self:PrepareTrial()
            end
        end
    end)
end

function Trial:Stop()
    isRunning = false
    if trialThread then
        task.cancel(trialThread)
        trialThread = nil
    end
end

function Trial:CheckV4Status()
    local remote = self.Core:GetRemote("CommF_")
    if not remote then return "Unknown" end
    
    local progress = remote:InvokeServer("RaceV4Progress", "Check")
    
    if progress == 0 then return "Not Started"
    elseif progress == 1 then return "Ready For Trial"
    elseif progress == 2 then return "Trial In Progress"
    elseif progress == 3 then return "Can Buy Gear"
    elseif progress == 4 then return "Done"
    end
    
    return "Unknown"
end

function Trial:PrepareTrial()
    local templeLocation = CFrame.new(28282.57, 14896.85, 105.1)
    self.Movement:MoveTo(templeLocation, 300, function()
        local door = self:FindRaceDoor()
        if door then
            self.Movement:MoveTo(door, 100)
        end
    end)
end

function Trial:FindRaceDoor()
    local temple = self.Core.Services.Workspace.Map:FindFirstChild("Temple of Time")
    if not temple then return nil end
    
    local corridorName = self.TrialData[self.Config.Race].Door
    local corridor = temple:FindFirstChild(corridorName)
    if not corridor then return nil end
    
    local door = corridor:FindFirstChild("Door")
    if not door then return nil end
    
    local doorPart = door:FindFirstChild("RightDoor")
    if not doorPart then return nil end
    
    return doorPart.CFrame
end

function Trial:DoTrial()
    local trialData = self.TrialData[self.Config.Race]
    if not trialData then return end
    
    self.Movement:MoveTo(trialData.Location, 300)
    
    local remote = self.Core:GetRemote("CommF_")
    if remote then
        remote:InvokeServer("RaceV4Progress", "Begin")
        task.wait(1)
    end
    
    while self:IsInTrial() do
        task.wait(0.1)
        
        local mob = self:FindTrialMob()
        
        if mob then
            self.Combat:AttackM1(mob)
            self.Combat:UseAutoSkill()
            self.Movement:MoveToMob(mob, 5, 300)
        else
            self.Movement:MoveToSpawnPoint(300)
        end
    end
    
    if remote then
        remote:InvokeServer("RaceV4Progress", "Continue")
        task.wait(1)
        remote:InvokeServer("RaceV4Progress", "Teleport")
        task.wait(1)
    end
end

function Trial:FindTrialMob()
    local nearest = nil
    local nearestDist = math.huge
    local root = self.Core:GetRootPart()
    
    if not root then return nil end
    
    for _, enemy in pairs(self.Core.Services.Workspace.Enemies:GetChildren()) do
        if self.Combat:IsMobAlive(enemy) then
            local hrp = enemy:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = Utils:Distance(hrp.Position, root.Position)
                if dist < nearestDist and dist < 1000 then
                    nearestDist = dist
                    nearest = enemy
                end
            end
        end
    end
    
    return nearest
end

function Trial:IsInTrial()
    local mainGui = self.Core.PlayerGui:FindFirstChild("Main")
    if not mainGui then return false end
    
    local topHUD = mainGui:FindFirstChild("TopHUDList")
    if not topHUD then return false end
    
    local raidTimer = topHUD:FindFirstChild("RaidTimer")
    if not raidTimer then return false end
    
    return raidTimer.Visible
end

function Trial:BuyGear()
    local remote = self.Core:GetRemote("CommF_")
    if not remote then return end
    
    self.Movement:MoveToNpc("Ancient One", 4, 300, function()
        remote:InvokeServer("UpgradeRace", "Buy")
        task.wait(0.5)
    end)
end

return Trial
