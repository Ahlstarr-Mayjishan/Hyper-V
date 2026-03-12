--!strict

local Effects = {}

local function forEachBasePart(model: Model, callback: (BasePart) -> ())
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			callback(descendant)
		end
	end
end

local function getAdornmentTarget(model: Model): BasePart?
	return model:FindFirstChild("HumanoidRootPart") :: BasePart? or model.PrimaryPart
end

function Effects.clear(cache)
	for key, value in pairs(cache) do
		if typeof(value) == "Instance" then
			value:Destroy()
		elseif type(value) == "table" then
			for _, item in ipairs(value) do
				if typeof(item) == "Instance" then
					item:Destroy()
				end
			end
		end
		cache[key] = nil
	end
end

function Effects.ensurePreviewStage(worldModel: WorldModel, cache)
	if cache.stage then
		return cache.stage
	end

	local stage = {}

	local pedestal = Instance.new("Part")
	pedestal.Name = "PreviewPedestal"
	pedestal.Anchored = true
	pedestal.CanCollide = false
	pedestal.CastShadow = false
	pedestal.Material = Enum.Material.SmoothPlastic
	pedestal.Color = Color3.fromRGB(33, 36, 44)
	pedestal.Size = Vector3.new(7.5, 0.4, 7.5)
	pedestal.Position = Vector3.new(0, -3.05, 0)
	pedestal.Parent = worldModel
	stage.pedestal = pedestal

	local glow = Instance.new("Part")
	glow.Name = "PreviewPedestalGlow"
	glow.Anchored = true
	glow.CanCollide = false
	glow.CastShadow = false
	glow.Material = Enum.Material.Neon
	glow.Color = Color3.fromRGB(90, 150, 255)
	glow.Transparency = 0.78
	glow.Size = Vector3.new(5.6, 0.05, 5.6)
	glow.Position = pedestal.Position + Vector3.new(0, 0.23, 0)
	glow.Parent = worldModel
	stage.glow = glow

	local keyLightPart = Instance.new("Part")
	keyLightPart.Name = "PreviewKeyLight"
	keyLightPart.Anchored = true
	keyLightPart.CanCollide = false
	keyLightPart.Transparency = 1
	keyLightPart.Position = Vector3.new(4.5, 4.6, 3.5)
	keyLightPart.Parent = worldModel

	local keyLight = Instance.new("PointLight")
	keyLight.Range = 16
	keyLight.Brightness = 1.2
	keyLight.Color = Color3.fromRGB(255, 244, 228)
	keyLight.Parent = keyLightPart
	stage.keyLightPart = keyLightPart

	local fillLightPart = Instance.new("Part")
	fillLightPart.Name = "PreviewFillLight"
	fillLightPart.Anchored = true
	fillLightPart.CanCollide = false
	fillLightPart.Transparency = 1
	fillLightPart.Position = Vector3.new(-4.4, 2.8, 4.2)
	fillLightPart.Parent = worldModel

	local fillLight = Instance.new("PointLight")
	fillLight.Range = 14
	fillLight.Brightness = 0.55
	fillLight.Color = Color3.fromRGB(154, 182, 255)
	fillLight.Parent = fillLightPart
	stage.fillLightPart = fillLightPart

	local rimLightPart = Instance.new("Part")
	rimLightPart.Name = "PreviewRimLight"
	rimLightPart.Anchored = true
	rimLightPart.CanCollide = false
	rimLightPart.Transparency = 1
	rimLightPart.Position = Vector3.new(0, 3.8, -5.8)
	rimLightPart.Parent = worldModel

	local rimLight = Instance.new("PointLight")
	rimLight.Range = 18
	rimLight.Brightness = 0.85
	rimLight.Color = Color3.fromRGB(112, 195, 255)
	rimLight.Parent = rimLightPart
	stage.rimLightPart = rimLightPart

	cache.stage = stage
	return stage
end

function Effects.applyTransparency(model: Model, value: number, cache)
	cache.transparencyOriginals = cache.transparencyOriginals or setmetatable({}, { __mode = "k" })
	cache.decalOriginals = cache.decalOriginals or setmetatable({}, { __mode = "k" })

	local transparencyValue = math.clamp(value, 0, 1)
	forEachBasePart(model, function(part)
		if cache.transparencyOriginals[part] == nil then
			cache.transparencyOriginals[part] = part.Transparency
		end

		local originalTransparency = cache.transparencyOriginals[part]
		local appliedTransparency = transparencyValue

		if part.Name == "Head" then
			appliedTransparency *= 0.9
		end

		if part:FindFirstAncestorOfClass("Accessory") then
			appliedTransparency *= 0.82
		end

		part.LocalTransparencyModifier = 0
		part.Transparency = originalTransparency + ((1 - originalTransparency) * appliedTransparency)
	end)

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Decal") or descendant:IsA("Texture") then
			if cache.decalOriginals[descendant] == nil then
				cache.decalOriginals[descendant] = descendant.Transparency
			end

			local originalTransparency = cache.decalOriginals[descendant]
			local appliedTransparency = transparencyValue
			if descendant.Name == "face" or descendant.Name == "Face" then
				appliedTransparency *= 0.72
			end

			descendant.Transparency = originalTransparency + ((1 - originalTransparency) * appliedTransparency)
		end
	end
end

function Effects.applyCharms(model: Model, config, cache, baseTransparency: number)
	cache.charmsOriginalColors = cache.charmsOriginalColors or {}
	cache.charmsOriginalTransparency = cache.charmsOriginalTransparency or setmetatable({}, { __mode = "k" })
	local transparencyValue = math.clamp(baseTransparency or 0, 0, 1)

	for _, accessory in ipairs(model:GetChildren()) do
		if accessory:IsA("Accessory") then
			for _, descendant in ipairs(accessory:GetDescendants()) do
				if descendant:IsA("BasePart") then
					if cache.charmsOriginalColors[descendant] == nil then
						cache.charmsOriginalColors[descendant] = descendant.Color
					end
					if cache.charmsOriginalTransparency[descendant] == nil then
						cache.charmsOriginalTransparency[descendant] = descendant.Transparency
					end
					local originalTransparency = cache.charmsOriginalTransparency[descendant]
					if config.visible then
						descendant.Transparency = originalTransparency + ((1 - originalTransparency) * (transparencyValue * 0.82))
					else
						descendant.Transparency = 1
					end
					if config.tintEnabled then
						descendant.Color = config.tintColor
					else
						descendant.Color = cache.charmsOriginalColors[descendant]
					end
				end
			end
		end
	end
end

function Effects.applyHighlight(model: Model, config, cache)
	if config.enabled then
		local highlight = cache.highlight
		if not highlight then
			highlight = Instance.new("Highlight")
			highlight.Adornee = model
			highlight.Parent = model
			cache.highlight = highlight
		end
		highlight.Enabled = true
		highlight.FillColor = config.fillColor
		highlight.OutlineColor = config.outlineColor
		highlight.FillTransparency = config.fillTransparency
		highlight.OutlineTransparency = config.outlineTransparency
		highlight.DepthMode = config.depthMode
	elseif cache.highlight then
		cache.highlight.Enabled = false
	end
end

function Effects.applyTrail(model: Model, config, cache)
	local root = getAdornmentTarget(model)
	if not root then
		return
	end

	if config.enabled then
		if not cache.trailPart then
			local anchorA = Instance.new("Part")
			anchorA.Name = "PreviewTrailAnchorA"
			anchorA.Size = Vector3.new(0.1, 0.1, 0.1)
			anchorA.Transparency = 1
			anchorA.CanCollide = false
			anchorA.Anchored = true
			anchorA.Parent = model

			local anchorB = anchorA:Clone()
			anchorB.Name = "PreviewTrailAnchorB"
			anchorB.Parent = model

			local attachmentA = Instance.new("Attachment")
			attachmentA.Parent = anchorA
			local attachmentB = Instance.new("Attachment")
			attachmentB.Parent = anchorB

			local trail = Instance.new("Trail")
			trail.Attachment0 = attachmentA
			trail.Attachment1 = attachmentB
			trail.Parent = anchorA

			cache.trailPart = { anchorA, anchorB, trail }
		end

		local anchorA = cache.trailPart[1]
		local anchorB = cache.trailPart[2]
		local trail = cache.trailPart[3]
		local base = root.CFrame
		anchorA.CFrame = base * CFrame.new(-0.8, 1.4, -0.6)
		anchorB.CFrame = base * CFrame.new(0.8, 0.2, 0.6)
		trail.Color = ColorSequence.new(config.color)
		trail.Lifetime = config.lifetime
		trail.Enabled = true
	elseif cache.trailPart then
		cache.trailPart[3].Enabled = false
	end
end

function Effects.applyParticles(model: Model, config, cache)
	local root = getAdornmentTarget(model)
	if not root then
		return
	end

	if config.enabled then
		local emitter = cache.particles
		if not emitter then
			emitter = Instance.new("ParticleEmitter")
			emitter.Parent = root
			emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			cache.particles = emitter
		end
		emitter.Enabled = true
		emitter.Color = ColorSequence.new(config.color)
		emitter.Rate = config.rate
		emitter.Speed = NumberRange.new(config.speed)
		emitter.Lifetime = NumberRange.new(config.lifetime)
		emitter.SpreadAngle = Vector2.new(20, 20)
	else
		if cache.particles then
			cache.particles.Enabled = false
		end
	end
end

function Effects.applyForceField(model: Model, config, cache)
	if config.enabled then
		local forceField = cache.forceField
		if not forceField then
			forceField = Instance.new("ForceField")
			forceField.Parent = model
			cache.forceField = forceField
		end
		forceField.Visible = config.visible
	else
		if cache.forceField then
			cache.forceField:Destroy()
			cache.forceField = nil
		end
	end
end

function Effects.applySound(model: Model, config, cache)
	local root = getAdornmentTarget(model)
	if not root then
		return
	end

	if config.enabled and config.soundId ~= "" then
		local sound = cache.sound
		if not sound then
			sound = Instance.new("Sound")
			sound.RollOffMaxDistance = 20
			sound.Parent = root
			cache.sound = sound
		end
		local normalizedId = string.find(config.soundId, "rbxassetid://", 1, true) and config.soundId or ("rbxassetid://" .. config.soundId)
		local shouldReplay = sound.SoundId ~= normalizedId or sound.IsPlaying == false
		sound.SoundId = normalizedId
		sound.Volume = config.volume
		sound.PlaybackSpeed = config.playbackSpeed
		sound.Looped = false
		if shouldReplay then
			sound.TimePosition = 0
			sound:Play()
		end
	else
		if cache.sound and cache.sound.IsPlaying then
			cache.sound:Stop()
		end
	end
end

local function getCornerSegment(parent: Frame, name: string): Frame
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Frame") then
		return existing
	end

	local segment = Instance.new("Frame")
	segment.Name = name
	segment.BorderSizePixel = 0
	segment.Parent = parent
	return segment
end

function Effects.applyEspBox(overlayFrame: Frame, boxFrame: Frame, projectedBounds, config)
	boxFrame.Visible = config.enabled and projectedBounds ~= nil
	if not projectedBounds then
		return
	end

	boxFrame.Size = UDim2.new(0, projectedBounds.width, 0, projectedBounds.height)
	boxFrame.Position = UDim2.new(0, projectedBounds.minX, 0, projectedBounds.minY)
	boxFrame.BackgroundTransparency = 1
	boxFrame.BorderSizePixel = 0
	boxFrame.ZIndex = 4
	boxFrame.Parent = overlayFrame

	local thickness = math.max(1, math.floor(config.thickness))
	local cornerLength = math.clamp(math.min(projectedBounds.width, projectedBounds.height) * 0.18, 14, 28)
	local color = config.color

	local topLeftHorizontal = getCornerSegment(boxFrame, "TopLeftHorizontal")
	local topLeftVertical = getCornerSegment(boxFrame, "TopLeftVertical")
	local topRightHorizontal = getCornerSegment(boxFrame, "TopRightHorizontal")
	local topRightVertical = getCornerSegment(boxFrame, "TopRightVertical")
	local bottomLeftHorizontal = getCornerSegment(boxFrame, "BottomLeftHorizontal")
	local bottomLeftVertical = getCornerSegment(boxFrame, "BottomLeftVertical")
	local bottomRightHorizontal = getCornerSegment(boxFrame, "BottomRightHorizontal")
	local bottomRightVertical = getCornerSegment(boxFrame, "BottomRightVertical")

	local segments = {
		topLeftHorizontal,
		topLeftVertical,
		topRightHorizontal,
		topRightVertical,
		bottomLeftHorizontal,
		bottomLeftVertical,
		bottomRightHorizontal,
		bottomRightVertical,
	}

	for _, segment in ipairs(segments) do
		segment.BackgroundColor3 = color
		segment.ZIndex = boxFrame.ZIndex
	end

	topLeftHorizontal.Position = UDim2.new(0, 0, 0, 0)
	topLeftHorizontal.Size = UDim2.new(0, cornerLength, 0, thickness)
	topLeftVertical.Position = UDim2.new(0, 0, 0, 0)
	topLeftVertical.Size = UDim2.new(0, thickness, 0, cornerLength)

	topRightHorizontal.Position = UDim2.new(1, -cornerLength, 0, 0)
	topRightHorizontal.Size = UDim2.new(0, cornerLength, 0, thickness)
	topRightVertical.Position = UDim2.new(1, -thickness, 0, 0)
	topRightVertical.Size = UDim2.new(0, thickness, 0, cornerLength)

	bottomLeftHorizontal.Position = UDim2.new(0, 0, 1, -thickness)
	bottomLeftHorizontal.Size = UDim2.new(0, cornerLength, 0, thickness)
	bottomLeftVertical.Position = UDim2.new(0, 0, 1, -cornerLength)
	bottomLeftVertical.Size = UDim2.new(0, thickness, 0, cornerLength)

	bottomRightHorizontal.Position = UDim2.new(1, -cornerLength, 1, -thickness)
	bottomRightHorizontal.Size = UDim2.new(0, cornerLength, 0, thickness)
	bottomRightVertical.Position = UDim2.new(1, -thickness, 1, -cornerLength)
	bottomRightVertical.Size = UDim2.new(0, thickness, 0, cornerLength)
end

function Effects.applyEspInfo(infoCard: Frame, infoLabel: TextLabel, projectedBounds, config, characterName: string, distance: number, healthText: string)
	infoCard.Visible = config.enabled and projectedBounds ~= nil
	infoLabel.Visible = config.enabled and projectedBounds ~= nil
	if not projectedBounds then
		return
	end

	local lines = {}
	if config.showName then
		table.insert(lines, characterName)
	end
	if config.showDistance then
		table.insert(lines, string.format("%dm", math.floor(distance + 0.5)))
	end
	if config.showHealth then
		table.insert(lines, healthText)
	end

	infoLabel.Text = table.concat(lines, "\n")
	infoLabel.TextColor3 = config.textColor
	infoCard.Position = UDim2.new(0, projectedBounds.minX, 0, math.max(0, projectedBounds.minY - 42))
	infoCard.Size = UDim2.new(0, math.max(projectedBounds.width + 10, 108), 0, 40)
	infoLabel.Position = UDim2.new(0, 0, 0, 0)
	infoLabel.Size = UDim2.new(1, 0, 1, 0)
end

function Effects.applyTracer(tracerFrame: Frame, projectedBounds, overlaySize: Vector2, config)
	tracerFrame.Visible = config.enabled and projectedBounds ~= nil
	if not projectedBounds then
		return
	end

	local fromX = overlaySize.X * 0.5
	local fromY = if config.originMode == "Center" then overlaySize.Y * 0.5 else overlaySize.Y - 6
	local toX = projectedBounds.minX + projectedBounds.width * 0.5
	local toY = projectedBounds.minY + projectedBounds.height * 0.5
	local delta = Vector2.new(toX - fromX, toY - fromY)
	local length = delta.Magnitude
	local angle = math.deg(math.atan2(delta.Y, delta.X))

	tracerFrame.AnchorPoint = Vector2.new(0, 0.5)
	tracerFrame.Position = UDim2.new(0, fromX, 0, fromY)
	tracerFrame.Size = UDim2.new(0, length, 0, math.max(1, math.floor(config.thickness)))
	tracerFrame.Rotation = angle
	tracerFrame.BackgroundColor3 = config.color
	tracerFrame.BorderSizePixel = 0

	local glow = tracerFrame:FindFirstChild("Glow")
	if glow and glow:IsA("Frame") then
		glow.BackgroundColor3 = config.color
		glow.Size = UDim2.new(1, 0, 0, math.max(3, math.floor(config.thickness) + 2))
		glow.Position = UDim2.new(0, 0, 0.5, -glow.Size.Y.Offset * 0.5)
	end
end

return Effects
