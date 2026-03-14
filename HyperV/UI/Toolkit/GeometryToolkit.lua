--!strict

local Bounds = require(script.Parent.Parent.Primitives.Bounds)

local GeometryToolkit = {}

function GeometryToolkit.getGuiBounds(guiObject: GuiObject)
	return Bounds.get(guiObject)
end

function GeometryToolkit.isPointInBounds(point: Vector2, target: GuiObject | any)
	return Bounds.contains(point, target)
end

return GeometryToolkit
