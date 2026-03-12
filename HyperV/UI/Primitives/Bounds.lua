--!strict

export type BoundsRect = {
	Position: Vector2,
	Size: Vector2,
}

local Bounds = {}

function Bounds.get(guiObject: GuiObject): BoundsRect
	return {
		Position = guiObject.AbsolutePosition,
		Size = guiObject.AbsoluteSize,
	}
end

function Bounds.contains(point: Vector2, target: GuiObject | BoundsRect): boolean
	local bounds = if typeof(target) == "Instance" then Bounds.get(target :: GuiObject) else target :: BoundsRect
	local minX = bounds.Position.X
	local minY = bounds.Position.Y
	local maxX = minX + bounds.Size.X
	local maxY = minY + bounds.Size.Y

	return point.X >= minX and point.X <= maxX and point.Y >= minY and point.Y <= maxY
end

return Bounds
