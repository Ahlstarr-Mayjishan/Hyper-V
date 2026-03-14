--!strict

local LayerAuthority = require(script.Parent.Parent.System.Authority.LayerAuthority)

local AppSurfaceRuntime = {}

function AppSurfaceRuntime.registerBrainHandlers(app)
	app.brain:registerHandler("runtime.surface.activate", function(payload)
		local surface = payload.surface
		if surface and surface._activateRuntime then
			surface:_activateRuntime(payload.priority or 0)
			return
		end

		if surface and surface.activate then
			surface:activate()
			return
		end

		if payload.surfaceId then
			app.interactionAuthority:requestFocus({
				id = payload.surfaceId,
				priority = payload.priority or 0,
			})
			app.layerAuthority:bringToFront(payload.surfaceId)
		end
	end)

	app.brain:registerHandler("runtime.surface.open", function(payload)
		local surface = payload.surface
		if surface and surface._openRuntime then
			return surface:_openRuntime()
		end
		if surface and surface.view then
			surface.view.Visible = true
		end
		return nil
	end)

	app.brain:registerHandler("runtime.surface.close", function(payload)
		local surface = payload.surface
		if surface and surface._closeRuntime then
			return surface:_closeRuntime()
		end
		if surface and surface.view then
			surface.view.Visible = false
		end
		return nil
	end)

	app.brain:registerHandler("runtime.preview.patch", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
	app.brain:registerHandler("runtime.preview.set", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
	app.brain:registerHandler("runtime.preview.commit", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
	app.brain:registerHandler("runtime.preview.target", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
	app.brain:registerHandler("runtime.dock.attach", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
	app.brain:registerHandler("runtime.dock.detach", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
end

function AppSurfaceRuntime.dispatchIntent(app, intent)
	if app.brain then
		return app.brain:dispatch(intent)
	end
	return nil, "System brain unavailable"
end

function AppSurfaceRuntime.requestSurfaceActivation(app, surface, priority: number?)
	return AppSurfaceRuntime.dispatchIntent(app, {
		type = "surface.activate",
		sourceId = surface.id,
		surfaceId = surface.id,
		surface = surface,
		priority = priority,
	})
end

function AppSurfaceRuntime.requestSurfaceOpen(app, surface)
	return AppSurfaceRuntime.dispatchIntent(app, {
		type = "surface.open",
		sourceId = surface.id,
		surfaceId = surface.id,
		surface = surface,
	})
end

function AppSurfaceRuntime.requestSurfaceClose(app, surface)
	return AppSurfaceRuntime.dispatchIntent(app, {
		type = "surface.close",
		sourceId = surface.id,
		surfaceId = surface.id,
		surface = surface,
	})
end

function AppSurfaceRuntime.unregisterSurface(app, surfaceId: string)
	local surface = app._surfaceHandles[surfaceId]
	if surface and surface._layerCleanup then
		surface._layerCleanup()
		surface._layerCleanup = nil
	end
	app._surfaceHandles[surfaceId] = nil

	return AppSurfaceRuntime.dispatchIntent(app, {
		type = "surface.unregister",
		sourceId = surfaceId,
		surfaceId = surfaceId,
	})
end

function AppSurfaceRuntime.cleanupStaleSurfaces(app)
	local staleHandleIds = {}
	for id, surface in pairs(app._surfaceHandles) do
		if not surface or not surface.view or typeof(surface.view) ~= "Instance" or surface.view.Parent == nil then
			table.insert(staleHandleIds, id)
		end
	end

	for _, id in ipairs(staleHandleIds) do
		AppSurfaceRuntime.unregisterSurface(app, id)
	end

	local snapshot = app.brain:getStateSnapshot()
	local staleBrainOnlyCount = 0
	for id in pairs(snapshot.surfaces) do
		if app._surfaceHandles[id] == nil then
			staleBrainOnlyCount += 1
			AppSurfaceRuntime.dispatchIntent(app, {
				type = "surface.unregister",
				sourceId = id,
				surfaceId = id,
			})
		end
	end

	app._surfaceMaintenanceLog = {
		lastRunAt = os.clock(),
		handleOnlyRemoved = #staleHandleIds,
		brainOnlyRemoved = staleBrainOnlyCount,
	}
	table.insert(app._surfaceMaintenanceHistory, 1, {
		lastRunAt = app._surfaceMaintenanceLog.lastRunAt,
		handleOnlyRemoved = #staleHandleIds,
		brainOnlyRemoved = staleBrainOnlyCount,
	})
	while #app._surfaceMaintenanceHistory > 6 do
		table.remove(app._surfaceMaintenanceHistory)
	end
end

function AppSurfaceRuntime.registerStylable(app, stylable)
	table.insert(app._stylables, stylable)
	if stylable.applyWhitespace then
		stylable:applyWhitespace(app._context.whitespaceScale)
	end
	return stylable
end

function AppSurfaceRuntime.registerSurface(app, surface, priority: number)
	if not surface or not surface.view or not surface.id then
		return surface
	end

	if surface.view:IsA("GuiObject") then
		surface.view:SetAttribute("HyperVSurfaceId", surface.id)
		surface.view:SetAttribute("HyperVSurfacePriority", priority)
	end

	app._surfaceHandles[surface.id] = surface

	if surface._layerCleanup then
		surface._layerCleanup()
	end

	if surface.registerLayer ~= false then
		surface._layerCleanup = app.layerAuthority:registerSurface(surface.id, priority, function(baseZIndex)
			if surface.applyLayer then
				surface:applyLayer(baseZIndex)
			else
				LayerAuthority.applyGuiTreeZIndex(surface.view, baseZIndex)
			end
		end)
	end

	app.brain:dispatch({
		type = "surface.register",
		sourceId = surface.id,
		surfaceId = surface.id,
		kind = surface.kind or "surface",
		title = surface.title,
		priority = priority,
		visible = if surface.view then surface.view.Visible else false,
	})

	if surface.autoActivate ~= false then
		app.brain:dispatch({
			type = "surface.activate",
			sourceId = surface.id,
			surfaceId = surface.id,
			surface = surface,
			priority = priority,
		})
	end

	return surface
end

return AppSurfaceRuntime
