--!strict

local SurfaceLifecyclePolicy = {}

local function deny(policyCode: string, message: string)
	return false, string.format("policy.%s: %s", policyCode, message), nil
end

local function makeCommand(commandType: string, payload: any)
	return {
		type = commandType,
		payload = payload,
	}
end

local function getIntentKind(intent)
	if intent.kind then
		return intent.kind
	end
	if intent.surface and intent.surface.kind then
		return intent.surface.kind
	end
	return nil
end

local function getRegisteredSurface(stateSnapshot, surfaceId: string?)
	if not surfaceId then
		return nil
	end
	return stateSnapshot.surfaces[surfaceId]
end

local function isLiveSurface(intent): boolean
	local surface = intent.surface
	if not surface then
		return false
	end
	if surface.view == nil then
		return false
	end
	if typeof(surface.view) ~= "Instance" then
		return false
	end
	return surface.view.Parent ~= nil
end

local function collectVisibleSurfaceIdsByKind(stateSnapshot, kind: string, excludeId: string?)
	local ids = {}
	for id, surface in pairs(stateSnapshot.surfaces) do
		if id ~= excludeId and surface.kind == kind and surface.visible == true then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

local function appendExclusiveCloseCommands(commands, stateSnapshot, kind: string, excludeId: string?)
	local existingIds = collectVisibleSurfaceIdsByKind(stateSnapshot, kind, excludeId)
	for _, id in ipairs(existingIds) do
		table.insert(commands, makeCommand("runtime.surface.close", {
			surfaceId = id,
		}))
		table.insert(commands, makeCommand("state.surface.visible", {
			id = id,
			visible = false,
		}))
	end
end

function SurfaceLifecyclePolicy.evaluate(stateSnapshot, intent)
	if intent.type == "surface.register" then
		return true, nil, {
			makeCommand("state.surface.register", {
				id = intent.surfaceId,
				kind = intent.kind or "surface",
				title = intent.title,
				priority = intent.priority or 0,
				visible = intent.visible,
			}),
		}
	end

	if intent.type == "surface.unregister" then
		return true, nil, {
			makeCommand("state.surface.unregister", {
				id = intent.surfaceId,
			}),
		}
	end

	if intent.type == "surface.activate" then
		local surfaceData = getRegisteredSurface(stateSnapshot, intent.surfaceId)
		if not surfaceData then
			return deny("surfaceUnknown", "Surface is not registered")
		end
		if intent.surface and not isLiveSurface(intent) then
			return deny("surfaceDisposed", "Surface view is no longer live")
		end
		if surfaceData.visible ~= true then
			return deny("surfaceHidden", "Cannot activate a hidden surface")
		end

		local commands = {}
		local kind = getIntentKind(intent) or surfaceData.kind
		if kind == "contextMenu" or kind == "dockMenu" then
			appendExclusiveCloseCommands(commands, stateSnapshot, kind, intent.surfaceId)
		end

		table.insert(commands, makeCommand("runtime.surface.activate", {
			surface = intent.surface,
			surfaceId = intent.surfaceId,
			priority = intent.priority,
		}))
		table.insert(commands, makeCommand("state.surface.focus", {
			id = intent.surfaceId,
		}))
		return true, nil, commands
	end

	if intent.type == "surface.open" then
		local surfaceData = getRegisteredSurface(stateSnapshot, intent.surfaceId)
		if not surfaceData then
			return deny("surfaceUnknown", "Surface is not registered")
		end
		if intent.surface and not isLiveSurface(intent) then
			return deny("surfaceDisposed", "Surface view is no longer live")
		end

		local commands = {}
		local kind = getIntentKind(intent) or surfaceData.kind
		if kind == "contextMenu" or kind == "dockMenu" then
			appendExclusiveCloseCommands(commands, stateSnapshot, kind, intent.surfaceId)
		end

		table.insert(commands, makeCommand("runtime.surface.open", {
			surface = intent.surface,
			surfaceId = intent.surfaceId,
		}))
		table.insert(commands, makeCommand("state.surface.visible", {
			id = intent.surfaceId,
			visible = true,
		}))
		return true, nil, commands
	end

	if intent.type == "surface.close" then
		local surfaceData = getRegisteredSurface(stateSnapshot, intent.surfaceId)
		if not surfaceData then
			return deny("surfaceUnknown", "Surface is not registered")
		end
		return true, nil, {
			makeCommand("runtime.surface.close", {
				surface = intent.surface,
				surfaceId = intent.surfaceId,
			}),
			makeCommand("state.surface.visible", {
				id = intent.surfaceId,
				visible = false,
			}),
		}
	end

	return nil, nil, nil
end

return SurfaceLifecyclePolicy
