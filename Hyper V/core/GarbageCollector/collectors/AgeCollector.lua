--[[
    AgeCollector - Cleanup dựa trên thời gian idle
    Single Responsibility: Xóa elements sau khi idle quá lâu
]]

local AgeCollector = {}
AgeCollector.__index = AgeCollector

export type AgeRule = {
    MaxAge: number,  -- seconds
    MaxCount: number,
}

function AgeCollector.new()
    local self = setmetatable({}, AgeCollector)
    
    self.Rules = {} :: { [string]: AgeRule }
    self.DefaultThreshold = 60  -- 60 seconds default
    
    return self
end

function AgeCollector:SetRule(elementType: string, maxAge: number, maxCount: number?)
    self.Rules[elementType] = {
        MaxAge = maxAge,
        MaxCount = maxCount or math.huge,
    }
end

function AgeCollector:RemoveRule(elementType: string)
    self.Rules[elementType] = nil
end

function AgeCollector:GetRule(elementType: string): AgeRule?
    return self.Rules[elementType]
end

function AgeCollector:CollectIdle(entries: {any}, collectorFunc: (id: string) -> boolean): number
    local collected = 0
    local now = os.time()
    
    for id, entry in pairs(entries) do
        if entry.AutoCleanup and entry.Refs <= 0 then
            local rule = self.Rules[entry.Type]
            local threshold = rule and rule.MaxAge or self.DefaultThreshold
            
            local idleTime = now - entry.LastUsed
            
            if idleTime > threshold then
                if collectorFunc(id) then
                    collected = collected + 1
                end
            end
        end
    end
    
    return collected
end

function AgeCollector:GetIdleEntries(entries: {any}): {string}
    local result = {}
    local now = os.time()
    
    for id, entry in pairs(entries) do
        local rule = self.Rules[entry.Type]
        local threshold = rule and rule.MaxAge or self.DefaultThreshold
        
        local idleTime = now - entry.LastUsed
        
        if idleTime > threshold then
            table.insert(result, {
                Id = id,
                IdleTime = idleTime,
                Type = entry.Type,
            })
        end
    end
    
    -- Sort by idle time (oldest first)
    table.sort(result, function(a, b)
        return a.IdleTime > b.IdleTime
    end)
    
    return result
end

function AgeCollector:ShouldCleanup(entry: any): boolean
    if not entry.AutoCleanup or entry.Refs > 0 then
        return false
    end
    
    local rule = self.Rules[entry.Type]
    local threshold = rule and rule.MaxAge or self.DefaultThreshold
    
    return (os.time() - entry.LastUsed) > threshold
end

function AgeCollector:SetDefaultThreshold(seconds: number)
    self.DefaultThreshold = seconds
end

return AgeCollector
