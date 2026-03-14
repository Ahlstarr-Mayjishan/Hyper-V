--!strict

local ColorPickerController = require(script.Parent.Parent.Elements.ColorPickerController)
local PresetManager = require(script.Parent.Parent.Elements.PresetManager)

local AppElementFactory = {}

function AppElementFactory.createButton(self, config, parentOverride)
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
	self.toolkit:SetRole(button, "Button")
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

function AppElementFactory.createLabel(self, config, parentOverride)
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
	self.toolkit:SetRole(label, "FieldLabel")

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

function AppElementFactory.createSection(self, config)
	assert(self.currentWindow, "createSection requires an active window")
	return self.currentWindow:createSection(config)
end

function AppElementFactory.createAccordionSection(self, config)
	config.Collapsible = true
	return self:createSection(config)
end

function AppElementFactory.createNumberInput(self, config)
	return self.legacyRendererFactory:createNumberInput(config)
end

function AppElementFactory.createRangeSlider(self, config)
	return self.legacyRendererFactory:createRangeSlider(config)
end

function AppElementFactory.createMultiSelectDropdown(self, config)
	return self.legacyRendererFactory:createMultiSelectDropdown(config)
end

function AppElementFactory.createCodeBlock(self, config)
	return self.legacyRendererFactory:createCodeBlock(config)
end

function AppElementFactory.createColorPicker(self, config)
	local picker = ColorPickerController.new(config, self._context)
	self:_registerStylable(picker)
	return picker
end

function AppElementFactory.createSubTabs(self, config, parentOverride)
	local nextConfig = table.clone(config)
	nextConfig.Parent = parentOverride or config.Parent
	return self.legacyRendererFactory:createSubTabs(nextConfig)
end

function AppElementFactory.createTreeView(self, config)
	return self.legacyRendererFactory:createTreeView(config)
end

function AppElementFactory.createVirtualList(self, config)
	return self.legacyRendererFactory:createVirtualList(config)
end

function AppElementFactory.createPresetManager(self, config)
	return PresetManager.new(config, self._context)
end

return AppElementFactory
