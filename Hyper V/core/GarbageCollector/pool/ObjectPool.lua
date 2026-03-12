--[[
    ObjectPool - Tái sử dụng objects thay vì tạo/xóa liên tục
    Single Responsibility: Quản lý việc tái sử dụng objects
]]

local ObjectPool = {}
ObjectPool.__index = ObjectPool

export type PoolConfig = {
    MaxSize: number?,
    Factory: (() -> Instance)?,
    Reset: ((instance: Instance) -> ())?,
    Validate: ((instance: Instance) -> boolean)?,
}

export type PooledObject = {
    Instance: Instance,
    InUse: boolean,
    LastUsed: number,
}

function ObjectPool.new(config: PoolConfig?)
    local self = setmetatable({}, ObjectPool)
    
    self.MaxSize = config.MaxSize or 50
    self.Factory = config.Factory
    self.ResetFunc = config.Reset
    self.ValidateFunc = config.Validate
    
    self.Available = {} :: {PooledObject}
    self.InUse = {} :: {PooledObject}
    self.Stats = {
        hits = 0,
        misses = 0,
        created = 0,
        recycled = 0,
    }
    
    return self
end

function ObjectPool:Get()
    -- Try to get from available pool
    local count = #self.Available
    for i = count, 1, -1 do
        local pooled = self.Available[i]
        
        -- Validate if validator exists
        if self.ValidateFunc then
            if not self.ValidateFunc(pooled.Instance) then
                -- Invalid, remove from pool
                table.remove(self.Available, i)
                continue
            end
        end
        
        -- Found valid object
        pooled.InUse = true
        pooled.LastUsed = os.time()
        
        table.remove(self.Available, i)
        table.insert(self.InUse, pooled)
        
        self.Stats.hits = self.Stats.hits + 1
        return pooled.Instance
    end
    
    -- No available objects, create new if under limit
    if self.Stats.created < self.MaxSize and self.Factory then
        local newInstance = self.Factory()
        local pooled = {
            Instance = newInstance,
            InUse = true,
            LastUsed = os.time(),
        }
        
        table.insert(self.InUse, pooled)
        self.Stats.created = self.Stats.created + 1
        
        return newInstance
    end
    
    -- Pool exhausted
    self.Stats.misses = self.Stats.misses + 1
    return nil
end

function ObjectPool:Return(instance: Instance)
    -- Find in use object
    for i, pooled in ipairs(self.InUse) do
        if pooled.Instance == instance then
            -- Reset if reset function exists
            if self.ResetFunc then
                self.ResetFunc(instance)
            end
            
            pooled.InUse = false
            pooled.LastUsed = os.time()
            
            table.remove(self.InUse, i)
            
            -- Add back to available if under max size
            if #self.Available < self.MaxSize then
                table.insert(self.Available, pooled)
                self.Stats.recycled = self.Stats.recycled + 1
            else
                -- Destroy if pool is full
                if instance and typeof(instance) == "Instance" then
                    pcall(function()
                        instance:Destroy()
                    end)
                end
            end
            
            return true
        end
    end
    
    return false
end

function ObjectPool:Clear()
    -- Clear available
    for _, pooled in ipairs(self.Available) do
        if pooled.Instance and typeof(pooled.Instance) == "Instance" then
            pcall(function()
                pooled.Instance:Destroy()
            end)
        end
    end
    self.Available = {}
    
    -- Clear in use
    for _, pooled in ipairs(self.InUse) do
        if pooled.Instance and typeof(pooled.Instance) == "Instance" then
            pcall(function()
                pooled.Instance:Destroy()
            end)
        end
    end
    self.InUse = {}
end

function ObjectPool:GetStats()
    return {
        available = #self.Available,
        inUse = #self.InUse,
        total = self.Stats.created,
        hits = self.Stats.hits,
        misses = self.Stats.misses,
        recycled = self.Stats.recycled,
        hitRate = self.Stats.hits / math.max(1, self.Stats.hits + self.Stats.misses),
    }
end

function ObjectPool:Preload(count: number)
    if not self.Factory then return 0 end
    
    local created = 0
    for i = 1, count do
        if #self.Available + #self.InUse >= self.MaxSize then break end
        
        local instance = self.Factory()
        table.insert(self.Available, {
            Instance = instance,
            InUse = false,
            LastUsed = os.time(),
        })
        created = created + 1
    end
    self.Stats.created = self.Stats.created + created
    
    return created
end

function ObjectPool:Destroy()
    self:Clear()
    self.Factory = nil
    self.ResetFunc = nil
    self.ValidateFunc = nil
end

return ObjectPool

