--!strict

local PaddingFactory = {}

function PaddingFactory.apply(parent: Instance, top: number?, bottom: number?, left: number?, right: number?): UIPadding
	local padding = Instance.new("UIPadding")
	if top then padding.PaddingTop = UDim.new(0, top) end
	if bottom then padding.PaddingBottom = UDim.new(0, bottom) end
	if left then padding.PaddingLeft = UDim.new(0, left) end
	if right then padding.PaddingRight = UDim.new(0, right) end
	padding.Parent = parent
	return padding
end

return PaddingFactory
