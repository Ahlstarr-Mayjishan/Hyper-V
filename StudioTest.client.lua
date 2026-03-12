--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function findPackageRoot(): Instance
	local candidates = {
		ReplicatedStorage:FindFirstChild("HyperV"),
		ReplicatedStorage:FindFirstChild("Hyper-V"),
		ReplicatedStorage:FindFirstChild("UIPackage"),
	}

	for _, candidate in ipairs(candidates) do
		if candidate and candidate:FindFirstChild("Main") then
			return candidate
		end
	end

	error("StudioTest could not find a package root containing Main in ReplicatedStorage")
end

local packageRoot = findPackageRoot()
local mainModule = packageRoot:FindFirstChild("Main")
assert(mainModule and mainModule:IsA("ModuleScript"), "Main module not found in package root")

local HyperV = require(mainModule)

local app = HyperV.createApp({
	Name = "HyperV Studio Test",
	Layout = "Default",
})

local window = app:createWindow({
	Title = "Hyper-V Studio Preview",
	Size = Vector2.new(920, 600),
})

local mainTab = window:createTab({ Name = "Preview" })
local previewSection = mainTab:createSection({
	Title = "Character Preview",
	Height = 180,
})

app:createLabel({
	Parent = previewSection.contentFrame,
	Text = "Open the side preview window to inspect highlight, ESP, charms, particles, and transparency before applying.",
})

local previewHandle = nil

local function openPreview()
	if previewHandle then
		previewHandle:open()
		return
	end

	previewHandle = app:createCharacterPreview({
		Title = "Character Preview",
		InitialConfig = {
			transparency = 0.15,
			highlight = {
				enabled = true,
				fillColor = Color3.fromRGB(0, 170, 255),
				fillTransparency = 0.72,
			},
			espBox = {
				enabled = true,
				color = Color3.fromRGB(110, 255, 190),
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
		OnApply = function(config)
			local highlightState = "OFF"
			if config.highlight.enabled then
				highlightState = "ON"
			end

			app:notifySuccess(
				"Preview Applied",
				string.format("Transparency %.2f | Highlight %s", config.transparency, highlightState),
				4
			)
		end,
		OnCancel = function()
			app:notifyInfo("Preview", "Preview changes discarded", 2)
		end,
	})
end

app:createButton({
	Parent = previewSection.contentFrame,
	Text = "Open Character Preview",
	OnClick = openPreview,
})

local settingsSection = mainTab:createSection({
	Title = "Quick Settings",
	Height = 190,
})

app:createNumberInput({
	Parent = settingsSection.contentFrame,
	Name = "OrbitSpeed",
	Title = "Orbit Speed",
	Min = 0,
	Max = 6,
	Default = 1,
})

app:createRangeSlider({
	Parent = settingsSection.contentFrame,
	Name = "TransparencyRange",
	Title = "Transparency Range",
	Min = 0,
	Max = 1,
	DefaultMin = 0.1,
	DefaultMax = 0.8,
	Step = 0.05,
})

app:createMultiSelectDropdown({
	Parent = settingsSection.contentFrame,
	Name = "PreviewEffects",
	Title = "Preview Effects",
	Options = { "Highlight", "ESP Box", "ESP Info", "Tracer", "Trail", "Particles", "Charms" },
	Default = { "Highlight", "ESP Box", "ESP Info" },
})

app:notifyInfo("Studio Test", "UI demo loaded. Use the Preview tab to open Character Preview.", 4)
