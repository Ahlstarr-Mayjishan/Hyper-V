--[[
    AdaptiveStrategy - Tự động điều chỉnh cleanup dựa trên memory pressure
    Single Responsibility: Quyết định khi nào cần cleanup mạnh hơn
]]

local AdaptiveStrategy = {}
AdaptiveStrategy.__index = AdaptiveStrategy

export type PressureLevel = "low" | "normal" | "high" | "critical"

export type AdaptiveConfig = {
    LowThreshold: number?,     -- Memory % bắt đầu cleanup
    HighThreshold: number?,   -- Memory % tăng cường cleanup
    CriticalThreshold: number?,
    LowInterval: number?,     -- Interval (giây) khi bình thường
    HighInterval: number?,    -- Interval khi cao
    CriticalInterval: number?,
}

local DEFAULT_CONFIG = {
    LowThreshold = 30,        -- 30% memory
    HighThreshold = 60,       -- 60% memory  
    CriticalThreshold = 80,   -- 80% memory
    LowInterval = 30,         -- 30s
    HighInterval = 10,        -- 10s
    CriticalInterval = 3,     -- 3s
}

function AdaptiveStrategy.new(config: AdaptiveConfig?)
    local self = setmetatable({}, AdaptiveStrategy)
    
    self.Config = config or DEFAULT_CONFIG
    
    -- State
    self.CurrentLevel: PressureLevel = "normal"
    self.MemoryPercent = 0
    self.LastCleanupTime = os.time()
    self.CleanupCount = 0
    
    -- Tracking
    self.History = {}
    self.HistoryMaxSize = 20
    
    return self
end

function AdaptiveStrategy:GetMemoryUsage(): number
    -- Prefer Stats service memory APIs when available.
    local success, result = pcall(function()
        local stats = game:GetService("Stats")

        if stats.GetTotalMemoryUsageMb then
            return stats:GetTotalMemoryUsageMb()
        end

        if stats.GetMemoryUsageForTag then
            local memory = stats:GetMemoryUsageForTag(Enum.DeveloperMemoryTag.Internal)
            return memory / 1024 / 1024
        end

        error("No supported memory API")
    end)
    
    if success and type(result) == "number" then
        return result
    end
    
    -- Fallback: use garbage collection count as proxy
    return collectgarbage("count") / 1024
end

function AdaptiveStrategy:CalculateMemoryPercent(): number
    -- Estimate based on typical Roblox memory limit (~2GB for game)
    local currentMem = self:GetMemoryUsage()
    local maxMem = 2048  -- 2GB in MB
    
    self.MemoryPercent = (currentMem / maxMem) * 100
    return self.MemoryPercent
end

function AdaptiveStrategy:GetPressureLevel(): PressureLevel
    local percent = self:CalculateMemoryPercent()
    
    if percent >= self.Config.CriticalThreshold then
        return "critical"
    elseif percent >= self.Config.HighThreshold then
        return "high"
    elseif percent >= self.Config.LowThreshold then
        return "normal"
    else
        return "low"
    end
end

function AdaptiveStrategy:ShouldCleanup(): boolean
    local level = self:GetPressureLevel()
    local now = os.time()
    local timeSinceLastCleanup = now - self.LastCleanupTime
    
    local requiredInterval: number
    
    if level == "critical" then
        requiredInterval = self.Config.CriticalInterval
    elseif level == "high" then
        requiredInterval = self.Config.HighInterval
    else
        requiredInterval = self.Config.LowInterval
    end
    
    return timeSinceLastCleanup >= requiredInterval
end

function AdaptiveStrategy:RecordCleanup()
    self.LastCleanupTime = os.time()
    self.CleanupCount = self.CleanupCount + 1
    
    -- Record to history
    table.insert(self.History, {
        Time = os.time(),
        MemoryPercent = self.MemoryPercent,
        PressureLevel = self.CurrentLevel,
    })
    
    -- Keep history limited
    while #self.History > self.HistoryMaxSize do
        table.remove(self.History, 1)
    end
end

function AdaptiveStrategy:GetRecommendedAction(): string
    local level = self:GetPressureLevel()
    self.CurrentLevel = level
    
    if level == "critical" then
        return "FORCE_COLLECT_ALL"  -- Collect everything
    elseif level == "high" then
        return "COLLECT_IDLE"       -- Collect idle only
    elseif level == "normal" then
        return "SKIP"               -- Normal operation
    else
        return "MINIMAL"            -- Very little memory pressure
    end
end

function AdaptiveStrategy:GetInterval(): number
    local level = self:GetPressureLevel()
    
    if level == "critical" then
        return self.Config.CriticalInterval
    elseif level == "high" then
        return self.Config.HighInterval
    else
        return self.Config.LowInterval
    end
end

function AdaptiveStrategy:GetStats()
    return {
        memoryMB = self:GetMemoryUsage(),
        memoryPercent = self.MemoryPercent,
        pressureLevel = self:GetPressureLevel(),
        recommendedAction = self:GetRecommendedAction(),
        cleanupCount = self.CleanupCount,
        lastCleanup = self.LastCleanupTime,
        interval = self:GetInterval(),
    }
end

function AdaptiveStrategy:GetHistory()
    return self.History
end

function AdaptiveStrategy:ResetStats()
    self.History = {}
    self.CleanupCount = 0
    self.LastCleanupTime = os.time()
end

return AdaptiveStrategy
