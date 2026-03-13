--!strict

local BrainState = require(script.Parent.BrainState)
local BrainResolver = require(script.Parent.BrainResolver)
local BrainRuntime = require(script.Parent.BrainRuntime)

local SystemBrain = {}
SystemBrain.__index = SystemBrain

local function trimHistory(history, limit)
	while #history > limit do
		table.remove(history, 1)
	end
end

function SystemBrain.new()
	local self = setmetatable({}, SystemBrain)
	self._state = BrainState.new()
	self._runtime = BrainRuntime.new()
	self._history = {} :: { any }
	self._maxHistory = 80
	return self
end

function SystemBrain:registerHandler(commandType: string, handler: (any) -> any)
	self._runtime:register(commandType, handler)
end

function SystemBrain:_applyStateCommand(command)
	local payload = command.payload

	if command.type == "state.surface.register" then
		self._state:registerSurface(payload.id, payload)
	elseif command.type == "state.surface.unregister" then
		self._state:unregisterSurface(payload.id)
	elseif command.type == "state.surface.focus" then
		self._state:focusSurface(payload.id)
	elseif command.type == "state.preview.patch" then
		self._state:patchPreview(payload.sourceId, payload.patch)
	elseif command.type == "state.preview.set" then
		self._state:setPreviewConfig(payload.sourceId, payload.config)
	elseif command.type == "state.preview.commit" then
		self._state:commitPreview(payload.sourceId, payload.snapshot)
	elseif command.type == "state.preview.target" then
		self._state:setPreviewTarget(payload.sourceId, payload.model)
	elseif command.type == "state.dock.attach" then
		self._state:dockAttach(payload.handleId, payload.targetId)
	elseif command.type == "state.dock.detach" then
		self._state:dockDetach(payload.handleId)
	end
end

function SystemBrain:dispatch(intent)
	local resolution = BrainResolver.resolve(self._state:snapshot(), intent)
	table.insert(self._history, {
		intent = intent,
		allowed = resolution.allowed,
		reason = resolution.reason,
	})
	trimHistory(self._history, self._maxHistory)

	if not resolution.allowed then
		return nil, resolution.reason
	end

	local runtimeResult = nil
	for _, command in ipairs(resolution.commands) do
		if string.sub(command.type, 1, 6) == "state." then
			self:_applyStateCommand(command)
		else
			local result = self._runtime:execute(command)
			if result ~= nil then
				runtimeResult = result
			end
		end
	end

	if runtimeResult ~= nil then
		return runtimeResult, nil
	end

	return true, nil
end

function SystemBrain:getStateSnapshot()
	return self._state:snapshot()
end

function SystemBrain:getLastIntents(limit: number?)
	local count = limit or #self._history
	local result = {}
	for index = math.max(1, #self._history - count + 1), #self._history do
		table.insert(result, self._history[index])
	end
	return result
end

return SystemBrain
