--!strict

local resolveLegacyRoot = require(script.Parent.Parent.Legacy.LegacyRoot)
local LayerAuthority = require(script.Parent.Parent.System.Authority.LayerAuthority)

local legacyRoot = resolveLegacyRoot(script)
local LegacyModal = require(legacyRoot.elements.Advanced.Modal)

local ModalController = {}
ModalController.__index = ModalController

function ModalController.new(config, context)
	local self = setmetatable({}, ModalController)
	self._context = context
	self.id = config.Id or config.Name or ("Modal_" .. tostring(os.clock()))
	self.kind = "modal"
	self.title = config.Title or "Modal"
	self._claimId = self.id .. ":modal"
	self.autoActivate = true
	self._legacy = LegacyModal.Show({
		Name = self.id,
		Title = config.Title,
		Content = config.Content,
		Type = config.Type,
		Buttons = config.Buttons,
		Parent = config.Parent or context.app:getOverlayHost():getRoot(),
		OnClose = function()
			if config.OnClose then
				config.OnClose()
			end
			self:_releaseClaims()
		end,
	}, context.theme, context.toolkit)
	self.view = self._legacy.Overlay
	return self
end

function ModalController:_releaseClaims()
	self._context.interactionAuthority:release("modal", self._claimId)
	self._context.interactionAuthority:releaseFocus(self.id)
end

function ModalController:applyLayer(baseZIndex: number)
	if self.view and self.view.Parent then
		LayerAuthority.applyGuiTreeZIndex(self.view, baseZIndex)
	end
end

function ModalController:activate()
	self._context.interactionAuthority:tryAcquire("modal", {
		id = self._claimId,
		priority = 60,
		allowSteal = true,
	})
	self._context.interactionAuthority:requestFocus({
		id = self.id,
		priority = 60,
	})
	self._context.layerAuthority:bringToFront(self.id)
end

function ModalController:close()
	if self._legacy and self._legacy.Close then
		self._legacy:Close()
	else
		self:_releaseClaims()
	end
end

function ModalController:dispose()
	if self._layerCleanup then
		self._layerCleanup()
		self._layerCleanup = nil
	end
	self:close()
end

return ModalController
