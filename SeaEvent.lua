-- ============================================
-- MODULE: SeaEvent
-- ============================================
-- Mô tả: Hệ thống Auto Sea Event
-- ============================================

local SeaEvent = {}
local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)
local Combat = require(script.Parent.Combat)
local Movement = require(script.Parent.Movement)

SeaEvent.Core = Core
SeaEvent.Utils = Utils
SeaEvent.Combat = Combat
SeaEvent.Movement = Movement

-- CONFIGURATION
SeaEvent.Config = {
    Enabled = false,
    Events = {SeaBeast = true, Terrorshark = true, Ship = true, Piranha = false},
    Boat = "PirateBrigade",
    AutoBuyBoat = true,
    UseDragonstorm = false,
    UseSkullGuitar = false,
    UseFruitM1 = false,
    DodgeSkill = true,
    TweenSpeed = 350,
}

SeaEvent.LocationData = {
    ["Tiki Outpost"] = CFrame.new(-16456.46, 530.25, 436.23),
    ["Hydra Island"] = CFrame.new(5020.95, 174.09, -2011.19),
    ["Sea Castle"] = CFrame.new(-5502.18, 323.67, -2863.46),
}

local isRunning = false
local seaThread = nil
local currentBoat = nil

function SeaEvent:Start()
    if isRunning then return end
    isRunning = true
    
    seaThread = task.spawn(function()
        while isRunning and self.Config.Enabled do
            task.wait(0.1)
            
            if not self.Core:IsAlive() then
                task.wait(2)
                continue
            end
            
            if not self:HasBoat() then
                if self.Config.AutoBuyBoat then
                    self:BuyBoat()
                end
                task.wait(2)
                continue
            end
            
            local event = self:FindSeaEvent()
            
            if event then
                self:FightSeaEvent(event)
            else
                self:Patrol()
            end
        end
    end)
end

function SeaEvent:Stop()
    isRunning = false
    if seaThread then
        task.cancel(seaThread)
        seaThread = nil
    end
end

function SeaEvent:HasBoat()
    for _, child in pairs(self.Core.Services.Workspace.Boats:GetChildren()) do
        if child:IsA("Model") then
            local owner = child:FindFirstChild("Owner")
            if owner and owner.Value == self.Core.LocalPlayer then
                currentBoat = child
                return true
            end
        end
    end
    return false
end

function SeaEvent:BuyBoat()
    local remote = self.Core:GetRemote("CommF_")
    if not remote then return end
    
    local buyPosition = CFrame.new(-13.49, 10.31, 2927.69)
    self.Movement:MoveTo(buyPosition, 300, function()
        remote:InvokeServer("BuyBoat", self.Config.Boat)
        task.wait(3)
    end)
end

function SeaEvent:DriveBoat(targetPosition, speed)
    speed = speed or self.Config.TweenSpeed
    
    if not currentBoat then return end
    
    local seat = currentBoat:FindFirstChild("VehicleSeat")
    if not seat then return end
    
    self.Movement:MoveTo(CFrame.new(targetPosition), speed)
end

function SeaEvent:FindSeaEvent()
    local events = {}
    local root = self.Core:GetRootPart()
    
    if not root then return nil end
    
    if self.Config.Events.SeaBeast then
        for _, child in pairs(self.Core.Services.Workspace.SeaBeasts:GetChildren()) do
            if self.Combat:IsMobAlive(child) and child.Name == "SeaBeast1" then
                local hrp = child:FindFirstChild("HumanoidRootPart")
                if hrp then
                    table.insert(events, {Type = "SeaBeast", Object = child, Position = hrp.Position})
                end
            end
        end
    end
    
    if self.Config.Events.Terrorshark then
        for _, child in pairs(self.Core.Services.Workspace.Enemies:GetChildren()) do
            if self.Combat:IsMobAlive(child) and child.Name == "Terrorshark" then
                local hrp = child:FindFirstChild("HumanoidRootPart")
                if hrp then
                    table.insert(events, {Type = "Terrorshark", Object = child, Position = hrp.Position})
                end
            end
        end
    end
    
    if self.Config.Events.Ship then
        for _, child in pairs(self.Core.Services.Workspace.Enemies:GetChildren()) do
            if child:FindFirstChild("Engine") and child:FindFirstChild("Health") then
                local health = child:FindFirstChild("Health")
                if health and health.Value > 0 then
                    local engine = child:FindFirstChild("Engine")
                    if engine then
                        table.insert(events, {Type = "Ship", Object = child, Position = engine.Position})
                    end
                end
            end
        end
    end
    
    if self.Config.Events.Piranha then
        for _, child in pairs(self.Core.Services.Workspace.Enemies:GetChildren()) do
            if self.Combat:IsMobAlive(child) and child.Name == "Piranha" then
                local hrp = child:FindFirstChild("HumanoidRootPart")
                if hrp then
                    table.insert(events, {Type = "Piranha", Object = child, Position = hrp.Position})
                end
            end
        end
    end
    
    table.sort(events, function(a, b)
        local distA = Utils:Distance(a.Position, root.Position)
        local distB = Utils:Distance(b.Position, root.Position)
        return distA < distB
    end)
    
    return events[1]
end

function SeaEvent:FightSeaEvent(event)
    if not event then return end
    
    self:DriveBoat(event.Position, self.Config.TweenSpeed)
    
    local target = event.Object
    
    if self.Combat:IsMobAlive(target) then
        self.Combat:AttackM1(target)
        self.Combat:UseAutoSkill()
        
        if self.Config.DodgeSkill then
            for _, child in pairs(target:GetDescendants()) do
                if child:IsA("Part") and Utils:StringContains(child.Name, "Skill") then
                    local root = self.Core:GetRootPart()
                    if root then
                        self.Movement:Teleport(CFrame.new(root.Position + Vector3.new(0, 50, 0)))
                        task.wait(0.5)
                    end
                    break
                end
            end
        end
    end
end

function SeaEvent:Patrol()
    local locations = {}
    for _, pos in pairs(self.LocationData) do
        table.insert(locations, pos)
    end
    
    for _, pos in pairs(locations) do
        if not self.Config.Enabled then break end
        self:DriveBoat(pos.Position, self.Config.TweenSpeed)
        task.wait(5)
    end
end

return SeaEvent
