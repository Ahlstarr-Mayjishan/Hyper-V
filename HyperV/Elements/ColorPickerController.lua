--!strict

local ColorPickerController = {}
ColorPickerController.__index = ColorPickerController

local function isPointInsideGui(guiObject: GuiObject, position: Vector3): boolean
	local absolutePosition = guiObject.AbsolutePosition
	local absoluteSize = guiObject.AbsoluteSize
	return position.X >= absolutePosition.X
		and position.X <= (absolutePosition.X + absoluteSize.X)
		and position.Y >= absolutePosition.Y
		and position.Y <= (absolutePosition.Y + absoluteSize.Y)
end

local function getPopupPixelSize(guiObject: GuiObject): Vector2
	local width = guiObject.AbsoluteSize.X
	local height = guiObject.AbsoluteSize.Y

	if width <= 0 then
		width = guiObject.Size.X.Offset
	end

	if height <= 0 then
		height = guiObject.Size.Y.Offset
	end

	return Vector2.new(width, height)
end

local function resolvePopupPosition(anchor: GuiObject, popup: GuiObject, parentGui: GuiObject): UDim2
	local gap = 8
	local popupSize = getPopupPixelSize(popup)
	local parentPosition = parentGui.AbsolutePosition
	local parentSize = parentGui.AbsoluteSize
	local anchorPosition = anchor.AbsolutePosition
	local anchorSize = anchor.AbsoluteSize

	local rightX = anchorPosition.X - parentPosition.X + anchorSize.X + gap
	local leftX = anchorPosition.X - parentPosition.X - popupSize.X - gap
	local belowY = anchorPosition.Y - parentPosition.Y + anchorSize.Y + gap
	local aboveY = anchorPosition.Y - parentPosition.Y - popupSize.Y - gap

	local useRight = rightX + popupSize.X <= parentSize.X
	local x = if useRight then rightX else leftX
	if x < 0 then
		x = math.clamp(anchorPosition.X - parentPosition.X - math.floor(popupSize.X * 0.5) + math.floor(anchorSize.X * 0.5), 0, math.max(0, parentSize.X - popupSize.X))
	end

	local useBelow = belowY + popupSize.Y <= parentSize.Y
	local y = if useBelow then belowY else aboveY
	if y < 0 then
		y = math.clamp(anchorPosition.Y - parentPosition.Y, 0, math.max(0, parentSize.Y - popupSize.Y))
	end

	return UDim2.new(
		0,
		math.clamp(x, 0, math.max(0, parentSize.X - popupSize.X)),
		0,
		math.clamp(y, 0, math.max(0, parentSize.Y - popupSize.Y))
	)
end

function ColorPickerController.new(config, context)
	local self = setmetatable({}, ColorPickerController)
	self._context = context
	self._currentColor = config.Default or Color3.new(1, 1, 1)
	self._hue = 0
	self._saturation = 0
	self._value = 1
	self._dragging = nil
	self._onChanged = nil

	local root = Instance.new("Frame")
	root.Name = config.Name or "ColorPicker"
	root.Size = UDim2.new(0, 198, 0, 208)
	root.Visible = false
	root.BackgroundColor3 = context.theme.Default
	root.BorderSizePixel = 0
	root:SetAttribute("HyperVRole", "PickerPopup")
	root.Parent = config.Parent
	context.toolkit:CreateCorner(root, 10)
	context.toolkit:CreateStroke(root, context.theme.Border)
	self.view = root

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = root

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 16)
	title.BackgroundTransparency = 1
	title.Text = config.Title or "Color Picker"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = context.theme.TitleText
	title.TextSize = 12
	title.Font = Enum.Font.GothamBold
	title:SetAttribute("HyperVRole", "SectionTitle")
	title.Parent = root

	local preview = Instance.new("Frame")
	preview.Size = UDim2.new(1, 0, 0, 22)
	preview.BackgroundColor3 = self._currentColor
	preview.BorderSizePixel = 0
	preview:SetAttribute("HyperVRole", "FieldInput")
	preview.Parent = root
	context.toolkit:CreateCorner(preview, 6)
	context.toolkit:CreateStroke(preview, context.theme.Border)
	self._preview = preview

	local svRow = Instance.new("Frame")
	svRow.Size = UDim2.new(1, 0, 0, 110)
	svRow.BackgroundTransparency = 1
	svRow.Parent = root

	local sv = Instance.new("Frame")
	sv.Size = UDim2.new(1, -20, 1, 0)
	sv.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
	sv.BorderSizePixel = 0
	sv:SetAttribute("HyperVRole", "PickerSurface")
	sv.Parent = svRow
	context.toolkit:CreateCorner(sv, 8)
	self._sv = sv

	local whiteOverlay = Instance.new("Frame")
	whiteOverlay.Size = UDim2.fromScale(1, 1)
	whiteOverlay.BackgroundColor3 = Color3.new(1, 1, 1)
	whiteOverlay.BorderSizePixel = 0
	whiteOverlay.Parent = sv
	context.toolkit:CreateCorner(whiteOverlay, 8)
	local whiteGradient = Instance.new("UIGradient")
	whiteGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	whiteGradient.Parent = whiteOverlay

	local blackOverlay = Instance.new("Frame")
	blackOverlay.Size = UDim2.fromScale(1, 1)
	blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	blackOverlay.BorderSizePixel = 0
	blackOverlay.Parent = sv
	context.toolkit:CreateCorner(blackOverlay, 8)
	local blackGradient = Instance.new("UIGradient")
	blackGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	blackGradient.Rotation = 90
	blackGradient.Parent = blackOverlay

	local svCursor = Instance.new("Frame")
	svCursor.Size = UDim2.new(0, 12, 0, 12)
	svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	svCursor.BorderSizePixel = 0
	svCursor.Parent = sv
	context.toolkit:CreateCorner(svCursor, 6)
	context.toolkit:CreateStroke(svCursor, Color3.new(0, 0, 0))
	self._svCursor = svCursor

	local hueBar = Instance.new("Frame")
	hueBar.Size = UDim2.new(0, 12, 1, 0)
	hueBar.Position = UDim2.new(1, -12, 0, 0)
	hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
	hueBar.BorderSizePixel = 0
	hueBar.Parent = svRow
	context.toolkit:CreateCorner(hueBar, 6)
	local hueGradient = Instance.new("UIGradient")
	hueGradient.Rotation = 90
	hueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	})
	hueGradient.Parent = hueBar
	self._hueBar = hueBar

	local hueCursor = Instance.new("Frame")
	hueCursor.Size = UDim2.new(1, 4, 0, 4)
	hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	hueCursor.BorderSizePixel = 0
	hueCursor.Parent = hueBar
	context.toolkit:CreateCorner(hueCursor, 2)
	context.toolkit:CreateStroke(hueCursor, Color3.new(0, 0, 0))
	self._hueCursor = hueCursor

	local rgbRow = Instance.new("Frame")
	rgbRow.Size = UDim2.new(1, 0, 0, 22)
	rgbRow.BackgroundTransparency = 1
	rgbRow.Parent = root
	local rgbLayout = Instance.new("UIListLayout")
	rgbLayout.FillDirection = Enum.FillDirection.Horizontal
	rgbLayout.Padding = UDim.new(0, 4)
	rgbLayout.Parent = rgbRow

	self._rgbBoxes = {}
	for _ = 1, 3 do
		local input = Instance.new("TextBox")
		input.Size = UDim2.new(0.333, -3, 1, 0)
		input.BackgroundColor3 = context.theme.Second
		input.BorderSizePixel = 0
		input.TextColor3 = context.theme.Text
		input.TextSize = 10
		input.Font = Enum.Font.Gotham
		input.ClearTextOnFocus = false
		input.Parent = rgbRow
		context.toolkit:CreateCorner(input, 6)
		context.toolkit:CreateStroke(input, context.theme.Border)
		table.insert(self._rgbBoxes, input)
	end

	local function emitRgb()
		local r = math.clamp(tonumber(self._rgbBoxes[1].Text) or 255, 0, 255)
		local g = math.clamp(tonumber(self._rgbBoxes[2].Text) or 255, 0, 255)
		local b = math.clamp(tonumber(self._rgbBoxes[3].Text) or 255, 0, 255)
		self:setColor(Color3.fromRGB(r, g, b), true)
	end
	for _, input in ipairs(self._rgbBoxes) do
		input.FocusLost:Connect(emitRgb)
	end

	self:setColor(self._currentColor, false)
	return self
end

function ColorPickerController:setColor(value: Color3, emit: boolean)
	self._currentColor = value
	local hue, saturation, brightness = value:ToHSV()
	self._hue = hue
	self._saturation = saturation
	self._value = brightness
	self._preview.BackgroundColor3 = value
	self._sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
	self._svCursor.Position = UDim2.new(saturation, 0, 1 - brightness, 0)
	self._hueCursor.Position = UDim2.new(0.5, 0, hue, 0)
	self._rgbBoxes[1].Text = tostring(math.floor(value.R * 255 + 0.5))
	self._rgbBoxes[2].Text = tostring(math.floor(value.G * 255 + 0.5))
	self._rgbBoxes[3].Text = tostring(math.floor(value.B * 255 + 0.5))
	if emit and self._onChanged then
		self._onChanged(value)
	end
end

function ColorPickerController:createSwatch(parent: Instance, initialColor: Color3, onChanged: (Color3) -> ())
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 28, 0, 22)
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, 0, 0.5, 0)
	button.BackgroundColor3 = initialColor
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button:SetAttribute("HyperVRole", "ColorSwatch")
	button.Parent = parent
	self._context.toolkit:CreateCorner(button, 6)
	self._context.toolkit:CreateStroke(button, self._context.theme.Border)

	local current = initialColor
	button.MouseButton1Click:Connect(function()
		if self.view.Visible and self._onChanged == onChanged then
			self:close()
			return
		end
		self:openFor(button, current, function(nextColor)
			current = nextColor
			button.BackgroundColor3 = nextColor
			onChanged(nextColor)
		end)
	end)

	return {
		button = button,
		setValue = function(_, value: Color3)
			current = value
			button.BackgroundColor3 = value
			if self.view.Visible and self._onChanged == onChanged then
				self:setColor(value, false)
			end
		end,
	}
end

function ColorPickerController:openFor(anchor: GuiObject, value: Color3, onChanged: (Color3) -> ())
	self._onChanged = onChanged
	self.view.Visible = true
	local parentGui = self.view.Parent :: GuiObject
	self.view.Position = resolvePopupPosition(anchor, self.view, parentGui)
	self:setColor(value, false)
end

function ColorPickerController:close()
	self.view.Visible = false
	self._dragging = nil
	self._onChanged = nil
end

function ColorPickerController:handleInputChanged(input: InputObject)
	if not self.view.Visible or not self._dragging then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	if self._dragging == "sv" then
		local width = math.max(self._sv.AbsoluteSize.X, 1)
		local height = math.max(self._sv.AbsoluteSize.Y, 1)
		local saturation = math.clamp((input.Position.X - self._sv.AbsolutePosition.X) / width, 0, 1)
		local value = 1 - math.clamp((input.Position.Y - self._sv.AbsolutePosition.Y) / height, 0, 1)
		self:setColor(Color3.fromHSV(self._hue, saturation, value), true)
	elseif self._dragging == "hue" then
		local height = math.max(self._hueBar.AbsoluteSize.Y, 1)
		local hue = math.clamp((input.Position.Y - self._hueBar.AbsolutePosition.Y) / height, 0, 1)
		self:setColor(Color3.fromHSV(hue, self._saturation, self._value), true)
	end
end

function ColorPickerController:handleInputBegan(input: InputObject)
	if not self.view.Visible then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if isPointInsideGui(self._sv, input.Position) then
		self._dragging = "sv"
		local width = math.max(self._sv.AbsoluteSize.X, 1)
		local height = math.max(self._sv.AbsoluteSize.Y, 1)
		local saturation = math.clamp((input.Position.X - self._sv.AbsolutePosition.X) / width, 0, 1)
		local value = 1 - math.clamp((input.Position.Y - self._sv.AbsolutePosition.Y) / height, 0, 1)
		self:setColor(Color3.fromHSV(self._hue, saturation, value), true)
		return
	end
	if isPointInsideGui(self._hueBar, input.Position) then
		self._dragging = "hue"
		local height = math.max(self._hueBar.AbsoluteSize.Y, 1)
		local hue = math.clamp((input.Position.Y - self._hueBar.AbsolutePosition.Y) / height, 0, 1)
		self:setColor(Color3.fromHSV(hue, self._saturation, self._value), true)
		return
	end
	if not isPointInsideGui(self.view, input.Position) then
		self:close()
	end
end

function ColorPickerController:handleInputEnded(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		self._dragging = nil
	end
end

function ColorPickerController:applyTheme(theme)
	self._context.theme = theme
	self.view.BackgroundColor3 = theme.Default
	local stroke = self.view:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = theme.Border
	end
	for _, box in ipairs(self._rgbBoxes) do
		box.BackgroundColor3 = theme.Second
		box.TextColor3 = theme.Text
		local boxStroke = box:FindFirstChildOfClass("UIStroke")
		if boxStroke then
			boxStroke.Color = theme.Border
		end
	end
	self._preview.BackgroundColor3 = self._currentColor
	local previewStroke = self._preview:FindFirstChildOfClass("UIStroke")
	if previewStroke then
		previewStroke.Color = theme.Border
	end
	self._sv.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)
end

function ColorPickerController:dispose()
	self:close()
	self.view:Destroy()
end

return ColorPickerController
