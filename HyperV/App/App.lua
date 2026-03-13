--!strict

local RunService = game:GetService("RunService")

local ThemeTokens = require(script.Parent.Parent.Tokens.ThemeTokens)
local LayoutSpecs = require(script.Parent.Parent.Tokens.LayoutSpecs)
local Utf8Text = require(script.Parent.Parent.Text.Utf8Text)
local ElementToolkit = require(script.Parent.Parent.UI.ElementToolkit)
local PresetRegistry = require(script.Parent.Parent.Registries.PresetRegistry)
local CommandRegistry = require(script.Parent.Parent.Registries.CommandRegistry)
local OverlayHost = require(script.Parent.Parent.Overlay.OverlayHost)
local DockRegistry = require(script.Parent.Parent.Windowing.DockRegistry)
local LegacyRendererFactory = require(script.Parent.Parent.Elements.LegacyRendererFactory)
local SystemBrain = require(script.Parent.Parent.Brain.SystemBrain)
local resolveLegacyRoot = require(script.Parent.Parent.Legacy.LegacyRoot)
local InteractionAuthority = require(script.Parent.Parent.System.Authority.InteractionAuthority)
local LayerAuthority = require(script.Parent.Parent.System.Authority.LayerAuthority)
local ProtectionGate = require(script.Parent.Parent.System.Authority.ProtectionGate)
local AppRuntime = require(script.Parent.AppRuntime)
local AppFactory = require(script.Parent.AppFactory)

-- Core systems
local legacyRoot = resolveLegacyRoot(script)
local GarbageCollector = require(legacyRoot.core.GarbageCollector.GarbageCollector)
local HyperVAPI = require(legacyRoot.core.API.RayfieldAPI)

local App = {}
App.__index = App

local function validatePreviewTarget(request)
	if request == nil then
		return false, "Missing preview target request"
	end

	if request.model == nil then
		return true, nil
	end

	if typeof(request.model) ~= "Instance" or not request.model:IsA("Model") then
		return false, "Preview target must be a Model"
	end

	return true, nil
end

local function validatePreviewPatch(request)
	if request == nil or type(request.sourceId) ~= "string" or type(request.patch) ~= "table" then
		return false, "Invalid preview patch request"
	end

	return true, nil
end

local function validatePreviewConfig(request)
	if request == nil or type(request.sourceId) ~= "string" or type(request.config) ~= "table" then
		return false, "Invalid preview config request"
	end

	return true, nil
end

local function validatePreviewCommit(request)
	if request == nil or type(request.sourceId) ~= "string" or type(request.snapshot) ~= "table" then
		return false, "Invalid preview commit request"
	end

	return true, nil
end

local function validateDockAttach(request)
	if request == nil or request.handle == nil or request.target == nil then
		return false, "Invalid dock attach request"
	end

	if not request.handle.view or typeof(request.handle.view) ~= "Instance" then
		return false, "Dock handle must expose a view"
	end

	if request.target.supportsHandle and request.target:supportsHandle(request.handle) == false then
		return false, "Dock target rejected handle"
	end

	return true, nil
end

local function validateDockDetach(request)
	if request == nil or request.handle == nil then
		return false, "Invalid dock detach request"
	end

	return true, nil
end

function App.new(config)
	local self = setmetatable({}, App)
	self.theme = ThemeTokens.getTheme(config.Theme)
	self.layout = LayoutSpecs.get(config.Layout)
	self.toolkit = ElementToolkit.new()
	self.screenGui = AppRuntime.createScreenGui(config.Name or "HyperV")
	self.interactionAuthority = InteractionAuthority.new()
	self.layerAuthority = LayerAuthority.new()
	self.protectionGate = ProtectionGate.new()
	self.brain = SystemBrain.new()
	self.brain:attachAuthority(self.interactionAuthority)
	self.toolkit._interactionAuthority = self.interactionAuthority
	self.presetRegistry = PresetRegistry.new()
	self.commandRegistry = CommandRegistry.new()
	self.dockRegistry = DockRegistry.new(self.protectionGate, self.brain)
	self.text = Utf8Text
	self.overlayHost = OverlayHost.new(self.screenGui, self.theme, self.toolkit, {
		app = self,
		layerAuthority = self.layerAuthority,
		interactionAuthority = self.interactionAuthority,
	})
	self.legacyRoot = legacyRoot
	self.legacyRendererFactory = LegacyRendererFactory.new(self.legacyRoot, self.theme, self.toolkit, self.presetRegistry)

	-- Initialize Core Systems
	self.gc = GarbageCollector.new(config.GC)
	self.api = HyperVAPI.new()
	self.api:SetMarker(self.gc.Marker)

	self._context = {
		app = self,
		theme = self.theme,
		layout = self.layout,
		whitespaceScale = AppRuntime.computeWhitespaceScale(),
		toolkit = self.toolkit,
		presetRegistry = self.presetRegistry,
		commandRegistry = self.commandRegistry,
		dockRegistry = self.dockRegistry,
		interactionAuthority = self.interactionAuthority,
		layerAuthority = self.layerAuthority,
		protectionGate = self.protectionGate,
		brain = self.brain,
		gc = self.gc,
		api = self.api,
		animation = nil :: any,
	}

	self.protectionGate:register("dock.attach", {
		validate = validateDockAttach,
	})
	self.protectionGate:register("dock.detach", {
		validate = validateDockDetach,
	})
	self.protectionGate:register("preview.patch", {
		validate = validatePreviewPatch,
	})
	self.protectionGate:register("preview.set", {
		validate = validatePreviewConfig,
	})
	self.protectionGate:register("preview.commit", {
		validate = validatePreviewCommit,
	})
	self.protectionGate:register("preview.target", {
		validate = validatePreviewTarget,
	})
	self.brain:registerHandler("runtime.surface.activate", function(payload)
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
			self.interactionAuthority:requestFocus({
				id = payload.surfaceId,
				priority = payload.priority or 0,
			})
			self.layerAuthority:bringToFront(payload.surfaceId)
		end
	end)
	self.brain:registerHandler("runtime.surface.open", function(payload)
		local surface = payload.surface
		if surface and surface._openRuntime then
			return surface:_openRuntime()
		end
		if surface and surface.view then
			surface.view.Visible = true
		end
		return nil
	end)
	self.brain:registerHandler("runtime.surface.close", function(payload)
		local surface = payload.surface
		if surface and surface._closeRuntime then
			return surface:_closeRuntime()
		end
		if surface and surface.view then
			surface.view.Visible = false
		end
		return nil
	end)
	self.brain:registerHandler("runtime.preview.patch", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
	self.brain:registerHandler("runtime.preview.set", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
	self.brain:registerHandler("runtime.preview.commit", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
	self.brain:registerHandler("runtime.preview.target", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
	self.brain:registerHandler("runtime.dock.attach", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
	self.brain:registerHandler("runtime.dock.detach", function(payload)
		if payload.apply then
			return payload.apply(payload)
		end
		return nil
	end)
	self.windows = {}
	self._surfaceHandles = {}
	self._stylables = {}
	self._surfaceMaintenanceAccumulator = 0
	self._surfaceMaintenanceLog = {
		lastRunAt = 0,
		handleOnlyRemoved = 0,
		brainOnlyRemoved = 0,
	}
	self._surfaceMaintenanceHistory = {}
	local viewportConnection = nil
	local function refreshWhitespace()
		self._context.whitespaceScale = AppRuntime.computeWhitespaceScale()
		local activeStylables = {}
		for _, stylable in ipairs(self._stylables) do
			if stylable and stylable.view and stylable.view.Parent then
				if stylable.applyWhitespace then
					stylable:applyWhitespace(self._context.whitespaceScale)
				end
				table.insert(activeStylables, stylable)
			end
		end
		self._stylables = activeStylables
	end
	local cameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if viewportConnection then
			viewportConnection:Disconnect()
			viewportConnection = nil
		end
		local camera = workspace.CurrentCamera
		if camera then
			viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshWhitespace)
		end
		refreshWhitespace()
	end)
	if workspace.CurrentCamera then
		viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshWhitespace)
	end
	self._whitespaceCleanup = function()
		cameraConnection:Disconnect()
		if viewportConnection then
			viewportConnection:Disconnect()
		end
	end
	self._surfaceMaintenanceCleanup = RunService.Heartbeat:Connect(function(deltaTime)
		self._surfaceMaintenanceAccumulator += deltaTime
		if self._surfaceMaintenanceAccumulator >= 1 then
			self._surfaceMaintenanceAccumulator = 0
			self:_cleanupStaleSurfaces()
		end
	end)
	self.currentWindow = nil
	refreshWhitespace()
	return self
end

function App:_dispatchIntent(intent)
	if self.brain then
		return self.brain:dispatch(intent)
	end
	return nil, "System brain unavailable"
end

function App:requestSurfaceActivation(surface, priority: number?)
	return self:_dispatchIntent({
		type = "surface.activate",
		sourceId = surface.id,
		surfaceId = surface.id,
		surface = surface,
		priority = priority,
	})
end

function App:requestSurfaceOpen(surface)
	return self:_dispatchIntent({
		type = "surface.open",
		sourceId = surface.id,
		surfaceId = surface.id,
		surface = surface,
	})
end

function App:requestSurfaceClose(surface)
	return self:_dispatchIntent({
		type = "surface.close",
		sourceId = surface.id,
		surfaceId = surface.id,
		surface = surface,
	})
end

function App:unregisterSurface(surfaceId: string)
	local surface = self._surfaceHandles[surfaceId]
	if surface and surface._layerCleanup then
		surface._layerCleanup()
		surface._layerCleanup = nil
	end
	self._surfaceHandles[surfaceId] = nil

	return self:_dispatchIntent({
		type = "surface.unregister",
		sourceId = surfaceId,
		surfaceId = surfaceId,
	})
end

function App:_cleanupStaleSurfaces()
	local staleHandleIds = {}
	for id, surface in pairs(self._surfaceHandles) do
		if not surface or not surface.view or typeof(surface.view) ~= "Instance" or surface.view.Parent == nil then
			table.insert(staleHandleIds, id)
		end
	end

	for _, id in ipairs(staleHandleIds) do
		self:unregisterSurface(id)
	end

	local snapshot = self.brain:getStateSnapshot()
	local staleBrainOnlyCount = 0
	for id in pairs(snapshot.surfaces) do
		if self._surfaceHandles[id] == nil then
			staleBrainOnlyCount += 1
			self:_dispatchIntent({
				type = "surface.unregister",
				sourceId = id,
				surfaceId = id,
			})
		end
	end

	self._surfaceMaintenanceLog = {
		lastRunAt = os.clock(),
		handleOnlyRemoved = #staleHandleIds,
		brainOnlyRemoved = staleBrainOnlyCount,
	}
	table.insert(self._surfaceMaintenanceHistory, 1, {
		lastRunAt = self._surfaceMaintenanceLog.lastRunAt,
		handleOnlyRemoved = #staleHandleIds,
		brainOnlyRemoved = staleBrainOnlyCount,
	})
	while #self._surfaceMaintenanceHistory > 6 do
		table.remove(self._surfaceMaintenanceHistory)
	end
end

function App:_registerStylable(stylable)
	table.insert(self._stylables, stylable)
	if stylable.applyWhitespace then
		stylable:applyWhitespace(self._context.whitespaceScale)
	end
	return stylable
end

function App:_registerSurface(surface, priority: number)
	if not surface or not surface.view or not surface.id then
		return surface
	end

	if surface.view:IsA("GuiObject") then
		surface.view:SetAttribute("HyperVSurfaceId", surface.id)
		surface.view:SetAttribute("HyperVSurfacePriority", priority)
	end

	self._surfaceHandles[surface.id] = surface

	if surface._layerCleanup then
		surface._layerCleanup()
	end

	if surface.registerLayer ~= false then
		surface._layerCleanup = self.layerAuthority:registerSurface(surface.id, priority, function(baseZIndex)
			if surface.applyLayer then
				surface:applyLayer(baseZIndex)
			else
				LayerAuthority.applyGuiTreeZIndex(surface.view, baseZIndex)
			end
		end)
	end

	self.brain:dispatch({
		type = "surface.register",
		sourceId = surface.id,
		surfaceId = surface.id,
		kind = surface.kind or "surface",
		title = surface.title,
		priority = priority,
		visible = if surface.view then surface.view.Visible else false,
	})

	if surface.autoActivate ~= false then
		self.brain:dispatch({
			type = "surface.activate",
			sourceId = surface.id,
			surfaceId = surface.id,
			surface = surface,
			priority = priority,
		})
	end

	return surface
end

function App:getTheme()
	return self.theme
end

function App:setTheme(name: string)
	self.theme = ThemeTokens.getTheme(name)
	self._context.theme = self.theme
	self.legacyRendererFactory.theme = self.theme
	self.overlayHost._theme = self.theme

	local activeStylables = {}
	for _, stylable in ipairs(self._stylables) do
		if stylable and stylable.view and stylable.view.Parent and stylable.applyTheme then
			stylable:applyTheme(self.theme, self.layout)
			table.insert(activeStylables, stylable)
		end
	end
	self._stylables = activeStylables
end

function App:getOverlayHost()
	return self.overlayHost
end

function App:getInteractionAuthority()
	return self.interactionAuthority
end

function App:getLayerAuthority()
	return self.layerAuthority
end

function App:getProtectionGate()
	return self.protectionGate
end

function App:getBrain()
	return self.brain
end

function App:getPresetRegistry()
	return self.presetRegistry
end

function App:getCommandRegistry()
	return self.commandRegistry
end

function App:getGC()
	return self.gc
end

function App:getAPI()
	return self.api
end

function App:getAnimation()
	if not self.animation then
		self.animation = require(script.Parent.Parent.Core.Animation.AnimationEngine)
	end
	return self.animation
end

function App:text()
	return Utf8Text
end

function App:dispose()
	-- Stop auto cleanup
	if self.gc then
		self.gc:StopAutoCleanup()
	end

	-- Destroy all windows
	for _, window in ipairs(self.windows) do
		if window.dispose then
			window:dispose()
		elseif window.destroy then
			window:destroy()
		end
	end

	-- Destroy screen gui
	if self.screenGui and self.screenGui.Parent then
		self.screenGui:Destroy()
	end

	if self._whitespaceCleanup then
		self._whitespaceCleanup()
		self._whitespaceCleanup = nil
	end
	if self._surfaceMaintenanceCleanup then
		self._surfaceMaintenanceCleanup:Disconnect()
		self._surfaceMaintenanceCleanup = nil
	end

	-- Clear references
	self.windows = {}
	self.currentWindow = nil
end

App.createWindow = AppFactory.createWindow
App.createButton = AppFactory.createButton
App.createLabel = AppFactory.createLabel
App.createSection = AppFactory.createSection
App.createAccordionSection = AppFactory.createAccordionSection
App.createDockPanel = AppFactory.createDockPanel
App.createDetachedWindow = AppFactory.createDetachedWindow
App.createCommandPalette = AppFactory.createCommandPalette
App.createModal = AppFactory.createModal
App.createContextMenu = AppFactory.createContextMenu
App.createBrainInspector = AppFactory.createBrainInspector
App.createNumberInput = AppFactory.createNumberInput
App.createRangeSlider = AppFactory.createRangeSlider
App.createMultiSelectDropdown = AppFactory.createMultiSelectDropdown
App.createCodeBlock = AppFactory.createCodeBlock
App.createColorPicker = AppFactory.createColorPicker
App.createSubTabs = AppFactory.createSubTabs
App.createTreeView = AppFactory.createTreeView
App.createVirtualList = AppFactory.createVirtualList
App.createPresetManager = AppFactory.createPresetManager
App.createCharacterPreview = AppFactory.createCharacterPreview
App.registerCommand = AppFactory.registerCommand
App.notify = AppFactory.notify
App.notifyInfo = AppFactory.notifyInfo
App.notifySuccess = AppFactory.notifySuccess

return App
