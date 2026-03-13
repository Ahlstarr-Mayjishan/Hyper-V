--!strict

local PreviewControlsFactory = {}

local function formatNumber(value: number): string
	local rounded = math.floor((value * 100) + 0.5) / 100
	local text = string.format("%.2f", rounded)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return text
end

function PreviewControlsFactory.createSection(parent: Instance, toolkit, theme, titleText: string)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundColor3 = theme.Default
	frame.BorderSizePixel = 0
	frame:SetAttribute("HyperVRole", "SectionSurface")
	frame.Parent = parent
	toolkit:CreateCorner(frame, 8)
	toolkit:CreateStroke(frame, theme.Border)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -12, 0, 18)
	title.Position = UDim2.new(0, 8, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = theme.TitleText
	title.TextSize = 12
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title:SetAttribute("HyperVRole", "SectionTitle")
	title.Parent = frame

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, -12, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Position = UDim2.new(0, 6, 0, 28)
	body.BackgroundTransparency = 1
	body.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = body

	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = body

	return body
end

function PreviewControlsFactory.createRow(
	parent: Instance,
	theme,
	titleText: string,
	controlWidth: number?,
	rowHeight: number?,
	minLabelWidth: number?,
	minControlWidth: number?
)
	local reservedWidth = controlWidth or 80
	local height = rowHeight or 26
	local minimumLabelWidth = minLabelWidth or 72
	local minimumControl = minControlWidth or math.min(reservedWidth, 44)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, height)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -(reservedWidth + 10), 1, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = theme.Text
	title.TextSize = 11
	title.Font = Enum.Font.Gotham
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title:SetAttribute("HyperVRole", "FieldLabel")
	title.Parent = row

	local controlHost = Instance.new("Frame")
	controlHost.Name = "ControlHost"
	controlHost.Size = UDim2.new(0, reservedWidth, 1, 0)
	controlHost.Position = UDim2.new(1, -reservedWidth, 0, 0)
	controlHost.BackgroundTransparency = 1
	controlHost.Parent = row

	local function updateLayout()
		local availableWidth = math.max(row.AbsoluteSize.X, reservedWidth + minimumLabelWidth + 10)
		local maxControlWidth = math.max(minimumControl, availableWidth - (minimumLabelWidth + 10))
		local adaptiveWidth = math.min(reservedWidth, maxControlWidth)
		adaptiveWidth = math.max(minimumControl, adaptiveWidth)
		controlHost.Size = UDim2.new(0, adaptiveWidth, 1, 0)
		controlHost.Position = UDim2.new(1, -adaptiveWidth, 0, 0)
		title.Size = UDim2.new(1, -(adaptiveWidth + 10), 1, 0)
	end

	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
	updateLayout()

	return row, controlHost
end

function PreviewControlsFactory.createToggle(parent: Instance, toolkit, theme, titleText: string, onChanged: (boolean) -> ())
	local row, controlHost = PreviewControlsFactory.createRow(parent, theme, titleText, 42)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 42, 0, 22)
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, 0, 0.5, 0)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = ""
	button.Parent = controlHost

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 1, 0)
	track.BackgroundColor3 = theme.Second
	track.BorderSizePixel = 0
	track:SetAttribute("HyperVRole", "ToggleTrack")
	track.Parent = button
	toolkit:CreateCorner(track, 11)

	local trackStroke = toolkit:CreateStroke(track, theme.Border)
	if trackStroke then
		trackStroke.Transparency = 0.35
	end

	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.new(0, 16, 0, 16)
	thumb.Position = UDim2.new(0, 3, 0.5, -8)
	thumb.BackgroundColor3 = Color3.new(1, 1, 1)
	thumb.BorderSizePixel = 0
	thumb:SetAttribute("HyperVRole", "ToggleThumb")
	thumb.Parent = track
	toolkit:CreateCorner(thumb, 8)

	local control = {}
	function control:setValue(value: boolean)
		track.BackgroundColor3 = if value then theme.Accent else theme.Second
		thumb.Position = if value
			then UDim2.new(1, -19, 0.5, -8)
			else UDim2.new(0, 3, 0.5, -8)
	end

	button.MouseButton1Click:Connect(function()
		local nextValue = thumb.Position.X.Scale == 0
		control:setValue(nextValue)
		onChanged(nextValue)
	end)

	return control
end

function PreviewControlsFactory.createTextInput(
	parent: Instance,
	toolkit,
	theme,
	titleText: string,
	width: number,
	onChanged: (string) -> ()
)
	local _, controlHost = PreviewControlsFactory.createRow(parent, theme, titleText, width)
	local input = Instance.new("TextBox")
	input.Size = UDim2.new(0, width, 0, 22)
	input.AnchorPoint = Vector2.new(1, 0.5)
	input.Position = UDim2.new(1, 0, 0.5, 0)
	input.BackgroundColor3 = theme.Second
	input.BorderSizePixel = 0
	input.TextColor3 = theme.Text
	input.TextSize = 11
	input.Font = Enum.Font.Gotham
	input.ClearTextOnFocus = false
	input:SetAttribute("HyperVRole", "FieldInput")
	input.Parent = controlHost
	toolkit:CreateCorner(input, 6)
	toolkit:CreateStroke(input, theme.Border)

	input.FocusLost:Connect(function()
		onChanged(input.Text)
	end)

	return {
		setValue = function(_, value)
			if type(value) == "number" then
				input.Text = formatNumber(value)
			else
				input.Text = tostring(value)
			end
		end,
		input = input,
	}
end

function PreviewControlsFactory.createNumberInput(parent: Instance, toolkit, theme, titleText: string, onChanged: (number) -> ())
	return PreviewControlsFactory.createTextInput(parent, toolkit, theme, titleText, 80, function(text)
		onChanged(tonumber(text) or 0)
	end)
end

function PreviewControlsFactory.createSlider(
	parent: Instance,
	toolkit,
	theme,
	titleText: string,
	minValue: number,
	maxValue: number,
	onChanged: (number) -> ()
)
	local sectionRow = Instance.new("Frame")
	sectionRow.Size = UDim2.new(1, 0, 0, 44)
	sectionRow.BackgroundTransparency = 1
	sectionRow.Parent = parent

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -62, 0, 16)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = theme.Text
	title.TextSize = 11
	title.Font = Enum.Font.Gotham
	title.TextXAlignment = Enum.TextXAlignment.Left
	title:SetAttribute("HyperVRole", "FieldLabel")
	title.Parent = sectionRow

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0, 56, 0, 16)
	valueLabel.Position = UDim2.new(1, -56, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextColor3 = theme.Accent
	valueLabel.TextSize = 11
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel:SetAttribute("HyperVRole", "AccentValue")
	valueLabel.Parent = sectionRow

	local function updateSliderLayout()
		local valueWidth = math.max(48, math.min(72, math.floor(sectionRow.AbsoluteSize.X * 0.28)))
		valueLabel.Size = UDim2.new(0, valueWidth, 0, 16)
		valueLabel.Position = UDim2.new(1, -valueWidth, 0, 0)
		title.Size = UDim2.new(1, -(valueWidth + 8), 0, 16)
	end

	sectionRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSliderLayout)
	updateSliderLayout()

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.new(0, 0, 0, 24)
	bar.BackgroundColor3 = theme.Second
	bar.BorderSizePixel = 0
	bar:SetAttribute("HyperVRole", "SliderTrack")
	bar.Parent = sectionRow
	toolkit:CreateCorner(bar, 4)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = theme.Accent
	fill.BorderSizePixel = 0
	fill:SetAttribute("HyperVRole", "SliderFill")
	fill.Parent = bar
	toolkit:CreateCorner(fill, 4)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob:SetAttribute("HyperVRole", "SliderKnob")
	knob.Parent = bar
	toolkit:CreateCorner(knob, 7)

	local dragging = false
	local control = {}

	local function setPercent(percent: number, emit: boolean)
		local nextPercent = math.clamp(percent, 0, 1)
		fill.Size = UDim2.new(nextPercent, 0, 1, 0)
		knob.Position = UDim2.new(nextPercent, 0, 0.5, 0)
		local value = minValue + ((maxValue - minValue) * nextPercent)
		valueLabel.Text = formatNumber(value)
		if emit then
			onChanged(value)
		end
	end

	local function updateFromX(x: number, emit: boolean)
		local width = math.max(bar.AbsoluteSize.X, 1)
		local percent = (x - bar.AbsolutePosition.X) / width
		setPercent(percent, emit)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateFromX(input.Position.X, true)
		end
	end)

	bar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	function control:handleMove(input: InputObject)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromX(input.Position.X, true)
		end
	end

	function control:setValue(value: number)
		local percent = (value - minValue) / (maxValue - minValue)
		setPercent(percent, false)
	end

	return control
end

return PreviewControlsFactory
