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

function Effects.applyTransparency(model: Model, value: number)
	forEachBasePart(model, function(part)
		part.LocalTransparencyModifier = 0
		part.Transparency = value
	end)

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = value
		end
	end
end

function Effects.applyCharms(model: Model, config, cache)
	cache.charmsOriginalColors = cache.charmsOriginalColors or {}

	for _, accessory in ipairs(model:GetChildren()) do
		if accessory:IsA("Accessory") then
			for _, descendant in ipairs(accessory:GetDescendants()) do
				if descendant:IsA("BasePart") then
					if cache.charmsOriginalColors[descendant] == nil then
						cache.charmsOriginalColors[descendant] = descendant.Color
					end
					descendant.Transparency = config.visible and 0 or 1
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

function Effects.applyEspBox(overlayFrame: Frame, boxFrame: Frame, projectedBounds, config)
	boxFrame.Visible = config.enabled and projectedBounds ~= nil
	if not projectedBounds then
		return
	end

	boxFrame.Size = UDim2.new(0, projectedBounds.width, 0, projectedBounds.height)
	boxFrame.Position = UDim2.new(0, projectedBounds.minX, 0, projectedBounds.minY)
	boxFrame.BackgroundTransparency = 1
	boxFrame.BorderSizePixel = math.max(1, math.floor(config.thickness))
	boxFrame.BorderColor3 = config.color
	boxFrame.ZIndex = 4
	boxFrame.Parent = overlayFrame
end

function Effects.applyEspInfo(infoLabel: TextLabel, projectedBounds, config, characterName: string, distance: number, healthText: string)
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
	infoLabel.Position = UDim2.new(0, projectedBounds.minX, 0, math.max(0, projectedBounds.minY - 32))
	infoLabel.Size = UDim2.new(0, math.max(projectedBounds.width, 84), 0, 32)
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
end

return Effects
