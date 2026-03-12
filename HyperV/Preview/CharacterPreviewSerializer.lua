--!strict

export type OrbitConfig = {
	angle: number,
	radius: number,
	height: number,
	autoRotate: boolean,
	speed: number,
}

export type HighlightConfig = {
	enabled: boolean,
	outlineColor: Color3,
	fillColor: Color3,
	fillTransparency: number,
	outlineTransparency: number,
	depthMode: Enum.HighlightDepthMode,
}

export type EspBoxConfig = {
	enabled: boolean,
	color: Color3,
	thickness: number,
	alwaysOnTop: boolean,
}

export type EspInfoConfig = {
	enabled: boolean,
	showName: boolean,
	showDistance: boolean,
	showHealth: boolean,
	textColor: Color3,
}

export type TracerConfig = {
	enabled: boolean,
	color: Color3,
	thickness: number,
	originMode: string,
}

export type TrailConfig = {
	enabled: boolean,
	color: Color3,
	lifetime: number,
}

export type ParticlesConfig = {
	enabled: boolean,
	color: Color3,
	rate: number,
	speed: number,
	lifetime: number,
}

export type ForceFieldConfig = {
	enabled: boolean,
	visible: boolean,
	color: Color3,
}

export type SoundConfig = {
	enabled: boolean,
	soundId: string,
	volume: number,
	playbackSpeed: number,
}

export type CharmsConfig = {
	visible: boolean,
	tintEnabled: boolean,
	tintColor: Color3,
}

export type CharacterPreviewConfig = {
	transparency: number,
	orbit: OrbitConfig,
	highlight: HighlightConfig,
	espBox: EspBoxConfig,
	espInfo: EspInfoConfig,
	tracer: TracerConfig,
	trail: TrailConfig,
	particles: ParticlesConfig,
	forceField: ForceFieldConfig,
	sound: SoundConfig,
	charms: CharmsConfig,
}

local Serializer = {}

local function clamp01(value: number): number
	return math.clamp(value, 0, 1)
end

local function asColor(value: any, fallback: Color3): Color3
	return if typeof(value) == "Color3" then value else fallback
end

local function deepClone(value: any): any
	if type(value) ~= "table" then
		return value
	end

	local clone = {}
	for key, child in pairs(value) do
		clone[key] = deepClone(child)
	end
	return clone
end

function Serializer.getDefaults(): CharacterPreviewConfig
	return {
		transparency = 0,
		orbit = {
			angle = math.rad(35),
			radius = 7,
			height = 2.25,
			autoRotate = true,
			speed = 0.9,
		},
		highlight = {
			enabled = false,
			outlineColor = Color3.fromRGB(255, 255, 255),
			fillColor = Color3.fromRGB(0, 102, 255),
			fillTransparency = 0.65,
			outlineTransparency = 0,
			depthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		},
		espBox = {
			enabled = false,
			color = Color3.fromRGB(0, 255, 170),
			thickness = 2,
			alwaysOnTop = true,
		},
		espInfo = {
			enabled = false,
			showName = true,
			showDistance = true,
			showHealth = true,
			textColor = Color3.fromRGB(255, 255, 255),
		},
		tracer = {
			enabled = false,
			color = Color3.fromRGB(255, 96, 96),
			thickness = 2,
			originMode = "BottomCenter",
		},
		trail = {
			enabled = false,
			color = Color3.fromRGB(170, 120, 255),
			lifetime = 0.4,
		},
		particles = {
			enabled = false,
			color = Color3.fromRGB(255, 210, 90),
			rate = 22,
			speed = 2.5,
			lifetime = 0.8,
		},
		forceField = {
			enabled = false,
			visible = true,
			color = Color3.fromRGB(120, 180, 255),
		},
		sound = {
			enabled = false,
			soundId = "",
			volume = 0.4,
			playbackSpeed = 1,
		},
		charms = {
			visible = true,
			tintEnabled = false,
			tintColor = Color3.fromRGB(255, 255, 255),
		},
	}
end

function Serializer.merge(baseConfig: CharacterPreviewConfig, patch: any): CharacterPreviewConfig
	local result = deepClone(baseConfig)
	for key, value in pairs(patch or {}) do
		if type(value) == "table" and type(result[key]) == "table" then
			result[key] = Serializer.merge(result[key], value)
		else
			result[key] = value
		end
	end
	return result
end

function Serializer.normalize(config: any): CharacterPreviewConfig
	local defaults = Serializer.getDefaults()
	local merged = Serializer.merge(defaults, config or {})

	merged.transparency = clamp01(tonumber(merged.transparency) or defaults.transparency)
	merged.orbit.angle = tonumber(merged.orbit.angle) or defaults.orbit.angle
	merged.orbit.radius = math.max(3, tonumber(merged.orbit.radius) or defaults.orbit.radius)
	merged.orbit.height = math.clamp(tonumber(merged.orbit.height) or defaults.orbit.height, -2, 6)
	merged.orbit.autoRotate = merged.orbit.autoRotate ~= false
	merged.orbit.speed = math.clamp(tonumber(merged.orbit.speed) or defaults.orbit.speed, 0, 6)

	merged.highlight.enabled = merged.highlight.enabled == true
	merged.highlight.outlineColor = asColor(merged.highlight.outlineColor, defaults.highlight.outlineColor)
	merged.highlight.fillColor = asColor(merged.highlight.fillColor, defaults.highlight.fillColor)
	merged.highlight.fillTransparency = clamp01(tonumber(merged.highlight.fillTransparency) or defaults.highlight.fillTransparency)
	merged.highlight.outlineTransparency = clamp01(tonumber(merged.highlight.outlineTransparency) or defaults.highlight.outlineTransparency)
	merged.highlight.depthMode = if typeof(merged.highlight.depthMode) == "EnumItem" then merged.highlight.depthMode else defaults.highlight.depthMode

	merged.espBox.enabled = merged.espBox.enabled == true
	merged.espBox.color = asColor(merged.espBox.color, defaults.espBox.color)
	merged.espBox.thickness = math.clamp(tonumber(merged.espBox.thickness) or defaults.espBox.thickness, 1, 6)
	merged.espBox.alwaysOnTop = merged.espBox.alwaysOnTop ~= false

	merged.espInfo.enabled = merged.espInfo.enabled == true
	merged.espInfo.showName = merged.espInfo.showName ~= false
	merged.espInfo.showDistance = merged.espInfo.showDistance ~= false
	merged.espInfo.showHealth = merged.espInfo.showHealth ~= false
	merged.espInfo.textColor = asColor(merged.espInfo.textColor, defaults.espInfo.textColor)

	merged.tracer.enabled = merged.tracer.enabled == true
	merged.tracer.color = asColor(merged.tracer.color, defaults.tracer.color)
	merged.tracer.thickness = math.clamp(tonumber(merged.tracer.thickness) or defaults.tracer.thickness, 1, 6)
	merged.tracer.originMode = if merged.tracer.originMode == "Center" then "Center" else "BottomCenter"

	merged.trail.enabled = merged.trail.enabled == true
	merged.trail.color = asColor(merged.trail.color, defaults.trail.color)
	merged.trail.lifetime = math.clamp(tonumber(merged.trail.lifetime) or defaults.trail.lifetime, 0.1, 3)

	merged.particles.enabled = merged.particles.enabled == true
	merged.particles.color = asColor(merged.particles.color, defaults.particles.color)
	merged.particles.rate = math.clamp(tonumber(merged.particles.rate) or defaults.particles.rate, 0, 200)
	merged.particles.speed = math.clamp(tonumber(merged.particles.speed) or defaults.particles.speed, 0, 20)
	merged.particles.lifetime = math.clamp(tonumber(merged.particles.lifetime) or defaults.particles.lifetime, 0.1, 6)

	merged.forceField.enabled = merged.forceField.enabled == true
	merged.forceField.visible = merged.forceField.visible ~= false
	merged.forceField.color = asColor(merged.forceField.color, defaults.forceField.color)

	merged.sound.enabled = merged.sound.enabled == true
	merged.sound.soundId = tostring(merged.sound.soundId or defaults.sound.soundId)
	merged.sound.volume = math.clamp(tonumber(merged.sound.volume) or defaults.sound.volume, 0, 1)
	merged.sound.playbackSpeed = math.clamp(tonumber(merged.sound.playbackSpeed) or defaults.sound.playbackSpeed, 0.25, 3)

	merged.charms.visible = merged.charms.visible ~= false
	merged.charms.tintEnabled = merged.charms.tintEnabled == true
	merged.charms.tintColor = asColor(merged.charms.tintColor, defaults.charms.tintColor)

	return merged
end

function Serializer.snapshot(config: CharacterPreviewConfig): CharacterPreviewConfig
	return deepClone(Serializer.normalize(config))
end

return Serializer
