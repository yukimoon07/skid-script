-- ============================================
-- MODULE: Combat
-- ============================================
-- Mô tả: Quản lý tấn công, skill, vũ khí
-- ============================================

local Combat = {}
local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)

Combat.Core = Core
Combat.Utils = Utils

-- CONFIGURATION
Combat.Config = {
    AttackRadius = 80,
    UseSkill = true,
    UseFruitM1 = false,
    SkillHoldTime = 0.5,
    AutoSkill = true,
}

-- WEAPON MANAGEMENT
function Combat:GetCurrentWeapon()
    local char = self.Core.Character
    if not char then return nil end
    
    for _, child in pairs(char:GetChildren()) do
        if child:IsA("Tool") then
            return child
        end
    end
    
    local backpack = self.Core.LocalPlayer.Backpack
    for _, child in pairs(backpack:GetChildren()) do
        if child:IsA("Tool") then
            return child
        end
    end
    
    return nil
end

function Combat:GetWeaponName(tool)
    if not tool then return nil end
    return tool.Name
end

function Combat:GetWeaponType(tool)
    if not tool then return nil end
    return tool.ToolTip
end

function Combat:EquipWeapon(weaponType)
    local char = self.Core.Character
    if not char then return false end
    
    local backpack = self.Core.LocalPlayer.Backpack
    local humanoid = self.Core:GetHumanoid()
    if not humanoid then return false end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == weaponType then
            humanoid:EquipTool(tool)
            task.wait(0.2)
            return true
        end
    end
    
    return false
end

function Combat:EquipToolByName(toolName)
    local char = self.Core.Character
    if not char then return false end
    
    local backpack = self.Core.LocalPlayer.Backpack
    local humanoid = self.Core:GetHumanoid()
    if not humanoid then return false end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name == toolName then
            humanoid:EquipTool(tool)
            task.wait(0.2)
            return true
        end
    end
    
    return false
end

-- SKILL MANAGEMENT
function Combat:GetSkillGUI()
    local mainGui = self.Core.PlayerGui:FindFirstChild("Main")
    if not mainGui then return nil end
    return mainGui:FindFirstChild("Skills")
end

function Combat:IsSkillReady(skillKey)
    local skills = self:GetSkillGUI()
    if not skills then return false end
    
    local skillFrame = skills:FindFirstChild(skillKey)
    if not skillFrame then return false end
    
    for _, child in pairs(skillFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "Template" then
            local title = child:FindFirstChild("Title")
            if title and title:IsA("TextLabel") then
                return title.TextColor3 == Color3.new(1, 1, 1)
            end
        end
    end
    
    return false
end

function Combat:UseSkill(skillKey)
    local vim = self.Core.Services.VirtualInputManager
    
    vim:SendKeyEvent(true, skillKey, false, game)
    task.wait(self.Config.SkillHoldTime)
    vim:SendKeyEvent(false, skillKey, false, game)
end

function Combat:UseAutoSkill()
    if not self.Config.AutoSkill then return end
    
    local skills = {"Z", "X", "C", "V"}
    for _, key in pairs(skills) do
        if self:IsSkillReady(key) then
            self:UseSkill(key)
            return true
        end
    end
    
    return false
end

-- ATTACK FUNCTIONS
function Combat:AttackM1(target, useFruit)
    if not target then return false end
    
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    if useFruit or self.Config.UseFruitM1 then
        return self:AttackFruitM1(target)
    end
    
    local remote = self.Core:GetRemote("CommF_")
    if remote then
        remote:InvokeServer("Attack", hrp.Position)
        return true
    end
    
    return false
end

function Combat:AttackFruitM1(target)
    if not target then return false end
    
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local fruit = self:GetCurrentWeapon()
    if not fruit or fruit.ToolTip ~= "Blox Fruit" then
        self:EquipWeapon("Blox Fruit")
        task.wait(0.2)
        fruit = self:GetCurrentWeapon()
    end
    
    if fruit then
        local leftClick = fruit:FindFirstChild("LeftClickRemote")
        if leftClick then
            leftClick:FireServer(hrp.Position)
            return true
        end
    end
    
    return false
end

-- MOB UTILITIES
function Combat:IsMobAlive(mob)
    if not mob or not mob.Parent then return false end
    
    local humanoid = mob:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    return humanoid.Health > 0
end

function Combat:FindNearestMob(radius)
    radius = radius or self.Config.AttackRadius
    local root = self.Core:GetRootPart()
    if not root then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, enemy in pairs(self.Core.Services.Workspace.Enemies:GetChildren()) do
        if self:IsMobAlive(enemy) then
            local hrp = enemy:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = Utils:Distance(hrp.Position, root.Position)
                if dist < nearestDist and dist <= radius then
                    nearestDist = dist
                    nearest = enemy
                end
            end
        end
    end
    
    return nearest
end

function Combat:FindMobByName(name)
    for _, enemy in pairs(self.Core.Services.Workspace.Enemies:GetChildren()) do
        if self:IsMobAlive(enemy) and enemy.Name == name then
            return enemy
        end
    end
    return nil
end

function Combat:FindMobByNames(names)
    local nearest = nil
    local nearestDist = math.huge
    local root = self.Core:GetRootPart()
    
    if not root then return nil end
    
    for _, enemy in pairs(self.Core.Services.Workspace.Enemies:GetChildren()) do
        if self:IsMobAlive(enemy) then
            for _, name in pairs(names) do
                if enemy.Name == name then
                    local hrp = enemy:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = Utils:Distance(hrp.Position, root.Position)
                        if dist < nearestDist then
                            nearestDist = dist
                            nearest = enemy
                        end
                    end
                    break
                end
            end
        end
    end
    
    return nearest
end

function Combat:BringMob(target, count, radius)
    count = count or 3
    radius = radius or 350
    
    if not target then return end
    
    local targetHrp = target:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return end
    
    local root = self.Core:GetRootPart()
    if not root then return end
    
    local distance = Utils:Distance(targetHrp.Position, root.Position)
    if distance > 80 then return end
    
    local nearbyMobs = {}
    for _, mob in pairs(self.Core.Services.Workspace.Enemies:GetChildren()) do
        if self:IsMobAlive(mob) and mob ~= target then
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = Utils:Distance(hrp.Position, targetHrp.Position)
                if dist < radius then
                    table.insert(nearbyMobs, mob)
                end
            end
        end
    end
    
    local maxCount = math.min(#nearbyMobs, count)
    for i = 1, maxCount do
        local mob = nearbyMobs[i]
        local hrp = mob:FindFirstChild("HumanoidRootPart")
        if hrp then
            local offset = CFrame.new(
                math.random(-3, 3),
                0,
                math.random(-3, 3)
            )
            hrp.CFrame = targetHrp.CFrame * offset
        end
    end
end

return Combat
