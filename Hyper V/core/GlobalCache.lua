--[[
    Hyper-V - GlobalCache
    Hệ thống cache dữ liệu tập trung với TTL
]]

local GlobalCache = {}
GlobalCache.__index = GlobalCache

-- Singleton
local instance = nil

function GlobalCache.new()
    if instance then return instance end
    
    local self = setmetatable({}, GlobalCache)
    
    -- Storage
    self.Cache = {}           -- {key = {value, expiry, ttl}}
    self.ExpiredCallbacks = {} -- Callbacks khi cache hết hạn
    self.Stats = {
        hits = 0,
        misses = 0,
        sets = 0,
        deletes = 0,
    }
    
    -- Auto cleanup task
    self.CleanupTask = nil
    self.CleanupInterval = 5  -- Giây
    
    instance = self
    return self
end

function GlobalCache:GetInstance()
    if not instance then
        instance = GlobalCache.new()
    end
    return instance
end

-- ===== BASIC OPERATIONS =====

function GlobalCache:Set(key, value, ttl)
    local expiry = nil
    if ttl and ttl > 0 then
        expiry = os.time() + ttl
    end
    
    self.Cache[key] = {
        value = value,
        expiry = expiry,
        ttl = ttl,
        createdAt = os.time(),
        accessCount = 0,
    }
    
    self.Stats.sets = self.Stats.sets + 1
    return true
end

function GlobalCache:Get(key)
    local entry = self.Cache[key]
    
    if not entry then
        self.Stats.misses = self.Stats.misses + 1
        return nil
    end
    
    -- Check expiry
    if entry.expiry and os.time() > entry.expiry then
        -- Trigger expired callback
        if self.ExpiredCallbacks[key] then
            local success, err = pcall(self.ExpiredCallbacks[key], key, entry.value)
            if not success then
                warn("[GlobalCache] Expired callback error: " .. tostring(err))
            end
        end
        
        -- Delete expired entry
        self.Cache[key] = nil
        self.Stats.misses = self.Stats.misses + 1
        return nil
    end
    
    entry.accessCount = entry.accessCount + 1
    self.Stats.hits = self.Stats.hits + 1
    return entry.value
end

function GlobalCache:GetAsync(key)
    -- Synchronous, same as Get for this implementation
    return self:Get(key)
end

function GlobalCache:Delete(key)
    if self.Cache[key] then
        self.Cache[key] = nil
        self.Stats.deletes = self.Stats.deletes + 1
        return true
    end
    return false
end

function GlobalCache:Clear()
    local count = 0
    for k, _ in pairs(self.Cache) do
        self.Cache[k] = nil
        count = count + 1
    end
    return count
end

-- ===== QUERY OPERATIONS =====

function GlobalCache:Has(key)
    local entry = self.Cache[key]
    if not entry then return false end
    
    if entry.expiry and os.time() > entry.expiry then
        self.Cache[key] = nil
        return false
    end
    
    return true
end

function GlobalCache:GetTTL(key)
    local entry = self.Cache[key]
    if not entry or not entry.expiry then return nil end
    
    local remaining = entry.expiry - os.time()
    return math.max(0, remaining)
end

function GlobalCache:Refresh(key, newTTL)
    local entry = self.Cache[key]
    if not entry then return false end
    
    if newTTL and newTTL > 0 then
        entry.expiry = os.time() + newTTL
        entry.ttl = newTTL
    end
    return true
end

-- ===== BATCH OPERATIONS =====

function GlobalCache:GetMany(keys)
    local results = {}
    for _, key in ipairs(keys) do
        results[key] = self:Get(key)
    end
    return results
end

function GlobalCache:SetMany(data, defaultTTL)
    local count = 0
    for key, value in pairs(data) do
        self:Set(key, value, defaultTTL)
        count = count + 1
    end
    return count
end

function GlobalCache:Keys()
    local keys = {}
    for k, entry in pairs(self.Cache) do
        -- Skip expired
        if entry.expiry and os.time() > entry.expiry then
            self.Cache[k] = nil
        else
            table.insert(keys, k)
        end
    end
    return keys
end

function GlobalCache:Values()
    local values = {}
    for _, entry in pairs(self.Cache) do
        if entry.expiry and os.time() > entry.expiry then
            -- skip
        else
            table.insert(values, entry.value)
        end
    end
    return values
end

function GlobalCache:Pairs()
    -- Return non-expired entries
    local result = {}
    for k, entry in pairs(self.Cache) do
        if entry.expiry and os.time() > entry.expiry then
            self.Cache[k] = nil
        else
            result[k] = entry.value
        end
    end
    return result
end

-- ===== CALLBACKS =====

function GlobalCache:OnExpire(key, callback)
    self.ExpiredCallbacks[key] = callback
end

function GlobalCache:OnExpireAny(callback)
    self.GlobalExpireCallback = callback
end

-- ===== AUTO CLEANUP =====

function GlobalCache:Cleanup()
    local removed = 0
    local now = os.time()
    
    for key, entry in pairs(self.Cache) do
        if entry.expiry and now > entry.expiry then
            -- Trigger callback if exists
            if self.ExpiredCallbacks[key] then
                pcall(self.ExpiredCallbacks[key], key, entry.value)
            end
            
            self.Cache[key] = nil
            removed = removed + 1
        end
    end
    
    if removed > 0 and self.GlobalExpireCallback then
        pcall(self.GlobalExpireCallback, removed)
    end
    
    return removed
end

function GlobalCache:StartAutoCleanup(interval)
    self.CleanupInterval = interval or 5
    self:StopAutoCleanup()
    local token = {}
    self.CleanupTask = token

    task.spawn(function()
        while self.CleanupTask == token do
            task.wait(self.CleanupInterval)
            self:Cleanup()
        end
    end)
end

function GlobalCache:StopAutoCleanup()
    self.CleanupTask = nil
end

-- ===== STATS =====

function GlobalCache:GetStats()
    local validCount = 0
    local expiredCount = 0
    local now = os.time()
    
    for _, entry in pairs(self.Cache) do
        if entry.expiry and now > entry.expiry then
            expiredCount = expiredCount + 1
        else
            validCount = validCount + 1
        end
    end
    
    return {
        entries = validCount,
        expired = expiredCount,
        total = validCount + expiredCount,
        hits = self.Stats.hits,
        misses = self.Stats.misses,
        sets = self.Stats.sets,
        deletes = self.Stats.deletes,
        hitRate = self.Stats.hits / math.max(1, self.Stats.hits + self.Stats.misses),
    }
end

function GlobalCache:ResetStats()
    self.Stats = {
        hits = 0,
        misses = 0,
        sets = 0,
        deletes = 0,
    }
end

-- ===== DESTROY =====

function GlobalCache:Destroy()
    self:Clear()
    self.ExpiredCallbacks = {}
    self:StopAutoCleanup()
    instance = nil
end

return GlobalCache
