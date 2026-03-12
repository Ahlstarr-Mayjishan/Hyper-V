--!strict

local Renderer = {}

export type BaselinePartEntry = {
	transparency: number,
	color: Color3,
}

export type BaselineDecalEntry = {
	transparency: number,
}

export type BaselineState = {
	parts: { [BasePart]: BaselinePartEntry },
	decals: { [Instance]: BaselineDecalEntry },
}

local function eachBasePart(model: Model, callback: (BasePart) -> ())
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			callback(descendant)
		end
	end
end

function Renderer.captureBaseline(model: Model): BaselineState
	local baseline: BaselineState = {
		parts = {},
		decals = {},
	}

	eachBasePart(model, function(part)
		baseline.parts[part] = {
			transparency = part.Transparency,
			color = part.Color,
		}
	end)

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Decal") or descendant:IsA("Texture") then
			baseline.decals[descendant] = {
				transparency = descendant.Transparency,
			}
		end
	end

	return baseline
end

function Renderer.restoreBaseline(baseline: BaselineState)
	for part, entry in pairs(baseline.parts) do
		if part.Parent then
			part.Transparency = entry.transparency
			part.LocalTransparencyModifier = 0
			part.Color = entry.color
		end
	end

	for decal, entry in pairs(baseline.decals) do
		if decal.Parent and (decal:IsA("Decal") or decal:IsA("Texture")) then
			decal.Transparency = entry.transparency
		end
	end
end

local function resolvePartTransparency(part: BasePart, baseTransparency: number, charmsVisible: boolean): number
	if baseTransparency >= 0.999 then
		return 1
	end

	local resolved = baseTransparency
	if part:GetAttribute("HyperVPreviewHead") == true then
		resolved *= 0.22
	elseif part.Name == "Head" then
		resolved *= 0.9
	end

	if part:FindFirstAncestorOfClass("Accessory") then
		if not charmsVisible then
			return 1
		end
		resolved *= 0.82
	end

	return math.clamp(resolved, 0, 1)
end

local function resolveDecalTransparency(instance: Instance, baseTransparency: number): number
	if baseTransparency >= 0.999 then
		return 1
	end

	local resolved = baseTransparency
	if instance:GetAttribute("HyperVPreviewFace") == true then
		resolved *= 0.12
	elseif instance.Name == "face" or instance.Name == "Face" then
		resolved *= 0.72
	end

	return math.clamp(resolved, 0, 1)
end

function Renderer.renderCore(model: Model, baseline: BaselineState, snapshot)
	Renderer.restoreBaseline(baseline)

	local baseTransparency = math.clamp(snapshot.transparency or 0, 0, 1)
	local charmsVisible = snapshot.charms.visible ~= false
	local tintEnabled = snapshot.charms.tintEnabled == true
	local tintColor = snapshot.charms.tintColor

	for part, entry in pairs(baseline.parts) do
		if part.Parent then
			part.Transparency = entry.transparency
			part.LocalTransparencyModifier = resolvePartTransparency(part, baseTransparency, charmsVisible)

			if part:FindFirstAncestorOfClass("Accessory") and tintEnabled then
				part.Color = tintColor
			else
				part.Color = entry.color
			end
		end
	end

	for instance, entry in pairs(baseline.decals) do
		if instance.Parent and (instance:IsA("Decal") or instance:IsA("Texture")) then
			local resolved = resolveDecalTransparency(instance, baseTransparency)
			instance.Transparency = entry.transparency + ((1 - entry.transparency) * resolved)
		end
	end
end

function Renderer.applyHighlight(model: Model, cache, config)
	local mainHighlight = cache.highlightMain
	local shellHighlight = cache.highlightShell

	if config.enabled then
		if not mainHighlight then
			mainHighlight = Instance.new("Highlight")
			mainHighlight.Name = "PreviewHighlightMain"
			mainHighlight.Adornee = model
			mainHighlight.Parent = model
			cache.highlightMain = mainHighlight
		end

		if not shellHighlight then
			shellHighlight = Instance.new("Highlight")
			shellHighlight.Name = "PreviewHighlightShell"
			shellHighlight.Adornee = model
			shellHighlight.Parent = model
			cache.highlightShell = shellHighlight
		end

		mainHighlight.Enabled = true
		mainHighlight.FillColor = config.fillColor
		mainHighlight.OutlineColor = config.outlineColor
		mainHighlight.FillTransparency = config.fillTransparency
		mainHighlight.OutlineTransparency = config.outlineTransparency
		mainHighlight.DepthMode = config.depthMode

		shellHighlight.Enabled = true
		shellHighlight.FillTransparency = 1
		shellHighlight.FillColor = config.fillColor
		shellHighlight.OutlineColor = config.outlineColor:Lerp(Color3.new(1, 1, 1), 0.25)
		shellHighlight.OutlineTransparency = math.max(0, config.outlineTransparency - 0.18)
		shellHighlight.DepthMode = config.depthMode
	else
		if mainHighlight then
			mainHighlight.Enabled = false
		end
		if shellHighlight then
			shellHighlight.Enabled = false
		end
	end
end

function Renderer.clearHighlights(cache)
	if cache.highlightMain then
		cache.highlightMain.Enabled = false
	end
	if cache.highlightShell then
		cache.highlightShell.Enabled = false
	end
end

return Renderer
