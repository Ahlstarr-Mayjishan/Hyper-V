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

local function parsePolicyReason(reason: any): (string?, string?)
	if type(reason) ~= "string" then
		return nil, nil
	end

	local policyCode, message = string.match(reason, "^policy%.([%w_]+):%s*(.+)$")
	if policyCode then
		return policyCode, message
	end

	return nil, reason
end

function SystemBrain.new()
	local self = setmetatable({}, SystemBrain)
	self._state = BrainState.new()
	self._runtime = BrainRuntime.new()
	self._authority = nil
	self._history = {} :: { any }
	self._maxHistory = 80
	self._diagnostics = {
		lastIntent = nil,
		lastBlocked = nil,
		policyCounts = {} :: { [string]: number },
		recentBlocked = {} :: { any },
	}
	return self
end

function SystemBrain:attachAuthority(authority)
	self._authority = authority
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
	elseif command.type == "state.surface.visible" then
		self._state:setSurfaceVisible(payload.id, payload.visible)
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
	local policyCode, policyMessage = parsePolicyReason(resolution.reason)
	self._diagnostics.lastIntent = {
		type = intent.type,
		sourceId = intent.sourceId,
		allowed = resolution.allowed,
		policyCode = policyCode,
		policyMessage = policyMessage,
	}
	if not resolution.allowed then
		if policyCode then
			self._diagnostics.policyCounts[policyCode] = (self._diagnostics.policyCounts[policyCode] or 0) + 1
		end
		self._diagnostics.lastBlocked = self._diagnostics.lastIntent
		table.insert(self._diagnostics.recentBlocked, 1, self._diagnostics.lastIntent)
		while #self._diagnostics.recentBlocked > 12 do
			table.remove(self._diagnostics.recentBlocked)
		end
	end
	table.insert(self._history, {
		intent = intent,
		allowed = resolution.allowed,
		reason = resolution.reason,
		policyCode = policyCode,
		policyMessage = policyMessage,
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

function SystemBrain:getAuthoritySnapshot()
	if self._authority and self._authority.getClaimsSnapshot then
		return self._authority:getClaimsSnapshot()
	end
	return {
		focus = nil,
		claims = {},
	}
end

function SystemBrain:getLastIntents(limit: number?)
	local count = limit or #self._history
	local result = {}
	for index = math.max(1, #self._history - count + 1), #self._history do
		table.insert(result, self._history[index])
	end
	return result
end

function SystemBrain:getDiagnosticsSnapshot()
	local policyCounts = {}
	for key, value in pairs(self._diagnostics.policyCounts) do
		policyCounts[key] = value
	end

	local recentBlocked = {}
	for _, entry in ipairs(self._diagnostics.recentBlocked) do
		table.insert(recentBlocked, {
			type = entry.type,
			sourceId = entry.sourceId,
			allowed = entry.allowed,
			policyCode = entry.policyCode,
			policyMessage = entry.policyMessage,
		})
	end

	return {
		lastIntent = self._diagnostics.lastIntent,
		lastBlocked = self._diagnostics.lastBlocked,
		policyCounts = policyCounts,
		recentBlocked = recentBlocked,
	}
end

return SystemBrain
