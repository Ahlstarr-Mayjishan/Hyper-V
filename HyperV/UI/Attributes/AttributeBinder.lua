--!strict

local StyleResolver = require(script.Parent.StyleResolver)

export type CornerBinding = {
	instance: Instance,
	corner: UICorner,
	fallbackRadius: number?,
}

export type StrokeBinding = {
	instance: Instance,
	stroke: UIStroke,
	fallbackColor: Color3?,
	fallbackThickness: number?,
}

local AttributeBinder = {}
AttributeBinder.__index = AttributeBinder

function AttributeBinder.new(theme, layout)
	return setmetatable({
		theme = theme,
		layout = layout,
		_cornerBindings = {} :: { CornerBinding },
		_strokeBindings = {} :: { StrokeBinding },
	}, AttributeBinder)
end

function AttributeBinder:setContext(theme, layout)
	self.theme = theme
	self.layout = layout
end

function AttributeBinder:bindCorner(instance: Instance, corner: UICorner, fallbackRadius: number?)
	table.insert(self._cornerBindings, {
		instance = instance,
		corner = corner,
		fallbackRadius = fallbackRadius,
	})
	self:applyCorner(instance, corner, fallbackRadius)
end

function AttributeBinder:bindStroke(instance: Instance, stroke: UIStroke, fallbackColor: Color3?, fallbackThickness: number?)
	table.insert(self._strokeBindings, {
		instance = instance,
		stroke = stroke,
		fallbackColor = fallbackColor,
		fallbackThickness = fallbackThickness,
	})
	self:applyStroke(instance, stroke, fallbackColor, fallbackThickness)
end

function AttributeBinder:applyCorner(instance: Instance, corner: UICorner, fallbackRadius: number?)
	local radius = StyleResolver.resolveCorner(instance, fallbackRadius, self.layout)
	if radius ~= nil then
		corner.CornerRadius = UDim.new(0, radius)
	end
end

function AttributeBinder:applyStroke(instance: Instance, stroke: UIStroke, fallbackColor: Color3?, fallbackThickness: number?)
	local color, thickness = StyleResolver.resolveStroke(instance, fallbackColor, fallbackThickness, self.theme)
	stroke.Color = color
	stroke.Thickness = thickness
end

function AttributeBinder:reapplyAll()
	local nextCorners = {}
	for _, binding in ipairs(self._cornerBindings) do
		if binding.instance.Parent and binding.corner.Parent then
			self:applyCorner(binding.instance, binding.corner, binding.fallbackRadius)
			table.insert(nextCorners, binding)
		end
	end
	self._cornerBindings = nextCorners

	local nextStrokes = {}
	for _, binding in ipairs(self._strokeBindings) do
		if binding.instance.Parent and binding.stroke.Parent then
			self:applyStroke(binding.instance, binding.stroke, binding.fallbackColor, binding.fallbackThickness)
			table.insert(nextStrokes, binding)
		end
	end
	self._strokeBindings = nextStrokes
end

return AttributeBinder
