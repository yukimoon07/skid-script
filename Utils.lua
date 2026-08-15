-- ============================================
-- MODULE: Utils
-- ============================================
-- Mô tả: Hàm hỗ trợ dùng chung
-- ============================================

local Utils = {}

-- STRING UTILITIES
function Utils:SplitString(str, delimiter)
    local result = {}
    for match in string.gmatch(str, "([^" .. delimiter .. "]+)") do
        table.insert(result, match)
    end
    return result
end

function Utils:GetMobName(str)
    if not str then return "" end
    return str:gsub(" %pLv%. %d+%p", ""):gsub("%s+$", "")
end

function Utils:StringContains(str, pattern)
    if not str or not pattern then return false end
    return string.find(str, pattern) ~= nil
end

-- TABLE UTILITIES
function Utils:TableFind(tbl, value)
    for i, v in pairs(tbl) do
        if v == value then return i end
    end
    return nil
end

function Utils:TableClone(tbl)
    local clone = {}
    for k, v in pairs(tbl) do
        clone[k] = v
    end
    return clone
end

function Utils:TableMerge(tbl1, tbl2)
    local result = self:TableClone(tbl1)
    for k, v in pairs(tbl2) do
        result[k] = v
    end
    return result
end

-- MATH UTILITIES
function Utils:Round(num)
    return math.floor(num + 0.5)
end

function Utils:Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function Utils:Distance(v1, v2)
    return (v1 - v2).Magnitude
end

-- TIME UTILITIES
function Utils:GetTime()
    return tick()
end

function Utils:IsOnCooldown(lastTime, cooldown)
    return (self:GetTime() - lastTime) < cooldown
end

-- ROBLOX UTILITIES
function Utils:FindInWorkspace(name)
    return game:GetService("Workspace"):FindFirstChild(name)
end

function Utils:FindInReplicatedStorage(name)
    return game:GetService("ReplicatedStorage"):FindFirstChild(name)
end

function Utils:FindInPlayers(name)
    return game:GetService("Players"):FindFirstChild(name)
end

-- WAIT UTILITIES
function Utils:WaitForCondition(condition, timeout)
    timeout = timeout or 10
    local startTime = self:GetTime()
    while not condition() and (self:GetTime() - startTime) < timeout do
        task.wait(0.1)
    end
    return condition()
end

function Utils:WaitForChild(parent, name, timeout)
    timeout = timeout or 10
    local startTime = self:GetTime()
    while not parent:FindFirstChild(name) and (self:GetTime() - startTime) < timeout do
        task.wait(0.1)
    end
    return parent:FindFirstChild(name)
end

return Utils
