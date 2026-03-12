--[[
    IncrementalStrategy - Chia nhỏ cleanup mỗi frame để tránh lag
    Single Responsibility: Xử lý cleanup từng bước, không lag game

    ZERO LAG OPTIMIZATIONS:
    - Time Budget: Giới hạn thời gian mỗi frame (2ms)
    - Batch Limits: Giới hạn items mỗi frame/second
    - Smart Queueing: Không rebuild queue mỗi frame
    - Yield Points: Nghỉ giữa các batch lớn
    - Priority Sorting: Ưu tiên oldest đầu tiên
    - Background Processing: Tách ra task riêng không block
]]

local RunService = game:GetService("RunService")

local IncrementalStrategy = {}
IncrementalStrategy.__index = IncrementalStrategy

export type CleanupBatch = {
    Ids: {string},
    Collected: number,
    Skipped: number,
    TimeSpent: number,
}

function IncrementalStrategy.new()
    local self = setmetatable({}, IncrementalStrategy)

    -- ZERO LAG SETTINGS
    self.MaxPerFrame = 3              -- Max 3 items/frame (very conservative)
    self.MaxPerSecond = 15            -- Max 15 items/second
    self.MaxBatchTime = 0.002         -- 2ms max per frame (leave 16ms for game)
    self.YieldAfterItems = 10         -- Yield sau 10 items (nếu batch lớn)
    self.UseRenderStep = true         -- Dùng RenderStep thay vì task.wait
    self.EnableBatching = true        -- Bật batch mode

    -- State
    self.Queue = {} :: {string}
    self.QueuedSet = {} :: {string: boolean}  -- Fast lookup
    self.PriorityQueue = {} :: {string}  -- Sorted by priority
    self.CurrentIndex = 1
    self.Processing = false
    self.LastFrameTime = os.clock()
    self.FrameCount = 0
    self.SecondCount = 0
    self.CollectedThisFrame = 0
    self.CollectedThisSecond = 0
    self.LastQueueRebuild = 0
    self.QueueRebuildInterval = 1.0   -- Rebuild queue mỗi 1 giây

    -- Callbacks
    self.CollectorFunc = nil :: ((id: string) -> boolean)?
    self.ShouldCollectFunc = nil :: ((entry: any) -> boolean)?

    -- Stats
    self.TotalCollected = 0
    self.TotalSkipped = 0
    self.TotalTimeSpent = 0
    self.LagEvents = 0

    return self
end

function IncrementalStrategy:SetCollector(collectorFunc: (id: string) -> boolean)
    self.CollectorFunc = collectorFunc
end

function IncrementalStrategy:SetShouldCollect(shouldCollectFunc: (entry: any) -> boolean)
    self.ShouldCollectFunc = shouldCollectFunc
end

-- Tối ưu: Chỉ thêm items mới, không rebuild cả queue
function IncrementalStrategy:AddToQueue(entries: {any})
    local currentTime = os.clock()

    -- Rebuild queue định kỳ (không phải mỗi frame!)
    if currentTime - self.LastQueueRebuild > self.QueueRebuildInterval then
        self:RebuildPriorityQueue(entries)
        self.LastQueueRebuild = currentTime
        return
    end

    -- Chỉ thêm items mới chưa có trong queue
    for id, entry in pairs(entries) do
        if not self.QueuedSet[id] then
            local shouldAdd = true
            if self.ShouldCollectFunc then
                shouldAdd = self.ShouldCollectFunc(entry)
            end

            if shouldAdd then
                table.insert(self.Queue, id)
                self.QueuedSet[id] = true
            end
        end
    end
end

-- Rebuild priority queue (chỉ gọi định kỳ)
function IncrementalStrategy:RebuildPriorityQueue(entries: {any})
    -- Clear
    self.Queue = {}
    self.QueuedSet = {}

    -- Collect candidates
    local candidates = {}
    for id, entry in pairs(entries) do
        local shouldAdd = true
        if self.ShouldCollectFunc then
            shouldAdd = self.ShouldCollectFunc(entry)
        end

        if shouldAdd then
            table.insert(candidates, {
                Id = id,
                LastUsed = entry.LastUsed or 0,
                Priority = entry.Priority or 0,
            })
        end
    end

    -- Sort by priority (oldest first = lowest LastUsed)
    table.sort(candidates, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority  -- Higher priority first
        end
        return a.LastUsed < b.LastUsed  -- Older first
    end)

    -- Build queue
    for _, item in ipairs(candidates) do
        table.insert(self.Queue, item.Id)
        self.QueuedSet[item.Id] = true
    end
end

function IncrementalStrategy:ClearQueue()
    self.Queue = {}
    self.QueuedSet = {}
    self.CurrentIndex = 1
end

-- Main frame process với time budget
function IncrementalStrategy:ProcessFrame(entries: {any}): CleanupBatch
    local batch = {
        Ids = {},
        Collected = 0,
        Skipped = 0,
        TimeSpent = 0,
    }

    if not self.CollectorFunc then
        return batch
    end

    local startTime = os.clock()
    local currentTime = startTime

    -- Track frame/second
    if currentTime - self.LastFrameTime >= 1 then
        self.SecondCount = self.SecondCount + 1
        self.CollectedThisSecond = 0
        self.LastFrameTime = currentTime
    end

    -- Check limits
    if self.CollectedThisFrame >= self.MaxPerFrame then
        return batch
    end

    if self.CollectedThisSecond >= self.MaxPerSecond then
        return batch
    end

    -- Process queue
    local queueLen = #self.Queue
    local processed = 0

    for i = self.CurrentIndex, queueLen do
        -- TIME BUDGET CHECK - Dừng nếu quá thời gian
        currentTime = os.clock()
        local elapsed = currentTime - startTime

        if elapsed >= self.MaxBatchTime then
            -- Gần lag, dừng sớm
            self.CurrentIndex = i
            self.LagEvents = self.LagEvents + 1
            break
        end

        -- FRAME LIMIT CHECK
        if self.CollectedThisFrame >= self.MaxPerFrame then
            self.CurrentIndex = i
            break
        end

        -- SECOND LIMIT CHECK
        if self.CollectedThisSecond >= self.MaxPerSecond then
            self.CurrentIndex = i
            break
        end

        local id = self.Queue[i]
        if id then
            -- Verify entry still exists and should be collected
            local entry = entries[id]
            if entry and (not self.ShouldCollectFunc or self.ShouldCollectFunc(entry)) then
                local success = self.CollectorFunc(id)
                if success then
                    batch.Collected = batch.Collected + 1
                    batch.Ids[#batch.Ids + 1] = id
                    self.CollectedThisFrame = self.CollectedThisFrame + 1
                    self.CollectedThisSecond = self.CollectedThisSecond + 1
                    self.TotalCollected = self.TotalCollected + 1

                    -- Remove from queue set
                    self.QueuedSet[id] = nil
                end
            else
                -- Entry gone or no longer valid
                self.QueuedSet[id] = nil
            end
        end

        processed = processed + 1

        -- YIELD POINT - Nghỉ sau nhiều items liên tiếp
        if processed >= self.YieldAfterItems then
            -- Schedule next batch
            self.CurrentIndex = i + 1
            processed = 0
            break
        end
    end

    -- Reset index if queue exhausted
    if self.CurrentIndex > queueLen then
        self.CurrentIndex = 1
    end

    batch.TimeSpent = (os.clock() - startTime) * 1000  -- ms
    self.TotalTimeSpent = self.TotalTimeSpent + batch.TimeSpent

    return batch
end

-- Process in background (non-blocking)
function IncrementalStrategy:ProcessInBackground(entries: {any}, onComplete: (() -> ())?)
    task.spawn(function()
        local batch = self:ProcessFrame(entries)

        if onComplete then
            onComplete()
        end
    end)
end

function IncrementalStrategy:IsQueueEmpty(): boolean
    return #self.Queue == 0 or self.CurrentIndex > #self.Queue
end

function IncrementalStrategy:GetQueueSize(): number
    return #self.Queue - self.CurrentIndex + 1
end

function IncrementalStrategy:GetStats()
    return {
        queueSize = self:GetQueueSize(),
        collectedThisFrame = self.CollectedThisFrame,
        collectedThisSecond = self.CollectedThisSecond,
        totalCollected = self.TotalCollected,
        totalSkipped = self.TotalSkipped,
        totalTimeSpent = self.TotalTimeSpent,
        lagEvents = self.LagEvents,
        maxPerFrame = self.MaxPerFrame,
        maxPerSecond = self.MaxPerSecond,
        maxBatchTime = self.MaxBatchTime * 1000,  -- Convert to ms
    }
end

-- Reset per-frame counters (gọi mỗi frame)
function IncrementalStrategy:ResetFrameCounters()
    self.CollectedThisFrame = 0
end

-- Adjust settings based on lag detection
function IncrementalStrategy:OnLagDetected()
    -- Giảm batch size nếu phát hiện lag
    self.MaxPerFrame = math.max(1, self.MaxPerFrame - 1)
    self.MaxBatchTime = self.MaxBatchTime * 0.8
    self.YieldAfterItems = math.max(5, self.YieldAfterItems - 2)
end

-- Adjust settings when performance is good
function IncrementalStrategy:OnPerformanceGood()
    -- Tăng batch size nếu performance tốt
    if self.LagEvents == 0 and self.TotalTimeSpent < self.MaxBatchTime * 100 then
        self.MaxPerFrame = math.min(5, self.MaxPerFrame + 1)
        self.MaxBatchTime = math.min(0.005, self.MaxBatchTime * 1.1)
    end
end

return IncrementalStrategy
                    -- Collect
                    if self.CollectorFunc(id) then
                        batch.Collected = batch.Collected + 1
                        self.TotalCollected = self.TotalCollected + 1
                        self.CollectedThisFrame = self.CollectedThisFrame + 1
                        self.CollectedThisSecond = self.CollectedThisSecond + 1
                        table.insert(batch.Ids, id)
                    end
                else
                    batch.Skipped = batch.Skipped + 1
                    self.TotalSkipped = self.TotalSkipped + 1
                end
            else
                -- No should collect func, collect anyway
                if self.CollectorFunc(id) then
                    batch.Collected = batch.Collected + 1
                    self.TotalCollected = self.TotalCollected + 1
                    self.CollectedThisFrame = self.CollectedThisFrame + 1
                    self.CollectedThisSecond = self.CollectedThisSecond + 1
                    table.insert(batch.Ids, id)
                end
            end
        end
        
        -- Remove from queue
        table.remove(self.Queue, self.CurrentIndex)
        processed = processed + 1
        
        -- Check batch time limit
        if os.clock() - batchStartTime >= self.MaxBatchTime then
            break
        end
    end
    
    return batch
end

function IncrementalStrategy:ProcessAll(entries: {any}, maxPerFrame: number?): number
    local total = 0
    local oldMaxPerFrame = self.MaxPerFrame
    
    if maxPerFrame then
        self.MaxPerFrame = maxPerFrame
    end
    
    -- Process until queue is empty or entries are gone
    while #self.Queue > 0 do
        local batch = self:ProcessFrame(entries)
        total = total + batch.Collected
        
        -- Safety: prevent infinite loop
        if batch.Collected == 0 and batch.Skipped == 0 then
            break
        end
        
        -- Yield to prevent blocking
        task.wait()
    end
    
    self.MaxPerFrame = oldMaxPerFrame
    return total
end

function IncrementalStrategy:GetQueueSize(): number
    return #self.Queue
end

function IncrementalStrategy:IsQueueEmpty(): boolean
    return #self.Queue == 0
end

function IncrementalStrategy:SetMaxPerFrame(max: number)
    self.MaxPerFrame = max
end

function IncrementalStrategy:SetMaxPerSecond(max: number)
    self.MaxPerSecond = max
end

function IncrementalStrategy:GetStats()
    return {
        queueSize = #self.Queue,
        collectedThisFrame = self.CollectedThisFrame,
        collectedThisSecond = self.CollectedThisSecond,
        totalCollected = self.TotalCollected,
        totalSkipped = self.TotalSkipped,
        maxPerFrame = self.MaxPerFrame,
        maxPerSecond = self.MaxPerSecond,
    }
end

function IncrementalStrategy:ResetStats()
    self.TotalCollected = 0
    self.TotalSkipped = 0
    self.CollectedThisFrame = 0
    self.CollectedThisSecond = 0
end

return IncrementalStrategy

