--!strict

local SectionHandle = require(script.Parent.SectionHandle)
local DragController = require(script.Parent.Parent.Input.DragController)
local LayerAuthority = require(script.Parent.Parent.System.Authority.LayerAuthority)

local WindowController = {}
WindowController.__index = WindowController

function WindowController.new(app, config)
	local self = setmetatable({}, WindowController)
	self.app = app
	self.id = config.Name or "MainWindow"
	self.kind = "window"
	self.title = config.Title or "Hyper-V"
	self.layout = app.layout
	self.theme = app.theme
	self.tabs = {}
	self.activeTab = nil
	self._minSize = config.MinSize or Vector2.new(720, 460)
	self._maxSize = config.MaxSize or Vector2.new(1600, 1100)
	self._surfacePriority = 10
	self._isSplixStyle = self.layout.Name == "Splix"

	local size = if typeof(config.Size) == "Vector2"
		then UDim2.new(0, config.Size.X, 0, config.Size.Y)
		elseif typeof(config.Size) == "UDim2"
		then config.Size
		else UDim2.new(0, 900, 0, 580)

	-- Splix style: 3-layer border (outline → inline → frame)
	if self._isSplixStyle then
		self:_createSplixWindow(size, config)
	else
		self:_createDefaultWindow(size, config)
	end

	return self
end

function WindowController:_createSplixWindow(size: UDim2, config)
	-- Layer 0: Outline (outermost, black)
	local outline = Instance.new("Frame")
	outline.Name = "SplixOutline"
	outline.Size = size + UDim2.new(0, 2, 0, 2)
	outline.Position = (config.Position or UDim2.new(0.5, -450, 0.5, -290)) - UDim2.new(0, 1, 0, 1)
	outline.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- outline color
	outline.BorderSizePixel = 0
	outline.Parent = self.app.screenGui

	-- Layer 1: Inline (middle layer, inline color)
	local inline = Instance.new("Frame")
	inline.Name = "SplixInline"
	inline.Size = size + UDim2.new(0, 0, 0, 0)
	inline.Position = UDim2.new(0, 1, 0, 1)
	inline.BackgroundColor3 = self.theme.Second -- inline color
	inline.BorderSizePixel = 0
	inline.Parent = outline

	-- Layer 2: Main frame (innermost)
	local root = Instance.new("Frame")
	root.Name = self.id
	root.Size = size
	root.Position = UDim2.new(0, 0, 0, 0)
	root.BackgroundColor3 = self.theme.Main -- dark_contrast
	root.BorderSizePixel = 0
	root.Parent = inline

	-- Title bar (very compact)
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, self.layout.TitleBarHeight)
	titleBar.BackgroundColor3 = self.theme.Default
	titleBar.BorderSizePixel = 0
	titleBar.Parent = root

	-- Title text - left aligned, no extra padding
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 1, 0)
	title.Position = UDim2.new(0, 6, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = self.title
	title.TextColor3 = self.theme.TitleText
	title.TextSize = self.layout.TitleTextSize
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	-- Close button - minimal
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 16, 0, 16)
	closeButton.Position = UDim2.new(1, -20, 0.5, -8)
	closeButton.BackgroundColor3 = self.theme.Second
	closeButton.BorderSizePixel = 0
	closeButton.Text = "x"
	closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeButton.TextSize = 10
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar

	-- Tab bar
	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, -8, 0, self.layout.TabBarHeight)
	tabBar.Position = UDim2.new(0, 4, 0, self.layout.TitleBarHeight + 2)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = root

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 2)
	tabLayout.Parent = tabBar

	-- Content area
	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -8, 1, -(self.layout.TitleBarHeight + self.layout.TabBarHeight + 10))
	content.Position = UDim2.new(0, 4, 0, self.layout.TitleBarHeight + self.layout.TabBarHeight + 6)
	content.BackgroundTransparency = 1
	content.Parent = root

	-- Store references
	self.view = outline
	self.root = root
	self._splixOutline = outline
	self._splixInline = inline
	self.contentFrame = content
	self._titleBar = titleBar
	self._titleLabel = title
	self._tabBar = tabBar
	self._tabLayout = tabLayout
	self._closeButton = closeButton
	self.parentFrame = self.app.screenGui

	-- Drag support (minimal)
	self._dragCleanup = self.app.toolkit:MakeDraggable(outline, titleBar)

	-- Setup close
	closeButton.MouseButton1Click:Connect(function()
		self:dispose()
	end)
end

function WindowController:_createDefaultWindow(size: UDim2, config)
	local root = Instance.new("Frame")
	root.Name = self.id
	root.Size = size
	root.Position = config.Position or UDim2.new(0.5, -450, 0.5, -290)
	root.BackgroundColor3 = self.theme.Main
	root.BorderSizePixel = 0
	root.Parent = self.app.screenGui

	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, self.layout.TitleBarHeight)
	titleBar.BackgroundColor3 = self.theme.Default
	titleBar.BorderSizePixel = 0
	titleBar.Parent = root
	self.app.toolkit:CreateCorner(titleBar, self.layout.WindowCorner)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 1, 0)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = self.title
	title.TextColor3 = self.theme.TitleText
	title.TextSize = self.layout.TitleTextSize
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 24, 0, 24)
	closeButton.Position = UDim2.new(1, -30, 0.5, -12)
	closeButton.BackgroundColor3 = self.theme.Second
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 120, 120)
	closeButton.TextSize = 11
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar
	self.app.toolkit:CreateCorner(closeButton, 6)

	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, -(self.layout.ContentInset * 2), 0, self.layout.TabBarHeight)
	tabBar.Position = UDim2.new(0, self.layout.ContentInset, 0, self.layout.TitleBarHeight + 6)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = root

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.Parent = tabBar

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -(self.layout.ContentInset * 2), 1, -(self.layout.TitleBarHeight + self.layout.TabBarHeight + 20))
	content.Position = UDim2.new(0, self.layout.ContentInset, 0, self.layout.TitleBarHeight + self.layout.TabBarHeight + 12)
	content.BackgroundTransparency = 1
	content.Parent = root

	local resizeRight = Instance.new("Frame")
	resizeRight.Name = "ResizeRight"
	resizeRight.Size = UDim2.new(0, 10, 1, -12)
	resizeRight.Position = UDim2.new(1, -10, 0, 0)
	resizeRight.BackgroundTransparency = 1
	resizeRight.BorderSizePixel = 0
	resizeRight.Active = true
	resizeRight.Parent = root

	local resizeBottom = Instance.new("Frame")
	resizeBottom.Name = "ResizeBottom"
	resizeBottom.Size = UDim2.new(1, -12, 0, 10)
	resizeBottom.Position = UDim2.new(0, 0, 1, -10)
	resizeBottom.BackgroundTransparency = 1
	resizeBottom.BorderSizePixel = 0
	resizeBottom.Active = true
	resizeBottom.Parent = root

	local resizeCorner = Instance.new("Frame")
	resizeCorner.Name = "ResizeCorner"
	resizeCorner.Size = UDim2.new(0, 18, 0, 18)
	resizeCorner.Position = UDim2.new(1, -18, 1, -18)
	resizeCorner.BackgroundColor3 = self.theme.Second
	resizeCorner.BackgroundTransparency = 0.15
	resizeCorner.BorderSizePixel = 0
	resizeCorner.Active = true
	resizeCorner.Parent = root
	self.app.toolkit:CreateCorner(resizeCorner, 6)

	self.view = root
	self.root = root
	self.contentFrame = content
	self._titleBar = titleBar
	self._titleLabel = title
	self._tabBar = tabBar
	self._tabLayout = tabLayout
	self._closeButton = closeButton
	self._resizeCorner = resizeCorner
	self.parentFrame = self.app.screenGui
	self._dragCleanup = DragController.attach(root, titleBar, {
		authority = self.app:getInteractionAuthority(),
		claimantId = self.id,
		interactionPriority = self._surfacePriority,
		onDragStart = function()
			self:activate()
		end,
	})
	self._resizeCleanup = self.app.toolkit:MakeResizable(root, {
		corner = resizeCorner,
		right = resizeRight,
		bottom = resizeBottom,
	}, {
		authority = self.app:getInteractionAuthority(),
		claimantId = self.id,
		interactionPriority = self._surfacePriority,
		minSize = self._minSize,
		maxSize = self._maxSize,
		onResizeStart = function()
			self:activate()
		end,
		onResize = function(_, nextSize)
			self:_setBaseSize(nextSize)
		end,
	})

	root.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self:activate()
		end
	end)

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self:activate()
		end
	end)

	closeButton.MouseButton1Click:Connect(function()
		self:dispose()
	end)

	return self
end

function WindowController:_setBaseSize(nextSize: Vector2)
	self._baseSize = nextSize
	self.root.Size = UDim2.new(0, nextSize.X, 0, nextSize.Y)
end

function WindowController:applyLayer(baseZIndex: number)
	LayerAuthority.applyGuiTreeZIndex(self.root, baseZIndex)
end

function WindowController:_activateRuntime()
	self.app:getInteractionAuthority():requestFocus({
		id = self.id,
		priority = self._surfacePriority,
	})
	self.app:getLayerAuthority():bringToFront(self.id)
end

function WindowController:activate()
	if self.app.getBrain and self.app:getBrain() then
		self.app:requestSurfaceActivation(self, self._surfacePriority)
		return
	end
	self:_activateRuntime()
end

function WindowController:applyTheme(theme, layout)
	self.theme = theme or self.theme
	self.layout = layout or self.layout

	if self._isSplixStyle and self._splixOutline and self._splixInline then
		-- Splix style theming (3-layer border)
		self._splixOutline.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- outline (always black)
		self._splixInline.BackgroundColor3 = self.theme.Second -- inline
		self.root.BackgroundColor3 = self.theme.Main -- dark_contrast
		self._titleBar.BackgroundColor3 = self.theme.Default
		self._titleLabel.TextColor3 = self.theme.TitleText
		self._closeButton.BackgroundColor3 = self.theme.Second
	else
		-- Default style theming
		self.root.BackgroundColor3 = self.theme.Main
		self._titleBar.BackgroundColor3 = self.theme.Default
		self._titleLabel.TextColor3 = self.theme.TitleText
		self._closeButton.BackgroundColor3 = self.theme.Second
		if self._resizeCorner then
			self._resizeCorner.BackgroundColor3 = self.theme.Second
		end
	end

	for tabKey, tab in pairs(self.tabs) do
		local selected = self.activeTab == tab or self.activeTab == self.tabs[tabKey]
		tab.button.BackgroundColor3 = selected and self.theme.Accent or self.theme.Second
		tab.button.TextColor3 = selected and Color3.new(1, 1, 1) or self.theme.Text
	end
end

function WindowController:applyWhitespace(scale)
	local spacingScale = scale or 1

	-- Splix style: very compact
	if self._isSplixStyle then
		local inset = math.floor(self.layout.ContentInset * spacingScale + 0.5)
		local tabGap = math.floor(2 * spacingScale + 0.5)

		-- Title bar: minimal padding
		self._titleLabel.Position = UDim2.new(0, 4, 0, 0)
		self._titleLabel.Size = UDim2.new(1, -30, 1, 0)
		self._closeButton.Size = UDim2.new(0, 16, 0, 16)
		self._closeButton.Position = UDim2.new(1, -18, 0.5, -8)

		-- Tab bar: compact
		self._tabBar.Size = UDim2.new(1, -(inset * 2), 0, self.layout.TabBarHeight)
		self._tabBar.Position = UDim2.new(0, inset, 0, self.layout.TitleBarHeight + 2)
		self._tabLayout.Padding = UDim.new(0, tabGap)

		-- Content: minimal inset
		self.contentFrame.Size = UDim2.new(1, -(inset * 2), 1, -(self.layout.TitleBarHeight + self.layout.TabBarHeight + 6))
		self.contentFrame.Position = UDim2.new(0, inset, 0, self.layout.TitleBarHeight + self.layout.TabBarHeight + 4)

		for _, tab in pairs(self.tabs) do
			tab.button.Size = UDim2.new(0, math.floor(self.layout.TabButtonWidth * spacingScale + 0.5), 0, self.layout.TabButtonHeight)
		end
		return
	end

	-- Default style spacing
	local inset = math.floor(self.layout.ContentInset * spacingScale + 0.5)
	local tabGap = math.floor(6 * spacingScale + 0.5)
	local titlePadding = math.floor(12 * spacingScale + 0.5)
	local closeSize = math.floor(24 * spacingScale + 0.5)
	local closeInset = math.floor(6 * spacingScale + 0.5)

	self._titleLabel.Position = UDim2.new(0, titlePadding, 0, 0)
	self._titleLabel.Size = UDim2.new(1, -(titlePadding + closeSize + closeInset + 8), 1, 0)
	self._closeButton.Size = UDim2.new(0, closeSize, 0, closeSize)
	self._closeButton.Position = UDim2.new(1, -(closeSize + closeInset), 0.5, math.floor(-closeSize * 0.5))

	self._tabBar.Size = UDim2.new(1, -(inset * 2), 0, self.layout.TabBarHeight)
	self._tabBar.Position = UDim2.new(0, inset, 0, self.layout.TitleBarHeight + math.floor(6 * spacingScale + 0.5))
	self._tabLayout.Padding = UDim.new(0, tabGap)
	self.contentFrame.Size = UDim2.new(1, -(inset * 2), 1, -(self.layout.TitleBarHeight + self.layout.TabBarHeight + math.floor(20 * spacingScale + 0.5)))
	self.contentFrame.Position = UDim2.new(0, inset, 0, self.layout.TitleBarHeight + self.layout.TabBarHeight + math.floor(12 * spacingScale + 0.5))

	for _, tab in pairs(self.tabs) do
		tab.button.Size = UDim2.new(0, math.floor(self.layout.TabButtonWidth * spacingScale + 0.5), 0, self.layout.TabButtonHeight)
	end
end

function WindowController:createTab(config)
	local key = config.Key or config.Name
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, self.layout.TabButtonWidth, 0, self.layout.TabButtonHeight)
	button.BackgroundColor3 = self.theme.Second
	button.BorderSizePixel = 0
	button.Text = config.Name
	button.TextColor3 = self.theme.Text
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.Parent = self._tabBar
	self.app.toolkit:CreateCorner(button, 6)

	local page = Instance.new("ScrollingFrame")
	page.Name = key .. "_Page"
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.Visible = false
	page.Parent = self.contentFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, self.layout.SectionGap)
	layout.Parent = page
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	end)

	self.tabs[key] = {
		id = key,
		name = config.Name,
		button = button,
		view = page,
		parentFrame = self.contentFrame,
		Content = page,
		ContentFrame = page,
		contentFrame = page,
		createSection = function(_, sectionConfig)
			sectionConfig.Parent = page
			return self:createSection(sectionConfig)
		end,
	}

	button.MouseButton1Click:Connect(function()
		self:selectTab(key)
	end)

	if not self.activeTab then
		self:selectTab(key)
	end

	return self.tabs[key]
end

function WindowController:selectTab(key)
	for tabKey, tab in pairs(self.tabs) do
		local selected = tabKey == key
		tab.view.Visible = selected
		tab.button.BackgroundColor3 = selected and self.theme.Accent or self.theme.Second
		tab.button.TextColor3 = selected and Color3.new(1, 1, 1) or self.theme.Text
	end
	self.activeTab = self.tabs[key]
end

function WindowController:createSection(config)
	return SectionHandle.new({
		Id = config.Name or config.Title or ("Section_" .. tostring(#self.tabs + 1)),
		Title = config.Title or config.Name or "Section",
		Parent = config.Parent or (self.activeTab and self.activeTab.Content) or self.contentFrame,
		Height = config.Height or 180,
		DefaultCollapsed = config.DefaultCollapsed == true,
		Collapsible = config.Collapsible ~= false,
	}, self.app._context)
end

function WindowController:dispose()
	self.app:unregisterSurface(self.id)
	if self._responsiveCleanup then
		self._responsiveCleanup()
		self._responsiveCleanup = nil
	end
	if self._dragCleanup then
		self._dragCleanup()
		self._dragCleanup = nil
	end
	if self._resizeCleanup then
		self._resizeCleanup()
		self._resizeCleanup = nil
	end
	if self._layerCleanup then
		self._layerCleanup()
		self._layerCleanup = nil
	end
	self.app:getInteractionAuthority():clearOwner(self.id)
	self.root:Destroy()
end

return WindowController
