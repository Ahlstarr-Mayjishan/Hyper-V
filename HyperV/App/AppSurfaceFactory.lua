--!strict

local DockPanelView = require(script.Parent.Parent.Windowing.DockPanelView)
local DetachedWindowHandle = require(script.Parent.Parent.Windowing.DetachedWindowHandle)
local WindowController = require(script.Parent.Parent.Windowing.WindowController)
local CommandPaletteController = require(script.Parent.Parent.Overlay.CommandPalette.CommandPaletteController)
local ContextMenuController = require(script.Parent.Parent.Overlay.ContextMenuController)
local ModalController = require(script.Parent.Parent.Overlay.ModalController)
local CharacterPreviewController = require(script.Parent.Parent.Preview.CharacterPreviewController)
local BrainInspector = require(script.Parent.Parent.Brain.BrainInspector)
local AppRuntime = require(script.Parent.AppRuntime)

local AppSurfaceFactory = {}

local SURFACE_PRIORITY = {
	window = 10,
	detached = 20,
	palette = 40,
	contextMenu = 45,
	modal = 60,
}

function AppSurfaceFactory.createWindow(self, config)
	local nextConfig = table.clone(config or {})
	local baseSize, resolvedPosition, _ = AppRuntime.resolveResponsiveRect(
		nextConfig.Size,
		nextConfig.Position,
		Vector2.new(900, 580),
		nextConfig.Margin
	)
	nextConfig.Size = Vector2.new(baseSize.X, baseSize.Y)
	nextConfig.Position = resolvedPosition

	local window = WindowController.new(self, nextConfig)
	window._responsiveCleanup = AppRuntime.attachResponsiveWindow(window, baseSize, nextConfig.Margin)
	self:_registerStylable(window)
	self:_registerSurface(window, SURFACE_PRIORITY.window)
	table.insert(self.windows, window)
	self.currentWindow = window
	return window
end

function AppSurfaceFactory.createDockPanel(self, config)
	local panel = DockPanelView.new({
		Id = config.Id or config.Name,
		Name = config.Name or "DockPanel",
		Title = config.Title or config.Name or "Dock Panel",
		Size = config.Size and UDim2.new(0, config.Size.X, 0, config.Size.Y) or UDim2.new(0, 240, 0, 220),
		Position = config.Position or UDim2.new(1, -250, 0, 90),
		Parent = config.Parent or self.screenGui,
		Accept = config.Accept or "Both",
	}, self._context)
	self.dockRegistry:registerTarget(panel.id, panel)
	return panel
end

function AppSurfaceFactory.createDetachedWindow(self, config)
	local baseSize, resolvedPosition, _ = AppRuntime.resolveResponsiveRect(
		config.Size,
		config.Position,
		Vector2.new(320, 220),
		config.Margin
	)

	local handle = DetachedWindowHandle.new({
		Id = config.Id or config.Name,
		Name = config.Name or "DetachedWindow",
		Title = config.Title,
		Size = UDim2.new(0, baseSize.X, 0, baseSize.Y),
		Position = resolvedPosition,
		Parent = config.Parent or self.screenGui,
		Content = config.Content,
		MinSize = config.MinSize,
		MaxSize = config.MaxSize,
		OnCloseRequested = config.OnCloseRequested,
	}, self._context)

	handle._responsiveCleanup = AppRuntime.attachResponsiveWindow(handle, baseSize, config.Margin)
	if handle._surfaceRegistrationDisabled ~= true then
		self:_registerSurface(handle, SURFACE_PRIORITY.detached)
	end
	return self:_registerStylable(handle)
end

function AppSurfaceFactory.createCommandPalette(self, config)
	local actions = {}
	for index, action in ipairs(config.Actions or self.commandRegistry:list()) do
		table.insert(actions, {
			id = action.id or ("action_" .. index),
			title = action.Title or action.title or ("Action " .. index),
			description = action.Description or action.description,
			callback = action.Callback or action.callback,
		})
	end
	local palette = CommandPaletteController.new({
		Hotkey = config.Hotkey,
		Actions = actions,
		Parent = config.Parent or self.screenGui,
	}, self._context)
	self:_registerSurface(palette, SURFACE_PRIORITY.palette)
	return palette
end

function AppSurfaceFactory.createModal(self, config)
	local modal = ModalController.new(config or {}, self._context)
	self:_registerSurface(modal, SURFACE_PRIORITY.modal)
	return modal
end

function AppSurfaceFactory.createContextMenu(self, config)
	local menu = ContextMenuController.new(config or {}, self._context)
	self:_registerSurface(menu, SURFACE_PRIORITY.contextMenu)
	return menu
end

function AppSurfaceFactory.createBrainInspector(self)
	return BrainInspector.new(self)
end

function AppSurfaceFactory.createCharacterPreview(self, config)
	local nextConfig = table.clone(config or {})
	local previewSize = AppRuntime.vectorFromSize(nextConfig.Size, Vector2.new(760, 560))
	nextConfig.Position = nextConfig.Position or AppRuntime.resolveDefaultPreviewPosition(self.currentWindow, previewSize)
	nextConfig.Parent = nextConfig.Parent or self.screenGui

	local preview = CharacterPreviewController.new(nextConfig, {
		app = self,
		theme = self.theme,
		layout = self.layout,
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
		defaultPreviewPosition = nextConfig.Position,
	})

	self:_registerStylable(preview)
	self:_registerSurface(preview, SURFACE_PRIORITY.detached)
	self.presetRegistry:register(preview)
	return preview
end

return AppSurfaceFactory
