--!strict

local DockPanelView = require(script.Parent.Parent.Windowing.DockPanelView)
local DetachedWindowHandle = require(script.Parent.Parent.Windowing.DetachedWindowHandle)
local WindowController = require(script.Parent.Parent.Windowing.WindowController)
local CommandPaletteController = require(script.Parent.Parent.Overlay.CommandPalette.CommandPaletteController)
local ContextMenuController = require(script.Parent.Parent.Overlay.ContextMenuController)
local ModalController = require(script.Parent.Parent.Overlay.ModalController)
local CharacterPreviewController = require(script.Parent.Parent.Preview.CharacterPreviewController)
local ColorPickerController = require(script.Parent.Parent.Elements.ColorPickerController)
local PresetManager = require(script.Parent.Parent.Elements.PresetManager)
local BrainInspector = require(script.Parent.Parent.Brain.BrainInspector)
local AppRuntime = require(script.Parent.AppRuntime)

local AppFactory = {}

local SURFACE_PRIORITY = {
	window = 10,
	detached = 20,
	palette = 40,
	contextMenu = 45,
	modal = 60,
}

function AppFactory.createWindow(self, config)
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

function AppFactory.createButton(self, config, parentOverride)
	local parent = parentOverride or config.Parent or (self.currentWindow and self.currentWindow.contentFrame) or self.screenGui
	local button = Instance.new("TextButton")
	button.Name = config.Name or "Button"
	button.Size = config.Size or UDim2.new(1, 0, 0, 34)
	button.BackgroundColor3 = self.theme.Accent
	button.BorderSizePixel = 0
	button.Text = config.Text or "Button"
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 13
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	self.toolkit:CreateCorner(button, 8)
	button.MouseButton1Click:Connect(function()
		if config.OnClick then
			config.OnClick()
		end
	end)

	return {
		id = config.Name or "Button",
		kind = "button",
		title = config.Text or "Button",
		view = button,
		parentFrame = parent,
		dispose = function(selfHandle)
			selfHandle.view:Destroy()
		end,
		undock = function(selfHandle)
			if selfHandle.parentFrame then
				selfHandle.view.Parent = selfHandle.parentFrame
			end
		end,
	}
end

function AppFactory.createLabel(self, config, parentOverride)
	local parent = parentOverride or config.Parent or (self.currentWindow and self.currentWindow.contentFrame) or self.screenGui
	local label = Instance.new("TextLabel")
	label.Name = config.Name or "Label"
	label.Size = config.Size or UDim2.new(1, 0, 0, 24)
	label.BackgroundTransparency = 1
	label.Text = config.Text or "Label"
	label.TextColor3 = self.theme.Text
	label.TextSize = config.TextSize or 13
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent

	return {
		id = config.Name or "Label",
		kind = "label",
		title = label.Text,
		view = label,
		parentFrame = parent,
		dispose = function(selfHandle)
			selfHandle.view:Destroy()
		end,
	}
end

function AppFactory.createSection(self, config)
	assert(self.currentWindow, "createSection requires an active window")
	return self.currentWindow:createSection(config)
end

function AppFactory.createAccordionSection(self, config)
	config.Collapsible = true
	return self:createSection(config)
end

function AppFactory.createDockPanel(self, config)
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

function AppFactory.createDetachedWindow(self, config)
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

function AppFactory.createCommandPalette(self, config)
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

function AppFactory.createModal(self, config)
	local modal = ModalController.new(config or {}, self._context)
	self:_registerSurface(modal, SURFACE_PRIORITY.modal)
	return modal
end

function AppFactory.createContextMenu(self, config)
	local menu = ContextMenuController.new(config or {}, self._context)
	self:_registerSurface(menu, SURFACE_PRIORITY.contextMenu)
	return menu
end

function AppFactory.createBrainInspector(self)
	return BrainInspector.new(self)
end

function AppFactory.createNumberInput(self, config)
	return self.legacyRendererFactory:createNumberInput(config)
end

function AppFactory.createRangeSlider(self, config)
	return self.legacyRendererFactory:createRangeSlider(config)
end

function AppFactory.createMultiSelectDropdown(self, config)
	return self.legacyRendererFactory:createMultiSelectDropdown(config)
end

function AppFactory.createCodeBlock(self, config)
	return self.legacyRendererFactory:createCodeBlock(config)
end

function AppFactory.createColorPicker(self, config)
	local picker = ColorPickerController.new(config, self._context)
	self:_registerStylable(picker)
	return picker
end

function AppFactory.createSubTabs(self, config, parentOverride)
	local nextConfig = table.clone(config)
	nextConfig.Parent = parentOverride or config.Parent
	return self.legacyRendererFactory:createSubTabs(nextConfig)
end

function AppFactory.createTreeView(self, config)
	return self.legacyRendererFactory:createTreeView(config)
end

function AppFactory.createVirtualList(self, config)
	return self.legacyRendererFactory:createVirtualList(config)
end

function AppFactory.createPresetManager(self, config)
	return PresetManager.new(config, self._context)
end

function AppFactory.createCharacterPreview(self, config)
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

function AppFactory.registerCommand(self, command)
	self.commandRegistry:register({
		id = command.id or command.Name or command.Title,
		title = command.title or command.Title,
		description = command.description or command.Description,
		callback = command.callback or command.Callback,
	})
end

function AppFactory.notify(self, config)
	return self.overlayHost:notify(config)
end

function AppFactory.notifyInfo(self, title, content, duration)
	return self:notify({
		Title = title,
		Content = content,
		Type = "info",
		Duration = duration or 3,
	})
end

function AppFactory.notifySuccess(self, title, content, duration)
	return self:notify({
		Title = title,
		Content = content,
		Type = "success",
		Duration = duration or 3,
	})
end

return AppFactory
