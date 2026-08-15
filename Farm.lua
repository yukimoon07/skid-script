-- ============================================
-- MODULE: Farm
-- ============================================
-- Mô tả: Hệ thống Auto Farm
-- ============================================

local Farm = {}
local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)
local Combat = require(script.Parent.Combat)
local Movement = require(script.Parent.Movement)

Farm.Core = Core
Farm.Utils = Utils
Farm.Combat = Combat
Farm.Movement = Movement

-- CONFIGURATION
Farm.Config = {
    Enabled = false,
    Method = "Level Farm",
    Distance = 300,
    AutoQuest = true,
    BringMob = true,
    BringMobCount = 3,
    UseSkill = true,
    UseFruitM1 = false,
    FarmMastery = false,
    MasteryWeapon = "Melee",
}

-- QUEST DATA
Farm.QuestData = {
    ["HauntedQuest2"] = {
        Name = "Haunted Quest 2",
        Level = 2050,
        Mobs = {"Reborn Skeleton", "Living Zombie"},
        NPC = "Alchemist",
        Location = CFrame.new(-9513.47, 142.1, 5528.84),
    },
    ["CakeQuest2"] = {
        Name = "Cake Quest 2",
        Level = 2275,
        Mobs = {"Cake Prince", "Cake Queen"},
        NPC = "Cake Queen",
        Location = CFrame.new(-2100.75, 69.98, -12128.27),
    },
    ["TikiQuest3"] = {
        Name = "Tiki Quest 3",
        Level = 2575,
        Mobs = {"Tyrant of the Skies"},
        NPC = "Tyrant",
        Location = CFrame.new(-16456.46, 530.25, 436.23),
    },
}

local isRunning = false
local farmThread = nil

-- MAIN FARM LOOP
function Farm:Start()
    if isRunning then return end
    isRunning = true
    
    farmThread = task.spawn(function()
        while isRunning and self.Config.Enabled do
            task.wait(0.1)
            
            if not self.Core:IsAlive() then
                task.wait(1)
                continue
            end
            
            local target = self:GetFarmTarget()
            
            if target then
                if self.Config.BringMob then
                    self.Combat:BringMob(target, self.Config.BringMobCount)
                end
                
                self.Movement:MoveToMob(target, 5, self.Config.TweenSpeed)
                self:AttackTarget(target)
            else
                self.Movement:MoveToSpawnPoint(self.Config.TweenSpeed)
            end
        end
    end)
end

function Farm:Stop()
    isRunning = false
    if farmThread then
        task.cancel(farmThread)
        farmThread = nil
    end
end

-- FARM TARGET MANAGEMENT
function Farm:GetFarmTarget()
    local method = self.Config.Method
    
    if method == "Aura Farm" then
        return self.Combat:FindNearestMob(self.Config.Distance)
    elseif method == "Level Farm" then
        local questName = self:GetCurrentQuest()
        if questName then
            local questData = self.QuestData[questName]
            if questData then
                local target = self.Combat:FindMobByNames(questData.Mobs)
                if target then return target end
            end
        end
        return self.Combat:FindNearestMob(self.Config.Distance)
    elseif method == "Katakuri" then
        return self.Combat:FindMobByName("Cake Prince") or self.Combat:FindMobByName("Cake Queen")
    elseif method == "Bones" then
        return self.Combat:FindMobByNames({"Reborn Skeleton", "Living Zombie"})
    elseif method == "Tyrant" then
        return self.Combat:FindMobByName("Tyrant of the Skies")
    end
    
    return nil
end

function Farm:GetCurrentQuest()
    local mainGui = self.Core.PlayerGui:FindFirstChild("Main")
    if not mainGui then return nil end
    
    local quest = mainGui:FindFirstChild("Quest")
    if not quest or not quest.Visible then return nil end
    
    local container = quest:FindFirstChild("Container")
    if not container then return nil end
    
    local questTitle = container:FindFirstChild("QuestTitle")
    if not questTitle then return nil end
    
    local title = questTitle:FindFirstChild("Title")
    if not title or not title:IsA("TextLabel") then return nil end
    
    local text = title.Text
    if text then
        for questName, _ in pairs(self.QuestData) do
            if Utils:StringContains(text, questName) then
                return questName
            end
        end
    end
    
    return nil
end

-- ATTACK TARGET
function Farm:AttackTarget(target)
    if not target or not self.Combat:IsMobAlive(target) then return end
    
    if self.Config.FarmMastery then
        self.Combat:EquipWeapon(self.Config.MasteryWeapon)
    end
    
    if self.Config.UseFruitM1 then
        self.Combat:AttackFruitM1(target)
    else
        self.Combat:AttackM1(target)
    end
    
    if self.Config.UseSkill then
        self.Combat:UseAutoSkill()
    end
end

-- AUTO QUEST
function Farm:AutoAcceptQuest()
    if not self.Config.AutoQuest then return end
    
    local level = self.Core.LocalPlayer.Data.Level.Value
    local selectedQuest = nil
    
    for questName, questData in pairs(self.QuestData) do
        if level >= questData.Level then
            if not selectedQuest or questData.Level > selectedQuest.Level then
                selectedQuest = questData
                selectedQuest.Name = questName
            end
        end
    end
    
    if not selectedQuest then return end
    
    local currentQuest = self:GetCurrentQuest()
    if currentQuest == selectedQuest.Name then return end
    
    self.Movement:MoveToNpc(selectedQuest.NPC, 4, self.Config.TweenSpeed, function()
        local remote = self.Core:GetRemote("CommF_")
        if remote then
            remote:InvokeServer("StartQuest", selectedQuest.Name, 1)
        end
    end)
end

return Farm
