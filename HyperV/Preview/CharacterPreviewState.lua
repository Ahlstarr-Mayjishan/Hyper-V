--!strict

local Serializer = require(script.Parent.CharacterPreviewSerializer)

local CharacterPreviewState = {}
CharacterPreviewState.__index = CharacterPreviewState

function CharacterPreviewState.new(initialConfig: any)
	local self = setmetatable({}, CharacterPreviewState)
	self._defaults = Serializer.getDefaults()
	self._config = Serializer.normalize(initialConfig)
	self._listeners = {}
	return self
end

function CharacterPreviewState:getConfig()
	return Serializer.snapshot(self._config)
end

function CharacterPreviewState:update(patch)
	self._config = Serializer.normalize(Serializer.merge(self._config, patch or {}))
	self:_emit()
	return self:getConfig()
end

function CharacterPreviewState:setConfig(config)
	self._config = Serializer.normalize(config)
	self:_emit()
	return self:getConfig()
end

function CharacterPreviewState:reset()
	self._config = Serializer.snapshot(self._defaults)
	self:_emit()
	return self:getConfig()
end

function CharacterPreviewState:subscribe(listener)
	table.insert(self._listeners, listener)
	return function()
		for index, candidate in ipairs(self._listeners) do
			if candidate == listener then
				table.remove(self._listeners, index)
				break
			end
		end
	end
end

function CharacterPreviewState:_emit()
	local snapshot = self:getConfig()
	for _, listener in ipairs(self._listeners) do
		listener(snapshot)
	end
end

return CharacterPreviewState
