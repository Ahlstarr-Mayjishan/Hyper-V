--!strict

local DockRegistry = {}
DockRegistry.__index = DockRegistry

function DockRegistry.new()
	return setmetatable({
		targets = {},
	}, DockRegistry)
end

function DockRegistry:registerTarget(id: string, target)
	(self :: any).targets[id] = target
end

function DockRegistry:unregisterTarget(id: string)
	(self :: any).targets[id] = nil
end

function DockRegistry:listTargets()
	local result = {}
	for id, target in pairs((self :: any).targets) do
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
	local target = (self :: any).targets[targetId]
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
