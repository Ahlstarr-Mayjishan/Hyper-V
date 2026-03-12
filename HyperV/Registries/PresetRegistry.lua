--!strict

local HttpService = game:GetService("HttpService")

export type PresetHandle = {
	id: string,
	kind: string,
	getPresetValue: ((self: any) -> any)?,
	applyPresetValue: ((self: any, value: any) -> ())?,
}

local PresetRegistry = {}
PresetRegistry.__index = PresetRegistry

function PresetRegistry.new()
	return setmetatable({
		_entries = {},
		_presets = {},
	}, PresetRegistry)
end

function PresetRegistry:register(handle: PresetHandle)
	if not handle.id or not handle.getPresetValue or not handle.applyPresetValue then
		return
	end

	local registry = self :: any
	registry._entries[handle.id] = handle
end

function PresetRegistry:collect()
	local registry = self :: any
	local snapshot = {}
	for id, handle in pairs(registry._entries) do
		local ok, value = pcall(function()
			return (handle :: any):getPresetValue()
		end)
		if ok then
			snapshot[id] = value
		end
	end
	return snapshot
end

function PresetRegistry:apply(snapshot)
	local registry = self :: any
	for id, value in pairs(snapshot or {}) do
		local handle = registry._entries[id]
		if handle and handle.applyPresetValue then
			pcall(function()
				(handle :: any):applyPresetValue(value)
			end)
		end
	end
end

function PresetRegistry:save(name: string)
	local registry = self :: any
	registry._presets[name] = self:collect()
end

function PresetRegistry:load(name: string)
	local registry = self :: any
	self:apply(registry._presets[name])
end

function PresetRegistry:export(name: string): string
	local registry = self :: any
	return HttpService:JSONEncode({
		name = name,
		state = registry._presets[name] or {},
	})
end

function PresetRegistry:import(name: string, payload: string): boolean
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(payload)
	end)
	if not ok or type(decoded) ~= "table" then
		return false
	end
	local registry = self :: any
	registry._presets[name] = decoded.state or {}
	return true
end

function PresetRegistry:list(): { string }
	local registry = self :: any
	local names = {}
	for name in pairs(registry._presets) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return PresetRegistry
