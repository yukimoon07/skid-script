-- ============================================
-- MODULE: Movement
-- ============================================
-- Mô tả: Quản lý di chuyển, tween, teleport
-- ============================================

local Movement = {}
local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)

Movement.Core = Core
Movement.Utils = Utils

-- CONFIGURATION
Movement.Config = {
    TweenSpeed = 300,
    UseTeleport = false,
    TeleportDistance = 1000,
    UsePortal = false,
}

local currentTween = nil
local currentTweenCallback = nil

-- TWEEN SYSTEM
function Movement:MoveTo(targetCFrame, speed, callback)
    speed = speed or self.Config.TweenSpeed
    
    local root = self.Core:GetRootPart()
    if not root then 
        if callback then callback() end
        return nil 
    end
    
    local distance = Utils:Distance(root.Position, targetCFrame.Position)
    
    if distance < 3 then
        if callback then callback() end
        return nil
    end
    
    self:CancelTween()
    
    local duration = distance / speed
    
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    local tween = self.Core.Services.TweenService:Create(
        root,
        tweenInfo,
        {CFrame = targetCFrame}
    )
    
    currentTween = tween
    currentTweenCallback = callback
    
    tween.Completed:Connect(function()
        currentTween = nil
        if currentTweenCallback then
            local cb = currentTweenCallback
            currentTweenCallback = nil
            cb()
        end
    end)
    
    tween:Play()
    
    return tween
end

function Movement:CancelTween()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
        currentTweenCallback = nil
    end
end

-- TELEPORT SYSTEM
function Movement:Teleport(targetCFrame)
    local root = self.Core:GetRootPart()
    if root then
        root.CFrame = targetCFrame
        self:CancelTween()
        return true
    end
    return false
end

function Movement:SmartTeleport(targetCFrame, speed, callback)
    speed = speed or self.Config.TweenSpeed
    
    local root = self.Core:GetRootPart()
    if not root then 
        if callback then callback() end
        return false
    end
    
    local distance = Utils:Distance(root.Position, targetCFrame.Position)
    
    if self.Config.UseTeleport and distance > self.Config.TeleportDistance then
        return self:Teleport(targetCFrame)
    end
    
    self:MoveTo(targetCFrame, speed, callback)
    return true
end

-- MOVEMENT TO SPECIFIC TARGETS
function Movement:MoveToMob(mob, offset, speed, callback)
    offset = offset or 5
    speed = speed or self.Config.TweenSpeed
    
    if not mob then 
        if callback then callback() end
        return nil 
    end
    
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        if callback then callback() end
        return nil 
    end
    
    local targetCFrame = hrp.CFrame * CFrame.new(0, 0, offset)
    return self:MoveTo(targetCFrame, speed, callback)
end

function Movement:MoveToNpc(npcName, offset, speed, callback)
    offset = offset or 4
    speed = speed or self.Config.TweenSpeed
    
    local npc = nil
    
    for _, child in pairs(self.Core.Services.Workspace:GetChildren()) do
        if child.Name == npcName and child:FindFirstChild("HumanoidRootPart") then
            npc = child
            break
        end
    end
    
    if not npc then
        for _, child in pairs(self.Core.Services.ReplicatedStorage:GetChildren()) do
            if child.Name == npcName and child:FindFirstChild("HumanoidRootPart") then
                npc = child
                break
            end
        end
    end
    
    if not npc then 
        if callback then callback() end
        return nil 
    end
    
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        if callback then callback() end
        return nil 
    end
    
    local targetCFrame = hrp.CFrame * CFrame.new(0, 0, offset)
    return self:MoveTo(targetCFrame, speed, callback)
end

function Movement:MoveToSpawnPoint(speed, callback)
    speed = speed or self.Config.TweenSpeed
    
    local spawns = self.Core.Services.Workspace:FindFirstChild("_WorldOrigin")
    if spawns then
        spawns = spawns:FindFirstChild("EnemySpawns")
    end
    
    if not spawns then
        if callback then callback() end
        return nil
    end
    
    local root = self.Core:GetRootPart()
    if not root then
        if callback then callback() end
        return nil
    end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, spawn in pairs(spawns:GetChildren()) do
        if spawn:IsA("BasePart") then
            local dist = Utils:Distance(spawn.Position, root.Position)
            if dist < nearestDist then
                nearestDist = dist
                nearest = spawn
            end
        end
    end
    
    if nearest then
        local targetCFrame = nearest.CFrame * CFrame.new(0, 0, -10)
        return self:MoveTo(targetCFrame, speed, callback)
    end
    
    if callback then callback() end
    return nil
end

function Movement:MoveToPosition(position, speed, callback)
    speed = speed or self.Config.TweenSpeed
    
    local targetCFrame = CFrame.new(position)
    return self:MoveTo(targetCFrame, speed, callback)
end

-- UTILITY MOVEMENT
function Movement:Jump()
    local humanoid = self.Core:GetHumanoid()
    if humanoid then
        humanoid.Jump = true
        return true
    end
    return false
end

function Movement:Stop()
    self:CancelTween()
    local root = self.Core:GetRootPart()
    if root then
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end

return Movement
