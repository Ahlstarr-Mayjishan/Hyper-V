--!strict

local CornerFactory = require(script.Parent.Parent.Primitives.CornerFactory)
local StrokeFactory = require(script.Parent.Parent.Primitives.StrokeFactory)
local PaddingFactory = require(script.Parent.Parent.Primitives.PaddingFactory)

local StyleToolkit = {}

function StyleToolkit.createCorner(parent: Instance, radius: number)
	return CornerFactory.apply(parent, radius)
end

function StyleToolkit.createStroke(parent: Instance, color: Color3, thickness: number?)
	return StrokeFactory.apply(parent, color, thickness)
end

function StyleToolkit.createPadding(parent: Instance, top: number?, bottom: number?, left: number?, right: number?)
	return PaddingFactory.apply(parent, top, bottom, left, right)
end

return StyleToolkit
