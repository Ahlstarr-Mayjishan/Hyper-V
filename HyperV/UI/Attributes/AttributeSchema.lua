--!strict

export type HyperVRole =
	"SurfaceRoot"
	| "SurfaceHeader"
	| "SectionSurface"
	| "ViewportSurface"
	| "PickerPopup"
	| "PickerSurface"
	| "InfoCard"
	| "PrimaryButton"
	| "SecondaryButton"
	| "Button"
	| "IconButton"
	| "FieldInput"
	| "FieldLabel"
	| "SectionTitle"
	| "AccentValue"
	| "StatusText"
	| "ColorSwatch"
	| "ToggleTrack"
	| "ToggleThumb"
	| "SliderTrack"
	| "SliderFill"
	| "SliderKnob"
	| "ResizeHandle"

local ROLE_SET: { [string]: boolean } = {
	SurfaceRoot = true,
	SurfaceHeader = true,
	SectionSurface = true,
	ViewportSurface = true,
	PickerPopup = true,
	PickerSurface = true,
	InfoCard = true,
	PrimaryButton = true,
	SecondaryButton = true,
	Button = true,
	IconButton = true,
	FieldInput = true,
	FieldLabel = true,
	SectionTitle = true,
	AccentValue = true,
	StatusText = true,
	ColorSwatch = true,
	ToggleTrack = true,
	ToggleThumb = true,
	SliderTrack = true,
	SliderFill = true,
	SliderKnob = true,
	ResizeHandle = true,
}

local AttributeSchema = {}

function AttributeSchema.getRole(instance: Instance): string?
	local value = instance:GetAttribute("HyperVRole")
	if type(value) == "string" and ROLE_SET[value] then
		return value
	end
	return nil
end

function AttributeSchema.setRole(instance: Instance, role: HyperVRole)
	instance:SetAttribute("HyperVRole", role)
end

return AttributeSchema
