--!strict

local Players = game:GetService("Players")

local ThemeTokens = require(script.Parent.Parent.Tokens.ThemeTokens)
local LayoutSpecs = require(script.Parent.Parent.Tokens.LayoutSpecs)
local Utf8Text = require(script.Parent.Parent.Text.Utf8Text)
local ElementToolkit = require(script.Parent.Parent.UI.ElementToolkit)
local PresetRegistry = require(script.Parent.Parent.Registries.PresetRegistry)
local CommandRegistry = require(script.Parent.Parent.Registries.CommandRegistry)
local OverlayHost = require(script.Parent.Parent.Overlay.OverlayHost)
local CommandPaletteController = require(script.Parent.Parent.Overlay.CommandPalette.CommandPaletteController)
local DockRegistry = require(script.Parent.Parent.Windowing.DockRegistry)
local DockPanelView = require(script.Parent.Parent.Windowing.DockPanelView)
local DetachedWindowHandle = require(script.Parent.Parent.Windowing.DetachedWindowHandle)
local WindowController = require(script.Parent.Parent.Windowing.WindowController)
local CharacterPreviewController = require(script.Parent.Parent.Preview.CharacterPreviewController)
local LegacyRendererFactory = require(script.Parent.Parent.Elements.LegacyRendererFactory)
local PresetManager = require(script.Parent.Parent.Elements.PresetManager)
local resolveLegacyRoot = require(script.Parent.Parent.Legacy.LegacyRoot)

-- Core systems
local legacyRoot = resolveLegacyRoot(script)
local GarbageCollector = require(legacyRoot.core.GarbageCollector.GarbageCollector)
local HyperVAPI = require(legacyRoot.core.API.RayfieldAPI)

local App = {}
App.__index = App

local function createScreenGui(name: string): ScreenGui
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild(name)
	if existing and existing:IsA("ScreenGui") then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	return screenGui
end

local function resolveDefaultPreviewPosition(window, requestedSize: Vector2?): UDim2
	local fallback = UDim2.new(0, 40, 0, 80)
	if not window or not window.root then
		return fallback
	end

	local root = window.root
	local width = if requestedSize then requestedSize.X else 760
	local height = if requestedSize then requestedSize.Y else 560
	local gap = 24
	local candidate = UDim2.new(
		root.Position.X.Scale,
		root.Position.X.Offset + root.AbsoluteSize.X + gap,
		root.Position.Y.Scale,
		root.Position.Y.Offset
	)

	local camera = workspace.CurrentCamera
	if not camera then
		return candidate
	end

	local viewport = camera.ViewportSize
	if candidate.X.Offset + width > viewport.X then
		return fallback
	end

	if candidate.Y.Offset + height > viewport.Y then
		return UDim2.new(0, math.max(24, viewport.X - width - 24), 0, math.max(24, viewport.Y - height - 24))
	end

	return candidate
end

function App.new(config)
	local self = setmetatable({}, App)
	self.theme = ThemeTokens.getTheme(config.Theme)
	self.layout = LayoutSpecs.get(config.Layout)
	self.toolkit = ElementToolkit.new()
	self.screenGui = createScreenGui(config.Name or "HyperV")
	self.presetRegistry = PresetRegistry.new()
	self.commandRegistry = CommandRegistry.new()
	self.dockRegistry = DockRegistry.new()
	self.text = Utf8Text
	self.overlayHost = OverlayHost.new(self.screenGui, self.theme, self.toolkit)
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
		toolkit = self.toolkit,
		presetRegistry = self.presetRegistry,
		commandRegistry = self.commandRegistry,
		dockRegistry = self.dockRegistry,
		gc = self.gc,
		api = self.api,
	}
	self.windows = {}
	self._stylables = {}
	self.currentWindow = nil
	return self
end

function App:_registerStylable(stylable)
	table.insert(self._stylables, stylable)
	return stylable
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

function App:createWindow(config)
	local window = WindowController.new(self, config or {})
	self:_registerStylable(window)
	table.insert(self.windows, window)
	self.currentWindow = window
	return window
end

function App:createButton(config, parentOverride)
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

function App:createLabel(config, parentOverride)
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

function App:createSection(config)
	assert(self.currentWindow, "createSection requires an active window")
	return self.currentWindow:createSection(config)
end

function App:createAccordionSection(config)
	config.Collapsible = true
	return self:createSection(config)
end

function App:createDockPanel(config)
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

function App:createDetachedWindow(config)
	return self:_registerStylable(DetachedWindowHandle.new({
		Id = config.Id or config.Name,
		Name = config.Name or "DetachedWindow",
		Title = config.Title,
		Size = if typeof(config.Size) == "Vector2" then UDim2.new(0, config.Size.X, 0, config.Size.Y) else config.Size,
		Position = config.Position,
		Parent = config.Parent or self.screenGui,
		Content = config.Content,
		OnCloseRequested = config.OnCloseRequested,
	}, self._context))
end

function App:createCommandPalette(config)
	local actions = {}
	for index, action in ipairs(config.Actions or self.commandRegistry:list()) do
		table.insert(actions, {
			id = action.id or ("action_" .. index),
			title = action.Title or action.title or ("Action " .. index),
			description = action.Description or action.description,
			callback = action.Callback or action.callback,
		})
	end
	return CommandPaletteController.new({
		Hotkey = config.Hotkey,
		Actions = actions,
		Parent = config.Parent or self.screenGui,
	}, self._context)
end

function App:createNumberInput(config)
	return self.legacyRendererFactory:createNumberInput(config)
end

function App:createRangeSlider(config)
	return self.legacyRendererFactory:createRangeSlider(config)
end

function App:createMultiSelectDropdown(config)
	return self.legacyRendererFactory:createMultiSelectDropdown(config)
end

function App:createCodeBlock(config)
	return self.legacyRendererFactory:createCodeBlock(config)
end

function App:createSubTabs(config, parentOverride)
	local nextConfig = table.clone(config)
	nextConfig.Parent = parentOverride or config.Parent
	return self.legacyRendererFactory:createSubTabs(nextConfig)
end

function App:createTreeView(config)
	return self.legacyRendererFactory:createTreeView(config)
end

function App:createVirtualList(config)
	return self.legacyRendererFactory:createVirtualList(config)
end

function App:createPresetManager(config)
	return PresetManager.new(config, self._context)
end

function App:createCharacterPreview(config)
	local nextConfig = table.clone(config or {})
	nextConfig.Position = nextConfig.Position or resolveDefaultPreviewPosition(self.currentWindow, nextConfig.Size)
	nextConfig.Parent = nextConfig.Parent or self.screenGui

	local preview = CharacterPreviewController.new(nextConfig, {
		app = self,
		theme = self.theme,
		layout = self.layout,
		toolkit = self.toolkit,
		presetRegistry = self.presetRegistry,
		commandRegistry = self.commandRegistry,
		dockRegistry = self.dockRegistry,
		gc = self.gc,
		api = self.api,
		defaultPreviewPosition = nextConfig.Position,
	})

	self:_registerStylable(preview)
	self.presetRegistry:register(preview)
	return preview
end

function App:registerCommand(command)
	self.commandRegistry:register({
		id = command.id or command.Name or command.Title,
		title = command.title or command.Title,
		description = command.description or command.Description,
		callback = command.callback or command.Callback,
	})
end

function App:notify(config)
	return self.overlayHost:notify(config)
end

function App:notifyInfo(title, content, duration)
	return self:notify({
		Title = title,
		Content = content,
		Type = "info",
		Duration = duration or 3,
	})
end

function App:notifySuccess(title, content, duration)
	return self:notify({
		Title = title,
		Content = content,
		Type = "success",
		Duration = duration or 3,
	})
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

	-- Clear references
	self.windows = {}
	self.currentWindow = nil
end

return App
