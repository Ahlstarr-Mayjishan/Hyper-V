--[[
    GarbageCollector - Main Facade
    Single Responsibility: Điều phối tất cả các module GC
]]

-- Module imports
local GCEntry = require(script.Parent.types.GCEntry)
local ObjectPool = require(script.Parent.pool.ObjectPool)
local AgeCollector = require(script.Parent.collectors.AgeCollector)
local CountCollector = require(script.Parent.collectors.CountCollector)
local AdaptiveStrategy = require(script.Parent.strategies.AdaptiveStrategy)
local IncrementalStrategy = require(script.Parent.strategies.IncrementalStrategy)
local MemoryListener = require(script.Parent.MemoryListener)
local RayfieldMarker = require(script.Parent.Parent.RayfieldMarker)
local RayfieldAPI = require(script.Parent.Parent.API.RayfieldAPI)

local GarbageCollector = {}
GarbageCollector.__index = GarbageCollector

-- Singleton
local instance = nil

export type GCConfig = {
    AutoCleanupEnabled: boolean?,
    CleanupInterval: number?,
    DefaultThreshold: number?,
    DefaultMaxCount: number?,
    MaxPerFrame: number?,         -- ZERO LAG: Items per frame (default: 3)
    MaxPerSecond: number?,        -- ZERO LAG: Items per second (default: 15)
    MaxBatchTime: number?,       -- ZERO LAG: Max ms per frame (default: 2ms)
    YieldAfterItems: number?,    -- ZERO LAG: Yield after N items
    MemoryWarningThreshold: number?,
    MemoryCriticalThreshold: number?,
}

local DEFAULT_CONFIG = {
    AutoCleanupEnabled = true,
    CleanupInterval = 30,
    DefaultThreshold = 60,
    DefaultMaxCount = 50,
    MaxPerFrame = 3,           -- ZERO LAG: Reduced to 3
    MaxPerSecond = 15,         -- ZERO LAG: Limited per second
    MaxBatchTime = 2,           -- ZERO LAG: 2ms max per frame
    YieldAfterItems = 10,       -- ZERO LAG: Yield after 10 items
    MemoryWarningThreshold = 60,
    MemoryCriticalThreshold = 80,
}

function GarbageCollector.new(config: GCConfig?)
    if instance then return instance end
    
    local self = setmetatable({}, GarbageCollector)
    
    -- Configuration
    self.Config = config or DEFAULT_CONFIG
    
    -- Registry
    self.Elements = {} :: {string: GCEntry.GCEntryType}
    
    -- Collectors
    self.AgeCollector = AgeCollector.new()
    self.CountCollector = CountCollector.new()
    
    -- Strategies
    self.AdaptiveStrategy = AdaptiveStrategy.new({
        LowThreshold = 30,
        HighThreshold = self.Config.MemoryWarningThreshold,
        CriticalThreshold = self.Config.MemoryCriticalThreshold,
    })
    
    self.IncrementalStrategy = IncrementalStrategy.new()
    self.IncrementalStrategy:SetMaxPerFrame(self.Config.MaxPerFrame)

    -- ZERO LAG: Pass all config to incremental strategy
    self.IncrementalStrategy.MaxPerSecond = self.Config.MaxPerSecond
    self.IncrementalStrategy.MaxBatchTime = (self.Config.MaxBatchTime or 2) / 1000  -- Convert ms to seconds
    self.IncrementalStrategy.YieldAfterItems = self.Config.YieldAfterItems or 10
    
    -- Memory Listener
    self.MemoryListener = MemoryListener.new({
        CheckInterval = 5,
        WarningThreshold = self.Config.MemoryWarningThreshold,
        CriticalThreshold = self.Config.MemoryCriticalThreshold,
        OnWarning = function(level, memory)
            warn("[GC] Memory warning:", math.floor(memory), "MB")
        end,
        OnCritical = function(level, memory)
            warn("[GC] Memory critical! Force collecting...")
            self:ForceCollect()
        end,
    })
    
    -- Object Pools
    self.Pools = {} :: {string: ObjectPool}

    -- RayfieldMarker integration
    self.Marker = RayfieldMarker.new({
        AutoCleanup = self.Config.AutoCleanupEnabled,
        MaxAge = self.Config.DefaultThreshold,
        CleanupInterval = self.Config.CleanupInterval,
    })

    -- RayfieldAPI integration
    self.API = RayfieldAPI.new()
    self.API:SetMarker(self.Marker)

    -- Stats
    self.Stats = {
        Registered = 0,
        Collected = 0,
        Peak = 0,
    }
    
    -- State
    self.IsAutoCleanupEnabled = self.Config.AutoCleanupEnabled
    self.CleanupTask = nil
    
    -- Setup default rules
    self:SetupDefaultRules()
    
    -- Setup incremental collector
    self.IncrementalStrategy.ShouldCollectFunc = function(entry)
        return self.AgeCollector:ShouldCleanup(entry)
    end
    
    instance = self
    return self
end

function GarbageCollector:Get()
    if not instance then
        instance = GarbageCollector.new()
    end
    return instance
end

-- ===== SETUP =====

function GarbageCollector:SetupDefaultRules()
    self.AgeCollector:SetRule("Notification", 30, 20)
    self.AgeCollector:SetRule("Modal", 300, 10)
    self.AgeCollector:SetRule("Detached", 600, 5)
    self.AgeCollector:SetRule("Tooltip", 10, 50)
    self.AgeCollector:SetRule("Generic", self.Config.DefaultThreshold, self.Config.DefaultMaxCount)
    
    self.CountCollector:SetRule("Notification", 20)
    self.CountCollector:SetRule("Modal", 10)
    self.CountCollector:SetRule("Detached", 5)
    self.CountCollector:SetRule("Tooltip", 50)
end

-- ===== REGISTRATION =====

function GarbageCollector:Register(config: {
    Id: string?,
    Element: Instance?,
    Type: string?,
    AutoCleanup: boolean?,
    OnCleanup: ((Instance?, any) -> ())?,
    CustomData: any?,
}): string
    local entry = GCEntry.new(config)

    self.Elements[entry.Id] = entry :: any
    self.Stats.Registered = self.Stats.Registered + 1

    -- Mark with RayfieldMarker
    if config.Element then
        self.Marker:Mark(config.Element, config.Type or "Generic")
    end

    if self.Stats.Registered > self.Stats.Peak then
        self.Stats.Peak = self.Stats.Registered
    end

    return entry.Id
end

function GarbageCollector:Unregister(id: string): boolean
    if self.Elements[id] then
        self.Elements[id] = nil
        return true
    end
    return false
end

function GarbageCollector:Touch(id: string)
    local entry = self.Elements[id]
    if entry then
        entry:Touch()
    end
end

function GarbageCollector:AddRef(id: string, count: number?)
    local entry = self.Elements[id]
    if entry then
        entry:AddRef(count)
    end
end

function GarbageCollector:ReleaseRef(id: string, count: number?)
    local entry = self.Elements[id]
    if entry then
        entry:ReleaseRef(count)
    end
end

-- ===== CLEANUP =====

function GarbageCollector:Collect(id: string): boolean
    local entry = self.Elements[id]
    if not entry then return false end

    -- Call cleanup callback
    if entry.OnCleanup then
        pcall(entry.OnCleanup, entry.Element, entry.CustomData)
    end

    -- Unmark from RayfieldMarker
    if entry.Element then
        self.Marker:Unmark(entry.Element)
    end

    -- Destroy element
    if entry.Element and typeof(entry.Element) == "Instance" then
        pcall(function()
            entry.Element:Destroy()
        end)
    end

    self.Elements[id] = nil
    self.Stats.Collected = self.Stats.Collected + 1

    return true
end

function GarbageCollector:CollectByType(elementType: string): number
    local collected = 0
    
    for id, entry in pairs(self.Elements) do
        if entry.Type == elementType then
            if self:Collect(id) then
                collected = collected + 1
            end
        end
    end
    
    return collected
end

function GarbageCollector:CollectIdle(): number
    local collected = self.AgeCollector:CollectIdle(self.Elements, function(id)
        return self:Collect(id)
    end)
    
    return collected
end

function GarbageCollector:CollectByCount(): number
    local collected = self.CountCollector:CollectByCount(self.Elements, function(id)
        return self:Collect(id)
    end)
    
    return collected
end

function GarbageCollector:CollectAll(): number
    local collected = 0
    
    for id, _ in pairs(self.Elements) do
        if self:Collect(id) then
            collected = collected + 1
        end
    end
    
    return collected
end

function GarbageCollector:ForceCollect()
    -- Force collect with all strategies
    local collected = 0
    
    -- Age-based
    collected = collected + self:CollectIdle()
    
    -- Count-based
    collected = collected + self:CollectByCount()
    
    -- Record in adaptive strategy
    self.AdaptiveStrategy:RecordCleanup()
    
    return collected
end

-- ===== INCREMENTAL CLEANUP =====

function GarbageCollector:ProcessIncremental()
    -- Add entries to queue
    self.IncrementalStrategy:AddToQueue(self.Elements)
    
    -- Process frame
    local batch = self.IncrementalStrategy:ProcessFrame(self.Elements)
    
    return batch.Collected
end

function GarbageCollector:StartIncrementalCleanup()
    task.spawn(function()
        while self.IsAutoCleanupEnabled do
            local collected = self:ProcessIncremental()
            
            if self.IncrementalStrategy:IsQueueEmpty() then
                -- Wait for next cleanup cycle
                task.wait(self.Config.CleanupInterval)
            else
                -- Continue processing
                task.wait()
            end
        end
    end)
end

-- ===== AUTO CLEANUP =====

function GarbageCollector:StartAutoCleanup(interval: number?)
    self.IsAutoCleanupEnabled = true
    self.Config.CleanupInterval = interval or self.Config.CleanupInterval
    
    -- Start memory listener
    self.MemoryListener:Start()
    
    -- Start incremental cleanup
    self:StartIncrementalCleanup()
end

function GarbageCollector:StopAutoCleanup()
    self.IsAutoCleanupEnabled = false
    self.MemoryListener:Stop()
end

-- ===== OBJECT POOL =====

function GarbageCollector:CreatePool(name: string, config: {
    MaxSize: number?,
    Factory: (() -> Instance)?,
    Reset: ((Instance) -> ())?,
    Validate: ((Instance) -> boolean)?,
}): ObjectPool
    local pool = ObjectPool.new(config)
    self.Pools[name] = pool
    return pool
end

function GarbageCollector:GetPool(name: string): ObjectPool?
    return self.Pools[name]
end

function GarbageCollector:DeletePool(name: string)
    if self.Pools[name] then
        self.Pools[name]:Destroy()
        self.Pools[name] = nil
    end
end

-- ===== RULES =====

function GarbageCollector:SetAgeRule(elementType: string, maxAge: number, maxCount: number?)
    self.AgeCollector:SetRule(elementType, maxAge, maxCount)
end

function GarbageCollector:SetCountRule(elementType: string, maxCount: number)
    self.CountCollector:SetRule(elementType, maxCount)
end

-- ===== ZERO LAG CONFIG =====

function GarbageCollector:SetZeroLagConfig(config: {
    MaxPerFrame: number?,
    MaxPerSecond: number?,
    MaxBatchTime: number?,
    YieldAfterItems: number?,
})
    if config.MaxPerFrame then
        self.Config.MaxPerFrame = config.MaxPerFrame
        self.IncrementalStrategy.MaxPerFrame = config.MaxPerFrame
    end
    if config.MaxPerSecond then
        self.Config.MaxPerSecond = config.MaxPerSecond
        self.IncrementalStrategy.MaxPerSecond = config.MaxPerSecond
    end
    if config.MaxBatchTime then
        self.Config.MaxBatchTime = config.MaxBatchTime
        self.IncrementalStrategy.MaxBatchTime = config.MaxBatchTime / 1000
    end
    if config.YieldAfterItems then
        self.Config.YieldAfterItems = config.YieldAfterItems
        self.IncrementalStrategy.YieldAfterItems = config.YieldAfterItems
    end
end

function GarbageCollector:GetZeroLagStats()
    return self.IncrementalStrategy:GetStats()
end

-- Force adaptive adjustment
function GarbageCollector:OnLagDetected()
    self.IncrementalStrategy:OnLagDetected()
end

function GarbageCollector:OnPerformanceGood()
    self.IncrementalStrategy:OnPerformanceGood()
end

-- ===== QUERY =====

function GarbageCollector:Get(id: string): GCEntry.GCEntryType?
    return self.Elements[id]
end

function GarbageCollector:GetByType(elementType: string): {GCEntry.GCEntryType}
    local results = {}
    
    for _, entry in pairs(self.Elements) do
        if entry.Type == elementType then
            table.insert(results, entry)
        end
    end
    
    return results
end

function GarbageCollector:Count(): number
    local count = 0
    for _ in pairs(self.Elements) do
        count = count + 1
    end
    return count
end

function GarbageCollector:CountByType(elementType: string): number
    local count = 0
    for _, entry in pairs(self.Elements) do
        if entry.Type == elementType then
            count = count + 1
        end
    end
    return count
end

-- ===== STATS =====

function GarbageCollector:GetStats()
    local byType = {}
    for _, entry in pairs(self.Elements) do
        byType[entry.Type] = (byType[entry.Type] or 0) + 1
    end
    
    return {
        registered = self.Stats.Registered,
        collected = self.Stats.Collected,
        peak = self.Stats.Peak,
        current = self:Count(),
        byType = byType,
        incremental = self.IncrementalStrategy:GetStats(),
        adaptive = self.AdaptiveStrategy:GetStats(),
        memory = self.MemoryListener:GetStats(),
    }
end

function GarbageCollector:Destroy()
    self:CollectAll()
    self:StopAutoCleanup()
    
    for _, pool in pairs(self.Pools) do
        pool:Destroy()
    end
    
    self.Elements = {}
    self.Pools = {}
    instance = nil
end

return GarbageCollector
