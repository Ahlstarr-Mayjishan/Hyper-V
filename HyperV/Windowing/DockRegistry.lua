--!strict

local DockRegistry = {}
DockRegistry.__index = DockRegistry

function DockRegistry.new(protectionGate, brain)
	return setmetatable({
		targets = {},
		_protectionGate = protectionGate,
		_brain = brain,
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

	local apply = function()
		local gate = registry._protectionGate
		if not gate then
			target:attach(handle)
			return
		end

		gate:execute("dock.attach", {
			sourceId = handle.id,
			handle = handle,
			targetId = targetId,
			target = target,
		}, function(request)
			request.target:attach(request.handle)
		end)
	end

	if registry._brain then
		registry._brain:dispatch({
			type = "dock.attach",
			sourceId = handle.id,
			handleId = handle.id,
			targetId = targetId,
			apply = apply,
		})
		return
	end

	apply()
end

function DockRegistry:undock(handle)
	local state = handle._dockState
	if not state then
		return
	end

	local registry = self :: any
	local apply = function()
		local gate = registry._protectionGate
		if gate then
			gate:execute("dock.detach", {
				sourceId = handle.id,
				handle = handle,
			}, function(request)
				local dockState = request.handle._dockState
				if dockState and dockState.panel and dockState.panel.remove then
					dockState.panel:remove(request.handle)
				end
			end)
			return
		end

		if state.panel and state.panel.remove then
			state.panel:remove(handle)
		end
	end

	if registry._brain then
		registry._brain:dispatch({
			type = "dock.detach",
			sourceId = handle.id,
			handleId = handle.id,
			apply = apply,
		})
		return
	end

	apply()
end

return DockRegistry
