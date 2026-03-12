--!strict

local CornerFactory = {}

function CornerFactory.apply(parent: Instance, radius: number): UICorner
	local corner = parent:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

return CornerFactory
