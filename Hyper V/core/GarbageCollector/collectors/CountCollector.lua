--[[
    CountCollector - Cleanup dựa trên số lượng
    Single Responsibility: Giới hạn số lượng elements mỗi loại
]]

local CountCollector = {}
CountCollector.__index = CountCollector

export type CountRule = {
    MaxCount: number,
    Strategy: "oldest" | "newest" | "lru",
}

function CountCollector.new()
    local self = setmetatable({}, CountCollector)
    
    self.Rules = {} :: {string, CountRule}
    self.DefaultMaxCount = 50
    
    return self
end

function CountCollector:SetRule(elementType: string, maxCount: number, strategy: "oldest" | "newest" | "lru"?)
    self.Rules[elementType] = {
        MaxCount = maxCount,
        Strategy = strategy or "oldest",
    }
end

function CountCollector:RemoveRule(elementType: string)
    self.Rules[elementType] = nil
end

function CountCollector:GetRule(elementType: string): CountRule?
    return self.Rules[elementType]
end

function CountCollector:CollectByCount(entries: {any}, collectorFunc: (id: string) -> boolean): number
    local collected = 0
    
    for elementType, rule in pairs(self.Rules) do
        local typeEntries = {}
        local count = 0
        
        -- Collect entries of this type
        for id, entry in pairs(entries) do
            if entry.Type == elementType then
                count = count + 1
                table.insert(typeEntries, {
                    Id = id,
                    Entry = entry,
                    LastUsed = entry.LastUsed,
                    CreatedAt = entry.CreatedAt,
                })
            end
        end
        
        -- If over limit, collect excess
        if count > rule.MaxCount then
            local toRemove = count - rule.MaxCount
            
            -- Sort based on strategy
            if rule.Strategy == "oldest" then
                table.sort(typeEntries, function(a, b)
                    return a.CreatedAt < b.CreatedAt
                })
            elseif rule.Strategy == "newest" then
                table.sort(typeEntries, function(a, b)
                    return a.CreatedAt > b.CreatedAt
                })
            elseif rule.Strategy == "lru" then
                table.sort(typeEntries, function(a, b)
                    return a.LastUsed < b.LastUsed
                end)
            end
            
            -- Collect oldest/newest/LRU entries
            for i = 1, toRemove do
                if typeEntries[i] and typeEntries[i].Entry.AutoCleanup then
                    if collectorFunc(typeEntries[i].Id) then
                        collected = collected + 1
                    end
                end
            end
        end
    end
    
    return collected
end

function CountCollector:GetCounts(entries: {any}): {string: number}
    local counts = {}
    
    for _, entry in pairs(entries) do
        counts[entry.Type] = (counts[entry.Type] or 0) + 1
    end
    
    return counts
end

function CountCollector:GetEntriesToCleanup(entries: {any}): {string}
    local toCleanup = {}
    
    for elementType, rule in pairs(self.Rules) do
        local typeEntries = {}
        
        for id, entry in pairs(entries) do
            if entry.Type == elementType and entry.AutoCleanup then
                table.insert(typeEntries, {
                    Id = id,
                    LastUsed = entry.LastUsed,
                    CreatedAt = entry.CreatedAt,
                })
            end
        end
        
        local count = #typeEntries
        
        if count > rule.MaxCount then
            local toRemove = count - rule.MaxCount
            
            -- Sort by strategy
            if rule.Strategy == "oldest" then
                table.sort(typeEntries, function(a, b)
                    return a.CreatedAt < b.CreatedAt
                })
            elseif rule.Strategy == "newest" then
                table.sort(typeEntries, function(a, b)
                    return a.CreatedAt > b.CreatedAt
                })
            elseif rule.Strategy == "lru" then
                table.sort(typeEntries, function(a, b)
                    return a.LastUsed < b.LastUsed
                end)
            end
            
            for i = 1, toRemove do
                table.insert(toCleanup, typeEntries[i].Id)
            end
        end
    end
    
    return toCleanup
end

function CountCollector:ShouldCleanup(entry: any): boolean
    -- This collector only runs in batch mode
    return false
end

function CountCollector:SetDefaultMaxCount(count: number)
    self.DefaultMaxCount = count
end

return CountCollector

