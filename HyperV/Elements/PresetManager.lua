--!strict

local HttpService = game:GetService("HttpService")

local PresetManager = {}
PresetManager.__index = PresetManager

function PresetManager.new(config, context)
	local self = setmetatable({}, PresetManager)
	self.id = config.Name or "PresetManager"
	self.kind = "presetManager"
	self.title = config.Title or "Presets"
	self.parentFrame = config.Parent
	self._registry = context.presetRegistry
	self._theme = context.theme
	self._toolkit = context.toolkit
	self._presets = table.clone(config.Presets or { "Default" })
	self._current = self._presets[config.Default or 1] or self._presets[1]

	local container = Instance.new("Frame")
	container.Name = self.id
	container.Size = UDim2.new(1, 0, 0, 72)
	container.BackgroundColor3 = context.theme.Default
	container.BorderSizePixel = 0
	container.Parent = config.Parent
	context.toolkit:CreateCorner(container, 8)
	context.toolkit:CreateStroke(container, context.theme.Border)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -110, 0, 18)
	title.Position = UDim2.new(0, 10, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = self.title
	title.TextColor3 = context.theme.TitleText
	title.TextSize = 13
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = container

	local exportButton = Instance.new("TextButton")
	exportButton.Size = UDim2.new(0, 44, 0, 20)
	exportButton.Position = UDim2.new(1, -100, 0, 5)
	exportButton.BackgroundColor3 = context.theme.Second
	exportButton.BorderSizePixel = 0
	exportButton.Text = "Exp"
	exportButton.TextColor3 = context.theme.Text
	exportButton.TextSize = 10
	exportButton.Font = Enum.Font.GothamBold
	exportButton.Parent = container
	context.toolkit:CreateCorner(exportButton, 5)

	local importButton = Instance.new("TextButton")
	importButton.Size = UDim2.new(0, 44, 0, 20)
	importButton.Position = UDim2.new(1, -52, 0, 5)
	importButton.BackgroundColor3 = context.theme.Second
	importButton.BorderSizePixel = 0
	importButton.Text = "Imp"
	importButton.TextColor3 = context.theme.Text
	importButton.TextSize = 10
	importButton.Font = Enum.Font.GothamBold
	importButton.Parent = container
	context.toolkit:CreateCorner(importButton, 5)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -20, 0, 28)
	bar.Position = UDim2.new(0, 10, 0, 34)
	bar.BackgroundTransparency = 1
	bar.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.Parent = bar

	self.view = container
	self.Container = container
	self._buttons = {}

	for _, presetName in ipairs(self._presets) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 84, 0, 28)
		button.BackgroundColor3 = presetName == self._current and context.theme.Accent or context.theme.Second
		button.BorderSizePixel = 0
		button.Text = presetName
		button.TextColor3 = presetName == self._current and Color3.new(1, 1, 1) or context.theme.Text
		button.TextSize = 11
		button.Font = Enum.Font.GothamBold
		button.Parent = bar
		context.toolkit:CreateCorner(button, 6)

		button.MouseButton1Click:Connect(function()
			self:load(presetName)
		end)

		button.MouseButton2Click:Connect(function()
			self:save(presetName)
		end)

		self._buttons[presetName] = button
	end

	exportButton.MouseButton1Click:Connect(function()
		local payload = self:export(self._current)
		if setclipboard then
			pcall(setclipboard, payload)
		end
	end)

	importButton.MouseButton1Click:Connect(function()
		importButton.Text = "API"
		task.delay(1, function()
			if importButton.Parent then
				importButton.Text = "Imp"
			end
		end)
	end)

	return self
end

function PresetManager:_refreshButtons()
	for presetName, button in pairs(self._buttons) do
		local selected = presetName == self._current
		button.BackgroundColor3 = selected and self._theme.Accent or self._theme.Second
		button.TextColor3 = selected and Color3.new(1, 1, 1) or self._theme.Text
	end
end

function PresetManager:save(name: string)
	self._registry:save(name)
end

function PresetManager:load(name: string)
	self._current = name
	self._registry:load(name)
	self:_refreshButtons()
end

function PresetManager:export(name: string): string
	self._registry:save(name)
	return self._registry:export(name)
end

function PresetManager:import(name: string, payload: string): boolean
	local ok = self._registry:import(name, payload)
	if ok then
		self._registry:load(name)
	end
	return ok
end

function PresetManager:dispose()
	self.view:Destroy()
end

return PresetManager
