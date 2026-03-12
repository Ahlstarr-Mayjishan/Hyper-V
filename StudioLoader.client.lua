--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function hasPackageParts(container: Instance): boolean
	local mainModule = container:FindFirstChild("Main") or container:FindFirstChild("main")
	local modernRoot = container:FindFirstChild("HyperV") or container:FindFirstChild("Hyperv")
	local legacyRoot = container:FindFirstChild("Hyper V")
	return mainModule ~= nil and modernRoot ~= nil and legacyRoot ~= nil
end

local function resolvePackageRoot(): Instance
	local candidates = {
		ReplicatedStorage:FindFirstChild("HyperV"),
		ReplicatedStorage:FindFirstChild("Hyper-V"),
		ReplicatedStorage:FindFirstChild("UIPackage"),
		ReplicatedStorage:FindFirstChild("UI"),
	}

	for _, candidate in ipairs(candidates) do
		if candidate and hasPackageParts(candidate) then
			return candidate
		end
	end

	for _, child in ipairs(ReplicatedStorage:GetChildren()) do
		if child:IsA("Folder") and hasPackageParts(child) then
			return child
		end
	end

	error("StudioLoader could not find a package root with Main, HyperV, and Hyper V inside ReplicatedStorage")
end

local packageRoot = resolvePackageRoot()
local mainModule = packageRoot:FindFirstChild("Main") or packageRoot:FindFirstChild("main")
assert(mainModule and mainModule:IsA("ModuleScript"), "StudioLoader could not find Main ModuleScript")

local HyperV = require(mainModule)

local app = HyperV.createApp({
	Name = "HyperV Studio Loader",
	Layout = "Default",
})

local window = app:createWindow({
	Title = "Hyper-V Studio Loader",
	Size = Vector2.new(920, 600),
})

local previewTab = window:createTab({ Name = "Preview" })
local previewSection = previewTab:createSection({
	Title = "Character Preview Test",
	Height = 180,
})

app:createLabel({
	Parent = previewSection.contentFrame,
	Text = "Use this loader in StarterPlayerScripts. It opens the main UI and lets you launch the side character preview immediately.",
})

local previewHandle = nil

local function openCharacterPreview()
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
	OnClick = openCharacterPreview,
})

local controlsSection = previewTab:createSection({
	Title = "Quick Controls",
	Height = 190,
})

app:createNumberInput({
	Parent = controlsSection.contentFrame,
	Name = "OrbitSpeed",
	Title = "Orbit Speed",
	Min = 0,
	Max = 6,
	Default = 1,
})

app:createRangeSlider({
	Parent = controlsSection.contentFrame,
	Name = "TransparencyRange",
	Title = "Transparency Range",
	Min = 0,
	Max = 1,
	DefaultMin = 0.1,
	DefaultMax = 0.8,
	Step = 0.05,
})

app:createMultiSelectDropdown({
	Parent = controlsSection.contentFrame,
	Name = "PreviewEffects",
	Title = "Preview Effects",
	Options = { "Highlight", "ESP Box", "ESP Info", "Tracer", "Trail", "Particles", "Charms" },
	Default = { "Highlight", "ESP Box", "ESP Info" },
})

app:notifyInfo("Studio Loader", "UI loaded. Click 'Open Character Preview' to test the preview panel.", 4)
