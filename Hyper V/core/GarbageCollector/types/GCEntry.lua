--[[
    GCEntry - Data structure for tracked objects
    Single Responsibility: Chỉ định nghĩa cấu trúc dữ liệu cho mỗi entry
]]

local GCEntry = {}
GCEntry.__index = GCEntry

export type GCEntryType = {
    Id: string,
    Element: Instance?,
    Type: string,
    CreatedAt: number,
    LastUsed: number,
    Refs: number,
    AutoCleanup: boolean,
    OnCleanup: ((element: Instance?, customData: any) -> ())?,
    CustomData: any,
    Generation: number,
    Marked: boolean,
}

function GCEntry.new(config: {
    Id: string?,
    Element: Instance?,
    Type: string?,
    AutoCleanup: boolean?,
    OnCleanup: ((element: Instance?, customData: any) -> ())?,
    CustomData: any?,
}): GCEntryType
    local self = setmetatable({}, GCEntry)
    
    self.Id = config.Id or ("Element_" .. tostring(os.time()) .. "_" .. math.random(1000, 9999))
    self.Element = config.Element
    self.Type = config.Type or "Generic"
    self.CreatedAt = os.time()
    self.LastUsed = os.time()
    self.Refs = 0
    self.AutoCleanup = config.AutoCleanup ~= false
    self.OnCleanup = config.OnCleanup
    self.CustomData = config.CustomData or {}
    self.Generation = 0  -- Generational GC support
    self.Marked = false  -- Mark & Sweep support
    
    return self :: any
end

function GCEntry:Touch()
    self.LastUsed = os.time()
end

function GCEntry:AddRef(count: number?)
    self.Refs = self.Refs + (count or 1)
end

function GCEntry:ReleaseRef(count: number?)
    self.Refs = math.max(0, self.Refs - (count or 1))
end

function GCEntry:IsIdle(idleThreshold: number): boolean
    return (os.time() - self.LastUsed) > idleThreshold
end

function GCEntry:GetAge(): number
    return os.time() - self.CreatedAt
end

function GCEntry:CanCleanup(): boolean
    return self.AutoCleanup and self.Refs <= 0
end

function GCEntry:Mark()
    self.Marked = true
end

function GCEntry:Unmark()
    self.Marked = false
end

function GCEntry:Promote()
    -- Move to next generation (less frequent cleanup)
    self.Generation = math.min(self.Generation + 1, 2)
end

function GCEntry:Reset()
    self.Marked = false
    self.Generation = 0
end

return GCEntry

