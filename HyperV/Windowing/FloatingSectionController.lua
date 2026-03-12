--!strict

local DetachedWindowHandle = require(script.Parent.DetachedWindowHandle)

local FloatingSectionController = {}
FloatingSectionController.__index = FloatingSectionController

function FloatingSectionController.new(sectionHandle, config, context)
	local self = setmetatable({}, FloatingSectionController)
	self.section = sectionHandle
	self._window = DetachedWindowHandle.new({
		Id = sectionHandle.id .. "_Floating",
		Title = sectionHandle.title,
		Size = config and config.Size or UDim2.new(0, 340, 0, 240),
		Position = config and config.Position or UDim2.new(0, 120, 0, 120),
		Parent = context.app:getOverlayHost():getRoot(),
		Content = sectionHandle.frame,
		OnCloseRequested = function()
			sectionHandle:dockBack()
			return false
		end,
	}, context)
	return self
end

function FloatingSectionController:getWindow()
	return self._window
end

function FloatingSectionController:dispose()
	self._window:dispose()
end

return FloatingSectionController
