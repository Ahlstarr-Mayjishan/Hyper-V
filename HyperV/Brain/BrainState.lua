--!strict

local BrainState = {}
BrainState.__index = BrainState

local function deepClone(value: any): any
	if type(value) ~= "table" then
		return value
	end

	local clone = {}
	for key, child in pairs(value) do
		clone[key] = deepClone(child)
	end
	return clone
end

local function deepMerge(baseValue: any, patchValue: any): any
	if type(baseValue) ~= "table" or type(patchValue) ~= "table" then
		return deepClone(patchValue)
	end

	local result = deepClone(baseValue)
	for key, value in pairs(patchValue) do
		result[key] = deepMerge(result[key], value)
	end
	return result
end

function BrainState.new()
	local self = setmetatable({}, BrainState)
	self._surfaces = {} :: { [string]: any }
	self._focusedSurfaceId = nil :: string?
	self._activeModalId = nil :: string?
	self._preview = {} :: { [string]: { config: any?, committed: any?, target: Model? } }
	self._dock = {} :: { [string]: { targetId: string? } }
	return self
end

function BrainState:registerSurface(id: string, surfaceData: any)
	self._surfaces[id] = deepClone(surfaceData)
end

function BrainState:unregisterSurface(id: string)
	local existing = self._surfaces[id]
	self._surfaces[id] = nil
	if self._focusedSurfaceId == id then
		self._focusedSurfaceId = nil
	end
	if existing and existing.kind == "modal" and self._activeModalId == id then
		self._activeModalId = nil
	end
end

function BrainState:focusSurface(id: string)
	self._focusedSurfaceId = id
	local surface = self._surfaces[id]
	if surface and surface.kind == "modal" then
		self._activeModalId = id
	end
end

function BrainState:setPreviewConfig(sourceId: string, config: any)
	local state = self._preview[sourceId] or {}
	state.config = deepClone(config)
	self._preview[sourceId] = state
end

function BrainState:patchPreview(sourceId: string, patch: any)
	local state = self._preview[sourceId] or {}
	state.config = deepMerge(state.config or {}, patch)
	self._preview[sourceId] = state
end

function BrainState:commitPreview(sourceId: string, snapshot: any)
	local state = self._preview[sourceId] or {}
	state.committed = deepClone(snapshot)
	self._preview[sourceId] = state
end

function BrainState:setPreviewTarget(sourceId: string, model: Model?)
	local state = self._preview[sourceId] or {}
	state.target = model
	self._preview[sourceId] = state
end

function BrainState:dockAttach(handleId: string, targetId: string)
	self._dock[handleId] = {
		targetId = targetId,
	}
end

function BrainState:dockDetach(handleId: string)
	self._dock[handleId] = nil
end

function BrainState:getActiveModalId(): string?
	return self._activeModalId
end

function BrainState:getFocusedSurfaceId(): string?
	return self._focusedSurfaceId
end

function BrainState:snapshot()
	return {
		surfaces = deepClone(self._surfaces),
		focusedSurfaceId = self._focusedSurfaceId,
		activeModalId = self._activeModalId,
		preview = deepClone(self._preview),
		dock = deepClone(self._dock),
	}
end

return BrainState
