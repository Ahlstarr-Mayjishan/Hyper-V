--!strict

local FloatingSectionController = require(script.Parent.FloatingSectionController)

local SectionHandle = {}
SectionHandle.__index = SectionHandle

function SectionHandle.new(config, context)
	local self = setmetatable({}, SectionHandle)
	self.id = config.Id
	self.kind = "section"
	self.title = config.Title
	self._context = context
	self.parentFrame = config.Parent
	self._collapsed = config.DefaultCollapsed == true
	self._collapsible = config.Collapsible ~= false

	local frame = Instance.new("Frame")
	frame.Name = self.id
	frame.Size = UDim2.new(1, 0, 0, config.Height or 180)
	frame.BackgroundColor3 = context.theme.Default
	frame.BorderSizePixel = 0
	frame.Parent = config.Parent
	context.toolkit:CreateCorner(frame, 8)
	context.toolkit:CreateStroke(frame, context.theme.Border)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 28)
	header.BackgroundColor3 = context.theme.Second
	header.BorderSizePixel = 0
	header.Parent = frame
	context.toolkit:CreateCorner(header, 8)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -90, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = config.Title
	title.TextColor3 = context.theme.TitleText
	title.TextSize = 13
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local collapseButton = Instance.new("TextButton")
	collapseButton.Size = UDim2.new(0, 24, 0, 20)
	collapseButton.Position = UDim2.new(1, -56, 0.5, -10)
	collapseButton.BackgroundColor3 = context.theme.Default
	collapseButton.BorderSizePixel = 0
	collapseButton.Text = self._collapsed and "+" or "-"
	collapseButton.TextColor3 = context.theme.Text
	collapseButton.TextSize = 12
	collapseButton.Font = Enum.Font.GothamBold
	collapseButton.Parent = header
	context.toolkit:CreateCorner(collapseButton, 5)
	collapseButton.Visible = self._collapsible

	local detachButton = Instance.new("TextButton")
	detachButton.Size = UDim2.new(0, 24, 0, 20)
	detachButton.Position = UDim2.new(1, -28, 0.5, -10)
	detachButton.BackgroundColor3 = context.theme.Accent
	detachButton.BorderSizePixel = 0
	detachButton.Text = "D"
	detachButton.TextColor3 = Color3.new(1, 1, 1)
	detachButton.TextSize = 11
	detachButton.Font = Enum.Font.GothamBold
	detachButton.Parent = header
	context.toolkit:CreateCorner(detachButton, 5)

	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -10, 1, -38)
	content.Position = UDim2.new(0, 5, 0, 33)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 2
	content.Parent = frame

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, context.layout.SectionGap)
	list.Parent = content
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		content.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 8)
	end)

	self.frame = frame
	self.view = frame
	self.contentFrame = content
	self.Content = content
	self._collapseButton = collapseButton
	self._detachButton = detachButton
	self._floating = nil
	self._restoreParent = config.Parent

	collapseButton.MouseButton1Click:Connect(function()
		self:toggleCollapsed()
	end)

	detachButton.MouseButton1Click:Connect(function()
		self:detach()
	end)

	if self._collapsed then
		self:setCollapsed(true)
	end

	return self
end

function SectionHandle:setCollapsed(collapsed: boolean)
	self._collapsed = collapsed
	self.contentFrame.Visible = not collapsed
	self._collapseButton.Text = collapsed and "+" or "-"
	self.frame.Size = UDim2.new(self.frame.Size.X.Scale, self.frame.Size.X.Offset, 0, collapsed and 32 or math.max(self.frame.Size.Y.Offset, 120))
end

function SectionHandle:toggleCollapsed()
	if not self._collapsible then
		return
	end
	self:setCollapsed(not self._collapsed)
end

function SectionHandle:createSubTabs(config)
	return self._context.app:createSubTabs(table.clone(config), self.contentFrame)
end

function SectionHandle:detach(position)
	if self._floating then
		return self._floating:getWindow()
	end

	self._floating = FloatingSectionController.new(self, {
		Position = position,
	}, self._context)
	self.frame.Parent = self._floating:getWindow().contentFrame
	self.parentFrame = self._floating:getWindow().contentFrame
	return self._floating:getWindow()
end

function SectionHandle:dock(target)
	self._context.dockRegistry:dock(self, if type(target) == "string" then target else target.id)
end

function SectionHandle:dockBack()
	if self._floating then
		self.frame.Parent = self._restoreParent
		self.parentFrame = self._restoreParent
		self._floating:dispose()
		self._floating = nil
	end
end

function SectionHandle:dispose()
	if self._floating then
		self._floating:dispose()
	end
	self.frame:Destroy()
end

return SectionHandle
