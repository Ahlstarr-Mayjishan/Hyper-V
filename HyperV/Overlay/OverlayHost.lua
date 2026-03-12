--!strict

local Players = game:GetService("Players")

local resolveLegacyRoot = require(script.Parent.Parent.Legacy.LegacyRoot)
local LayerAuthority = require(script.Parent.Parent.System.Authority.LayerAuthority)

local legacyRoot = resolveLegacyRoot(script)
local Notification = require(legacyRoot.elements.Basics.Notification)

local OverlayHost = {}
OverlayHost.__index = OverlayHost

function OverlayHost.new(screenGui: ScreenGui, theme, toolkit, systems)
	local self = setmetatable({}, OverlayHost)
	self._screenGui = screenGui
	self._theme = theme
	self._toolkit = toolkit
	self._systems = systems or {}
	self._notification = Notification.new({}, theme, toolkit)
	self._notificationSurface = nil
	return self
end

function OverlayHost:getRoot(): ScreenGui
	return self._screenGui
end

function OverlayHost:notify(config)
	local result = self._notification:Notify(config)
	self:_registerNotificationSurface()
	if self._systems.layerAuthority and self._notificationSurface then
		self._systems.layerAuthority:bringToFront(self._notificationSurface.id)
	end
	return result
end

function OverlayHost:_registerNotificationSurface()
	local playerGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	local container = playerGui:FindFirstChild("Hyper-VNotifications")
	if not container or not container:IsA("GuiObject") then
		return
	end

	if self._notificationSurface and self._notificationSurface.view == container then
		return
	end

	if self._notificationSurface and self._notificationSurface._layerCleanup then
		self._notificationSurface._layerCleanup()
	end

	local surface = {
		id = "NotificationOverlay",
		view = container,
		autoActivate = false,
		applyLayer = function(_, baseZIndex)
			LayerAuthority.applyGuiTreeZIndex(container, baseZIndex)
		end,
	}
	self._notificationSurface = surface

	if self._systems.layerAuthority then
		surface._layerCleanup = self._systems.layerAuthority:registerSurface(surface.id, 50, function(baseZIndex)
			surface:applyLayer(baseZIndex)
		end)
	end
end

return OverlayHost
