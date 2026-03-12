--!strict

local Notification = require(script.Parent.Parent.Parent["Hyper V"].elements.Basics.Notification)

local OverlayHost = {}
OverlayHost.__index = OverlayHost

function OverlayHost.new(screenGui: ScreenGui, theme, toolkit)
	local self = setmetatable({}, OverlayHost)
	self._screenGui = screenGui
	self._theme = theme
	self._toolkit = toolkit
	self._notification = Notification.new({}, theme, toolkit)
	return self
end

function OverlayHost:getRoot(): ScreenGui
	return self._screenGui
end

function OverlayHost:notify(config)
	return self._notification:Notify(config)
end

return OverlayHost
