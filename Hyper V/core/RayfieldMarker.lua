--[[
    HyperVMarker - Đánh dấu và theo dõi tất cả UI elements của Hyper-V
    Sử dụng Mark & Sweep algorithm
]]

local HyperVMarker = {}
HyperVMarker.__index = HyperVMarker

-- Singleton
local instance = nil

export type MarkConfig = {
    AutoCleanup: boolean?,
    MaxAge: number?,
    CleanupInterval: number?,
}

local DEFAULT_CONFIG = {
    AutoCleanup = true,
    MaxAge = 300,  -- 5 minutes
    CleanupInterval = 30,  -- 30 seconds
}

function HyperVMarker.new(config: MarkConfig?)
    if instance then return instance end
    
    local self = setmetatable({}, HyperVMarker)
    
    self.Config = config or DEFAULT_CONFIG
    
    -- Registry: lưu tất cả instances đã mark
    self.Registry = {} :: {number: {
        Instance: Instance,
        MarkedAt: number,
        LastUsed: number,
        Tag: string?,
        Parent: Instance?,
    }}
    
    -- Reverse lookup: instance -> registry key
    self.InstanceToKey = {} :: {number: number}
    
    -- Statistics
    self.Stats = {
        TotalMarked = 0,
        TotalCleaned = 0,
        Peak = 0,
    }
    
    -- Auto cleanup task
    self.CleanupTask = nil
    self.IsRunning = false
    
    -- Callbacks
    self.OnMark = nil :: ((instance: Instance, key: number) -> ())?
    self.OnClean = nil :: ((instance: Instance) -> ())?
    self.OnWarning = nil :: ((count: number) -> ())?
    
    instance = self
    return self
end

function HyperVMarker:Get()
    if not instance then
        instance = HyperVMarker.new()
    end
    return instance
end

-- ===== MARKING =====

function HyperVMarker:Mark(instance: Instance, tag: string?): number
    if not instance or typeof(instance) ~= "Instance" then
        return -1
    end
    
    -- Kiểm tra đã mark chưa
    local existingKey = self.InstanceToKey[instance:GetAttribute("RayfieldMarkKey") or -1]
    if existingKey then
        return existingKey
    end
    
    -- Thêm vào registry
    local key = #self.Registry + 1
    local now = os.time()
    
    self.Registry[key] = {
        Instance = instance,
        MarkedAt = now,
        LastUsed = now,
        Tag = tag,
        Parent = instance.Parent,
    }
    
    -- Đánh dấu instance
    instance:SetAttribute("RayfieldMarked", true)
    instance:SetAttribute("RayfieldMarkKey", key)
    instance:SetAttribute("RayfieldMarkTime", now)
    if tag then
        instance:SetAttribute("RayfieldTag", tag)
    end
    
    -- Store reference
    self.InstanceToKey[instance] = key
    
    -- Update stats
    self.Stats.TotalMarked = self.Stats.TotalMarked + 1
    if self.Stats.TotalMarked > self.Stats.Peak then
        self.Stats.Peak = self.Stats.TotalMarked
    end
    
    -- Callback
    if self.OnMark then
        pcall(self.OnMark, instance, key)
    end
    
    return key
end

function HyperVMarker:MarkWithChildren(parent: Instance, tag: string?): number
    local marked = 0
    
    -- Mark parent
    self:Mark(parent, tag)
    marked = marked + 1
    
    -- Mark all descendants
    for _, child in ipairs(parent:GetDescendants()) do
        if child:IsA("Instance") then
            self:Mark(child, tag)
            marked = marked + 1
        end
    end
    
    return marked
end

function HyperVMarker:Unmark(instance: Instance): boolean
    local key = self.InstanceToKey[instance]
    if not key then return false end
    
    -- Remove from registry
    self.Registry[key] = nil
    
    -- Remove references
    self.InstanceToKey[instance] = nil
    
    -- Remove attributes
    instance:SetAttribute("RayfieldMarked", false)
    instance:SetAttribute("RayfieldMarkKey", nil)
    instance:SetAttribute("RayfieldMarkTime", nil)
    instance:SetAttribute("RayfieldTag", nil)
    
    return true
end

function HyperVMarker:IsMarked(instance: Instance): boolean
    return instance:GetAttribute("RayfieldMarked") == true
end

function HyperVMarker:Touch(instance: Instance)
    local key = self.InstanceToKey[instance]
    if key and self.Registry[key] then
        self.Registry[key].LastUsed = os.time()
    end
end

-- ===== QUERYING =====

function HyperVMarker:Get(key: number): any
    return self.Registry[key]
end

function HyperVMarker:GetByInstance(instance: Instance): any
    local key = self.InstanceToKey[instance]
    if key then
        return self.Registry[key]
    end
    return nil
end

function HyperVMarker:GetByTag(tag: string): {any}
    local results = {}
    for _, entry in ipairs(self.Registry) do
        if entry and entry.Tag == tag then
            table.insert(results, entry)
        end
    end
    return results
end

function HyperVMarker:Count(): number
    local count = 0
    for _ in pairs(self.Registry) do
        count = count + 1
    end
    return count
end

function HyperVMarker:GetAll(): {any}
    local results = {}
    for _, entry in ipairs(self.Registry) do
        if entry then
            table.insert(results, entry)
        end
    end
    return results
end

-- ===== SWEEP / CLEANUP =====

function HyperVMarker:Sweep(instance: Instance): boolean
    local entry = self:GetByInstance(instance)
    if not entry then return false end
    
    -- Check if instance still exists and is valid
    if entry.Instance and entry.Instance.Parent then
        -- Destroy the instance
        local success, err = pcall(function()
            entry.Instance:Destroy()
        end)
        
        if not success then
            warn("[HyperVMarker] Failed to destroy:", err)
        end
    end
    
    -- Callback
    if self.OnClean then
        pcall(self.OnClean, entry.Instance)
    end
    
    -- Remove from registry
    self.Registry[self.InstanceToKey[instance]] = nil
    self.InstanceToKey[instance] = nil
    
    -- Remove attributes
    if entry.Instance then
        entry.Instance:SetAttribute("RayfieldMarked", false)
        entry.Instance:SetAttribute("RayfieldMarkKey", nil)
    end
    
    self.Stats.TotalCleaned = self.Stats.TotalCleaned + 1
    
    return true
end

function HyperVMarker:SweepByTag(tag: string): number
    local entries = self:GetByTag(tag)
    local count = 0
    
    for _, entry in ipairs(entries) do
        if self:Sweep(entry.Instance) then
            count = count + 1
        end
    end
    
    return count
end

function HyperVMarker:SweepByAge(maxAge: number): number
    local now = os.time()
    local count = 0
    local toRemove = {}
    
    -- Find all old entries
    for key, entry in ipairs(self.Registry) do
        if entry then
            local age = now - entry.LastUsed
            if age > maxAge then
                table.insert(toRemove, entry.Instance)
            end
        end
    end
    
    -- Sweep them
    for _, instance in ipairs(toRemove) do
        if self:Sweep(instance) then
            count = count + 1
        end
    end
    
    return count
end

function HyperVMarker:SweepInvalid(): number
    local count = 0
    local toRemove = {}
    
    -- Find invalid entries
    for key, entry in ipairs(self.Registry) do
        if not entry then continue end
        
        local valid = false
        local success, err = pcall(function()
            if entry.Instance and entry.Instance.Parent then
                valid = true
            end
        end)
        
        if not valid or not success then
            table.insert(toRemove, entry.Instance)
        end
    end
    
    -- Remove them
    for _, instance in ipairs(toRemove) do
        if self:Sweep(instance) then
            count = count + 1
        end
    end
    
    return count
end

function HyperVMarker:SweepAll(): number
    local count = 0
    local instances = self:GetAll()
    
    for _, entry in ipairs(instances) do
        if entry.Instance and self:Sweep(entry.Instance) then
            count = count + 1
        end
    end
    
    return count
end

-- ===== INSTANCE CONTROL =====

function HyperVMarker:Destroy(instance: Instance): boolean
    -- Alias for Sweep - destroys and removes from registry
    return self:Sweep(instance)
end

function HyperVMarker:Hide(instance: Instance): boolean
    local entry = self:GetByInstance(instance)
    if not entry then return false end

    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            instance.Visible = false
        end
    end)

    return success
end

function HyperVMarker:Show(instance: Instance): boolean
    local entry = self:GetByInstance(instance)
    if not entry then return false end

    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            instance.Visible = true
        end
    end)

    return success
end

function HyperVMarker:Enable(instance: Instance): boolean
    local entry = self:GetByInstance(instance)
    if not entry then return false end

    local success, err = pcall(function()
        if instance:IsA("GuiObject") or instance:IsA("TextButton") or instance:IsA("ImageButton") then
            instance.Active = true
        end
        if instance:IsA("Frame") or instance:IsA("ScrollingFrame") then
            instance.Visible = true
        end
    end)

    return success
end

function HyperVMarker:Disable(instance: Instance): boolean
    local entry = self:GetByInstance(instance)
    if not entry then return false end

    local success, err = pcall(function()
        if instance:IsA("GuiObject") or instance:IsA("TextButton") or instance:IsA("ImageButton") then
            instance.Active = false
        end
    end)

    return success
end

function HyperVMarker:IsVisible(instance: Instance): boolean?
    local entry = self:GetByInstance(instance)
    if not entry then return nil end

    local success, result = pcall(function()
        if instance:IsA("GuiObject") then
            return instance.Visible
        end
        return nil
    end)

    return success and result
end

function HyperVMarker:IsEnabled(instance: Instance): boolean?
    local entry = self:GetByInstance(instance)
    if not entry then return nil end

    local success, result = pcall(function()
        if instance:IsA("GuiObject") then
            return instance.Active ~= false
        end
        return nil
    end)

    return success and result
end

function HyperVMarker:SetVisible(instance: Instance, visible: boolean): boolean
    local entry = self:GetByInstance(instance)
    if not entry then return false end

    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            instance.Visible = visible
        end
    end)

    return success
end

function HyperVMarker:SetEnabled(instance: Instance, enabled: boolean): boolean
    local entry = self:GetByInstance(instance)
    if not entry then return false end

    local success, err = pcall(function()
        if instance:IsA("GuiObject") or instance:IsA("TextButton") or instance:IsA("ImageButton") then
            instance.Active = enabled
        end
    end)

    return success
end

function HyperVMarker:GetParent(instance: Instance): Instance?
    local entry = self:GetByInstance(instance)
    if not entry then return nil end

    local success, result = pcall(function()
        return instance.Parent
    end)

    return success and result
end

function HyperVMarker:SetParent(instance: Instance, parent: Instance): boolean
    local entry = self:GetByInstance(instance)
    if not entry then return false end

    local success, err = pcall(function()
        instance.Parent = parent
        entry.Parent = parent  -- Update registry
    end)

    return success
end

-- ===== BATCH OPERATIONS =====

function HyperVMarker:HideByTag(tag: string): number
    local entries = self:GetByTag(tag)
    local count = 0

    for _, entry in ipairs(entries) do
        if self:Hide(entry.Instance) then
            count = count + 1
        end
    end

    return count
end

function HyperVMarker:ShowByTag(tag: string): number
    local entries = self:GetByTag(tag)
    local count = 0

    for _, entry in ipairs(entries) do
        if self:Show(entry.Instance) then
            count = count + 1
        end
    end

    return count
end

function HyperVMarker:DisableByTag(tag: string): number
    local entries = self:GetByTag(tag)
    local count = 0

    for _, entry in ipairs(entries) do
        if self:Disable(entry.Instance) then
            count = count + 1
        end
    end

    return count
end

function HyperVMarker:EnableByTag(tag: string): number
    local entries = self:GetByTag(tag)
    local count = 0

    for _, entry in ipairs(entries) do
        if self:Enable(entry.Instance) then
            count = count + 1
        end
    end

    return count
end

-- ===== AUTO CLEANUP =====

function HyperVMarker:StartAutoCleanup(interval: number?)
    if self.IsRunning then return end
    
    self.IsRunning = true
    local cleanupInterval = interval or self.Config.CleanupInterval
    
    self.CleanupTask = task.spawn(function()
        while self.IsRunning do
            task.wait(cleanupInterval)
            
            if not self.IsRunning then break end
            
            -- Sweep invalid instances first
            self:SweepInvalid()
            
            -- Sweep old instances
            self:SweepByAge(self.Config.MaxAge)
            
            -- Warning if too many
            local count = self:Count()
            if count > 100 and self.OnWarning then
                pcall(self.OnWarning, count)
            end
        end
    end)
end

function HyperVMarker:StopAutoCleanup()
    self.IsRunning = false
    if self.CleanupTask then
        task.cancel(self.CleanupTask)
        self.CleanupTask = nil
    end
end

-- ===== STATS =====

function HyperVMarker:GetStats()
    return {
        totalMarked = self.Stats.TotalMarked,
        totalCleaned = self.Stats.TotalCleaned,
        current = self:Count(),
        peak = self.Stats.Peak,
        running = self.IsRunning,
    }
end

function HyperVMarker:ResetStats()
    self.Stats = {
        TotalMarked = 0,
        TotalCleaned = 0,
        Peak = 0,
    }
end

-- ===== CALLBACKS =====

function HyperVMarker:OnMark(callback: (instance: Instance, key: number) -> ())
    self.OnMark = callback
end

function HyperVMarker:OnClean(callback: (instance: Instance) -> ())
    self.OnClean = callback
end

function HyperVMarker:OnWarning(callback: (count: number) -> ())
    self.OnWarning = callback
end

-- ===== DESTROY =====

function HyperVMarker:Destroy()
    self:StopAutoCleanup()
    self:SweepAll()
    self.Registry = {}
    self.InstanceToKey = {}
    instance = nil
end

return HyperVMarker


