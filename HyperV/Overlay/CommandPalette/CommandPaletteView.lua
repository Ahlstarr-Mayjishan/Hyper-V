--!strict

local DisposableStore = require(script.Parent.Parent.Parent.Core.DisposableStore)

export type CommandPaletteView = {
	overlay: Frame,
	input: TextBox,
	setVisible: (self: CommandPaletteView, visible: boolean) -> (),
	setItems: (self: CommandPaletteView, items: { any }, selectedId: string?) -> (),
	setQuery: (self: CommandPaletteView, query: string) -> (),
	dispose: (self: CommandPaletteView) -> (),
}

local CommandPaletteView = {}
CommandPaletteView.__index = CommandPaletteView

function CommandPaletteView.new(parent: Instance, theme, toolkit, callbacks)
	local self = setmetatable({}, CommandPaletteView)
	self._disposables = DisposableStore.new()
	self._rowDisposables = DisposableStore.new()
	self._theme = theme
	self._callbacks = callbacks or {}

	local overlay = Instance.new("Frame")
	overlay.Name = "CommandPaletteOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.Visible = false
	overlay.Parent = parent

	local panel = Instance.new("Frame")
	panel.Name = "CommandPalettePanel"
	panel.Size = UDim2.new(0, 420, 0, 320)
	panel.Position = UDim2.new(0.5, -210, 0.18, 0)
	panel.BackgroundColor3 = theme.Main
	panel.BorderSizePixel = 0
	panel.Parent = overlay
	toolkit:CreateCorner(panel, 10)
	toolkit:CreateStroke(panel, theme.Border)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 22)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "Command Palette"
	title.TextColor3 = theme.TitleText
	title.TextSize = 13
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -20, 0, 32)
	input.Position = UDim2.new(0, 10, 0, 34)
	input.BackgroundColor3 = theme.Second
	input.BorderSizePixel = 0
	input.PlaceholderText = "Type a command..."
	input.Text = ""
	input.TextColor3 = theme.Text
	input.PlaceholderColor3 = theme.SecondText
	input.TextSize = 12
	input.Font = Enum.Font.Gotham
	input.ClearTextOnFocus = false
	input.Parent = panel
	toolkit:CreateCorner(input, 6)
	toolkit:CreateStroke(input, theme.Border)

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -20, 1, -82)
	list.Position = UDim2.new(0, 10, 0, 72)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list
	self._disposables:add(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	end))

	self._disposables:add(overlay.InputBegan:Connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 and inputObject.Target == overlay and self._callbacks.onClose then
			self._callbacks.onClose()
		end
	end))

	self._disposables:add(input:GetPropertyChangedSignal("Text"):Connect(function()
		if self._callbacks.onQueryChanged then
			self._callbacks.onQueryChanged(input.Text)
		end
	end))

	self.overlay = overlay
	self.input = input
	self._list = list
	self._layout = layout
	self._theme = theme
	self._toolkit = toolkit

	return self :: any
end

function CommandPaletteView:setVisible(visible: boolean)
	self.overlay.Visible = visible
end

function CommandPaletteView:setQuery(query: string)
	self.input.Text = query
end

function CommandPaletteView:setItems(items: { any }, selectedId: string?)
	self._rowDisposables:cleanup()

	for _, child in ipairs(self._list:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	if #items == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 28)
		empty.BackgroundTransparency = 1
		empty.Text = "No commands"
		empty.TextColor3 = self._theme.Text
		empty.TextSize = 12
		empty.Font = Enum.Font.Gotham
		empty.Parent = self._list
		return
	end

	for _, item in ipairs(items) do
		local selected = item.id == selectedId
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 42)
		button.BackgroundColor3 = selected and self._theme.Accent or self._theme.Second
		button.BorderSizePixel = 0
		button.Text = ""
		button.Parent = self._list
		self._toolkit:CreateCorner(button, 6)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -12, 0, 18)
		title.Position = UDim2.new(0, 8, 0, 4)
		title.BackgroundTransparency = 1
		title.Text = item.title
		title.TextColor3 = selected and Color3.new(1, 1, 1) or self._theme.TitleText
		title.TextSize = 12
		title.Font = Enum.Font.GothamBold
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = button

		local description = Instance.new("TextLabel")
		description.Size = UDim2.new(1, -12, 0, 14)
		description.Position = UDim2.new(0, 8, 0, 22)
		description.BackgroundTransparency = 1
		description.Text = item.description or ""
		description.TextColor3 = selected and Color3.new(0.92, 0.92, 0.92) or self._theme.SecondText
		description.TextSize = 10
		description.Font = Enum.Font.Gotham
		description.TextXAlignment = Enum.TextXAlignment.Left
		description.Parent = button

		self._rowDisposables:add(button.MouseButton1Click:Connect(function()
			if self._callbacks.onActivate then
				self._callbacks.onActivate(item.id)
			end
		end))
	end
end

function CommandPaletteView:dispose()
	self._rowDisposables:cleanup()
	self._disposables:cleanup()
	self.overlay:Destroy()
end

return CommandPaletteView
