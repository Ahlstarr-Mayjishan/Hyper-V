--[[
    MemoryListener - Theo dõi memory pressure và cảnh báo
    Single Responsibility: Lắng nghe và phản hồi memory pressure
]]

local MemoryListener = {}
MemoryListener.__index = MemoryListener

export type MemoryCallback = (level: string, memoryMB: number) -> ()

export type MemoryConfig = {
    CheckInterval: number?,
    WarningThreshold: number?,
    CriticalThreshold: number?,
    OnWarning: MemoryCallback?,
    OnCritical: MemoryCallback?,
    OnNormal: MemoryCallback?,
}

local DEFAULT_CONFIG = {
    CheckInterval = 5,         -- Check every 5 seconds
    WarningThreshold = 60,    -- 60% memory
    CriticalThreshold = 80,   -- 80% memory
}

function MemoryListener.new(config: MemoryConfig?)
    local self = setmetatable({}, MemoryListener)
    
    self.Config = config or DEFAULT_CONFIG
    
    -- State
    self.IsListening = false
    self.CurrentLevel = "normal" :: "normal" | "warning" | "critical"
    self.CurrentMemoryMB = 0
    self.PeakMemoryMB = 0
    
    -- Callbacks
    self.WarningCallback = config.OnWarning
    self.CriticalCallback = config.OnCritical
    self.NormalCallback = config.OnNormal
    
    -- History
    self.History = {}
    self.HistoryMaxSize = 60  -- 5 minutes of history (at 5s intervals)
    
    -- Connections
    self.ListenTask = nil
    
    return self
end

function MemoryListener:Start()
    if self.IsListening then return end
    self.IsListening = true
    
    self.ListenTask = task.spawn(function()
        while self.IsListening do
            self:Check()
            task.wait(self.Config.CheckInterval)
        end
    end)
end

function MemoryListener:Stop()
    self.IsListening = false
    if self.ListenTask then
        task.cancel(self.ListenTask)
        self.ListenTask = nil
    end
end

function MemoryListener:GetMemoryUsage(): number
    -- Try to get memory usage
    local success, result = pcall(function()
        local stats = game:GetService("Stats")
        local memory = stats:GetMemoryUsageForTag("Engine")
        return memory / 1024 / 1024  -- Convert to MB
    end)
    
    if success then
        return result
    end
    
    -- Fallback: use GC count as proxy
    return collectgarbage("count") / 1024
end

function MemoryListener:CalculatePercent(): number
    local current = self:GetMemoryUsage()
    local max = 2048  -- 2GB typical limit
    
    self.CurrentMemoryMB = current
    
    if current > self.PeakMemoryMB then
        self.PeakMemoryMB = current
    end
    
    return (current / max) * 100
end

function MemoryListener:Check()
    local percent = self:CalculatePercent()
    local oldLevel = self.CurrentLevel
    
    -- Determine level
    if percent >= self.Config.CriticalThreshold then
        self.CurrentLevel = "critical"
    elseif percent >= self.Config.WarningThreshold then
        self.CurrentLevel = "warning"
    else
        self.CurrentLevel = "normal"
    end
    
    -- Record to history
    table.insert(self.History, {
        Time = os.time(),
        MemoryMB = self.CurrentMemoryMB,
        Percent = percent,
        Level = self.CurrentLevel,
    })
    
    -- Keep history limited
    while #self.History > self.HistoryMaxSize do
        table.remove(self.History, 1)
    end
    
    -- Trigger callbacks if level changed
    if oldLevel ~= self.CurrentLevel then
        if self.CurrentLevel == "critical" and self.CriticalCallback then
            pcall(self.CriticalCallback, self.CurrentLevel, self.CurrentMemoryMB)
        elseif self.CurrentLevel == "warning" and self.WarningCallback then
            pcall(self.WarningCallback, self.CurrentLevel, self.CurrentMemoryMB)
        elseif self.CurrentLevel == "normal" and self.NormalCallback then
            pcall(self.NormalCallback, self.CurrentLevel, self.CurrentMemoryMB)
        end
    end
end

function MemoryListener:ForceCheck()
    self:Check()
end

function MemoryListener:GetLevel(): string
    return self.CurrentLevel
end

function MemoryListener:GetMemory(): number
    return self.CurrentMemoryMB
end

function MemoryListener:GetPeak(): number
    return self.PeakMemoryMB
end

function MemoryListener:GetHistory(): {{Time: number, MemoryMB: number, Percent: number, Level: string}}
    return self.History
end

function MemoryListener:OnWarning(callback: MemoryCallback)
    self.WarningCallback = callback
end

function MemoryListener:OnCritical(callback: MemoryCallback)
    self.CriticalCallback = callback
end

function MemoryListener:OnNormal(callback: MemoryCallback)
    self.NormalCallback = callback
end

function MemoryListener:ResetPeak()
    self.PeakMemoryMB = self.CurrentMemoryMB
end

function MemoryListener:GetStats()
    return {
        currentMB = self.CurrentMemoryMB,
        peakMB = self.PeakMemoryMB,
        percent = self:CalculatePercent(),
        level = self.CurrentLevel,
        historySize = #self.History,
        isListening = self.IsListening,
    }
end

function MemoryListener:Destroy()
    self:Stop()
    self.History = {}
    self.WarningCallback = nil
    self.CriticalCallback = nil
    self.NormalCallback = nil
end

return MemoryListener

