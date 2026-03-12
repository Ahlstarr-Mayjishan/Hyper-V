--!strict

local UserInputService = game:GetService("UserInputService")

local DisposableStore = require(script.Parent.Parent.Parent.Core.DisposableStore)
local CommandPaletteState = require(script.Parent.CommandPaletteState)
local CommandPaletteView = require(script.Parent.CommandPaletteView)
local LayerAuthority = require(script.Parent.Parent.Parent.System.Authority.LayerAuthority)

local CommandPaletteController = {}
CommandPaletteController.__index = CommandPaletteController

function CommandPaletteController.new(config, context)
	local self = setmetatable({}, CommandPaletteController)
	self._disposables = DisposableStore.new()
	self._context = context
	self._hotkey = config.Hotkey
	self.id = config.Id or "CommandPalette"
	self.kind = "commandPalette"
	self.autoActivate = false
	self._state = CommandPaletteState.new(config.Actions or context.commandRegistry:list())
	self._view = CommandPaletteView.new(config.Parent or context.app:getOverlayHost():getRoot(), context.theme, context.toolkit, {
		onQueryChanged = function(query)
			self._state:setQuery(query)
			self:_render()
		end,
		onActivate = function(id)
			self:activate(id)
		end,
		onClose = function()
			self:close()
		end,
	})
	self.view = self._view.overlay

	self._disposables:add(UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
		if gameProcessed then
			return
		end

		if self._hotkey and inputObject.KeyCode == self._hotkey then
			if self._view.overlay.Visible then
				self:close()
			else
				self:open()
			end
			return
		end

		if not self._view.overlay.Visible then
			return
		end

		if inputObject.KeyCode == Enum.KeyCode.Escape then
			self:close()
		elseif inputObject.KeyCode == Enum.KeyCode.Down then
			self._state:moveSelection(1)
			self:_render()
		elseif inputObject.KeyCode == Enum.KeyCode.Up then
			self._state:moveSelection(-1)
			self:_render()
		elseif inputObject.KeyCode == Enum.KeyCode.Return or inputObject.KeyCode == Enum.KeyCode.KeypadEnter then
			local selected = self._state:getSelected()
			if selected then
				self:activate(selected.id)
			end
		end
	end))

	self:_render()
	return self
end

function CommandPaletteController:setActions(actions)
	self._state:setActions(actions)
	self:_render()
end

function CommandPaletteController:_render()
	local items = self._state:getFiltered()
	local selected = self._state:getSelected()
	self._view:setItems(items, selected and selected.id or nil)
end

function CommandPaletteController:activate(id)
	for _, action in ipairs(self._state:getFiltered()) do
		if action.id == id then
			action.callback(action)
			break
		end
	end
	self:close()
end

function CommandPaletteController:applyLayer(baseZIndex: number)
	LayerAuthority.applyGuiTreeZIndex(self._view.overlay, baseZIndex)
end

function CommandPaletteController:activateSurface()
	self._context.interactionAuthority:requestFocus({
		id = self.id,
		priority = 40,
	})
	self._context.layerAuthority:bringToFront(self.id)
end

function CommandPaletteController:activate()
	self:activateSurface()
end

function CommandPaletteController:open(query)
	self:activateSurface()
	self._view:setVisible(true)
	self._view:setQuery(query or "")
	self._state:setQuery(query or "")
	self:_render()
	task.defer(function()
		self._view.input:CaptureFocus()
	end)
end

function CommandPaletteController:close()
	self._view:setVisible(false)
	self._view.input:ReleaseFocus()
	self._context.interactionAuthority:releaseFocus(self.id)
end

function CommandPaletteController:dispose()
	if self._layerCleanup then
		self._layerCleanup()
		self._layerCleanup = nil
	end
	self._context.interactionAuthority:clearOwner(self.id)
	self._disposables:cleanup()
	self._view:dispose()
end

return CommandPaletteController
