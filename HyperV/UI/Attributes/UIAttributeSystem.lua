--!strict

local AttributeBinder = require(script.Parent.AttributeBinder)
local AttributeSchema = require(script.Parent.AttributeSchema)

local UIAttributeSystem = {}
UIAttributeSystem.__index = UIAttributeSystem

function UIAttributeSystem.new(theme, layout)
	return setmetatable({
		_binder = AttributeBinder.new(theme, layout),
	}, UIAttributeSystem)
end

function UIAttributeSystem:setContext(theme, layout)
	self._binder:setContext(theme, layout)
	self._binder:reapplyAll()
end

function UIAttributeSystem:setRole(instance: Instance, role)
	AttributeSchema.setRole(instance, role)
end

function UIAttributeSystem:bindCorner(instance: Instance, corner: UICorner, fallbackRadius: number?)
	self._binder:bindCorner(instance, corner, fallbackRadius)
end

function UIAttributeSystem:bindStroke(instance: Instance, stroke: UIStroke, fallbackColor: Color3?, fallbackThickness: number?)
	self._binder:bindStroke(instance, stroke, fallbackColor, fallbackThickness)
end

return UIAttributeSystem
