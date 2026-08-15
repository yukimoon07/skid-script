-- ============================================
-- MODULE: GUI
-- ============================================
-- Mô tả: Hệ thống giao diện người dùng
-- ============================================

local GUI = {}
local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)

GUI.Core = Core
GUI.Utils = Utils

-- GUI hiện tại
local guiInstance = nil
local mainFrame = nil

-- Màu sắc
local Colors = {
    Background = Color3.fromRGB(25, 25, 35),
    BackgroundDark = Color3.fromRGB(20, 20, 28),
    BackgroundLight = Color3.fromRGB(40, 40, 60),
    Primary = Color3.fromRGB(255, 200, 50),
    Secondary = Color3.fromRGB(50, 200, 50),
    Danger = Color3.fromRGB(255, 80, 80),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 150),
    Border = Color3.fromRGB(60, 60, 80),
}

function GUI:Create()
    self:Destroy()
    
    guiInstance = Instance.new("ScreenGui")
    guiInstance.Name = "BananaHub"
    guiInstance.ResetOnSpawn = false
    guiInstance.Parent = self.Core.CoreGui
    
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 380, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -260)
    mainFrame.BackgroundColor3 = Colors.Background
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = guiInstance
    
    self:CreateTitleBar(mainFrame)
    self:CreateTabs(mainFrame)
    
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, -70)
    contentContainer.Position = UDim2.new(0, 0, 0, 70)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    
    self:CreateFarmTab(contentContainer)
    self:CreateCombatTab(contentContainer)
    self:CreateMovementTab(contentContainer)
    self:CreateSettingsTab(contentContainer)
    
    self:SwitchTab("Farm")
    self:MakeDraggable(mainFrame)
    
    return guiInstance
end

function GUI:Destroy()
    if guiInstance then
        guiInstance:Destroy()
        guiInstance = nil
        mainFrame = nil
    end
end

function GUI:CreateTitleBar(parent)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Colors.BackgroundDark
    titleBar.BackgroundTransparency = 0.1
    titleBar.BorderSizePixel = 0
    titleBar.Parent = parent
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 40, 1, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "🍌"
    logo.TextSize = 24
    logo.Font = Enum.Font.GothamBold
    logo.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 200, 1, 0)
    title.Position = UDim2.new(0, 40, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Banana Hub v2.0"
    title.TextColor3 = Colors.Primary
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 1, 0)
    closeBtn.Position = UDim2.new(1, -30, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Colors.Text
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
end

function GUI:CreateTabs(parent)
    local tabs = {"Farm", "Combat", "Movement", "Settings"}
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 30)
    tabBar.Position = UDim2.new(0, 0, 0, 40)
    tabBar.BackgroundColor3 = Colors.BackgroundDark
    tabBar.BackgroundTransparency = 0.1
    tabBar.BorderSizePixel = 0
    tabBar.Parent = parent
    
    local tabButtons = {}
    
    for i, tabName in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = tabName
        btn.Size = UDim2.new(1/#tabs, 0, 1, 0)
        btn.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = tabName
        btn.TextColor3 = Colors.TextDim
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamMedium
        btn.Parent = tabBar
        
        tabButtons[tabName] = btn
        
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(tabName)
        end)
    end
    
    GUI.TabButtons = tabButtons
end

function GUI:SwitchTab(tabName)
    local container = mainFrame:FindFirstChild("ContentContainer")
    if not container then return end
    
    for _, child in pairs(container:GetChildren()) do
        child.Visible = false
    end
    
    local tab = container:FindFirstChild(tabName)
    if tab then
        tab.Visible = true
    end
    
    if GUI.TabButtons then
        for name, btn in pairs(GUI.TabButtons) do
            if name == tabName then
                btn.TextColor3 = Colors.Primary
                btn.BackgroundColor3 = Colors.BackgroundLight
            else
                btn.TextColor3 = Colors.TextDim
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                btn.BackgroundTransparency = 1
            end
        end
    end
end

function GUI:CreateFarmTab(container)
    local tab = Instance.new("ScrollingFrame")
    tab.Name = "Farm"
    tab.Size = UDim2.new(1, 0, 1, 0)
    tab.BackgroundTransparency = 1
    tab.ScrollBarThickness = 6
    tab.Parent = container
    
    local y = 10
    
    y = self:CreateToggle(tab, "Start Farm", "Bật/tắt auto farm", y, function(value)
        local farm = require(script.Parent.Farm)
        farm.Config.Enabled = value
        if value then farm:Start() else farm:Stop() end
    end)
    
    y = self:CreateDropdown(tab, "Farm Method", {"Level Farm", "Katakuri", "Bones", "Tyrant", "Aura"}, y, function(value)
        local farm = require(script.Parent.Farm)
        farm.Config.Method = value
    end)
    
    y = self:CreateSlider(tab, "Farm Distance", 100, 500, 300, y, function(value)
        local farm = require(script.Parent.Farm)
        farm.Config.Distance = value
    end)
    
    y = self:CreateToggle(tab, "Bring Mob", "Kéo quái lại gần", y, function(value)
        local farm = require(script.Parent.Farm)
        farm.Config.BringMob = value
    end)
    
    y = self:CreateSlider(tab, "Bring Mob Count", 1, 6, 3, y, function(value)
        local farm = require(script.Parent.Farm)
        farm.Config.BringMobCount = value
    end)
    
    y = self:CreateToggle(tab, "Use Skill", "Tự động sử dụng skill", y, function(value)
        local farm = require(script.Parent.Farm)
        farm.Config.UseSkill = value
    end)
    
    y = self:CreateToggle(tab, "Auto Quest", "Tự động nhận quest", y, function(value)
        local farm = require(script.Parent.Farm)
        farm.Config.AutoQuest = value
    end)
end

function GUI:CreateCombatTab(container)
    local tab = Instance.new("ScrollingFrame")
    tab.Name = "Combat"
    tab.Size = UDim2.new(1, 0, 1, 0)
    tab.BackgroundTransparency = 1
    tab.ScrollBarThickness = 6
    tab.Parent = container
    
    local y = 10
    
    y = self:CreateSlider(tab, "Attack Radius", 30, 150, 80, y, function(value)
        local combat = require(script.Parent.Combat)
        combat.Config.AttackRadius = value
    end)
    
    y = self:CreateToggle(tab, "Auto Skill", "Tự động sử dụng skill", y, function(value)
        local combat = require(script.Parent.Combat)
        combat.Config.AutoSkill = value
    end)
    
    y = self:CreateSlider(tab, "Skill Hold Time", 0, 1, 0.5, y, function(value)
        local combat = require(script.Parent.Combat)
        combat.Config.SkillHoldTime = value
    end)
    
    y = self:CreateToggle(tab, "Use Fruit M1", "Sử dụng M1 của trái ác quỷ", y, function(value)
        local combat = require(script.Parent.Combat)
        combat.Config.UseFruitM1 = value
    end)
end

function GUI:CreateMovementTab(container)
    local tab = Instance.new("ScrollingFrame")
    tab.Name = "Movement"
    tab.Size = UDim2.new(1, 0, 1, 0)
    tab.BackgroundTransparency = 1
    tab.ScrollBarThickness = 6
    tab.Parent = container
    
    local y = 10
    
    y = self:CreateSlider(tab, "Tween Speed", 50, 500, 300, y, function(value)
        local movement = require(script.Parent.Movement)
        movement.Config.TweenSpeed = value
    end)
    
    y = self:CreateToggle(tab, "Use Teleport", "Teleport khi khoảng cách xa (risk)", y, function(value)
        local movement = require(script.Parent.Movement)
        movement.Config.UseTeleport = value
    end)
    
    y = self:CreateSlider(tab, "Teleport Distance", 500, 5000, 1000, y, function(value)
        local movement = require(script.Parent.Movement)
        movement.Config.TeleportDistance = value
    end)
end

function GUI:CreateSettingsTab(container)
    local tab = Instance.new("ScrollingFrame")
    tab.Name = "Settings"
    tab.Size = UDim2.new(1, 0, 1, 0)
    tab.BackgroundTransparency = 1
    tab.ScrollBarThickness = 6
    tab.Parent = container
    
    local y = 10
    
    y = self:CreateToggle(tab, "White Screen", "Bật/tắt màn hình trắng (tăng FPS)", y, function(value)
        local rs = game:GetService("RunService")
        rs:Set3dRenderingEnabled(not value)
    end)
    
    y = self:CreateToggle(tab, "FPS Boost", "Tối ưu hóa FPS", y, function(value)
        if value then
            local lighting = game:GetService("Lighting")
            lighting.GlobalShadows = false
            lighting.Brightness = 0
            lighting.FogEnd = 9e9
            
            local terrain = workspace.Terrain
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
        end
    end)
    
    y = self:CreateToggle(tab, "Remove Notification", "Xóa thông báo trên màn hình", y, function(value)
        -- Sẽ implement sau
    end)
end

-- GUI HELPERS
function GUI:CreateToggle(parent, title, desc, y, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Colors.Text
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.Parent = frame
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0, 200, 0, 16)
    descLabel.Position = UDim2.new(0, 0, 0, 20)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = desc
    descLabel.TextColor3 = Colors.TextDim
    descLabel.TextSize = 11
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Font = Enum.Font.GothamMedium
    descLabel.Parent = frame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 50, 0, 28)
    toggle.Position = UDim2.new(1, -55, 0.5, -14)
    toggle.BackgroundColor3 = Colors.BackgroundLight
    toggle.BorderSizePixel = 0
    toggle.Text = "OFF"
    toggle.TextColor3 = Colors.TextDim
    toggle.TextSize = 12
    toggle.Font = Enum.Font.GothamBold
    toggle.Parent = frame
    
    local isOn = false
    
    toggle.MouseButton1Click:Connect(function()
        isOn = not isOn
        toggle.Text = isOn and "ON" or "OFF"
        toggle.BackgroundColor3 = isOn and Colors.Secondary or Colors.BackgroundLight
        toggle.TextColor3 = isOn and Colors.Text or Colors.TextDim
        if callback then callback(isOn) end
    end)
    
    return y + 45
end

function GUI:CreateDropdown(parent, title, options, y, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 50)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Colors.Text
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.Parent = frame
    
    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(1, 0, 0, 25)
    dropdown.Position = UDim2.new(0, 0, 0, 22)
    dropdown.BackgroundColor3 = Colors.BackgroundLight
    dropdown.BorderSizePixel = 0
    dropdown.Text = options[1]
    dropdown.TextColor3 = Colors.Text
    dropdown.TextSize = 13
    dropdown.Font = Enum.Font.GothamMedium
    dropdown.Parent = frame
    
    local currentIndex = 1
    
    dropdown.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #options + 1
        dropdown.Text = options[currentIndex]
        if callback then callback(options[currentIndex]) end
    end)
    
    return y + 55
end

function GUI:CreateSlider(parent, title, min, max, default, y, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 50)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title .. ": " .. tostring(default)
    label.TextColor3 = Colors.Text
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.Parent = frame
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, 0, 0, 6)
    slider.Position = UDim2.new(0, 0, 0, 35)
    slider.BackgroundColor3 = Colors.BackgroundLight
    slider.BorderSizePixel = 0
    slider.Parent = frame
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(default / max, 0, 1, 0)
    fill.BackgroundColor3 = Colors.Primary
    fill.BorderSizePixel = 0
    fill.Parent = slider
    
    local value = default
    local isDragging = false
    
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            local mouse = game:GetService("UserInputService"):GetMouseLocation()
            local relX = (mouse.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X
            value = Utils:Clamp(math.round(relX * max), min, max)
            fill.Size = UDim2.new(value / max, 0, 1, 0)
            label.Text = title .. ": " .. tostring(value)
            if callback then callback(value) end
        end
    end)
    
    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = game:GetService("UserInputService"):GetMouseLocation()
            local relX = (mouse.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X
            value = Utils:Clamp(math.round(relX * max), min, max)
            fill.Size = UDim2.new(value / max, 0, 1, 0)
            label.Text = title .. ": " .. tostring(value)
            if callback then callback(value) end
        end
    end)
    
    return y + 55
end

function GUI:MakeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

return GUI
