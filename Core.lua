-- ============================================
-- MODULE: Core
-- ============================================
-- Mô tả: Core engine - services, events, utils
-- ============================================

local Core = {}
local Utils = require(script.Parent.Utils)

-- SERVICES
Core.Services = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    UserInputService = game:GetService("UserInputService"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    CollectionService = game:GetService("CollectionService"),
    TeleportService = game:GetService("TeleportService"),
    CoreGui = game:GetService("CoreGui"),
}

-- LOCAL PLAYER
Core.LocalPlayer = Core.Services.Players.LocalPlayer
Core.Character = Core.LocalPlayer.Character or Core.LocalPlayer.CharacterAdded:Wait()
Core.PlayerGui = Core.LocalPlayer.PlayerGui

-- EVENTS
Core.LocalPlayer.CharacterAdded:Connect(function(char)
    Core.Character = char
    Core:OnCharacterAdded(char)
end)

Core.LocalPlayer.CharacterRemoving:Connect(function()
    Core:OnCharacterRemoved()
end)

-- CORE FUNCTIONS
function Core:GetRootPart()
    local char = self.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") 
        or char:FindFirstChild("Torso") 
        or char:FindFirstChild("UpperTorso")
end

function Core:GetHumanoid()
    local char = self.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

function Core:IsAlive()
    local humanoid = self:GetHumanoid()
    return humanoid and humanoid.Health > 0
end

function Core:DistanceFromCharacter(position)
    local root = self:GetRootPart()
    if not root then return math.huge end
    return Utils:Distance(root.Position, position)
end

function Core:GetCharacterCFrame()
    local root = self:GetRootPart()
    if not root then return CFrame.new() end
    return root.CFrame
end

function Core:GetCharacterPosition()
    local root = self:GetRootPart()
    if not root then return Vector3.new() end
    return root.Position
end

-- EVENTS HANDLERS
function Core:OnCharacterAdded(char)
    print("[Core] Character added:", char.Name)
end

function Core:OnCharacterRemoved()
    print("[Core] Character removed")
end

-- UTILITY FUNCTIONS
function Core:GetRemote(remoteName)
    local remotes = self.Services.ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end
    return remotes:FindFirstChild(remoteName)
end

function Core:FireRemote(remoteName, ...)
    local remote = self:GetRemote(remoteName)
    if remote then
        if remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        end
    end
    return nil
end

return Core
