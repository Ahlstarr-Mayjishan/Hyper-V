--!strict

local DockRegistry = {}
DockRegistry.__index = DockRegistry

function DockRegistry.new()
	return setmetatable({
		targets = {},
	}, DockRegistry)
end

function DockRegistry:registerTarget(id: string, target)
	local registry = self :: any
	registry.targets[id] = target
end

function DockRegistry:unregisterTarget(id: string)
	local registry = self :: any
	registry.targets[id] = nil
end

function DockRegistry:listTargets()
	local registry = self :: any
	local result = {}
	for id, target in pairs(registry.targets) do
		table.insert(result, {
			Id = id,
			Name = target.title or id,
			Title = target.title or id,
			target = target,
		})
	end
	table.sort(result, function(left, right)
		return left.Title < right.Title
	end)
	return result
end

function DockRegistry:dock(handle, targetId: string)
	local registry = self :: any
	local target = registry.targets[targetId]
	if not target then
		return
	end
	target:attach(handle)
end

function DockRegistry:undock(handle)
	local state = handle._dockState
	if not state then
		return
	end

	if state.panel and state.panel.remove then
		state.panel:remove(handle)
	end
end

return DockRegistry
