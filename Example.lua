--!strict

local packageRoot = game.ReplicatedStorage:FindFirstChild("HyperV")
assert(packageRoot, "HyperV package root not found in ReplicatedStorage")

local HyperV = require(packageRoot.Main)
local app = HyperV.createApp({
	Name = "HyperV",
	Layout = "Default",
})

local window = app:createWindow({
	Title = "Hyper-V Refactor Demo",
	Size = Vector2.new(900, 580),
})

local workspaceTab = window:createTab({ Name = "Workspace" })
local featureSection = workspaceTab:createSection({
	Title = "Main UI Features",
	Height = 180,
})

app:createLabel({
	Parent = featureSection.contentFrame,
	Text = "Detach section, dock elements, and use floating tool windows.",
})

local customDock = app:createDockPanel({
	Name = "FeatureDock",
	Title = "Feature Dock",
	Size = Vector2.new(240, 220),
	Position = UDim2.new(1, -250, 0, 90),
})

app:createButton({
	Parent = featureSection.contentFrame,
	Text = "Detach This Section",
	OnClick = function()
		featureSection:detach(UDim2.new(0, 120, 0, 120))
	end,
})

app:createButton({
	Parent = featureSection.contentFrame,
	Text = "Dock Section To Custom Panel",
	OnClick = function()
		featureSection:dock(customDock)
	end,
})

local looseButton = app:createButton({
	Parent = workspaceTab.contentFrame,
	Text = "Loose Action Button",
	OnClick = function()
		app:notifyInfo("Dock Demo", "Loose button clicked")
	end,
})

app:createButton({
	Parent = workspaceTab.contentFrame,
	Text = "Dock Loose Button",
	OnClick = function()
		customDock:attach(looseButton)
	end,
})

local toolWindow = app:createDetachedWindow({
	Title = "Detached Tools",
	Size = Vector2.new(320, 220),
	Position = UDim2.new(0, 80, 0, 120),
})

app:createLabel({
	Parent = toolWindow.contentFrame,
	Text = "This is a standalone detached window.",
})

app:createButton({
	Parent = toolWindow.contentFrame,
	Text = "Dock Detached Window",
	OnClick = function()
		toolWindow:dock(customDock.id)
	end,
})

local elementsTab = window:createTab({ Name = "Elements" })

local denseSection = elementsTab:createSection({
	Title = "Dense Settings",
	Height = 260,
})

app:createNumberInput({
	Parent = denseSection.contentFrame,
	Name = "WalkSpeed",
	Title = "WalkSpeed",
	Min = 0,
	Max = 200,
	Default = 16,
})

app:createRangeSlider({
	Parent = denseSection.contentFrame,
	Name = "FOVRange",
	Title = "FOV Range",
	Min = 40,
	Max = 120,
	DefaultMin = 70,
	DefaultMax = 90,
	Step = 1,
})

app:createMultiSelectDropdown({
	Parent = denseSection.contentFrame,
	Name = "TargetParts",
	Title = "Target Parts",
	Options = { "Head", "Torso", "Arms", "Legs" },
	Default = { "Head", "Torso" },
})

local groupTabs = denseSection:createSubTabs({
	Name = "FeatureGroups",
	Height = 180,
	Tabs = {
		{ Name = "Code" },
		{ Name = "Tree" },
		{ Name = "List" },
	},
})

app:createCodeBlock({
	Parent = groupTabs:GetTab("Code").Content,
	Name = "ConfigPreview",
	Title = "Config Preview",
	Language = "lua",
	Height = 130,
	Text = "return {\n    WalkSpeed = 16,\n    FOV = {70, 90},\n}",
})

app:createTreeView({
	Parent = groupTabs:GetTab("Tree").Content,
	Name = "CategoryTree",
	Title = "Category Tree",
	Height = 130,
	DefaultExpanded = true,
	Nodes = {
		{
			Name = "Combat",
			Children = {
				{
					Name = "Aim Assist",
					Children = {
						{ Name = "FOV" },
						{ Name = "Prediction" },
					},
				},
				{ Name = "Silent Aim" },
			},
		},
		{
			Name = "Visual",
			Children = {
				{ Name = "ESP" },
				{
					Name = "Chams",
					Children = {
						{ Name = "Visible" },
						{ Name = "Hidden" },
					},
				},
			},
		},
	},
})

local virtualItems = {}
for index = 1, 750 do
	table.insert(virtualItems, { text = string.format("Log Row %03d", index) })
end

app:createVirtualList({
	Parent = groupTabs:GetTab("List").Content,
	Name = "VirtualLogs",
	Title = "Virtualized Rows",
	Height = 130,
	ItemHeight = 26,
	Items = virtualItems,
})

local presetSection = elementsTab:createSection({
	Title = "Presets + Actions",
	Height = 210,
})

local previewHandle = nil
local function openCharacterPreview()
	if previewHandle then
		previewHandle:open()
		return
	end

	previewHandle = app:createCharacterPreview({
		Title = "ESP Character Preview",
		InitialConfig = {
			transparency = 0.2,
			highlight = {
				enabled = true,
				fillColor = Color3.fromRGB(0, 170, 255),
				fillTransparency = 0.7,
			},
			espBox = {
				enabled = true,
				color = Color3.fromRGB(120, 255, 190),
			},
			espInfo = {
				enabled = true,
			},
			tracer = {
				enabled = true,
			},
			charms = {
				tintEnabled = true,
				tintColor = Color3.fromRGB(255, 210, 110),
			},
		},
		OnApply = function(previewConfig)
			local highlightState = "OFF"
			if previewConfig.highlight.enabled then
				highlightState = "ON"
			end
			app:notifySuccess(
				"Preview Applied",
				string.format("Transparency %.2f, Highlight %s", previewConfig.transparency, highlightState),
				4
			)
		end,
		OnCancel = function()
			app:notifyInfo("Preview", "Preview changes discarded", 2)
		end,
	})
end

app:createButton({
	Parent = presetSection.contentFrame,
	Text = "Open Character Preview",
	OnClick = function()
		openCharacterPreview()
	end,
})

local palette = app:createCommandPalette({
	Hotkey = Enum.KeyCode.RightControl,
	Actions = {
		{
			id = "notify_preset",
			title = "Notify Undo Toast",
			description = "Show toast with Copy and Undo actions",
			callback = function()
				app:notify({
					Title = "Preset Saved",
					Content = "Profile copied to clipboard-ready buffer.",
					Type = "success",
					Duration = 5,
					Actions = {
						{ Label = "Copy", ActionId = "Copy" },
						{
							Label = "Undo",
							Callback = function()
								app:notifyInfo("Undo", "Undo action clicked", 2)
							end,
						},
					},
				})
			end,
		},
		{
			id = "open_tools",
			title = "Open Tool Window",
			description = "Bring back detached tools",
			callback = function()
				toolWindow:open()
			end,
		},
		{
			id = "open_character_preview",
			title = "Open Character Preview",
			description = "Open side-by-side viewport preview",
			callback = function()
				openCharacterPreview()
			end,
		},
	},
})

app:createButton({
	Parent = presetSection.contentFrame,
	Text = "Open Command Palette",
	OnClick = function()
		palette:open()
	end,
})

app:createPresetManager({
	Parent = presetSection.contentFrame,
	Name = "DemoPresetManager",
	Title = "Demo Presets",
	Presets = { "Legit", "Rage", "Visual" },
	Default = 1,
})
