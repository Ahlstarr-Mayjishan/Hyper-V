--!strict

local SectionHandle = require(script.Parent.SectionHandle)
local DragController = require(script.Parent.Parent.Input.DragController)

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

	local size = if typeof(config.Size) == "Vector2"
		then UDim2.new(0, config.Size.X, 0, config.Size.Y)
		elseif typeof(config.Size) == "UDim2"
		then config.Size
		else UDim2.new(0, 900, 0, 580)

	local root = Instance.new("Frame")
	root.Name = self.id
	root.Size = size
	root.Position = config.Position or UDim2.new(0.5, -450, 0.5, -290)
	root.BackgroundColor3 = self.theme.Main
	root.BorderSizePixel = 0
	root.Parent = app.screenGui
	app.toolkit:CreateCorner(root, self.layout.WindowCorner)
	app.toolkit:CreateStroke(root, self.theme.Border)

	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, self.layout.TitleBarHeight)
	titleBar.BackgroundColor3 = self.theme.Default
	titleBar.BorderSizePixel = 0
	titleBar.Parent = root
	app.toolkit:CreateCorner(titleBar, self.layout.WindowCorner)

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
	app.toolkit:CreateCorner(closeButton, 6)

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

	self.view = root
	self.root = root
	self.contentFrame = content
	self._titleBar = titleBar
	self._titleLabel = title
	self._tabBar = tabBar
	self._closeButton = closeButton
	self.parentFrame = app.screenGui
	self._dragCleanup = DragController.attach(root, titleBar, {})

	closeButton.MouseButton1Click:Connect(function()
		self:dispose()
	end)

	return self
end

function WindowController:applyTheme(theme, layout)
	self.theme = theme or self.theme
	self.layout = layout or self.layout
	self.root.BackgroundColor3 = self.theme.Main
	self._titleBar.BackgroundColor3 = self.theme.Default
	self._titleLabel.TextColor3 = self.theme.TitleText
	self._closeButton.BackgroundColor3 = self.theme.Second

	for tabKey, tab in pairs(self.tabs) do
		local selected = self.activeTab == tab or self.activeTab == self.tabs[tabKey]
		tab.button.BackgroundColor3 = selected and self.theme.Accent or self.theme.Second
		tab.button.TextColor3 = selected and Color3.new(1, 1, 1) or self.theme.Text
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
	if self._responsiveCleanup then
		self._responsiveCleanup()
		self._responsiveCleanup = nil
	end
	if self._dragCleanup then
		self._dragCleanup()
		self._dragCleanup = nil
	end
	self.root:Destroy()
end

return WindowController
