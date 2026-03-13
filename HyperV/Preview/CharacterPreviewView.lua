--!strict

local PreviewControlsFactory = require(script.Parent.PreviewControlsFactory)

local CharacterPreviewView = {}
CharacterPreviewView.__index = CharacterPreviewView

local function setGuiZIndex(root: Instance, zIndex: number)
	if root:IsA("GuiObject") then
		root.ZIndex = zIndex
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			descendant.ZIndex = zIndex
		end
	end
end

local function createSection(parent: Instance, toolkit, theme, titleText: string)
	return PreviewControlsFactory.createSection(parent, toolkit, theme, titleText)
end

local function createRow(
	parent: Instance,
	theme,
	titleText: string,
	controlWidth: number?,
	rowHeight: number?,
	minLabelWidth: number?,
	minControlWidth: number?
)
	return PreviewControlsFactory.createRow(parent, theme, titleText, controlWidth, rowHeight, minLabelWidth, minControlWidth)
end

local function createToggle(parent: Instance, toolkit, theme, titleText: string, onChanged: (boolean) -> ())
	return PreviewControlsFactory.createToggle(parent, toolkit, theme, titleText, onChanged)
end

local function createTextInput(
	parent: Instance,
	toolkit,
	theme,
	titleText: string,
	width: number,
	onChanged: (string) -> ()
)
	return PreviewControlsFactory.createTextInput(parent, toolkit, theme, titleText, width, onChanged)
end

local function createNumberInput(parent: Instance, toolkit, theme, titleText: string, onChanged: (number) -> ())
	return PreviewControlsFactory.createNumberInput(parent, toolkit, theme, titleText, onChanged)
end

local function createSlider(
	parent: Instance,
	toolkit,
	theme,
	titleText: string,
	minValue: number,
	maxValue: number,
	onChanged: (number) -> ()
)
	return PreviewControlsFactory.createSlider(parent, toolkit, theme, titleText, minValue, maxValue, onChanged)
end

function CharacterPreviewView.new(windowHandle, context, callbacks)
	local self = setmetatable({}, CharacterPreviewView)
	self._context = context
	self._callbacks = callbacks
	self.window = windowHandle
	self.view = windowHandle.view
	self.contentFrame = windowHandle.contentFrame
	self.controls = {}
	self.sliderControls = {}
	local baseZIndex = math.max(2, (self.view.ZIndex or 1) + 2)

	local root = Instance.new("Frame")
	root.Name = "CharacterPreviewRoot"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = self.contentFrame

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Viewport"
	viewport.Size = UDim2.new(1, -246, 1, -12)
	viewport.Position = UDim2.new(0, 0, 0, 0)
	viewport.BackgroundColor3 = context.theme.Main
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(210, 210, 210)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -0.75)
	viewport:SetAttribute("HyperVRole", "ViewportSurface")
	viewport.Parent = root
	context.toolkit:CreateCorner(viewport, 8)
	context.toolkit:CreateStroke(viewport, context.theme.Border)

	local overlay = Instance.new("Frame")
	overlay.Name = "ViewportOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ClipsDescendants = true
	overlay.Parent = viewport

	local boxFrame = Instance.new("Frame")
	boxFrame.Name = "EspBox"
	boxFrame.Visible = false
	boxFrame.BackgroundTransparency = 1
	boxFrame.Parent = overlay

	local infoCard = Instance.new("Frame")
	infoCard.Name = "EspInfoCard"
	infoCard.BackgroundColor3 = context.theme.Default
	infoCard.BackgroundTransparency = 0.08
	infoCard.BorderSizePixel = 0
	infoCard.Visible = false
	infoCard:SetAttribute("HyperVRole", "InfoCard")
	infoCard.Parent = overlay
	context.toolkit:CreateCorner(infoCard, 8)
	context.toolkit:CreateStroke(infoCard, context.theme.Border)

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "EspInfo"
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextWrapped = true
	infoLabel.TextSize = 11
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextYAlignment = Enum.TextYAlignment.Top
	infoLabel.Visible = false
	infoLabel.Parent = infoCard

	local infoPadding = Instance.new("UIPadding")
	infoPadding.PaddingTop = UDim.new(0, 7)
	infoPadding.PaddingBottom = UDim.new(0, 7)
	infoPadding.PaddingLeft = UDim.new(0, 8)
	infoPadding.PaddingRight = UDim.new(0, 8)
	infoPadding.Parent = infoCard

	local tracerFrame = Instance.new("Frame")
	tracerFrame.Name = "Tracer"
	tracerFrame.Visible = false
	tracerFrame.BackgroundTransparency = 0
	tracerFrame.BorderSizePixel = 0
	tracerFrame.Parent = overlay

	local tracerGlow = Instance.new("Frame")
	tracerGlow.Name = "Glow"
	tracerGlow.Size = UDim2.fromScale(1, 1)
	tracerGlow.BackgroundTransparency = 0.55
	tracerGlow.BorderSizePixel = 0
	tracerGlow.Parent = tracerFrame

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	statusLabel.Position = UDim2.fromScale(0.5, 0.5)
	statusLabel.Size = UDim2.new(1, -32, 0, 48)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextWrapped = true
	statusLabel.TextColor3 = context.theme.SecondText
	statusLabel.TextSize = 13
	statusLabel.Font = Enum.Font.GothamMedium
	statusLabel.Visible = false
	statusLabel:SetAttribute("HyperVRole", "StatusText")
	statusLabel.Parent = viewport

	local camera = Instance.new("Camera")
	camera.Name = "PreviewCamera"
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	local sharedColorPicker = context.app:createColorPicker({
		Name = "PreviewColorPicker",
		Title = "Color Picker",
		Parent = root,
		Default = Color3.new(1, 1, 1),
	})

	local controlsPanel = Instance.new("ScrollingFrame")
	controlsPanel.Name = "Controls"
	controlsPanel.Size = UDim2.new(0, 230, 1, -56)
	controlsPanel.Position = UDim2.new(1, -230, 0, 0)
	controlsPanel.BackgroundTransparency = 0
	controlsPanel.BackgroundColor3 = context.theme.Default
	controlsPanel.BorderSizePixel = 0
	controlsPanel.ScrollBarThickness = 4
	controlsPanel.Parent = root
	controlsPanel:SetAttribute("HyperVRole", "SectionSurface")
	context.toolkit:CreateCorner(controlsPanel, 8)
	context.toolkit:CreateStroke(controlsPanel, context.theme.Border)

	local controlsPadding = Instance.new("UIPadding")
	controlsPadding.PaddingTop = UDim.new(0, 8)
	controlsPadding.PaddingBottom = UDim.new(0, 8)
	controlsPadding.PaddingLeft = UDim.new(0, 8)
	controlsPadding.PaddingRight = UDim.new(0, 8)
	controlsPadding.Parent = controlsPanel

	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.Padding = UDim.new(0, 8)
	controlsLayout.Parent = controlsPanel
	controlsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		controlsPanel.CanvasSize = UDim2.new(0, 0, 0, controlsLayout.AbsoluteContentSize.Y + 8)
	end)

	local actionsRow = Instance.new("Frame")
	actionsRow.Size = UDim2.new(0, 230, 0, 44)
	actionsRow.Position = UDim2.new(1, -230, 1, -44)
	actionsRow.BackgroundTransparency = 0
	actionsRow.BackgroundColor3 = context.theme.Default
	actionsRow.Parent = root
	actionsRow:SetAttribute("HyperVRole", "SectionSurface")
	context.toolkit:CreateCorner(actionsRow, 8)
	context.toolkit:CreateStroke(actionsRow, context.theme.Border)

	local actionLayout = Instance.new("UIListLayout")
	actionLayout.FillDirection = Enum.FillDirection.Horizontal
	actionLayout.Padding = UDim.new(0, 6)
	actionLayout.Parent = actionsRow

	local actionsPadding = Instance.new("UIPadding")
	actionsPadding.PaddingTop = UDim.new(0, 6)
	actionsPadding.PaddingBottom = UDim.new(0, 6)
	actionsPadding.PaddingLeft = UDim.new(0, 6)
	actionsPadding.PaddingRight = UDim.new(0, 6)
	actionsPadding.Parent = actionsRow

	local cancelButton = Instance.new("TextButton")
	cancelButton.Size = UDim2.new(0, 70, 0, 32)
	cancelButton.BackgroundColor3 = context.theme.Second
	cancelButton.BorderSizePixel = 0
	cancelButton.Text = "Cancel"
	cancelButton.TextColor3 = context.theme.Text
	cancelButton.TextSize = 12
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton:SetAttribute("HyperVRole", "SecondaryButton")
	cancelButton.Parent = actionsRow
	context.toolkit:CreateCorner(cancelButton, 8)

	local resetButton = cancelButton:Clone()
	resetButton.Text = "Reset"
	resetButton.Parent = actionsRow

	local applyButton = cancelButton:Clone()
	applyButton.Size = UDim2.new(0, 78, 0, 32)
	applyButton.Text = "Apply"
	applyButton.BackgroundColor3 = context.theme.Accent
	applyButton.TextColor3 = Color3.new(1, 1, 1)
	applyButton:SetAttribute("HyperVRole", "PrimaryButton")
	applyButton.Parent = actionsRow

	self.root = root
	self.viewport = viewport
	self.viewportOverlay = overlay
	self.boxFrame = boxFrame
	self.infoCard = infoCard
	self.infoLabel = infoLabel
	self._infoPadding = infoPadding
	self.tracerFrame = tracerFrame
	self.statusLabel = statusLabel
	self.camera = camera
	self.worldModel = worldModel
	self.controlsPanel = controlsPanel
	self._controlsPadding = controlsPadding
	self._controlsLayout = controlsLayout
	self._actionsRow = actionsRow
	self._actionLayout = actionLayout
	self._actionsPadding = actionsPadding
	self._cancelButton = cancelButton
	self._resetButton = resetButton
	self._applyButton = applyButton
	self._sharedColorPicker = sharedColorPicker

	local function createPreviewColorInput(parent: Instance, titleText: string, onChanged: (Color3) -> ())
		local row, controlHost = createRow(parent, context.theme, titleText, 36, nil, 88, 36)
		return sharedColorPicker:createSwatch(controlHost, Color3.new(1, 1, 1), onChanged)
	end

	local cameraSection = createSection(controlsPanel, context.toolkit, context.theme, "Camera")
	local transparencySection = createSection(controlsPanel, context.toolkit, context.theme, "Transparency")
	local highlightSection = createSection(controlsPanel, context.toolkit, context.theme, "Highlight / Chams")
	local espSection = createSection(controlsPanel, context.toolkit, context.theme, "ESP")
	local effectsSection = createSection(controlsPanel, context.toolkit, context.theme, "Effects")
	local charmsSection = createSection(controlsPanel, context.toolkit, context.theme, "Charms")

	self.controls.autoRotate = createToggle(
		cameraSection,
		context.toolkit,
		context.theme,
		"Auto Rotate",
		function(value)
			callbacks.onPatch({ orbit = { autoRotate = value } })
		end
	)
	self.controls.orbitSpeed = createNumberInput(cameraSection, context.toolkit, context.theme, "Speed", function(value)
		callbacks.onPatch({ orbit = { speed = value } })
	end)
	self.controls.orbitRadius = createNumberInput(
		cameraSection,
		context.toolkit,
		context.theme,
		"Radius",
		function(value)
			callbacks.onPatch({ orbit = { radius = value } })
		end
	)
	self.controls.orbitHeight = createNumberInput(
		cameraSection,
		context.toolkit,
		context.theme,
		"Height",
		function(value)
			callbacks.onPatch({ orbit = { height = value } })
		end
	)

	local resetViewButton = Instance.new("TextButton")
	resetViewButton.Size = UDim2.new(1, 0, 0, 26)
	resetViewButton.BackgroundColor3 = context.theme.Second
	resetViewButton.BorderSizePixel = 0
	resetViewButton.Text = "Reset View"
	resetViewButton.TextColor3 = context.theme.Text
	resetViewButton.TextSize = 11
	resetViewButton.Font = Enum.Font.GothamBold
	resetViewButton.Parent = cameraSection
	context.toolkit:CreateCorner(resetViewButton, 6)
	resetViewButton.MouseButton1Click:Connect(callbacks.onResetView)

	self.controls.transparency = createSlider(
		transparencySection,
		context.toolkit,
		context.theme,
		"Transparency",
		0,
		1,
		function(value)
			callbacks.onPatch({ transparency = value })
		end
	)
	table.insert(self.sliderControls, self.controls.transparency)

	self.controls.highlightEnabled = createToggle(
		highlightSection,
		context.toolkit,
		context.theme,
		"Enabled",
		function(value)
			callbacks.onPatch({ highlight = { enabled = value } })
		end
	)
	self.controls.highlightFillColor = createPreviewColorInput(
		highlightSection,
		"Fill Color",
		function(value)
			callbacks.onPatch({ highlight = { fillColor = value } })
		end
	)
	self.controls.highlightOutlineColor = createPreviewColorInput(
		highlightSection,
		"Outline Color",
		function(value)
			callbacks.onPatch({ highlight = { outlineColor = value } })
		end
	)
	self.controls.highlightFillTransparency = createSlider(
		highlightSection,
		context.toolkit,
		context.theme,
		"Fill Transparency",
		0,
		1,
		function(value)
			callbacks.onPatch({ highlight = { fillTransparency = value } })
		end
	)
	table.insert(self.sliderControls, self.controls.highlightFillTransparency)
	self.controls.highlightOutlineTransparency = createSlider(
		highlightSection,
		context.toolkit,
		context.theme,
		"Outline Transparency",
		0,
		1,
		function(value)
			callbacks.onPatch({ highlight = { outlineTransparency = value } })
		end
	)
	table.insert(self.sliderControls, self.controls.highlightOutlineTransparency)
	self.controls.depthMode = createToggle(
		highlightSection,
		context.toolkit,
		context.theme,
		"Always On Top",
		function(value)
			callbacks.onPatch({
				highlight = {
					depthMode = if value then Enum.HighlightDepthMode.AlwaysOnTop else Enum.HighlightDepthMode.Occluded,
				},
			})
		end
	)

	self.controls.espBoxEnabled = createToggle(espSection, context.toolkit, context.theme, "ESP Box", function(value)
		callbacks.onPatch({ espBox = { enabled = value } })
	end)
	self.controls.espBoxColor = createPreviewColorInput(
		espSection,
		"Box Color",
		function(value)
			callbacks.onPatch({ espBox = { color = value } })
		end
	)
	self.controls.espBoxThickness = createNumberInput(
		espSection,
		context.toolkit,
		context.theme,
		"Box Thickness",
		function(value)
			callbacks.onPatch({ espBox = { thickness = value } })
		end
	)
	self.controls.espInfoEnabled = createToggle(espSection, context.toolkit, context.theme, "ESP Info", function(value)
		callbacks.onPatch({ espInfo = { enabled = value } })
	end)
	self.controls.espShowName = createToggle(espSection, context.toolkit, context.theme, "Show Name", function(value)
		callbacks.onPatch({ espInfo = { showName = value } })
	end)
	self.controls.espShowDistance = createToggle(
		espSection,
		context.toolkit,
		context.theme,
		"Show Distance",
		function(value)
			callbacks.onPatch({ espInfo = { showDistance = value } })
		end
	)
	self.controls.espShowHealth = createToggle(
		espSection,
		context.toolkit,
		context.theme,
		"Show Health",
		function(value)
			callbacks.onPatch({ espInfo = { showHealth = value } })
		end
	)
	self.controls.espInfoColor = createPreviewColorInput(
		espSection,
		"Info Color",
		function(value)
			callbacks.onPatch({ espInfo = { textColor = value } })
		end
	)
	self.controls.tracerEnabled = createToggle(espSection, context.toolkit, context.theme, "Tracer", function(value)
		callbacks.onPatch({ tracer = { enabled = value } })
	end)
	self.controls.tracerColor = createPreviewColorInput(
		espSection,
		"Tracer Color",
		function(value)
			callbacks.onPatch({ tracer = { color = value } })
		end
	)
	self.controls.tracerThickness = createNumberInput(
		espSection,
		context.toolkit,
		context.theme,
		"Tracer Thick",
		function(value)
			callbacks.onPatch({ tracer = { thickness = value } })
		end
	)

	self.controls.trailEnabled = createToggle(effectsSection, context.toolkit, context.theme, "Trail", function(value)
		callbacks.onPatch({ trail = { enabled = value } })
	end)
	self.controls.trailColor = createPreviewColorInput(
		effectsSection,
		"Trail Color",
		function(value)
			callbacks.onPatch({ trail = { color = value } })
		end
	)
	self.controls.trailLifetime = createNumberInput(
		effectsSection,
		context.toolkit,
		context.theme,
		"Trail Life",
		function(value)
			callbacks.onPatch({ trail = { lifetime = value } })
		end
	)
	self.controls.particlesEnabled = createToggle(
		effectsSection,
		context.toolkit,
		context.theme,
		"Particles",
		function(value)
			callbacks.onPatch({ particles = { enabled = value } })
		end
	)
	self.controls.particlesColor = createPreviewColorInput(
		effectsSection,
		"Particles Color",
		function(value)
			callbacks.onPatch({ particles = { color = value } })
		end
	)
	self.controls.particlesRate = createNumberInput(
		effectsSection,
		context.toolkit,
		context.theme,
		"Particles Rate",
		function(value)
			callbacks.onPatch({ particles = { rate = value } })
		end
	)
	self.controls.particlesSpeed = createNumberInput(
		effectsSection,
		context.toolkit,
		context.theme,
		"Particles Speed",
		function(value)
			callbacks.onPatch({ particles = { speed = value } })
		end
	)
	self.controls.forceFieldEnabled = createToggle(
		effectsSection,
		context.toolkit,
		context.theme,
		"ForceField",
		function(value)
			callbacks.onPatch({ forceField = { enabled = value } })
		end
	)
	self.controls.forceFieldVisible = createToggle(
		effectsSection,
		context.toolkit,
		context.theme,
		"FF Visible",
		function(value)
			callbacks.onPatch({ forceField = { visible = value } })
		end
	)
	self.controls.forceFieldColor = createPreviewColorInput(
		effectsSection,
		"FF Color",
		function(value)
			callbacks.onPatch({ forceField = { color = value } })
		end
	)
	self.controls.soundEnabled = createToggle(effectsSection, context.toolkit, context.theme, "Sound", function(value)
		callbacks.onPatch({ sound = { enabled = value } })
	end)
	self.controls.soundId = createTextInput(
		effectsSection,
		context.toolkit,
		context.theme,
		"SoundId",
		120,
		function(value)
			callbacks.onPatch({ sound = { soundId = value } })
		end
	)
	self.controls.soundVolume = createNumberInput(
		effectsSection,
		context.toolkit,
		context.theme,
		"Volume",
		function(value)
			callbacks.onPatch({ sound = { volume = value } })
		end
	)
	self.controls.soundSpeed = createNumberInput(
		effectsSection,
		context.toolkit,
		context.theme,
		"Playback",
		function(value)
			callbacks.onPatch({ sound = { playbackSpeed = value } })
		end
	)

	self.controls.charmsVisible = createToggle(charmsSection, context.toolkit, context.theme, "Visible", function(value)
		callbacks.onPatch({ charms = { visible = value } })
	end)
	self.controls.charmsTintEnabled = createToggle(
		charmsSection,
		context.toolkit,
		context.theme,
		"Tint",
		function(value)
			callbacks.onPatch({ charms = { tintEnabled = value } })
		end
	)
	self.controls.charmsTintColor = createPreviewColorInput(
		charmsSection,
		"Tint Color",
		function(value)
			callbacks.onPatch({ charms = { tintColor = value } })
		end
	)

	cancelButton.MouseButton1Click:Connect(callbacks.onCancel)
	resetButton.MouseButton1Click:Connect(callbacks.onReset)
	applyButton.MouseButton1Click:Connect(callbacks.onApply)

	setGuiZIndex(root, baseZIndex)
	boxFrame.ZIndex = baseZIndex + 1
	infoCard.ZIndex = baseZIndex + 2
	infoLabel.ZIndex = baseZIndex + 3
	tracerFrame.ZIndex = baseZIndex + 1
	tracerGlow.ZIndex = baseZIndex
	statusLabel.ZIndex = baseZIndex + 3

	return self
end

function CharacterPreviewView:setConfig(config)
	self.controls.autoRotate:setValue(config.orbit.autoRotate)
	self.controls.orbitSpeed:setValue(config.orbit.speed)
	self.controls.orbitRadius:setValue(config.orbit.radius)
	self.controls.orbitHeight:setValue(config.orbit.height)
	self.controls.transparency:setValue(config.transparency)
	self.controls.highlightEnabled:setValue(config.highlight.enabled)
	self.controls.highlightFillColor:setValue(config.highlight.fillColor)
	self.controls.highlightOutlineColor:setValue(config.highlight.outlineColor)
	self.controls.highlightFillTransparency:setValue(config.highlight.fillTransparency)
	self.controls.highlightOutlineTransparency:setValue(config.highlight.outlineTransparency)
	self.controls.depthMode:setValue(config.highlight.depthMode == Enum.HighlightDepthMode.AlwaysOnTop)
	self.controls.espBoxEnabled:setValue(config.espBox.enabled)
	self.controls.espBoxColor:setValue(config.espBox.color)
	self.controls.espBoxThickness:setValue(config.espBox.thickness)
	self.controls.espInfoEnabled:setValue(config.espInfo.enabled)
	self.controls.espShowName:setValue(config.espInfo.showName)
	self.controls.espShowDistance:setValue(config.espInfo.showDistance)
	self.controls.espShowHealth:setValue(config.espInfo.showHealth)
	self.controls.espInfoColor:setValue(config.espInfo.textColor)
	self.controls.tracerEnabled:setValue(config.tracer.enabled)
	self.controls.tracerColor:setValue(config.tracer.color)
	self.controls.tracerThickness:setValue(config.tracer.thickness)
	self.controls.trailEnabled:setValue(config.trail.enabled)
	self.controls.trailColor:setValue(config.trail.color)
	self.controls.trailLifetime:setValue(config.trail.lifetime)
	self.controls.particlesEnabled:setValue(config.particles.enabled)
	self.controls.particlesColor:setValue(config.particles.color)
	self.controls.particlesRate:setValue(config.particles.rate)
	self.controls.particlesSpeed:setValue(config.particles.speed)
	self.controls.forceFieldEnabled:setValue(config.forceField.enabled)
	self.controls.forceFieldVisible:setValue(config.forceField.visible)
	self.controls.forceFieldColor:setValue(config.forceField.color)
	self.controls.soundEnabled:setValue(config.sound.enabled)
	self.controls.soundId:setValue(config.sound.soundId)
	self.controls.soundVolume:setValue(config.sound.volume)
	self.controls.soundSpeed:setValue(config.sound.playbackSpeed)
	self.controls.charmsVisible:setValue(config.charms.visible)
	self.controls.charmsTintEnabled:setValue(config.charms.tintEnabled)
	self.controls.charmsTintColor:setValue(config.charms.tintColor)
end

function CharacterPreviewView:handleInputChanged(input: InputObject)
	for _, control in ipairs(self.sliderControls) do
		control:handleMove(input)
	end

	if self._sharedColorPicker then
		self._sharedColorPicker:handleInputChanged(input)
	end
end

function CharacterPreviewView:handleInputBegan(input: InputObject)
	if self._sharedColorPicker then
		self._sharedColorPicker:handleInputBegan(input)
	end
end

function CharacterPreviewView:handleInputEnded(input: InputObject)
	if self._sharedColorPicker then
		self._sharedColorPicker:handleInputEnded(input)
	end
end

function CharacterPreviewView:setStatus(message: string?)
	local text = message or ""
	self.statusLabel.Text = text
	self.statusLabel.Visible = text ~= ""
end

function CharacterPreviewView:applyTheme(theme)
	self._context.theme = theme
	self.viewport.BackgroundColor3 = theme.Main
	self.statusLabel.TextColor3 = theme.SecondText
	if self._sharedColorPicker then
		self._sharedColorPicker:applyTheme(theme)
	end

	for _, descendant in ipairs(self.root:GetDescendants()) do
		local role = descendant:GetAttribute("HyperVRole")
		if role == "SectionSurface" and descendant:IsA("Frame") then
			descendant.BackgroundColor3 = theme.Default
		elseif role == "SectionTitle" and descendant:IsA("TextLabel") then
			descendant.TextColor3 = theme.TitleText
		elseif role == "FieldLabel" and descendant:IsA("TextLabel") then
			descendant.TextColor3 = theme.Text
		elseif role == "ToggleTrack" and descendant:IsA("Frame") then
			local thumb = descendant:FindFirstChild("Frame")
			local isOn = false
			if thumb and thumb:IsA("Frame") then
				isOn = thumb.Position.X.Scale > 0
			end
			descendant.BackgroundColor3 = if isOn then theme.Accent else theme.Second
			local stroke = descendant:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = theme.Border
			end
		elseif role == "ToggleThumb" and descendant:IsA("Frame") then
			descendant.BackgroundColor3 = Color3.new(1, 1, 1)
		elseif role == "FieldInput" and (descendant:IsA("TextBox") or descendant:IsA("TextButton")) then
			descendant.BackgroundColor3 = theme.Second
			descendant.TextColor3 = theme.Text
			local stroke = descendant:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = theme.Border
			end
		elseif role == "ColorSwatch" and descendant:IsA("TextButton") then
			local stroke = descendant:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = theme.Border
			end
		elseif role == "AccentValue" and descendant:IsA("TextLabel") then
			descendant.TextColor3 = theme.Accent
		elseif role == "SliderTrack" and descendant:IsA("Frame") then
			descendant.BackgroundColor3 = theme.Second
		elseif role == "SliderFill" and descendant:IsA("Frame") then
			descendant.BackgroundColor3 = theme.Accent
		elseif role == "SliderKnob" and descendant:IsA("Frame") then
			descendant.BackgroundColor3 = Color3.new(1, 1, 1)
		elseif role == "SecondaryButton" and descendant:IsA("TextButton") then
			descendant.BackgroundColor3 = theme.Second
			descendant.TextColor3 = theme.Text
		elseif role == "PrimaryButton" and descendant:IsA("TextButton") then
			descendant.BackgroundColor3 = theme.Accent
			descendant.TextColor3 = Color3.new(1, 1, 1)
		elseif role == "StatusText" and descendant:IsA("TextLabel") then
			descendant.TextColor3 = theme.SecondText
		elseif role == "InfoCard" and descendant:IsA("Frame") then
			descendant.BackgroundColor3 = theme.Default
			local stroke = descendant:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = theme.Border
			end
		elseif role == "ViewportSurface" and descendant:IsA("ViewportFrame") then
			descendant.BackgroundColor3 = theme.Main
			local stroke = descendant:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = theme.Border
			end
		end
	end
end

function CharacterPreviewView:applyWhitespace(scale)
	local spacingScale = scale or 1
	local panelWidth = math.floor(230 * math.clamp(spacingScale, 0.94, 1.14) + 0.5)
	local actionHeight = math.floor(44 * spacingScale + 0.5)
	local inset = math.floor(8 * spacingScale + 0.5)
	local listGap = math.floor(8 * spacingScale + 0.5)
	local buttonGap = math.floor(6 * spacingScale + 0.5)
	local sideButtonHeight = math.floor(32 * spacingScale + 0.5)

	self.viewport.Size = UDim2.new(1, -(panelWidth + 16), 1, -(actionHeight + 12))
	self.controlsPanel.Size = UDim2.new(0, panelWidth, 1, -(actionHeight + 12))
	self.controlsPanel.Position = UDim2.new(1, -panelWidth, 0, 0)
	self._controlsPadding.PaddingTop = UDim.new(0, inset)
	self._controlsPadding.PaddingBottom = UDim.new(0, inset)
	self._controlsPadding.PaddingLeft = UDim.new(0, inset)
	self._controlsPadding.PaddingRight = UDim.new(0, inset)
	self._controlsLayout.Padding = UDim.new(0, listGap)

	self._actionsRow.Size = UDim2.new(0, panelWidth, 0, actionHeight)
	self._actionsRow.Position = UDim2.new(1, -panelWidth, 1, -actionHeight)
	self._actionLayout.Padding = UDim.new(0, buttonGap)
	self._actionsPadding.PaddingTop = UDim.new(0, math.floor(6 * spacingScale + 0.5))
	self._actionsPadding.PaddingBottom = UDim.new(0, math.floor(6 * spacingScale + 0.5))
	self._actionsPadding.PaddingLeft = UDim.new(0, math.floor(6 * spacingScale + 0.5))
	self._actionsPadding.PaddingRight = UDim.new(0, math.floor(6 * spacingScale + 0.5))
	local availableButtonWidth = math.max(140, panelWidth - (self._actionsPadding.PaddingLeft.Offset + self._actionsPadding.PaddingRight.Offset))
	local secondaryWidth = math.floor((availableButtonWidth - (buttonGap * 2)) * 0.28 + 0.5)
	local primaryWidth = math.max(secondaryWidth + 8, availableButtonWidth - (secondaryWidth * 2) - (buttonGap * 2))
	self._cancelButton.Size = UDim2.new(0, secondaryWidth, 0, sideButtonHeight)
	self._resetButton.Size = UDim2.new(0, secondaryWidth, 0, sideButtonHeight)
	self._applyButton.Size = UDim2.new(0, primaryWidth, 0, sideButtonHeight)

	local infoInsetY = math.floor(7 * spacingScale + 0.5)
	local infoInsetX = math.floor(8 * spacingScale + 0.5)
	self._infoPadding.PaddingTop = UDim.new(0, infoInsetY)
	self._infoPadding.PaddingBottom = UDim.new(0, infoInsetY)
	self._infoPadding.PaddingLeft = UDim.new(0, infoInsetX)
	self._infoPadding.PaddingRight = UDim.new(0, infoInsetX)
end

function CharacterPreviewView:open()
	self.window.view.Visible = true
end

function CharacterPreviewView:close()
	self.window.view.Visible = false
end

function CharacterPreviewView:dispose()
	if self._sharedColorPicker then
		self._sharedColorPicker:dispose()
		self._sharedColorPicker = nil
	end
	self.window:dispose()
end

return CharacterPreviewView
