--!strict

local AttributeSchema = require(script.Parent.AttributeSchema)

local StyleResolver = {}

local function resolveCornerByRole(role: string, layout): number?
	local surfaceCorner = layout.WindowCorner
	local controlCorner = math.max(6, surfaceCorner - 2)
	local compactCorner = math.max(4, controlCorner - 2)
	local microCorner = math.max(2, compactCorner - 2)

	local corners = {
		SurfaceRoot = surfaceCorner,
		SurfaceHeader = surfaceCorner,
		SectionSurface = surfaceCorner,
		ViewportSurface = surfaceCorner,
		PickerPopup = surfaceCorner,
		PickerSurface = controlCorner,
		InfoCard = controlCorner,
		PrimaryButton = controlCorner,
		SecondaryButton = controlCorner,
		Button = controlCorner,
		IconButton = controlCorner,
		FieldInput = controlCorner,
		ColorSwatch = controlCorner,
		ToggleTrack = controlCorner + 1,
		ToggleThumb = compactCorner + 1,
		SliderTrack = compactCorner,
		SliderFill = compactCorner,
		SliderKnob = compactCorner + 1,
		ResizeHandle = compactCorner,
	}

	return corners[role]
end

function StyleResolver.resolveCorner(instance: Instance, fallbackRadius: number?, layout): number?
	local role = AttributeSchema.getRole(instance)
	if role ~= nil then
		return resolveCornerByRole(role, layout) or fallbackRadius
	end
	return fallbackRadius
end

function StyleResolver.resolveStroke(instance: Instance, fallbackColor: Color3?, fallbackThickness: number?, theme): (Color3, number)
	local role = AttributeSchema.getRole(instance)
	local thickness = fallbackThickness or 1
	local color = fallbackColor or theme.Border

	if role == "PrimaryButton" then
		color = theme.Accent
	elseif role == "AccentValue" or role == "SliderFill" then
		color = theme.Accent
	elseif role == "StatusText" then
		color = theme.SecondText
	end

	return color, thickness
end

return StyleResolver
