--[[
    IncrementalStrategy - Chia nho cleanup moi frame de tranh lag
    Single Responsibility: Xu ly cleanup tung buoc, khong lag game

    ZERO LAG OPTIMIZATIONS:
    - Time Budget: Gioi han thoi gian moi frame (2ms)
    - Batch Limits: Gioi han items moi frame/second
    - Smart Queueing: Khong rebuild queue moi frame
    - Yield Points: Nghi giua cac batch lon
    - Priority Sorting: Uu tien oldest dau tien
    - Background Processing: Tach ra task rieng khong block
]]

local RunService = game:GetService("RunService")

local IncrementalStrategy = {}
IncrementalStrategy.__index = IncrementalStrategy

export type CleanupBatch = {
	Ids: { string },
	Collected: number,
	Skipped: number,
	TimeSpent: number,
}

function IncrementalStrategy.new()
	local self = setmetatable({}, IncrementalStrategy)

	self.MaxPerFrame = 3
	self.MaxPerSecond = 15
	self.MaxBatchTime = 0.002
	self.YieldAfterItems = 10
	self.UseRenderStep = true
	self.EnableBatching = true

	self.Queue = {} :: { string }
	self.QueuedSet = {} :: { [string]: boolean }
	self.PriorityQueue = {} :: { string }
	self.CurrentIndex = 1
	self.Processing = false
	self.LastFrameTime = os.clock()
	self.FrameCount = 0
	self.SecondCount = 0
	self.CollectedThisFrame = 0
	self.CollectedThisSecond = 0
	self.LastQueueRebuild = 0
	self.QueueRebuildInterval = 1.0

	self.CollectorFunc = nil :: ((id: string) -> boolean)?
	self.ShouldCollectFunc = nil :: ((entry: any) -> boolean)?

	self.TotalCollected = 0
	self.TotalSkipped = 0
	self.TotalTimeSpent = 0
	self.LagEvents = 0
	self.RenderConnection = nil :: RBXScriptConnection?

	return self
end

function IncrementalStrategy:SetCollector(collectorFunc: (id: string) -> boolean)
	self.CollectorFunc = collectorFunc
end

function IncrementalStrategy:SetShouldCollect(shouldCollectFunc: (entry: any) -> boolean)
	self.ShouldCollectFunc = shouldCollectFunc
end

function IncrementalStrategy:AddToQueue(entries: { [string]: any })
	local currentTime = os.clock()

	if currentTime - self.LastQueueRebuild > self.QueueRebuildInterval then
		self:RebuildPriorityQueue(entries)
		self.LastQueueRebuild = currentTime
		return
	end

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

function IncrementalStrategy:RebuildPriorityQueue(entries: { [string]: any })
	self.Queue = {}
	self.QueuedSet = {}

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

	table.sort(candidates, function(a, b)
		if a.Priority ~= b.Priority then
			return a.Priority > b.Priority
		end
		return a.LastUsed < b.LastUsed
	end)

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

function IncrementalStrategy:ProcessFrame(entries: { [string]: any }): CleanupBatch
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

	self.CollectedThisFrame = 0

	if currentTime - self.LastFrameTime >= 1 then
		self.SecondCount = self.SecondCount + 1
		self.CollectedThisSecond = 0
		self.LastFrameTime = currentTime
	end

	if self.CollectedThisSecond >= self.MaxPerSecond then
		return batch
	end

	local queueLen = #self.Queue
	local processed = 0

	for i = self.CurrentIndex, queueLen do
		currentTime = os.clock()
		local elapsed = currentTime - startTime

		if elapsed >= self.MaxBatchTime then
			self.CurrentIndex = i
			self.LagEvents = self.LagEvents + 1
			break
		end

		if self.CollectedThisFrame >= self.MaxPerFrame then
			self.CurrentIndex = i
			break
		end

		if self.CollectedThisSecond >= self.MaxPerSecond then
			self.CurrentIndex = i
			break
		end

		local id = self.Queue[i]
		if id then
			local entry = entries[id]
			if entry and (not self.ShouldCollectFunc or self.ShouldCollectFunc(entry)) then
				local success = self.CollectorFunc(id)
				if success then
					batch.Collected = batch.Collected + 1
					batch.Ids[#batch.Ids + 1] = id
					self.CollectedThisFrame = self.CollectedThisFrame + 1
					self.CollectedThisSecond = self.CollectedThisSecond + 1
					self.TotalCollected = self.TotalCollected + 1
					self.QueuedSet[id] = nil
				else
					batch.Skipped = batch.Skipped + 1
					self.TotalSkipped = self.TotalSkipped + 1
				end
			else
				batch.Skipped = batch.Skipped + 1
				self.TotalSkipped = self.TotalSkipped + 1
				self.QueuedSet[id] = nil
			end
		end

		processed = processed + 1

		if processed >= self.YieldAfterItems then
			self.CurrentIndex = i + 1
			processed = 0
			break
		end
	end

	if self.CurrentIndex > queueLen then
		self.CurrentIndex = 1
	end

	batch.TimeSpent = (os.clock() - startTime) * 1000
	self.TotalTimeSpent = self.TotalTimeSpent + batch.TimeSpent

	return batch
end

function IncrementalStrategy:ProcessInBackground(entries: { [string]: any }, onComplete: (() -> ())?)
	task.spawn(function()
		self:ProcessFrame(entries)

		if onComplete then
			onComplete()
		end
	end)
end

function IncrementalStrategy:ProcessAll(entries: { [string]: any }, maxPerFrame: number?): number
	local total = 0
	local oldMaxPerFrame = self.MaxPerFrame

	if maxPerFrame then
		self.MaxPerFrame = maxPerFrame
	end

	while not self:IsQueueEmpty() do
		local batch = self:ProcessFrame(entries)
		total = total + batch.Collected

		if batch.Collected == 0 and batch.Skipped == 0 then
			break
		end

		task.wait()
	end

	self.MaxPerFrame = oldMaxPerFrame
	return total
end

function IncrementalStrategy:IsQueueEmpty(): boolean
	return #self.Queue == 0 or self.CurrentIndex > #self.Queue
end

function IncrementalStrategy:GetQueueSize(): number
	return math.max(0, #self.Queue - self.CurrentIndex + 1)
end

function IncrementalStrategy:SetMaxPerFrame(max: number)
	self.MaxPerFrame = max
end

function IncrementalStrategy:SetMaxPerSecond(max: number)
	self.MaxPerSecond = max
end

function IncrementalStrategy:ResetFrameCounters()
	self.CollectedThisFrame = 0
end

function IncrementalStrategy:OnLagDetected()
	self.MaxPerFrame = math.max(1, self.MaxPerFrame - 1)
	self.MaxBatchTime = self.MaxBatchTime * 0.8
	self.YieldAfterItems = math.max(5, self.YieldAfterItems - 2)
end

function IncrementalStrategy:OnPerformanceGood()
	if self.LagEvents == 0 and self.TotalTimeSpent < self.MaxBatchTime * 100 then
		self.MaxPerFrame = math.min(5, self.MaxPerFrame + 1)
		self.MaxBatchTime = math.min(0.005, self.MaxBatchTime * 1.1)
	end
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
		maxBatchTime = self.MaxBatchTime * 1000,
		useRenderStep = self.UseRenderStep,
		batchingEnabled = self.EnableBatching,
		isRunning = self.Processing,
		runServiceActive = RunService:IsClient(),
	}
end

function IncrementalStrategy:ResetStats()
	self.TotalCollected = 0
	self.TotalSkipped = 0
	self.TotalTimeSpent = 0
	self.CollectedThisFrame = 0
	self.CollectedThisSecond = 0
	self.LagEvents = 0
	self.FrameCount = 0
	self.SecondCount = 0
	self.LastFrameTime = os.clock()
end

function IncrementalStrategy:Destroy()
	if self.RenderConnection then
		self.RenderConnection:Disconnect()
		self.RenderConnection = nil
	end

	self:ClearQueue()
	self.CollectorFunc = nil
	self.ShouldCollectFunc = nil
	self.Processing = false
end

return IncrementalStrategy
