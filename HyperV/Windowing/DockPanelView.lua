--!strict

local LegacyDockPanel = require(script.Parent.Parent.Parent["Hyper V"].Feature.DockPanel)

local DockPanelView = {}
DockPanelView.__index = DockPanelView

function DockPanelView.new(config, context)
	local self = setmetatable({}, DockPanelView)
	self._handles = {}
	self._legacy = LegacyDockPanel.new({
		Name = config.Name,
		Title = config.Title,
		Size = config.Size,
		Position = config.Position,
		Parent = config.Parent,
		Accept = config.Accept,
		OnUndock = function(_, state)
			local handle = state.Handle
			if handle and handle.undock then
				handle:undock()
			end
		end,
	}, {
		HyperV = context.app,
		Theme = context.theme,
		Utilities = context.toolkit,
	})
	self.id = config.Id or config.Name
	self.title = config.Title or config.Name
	return self
end

function DockPanelView:attach(handle)
	local state = handle._dockState or {
		Id = handle.id,
		Handle = handle,
		Frame = handle.view,
		ActiveFrame = handle.view,
		Title = handle.title,
		Kind = handle.kind,
		RestoreParent = handle.parentFrame,
		RestoreSize = handle.view.Size,
		panel = self,
	}
	handle._dockState = state
	state.panel = self
	self._legacy:AttachState(state)
end

function DockPanelView:remove(handle)
	local state = handle._dockState
	if state then
		self._legacy:RemoveState(state)
	end
	if handle.parentFrame then
		handle.view.Parent = handle.parentFrame
	end
end

function DockPanelView:dock(handle)
	self:attach(handle)
end

function DockPanelView:undock(handle)
	self:remove(handle)
end

function DockPanelView:dispose()
	self._legacy:Destroy()
end

return DockPanelView
