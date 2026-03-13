--!strict

local LayerAuthority = require(script.Parent.Parent.System.Authority.LayerAuthority)

type ContextMenuItem = {
	id: string?,
	title: string,
	description: string?,
	callback: (() -> ())?,
	autoClose: boolean?,
	disabled: boolean?,
}

local ContextMenuController = {}
ContextMenuController.__index = ContextMenuController

local function createButton(parent: GuiObject, theme, item: ContextMenuItem, onActivate: () -> ())
	local button = Instance.new("TextButton")
	button.Name = item.id or item.title
	button.Size = UDim2.new(1, 0, 0, 32)
	button.BackgroundColor3 = theme.Second
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = item.title
	button.TextColor3 = if item.disabled then theme.SubText or theme.Text else theme.Text
	button.TextSize = 13
	button.Font = Enum.Font.GothamMedium
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	button.MouseButton1Click:Connect(function()
		if item.disabled then
			return
		end
		onActivate()
	end)

	return button
end

function ContextMenuController.new(config, context)
	local self = setmetatable({}, ContextMenuController)
	self._context = context
	self.id = config.Id or config.Name or ("ContextMenu_" .. tostring(os.clock()))
	self.kind = "contextMenu"
	self.title = config.Title or "Context Menu"
	self.autoActivate = false
	self._claimId = self.id .. ":contextMenu"
	self._items = config.Items or {}

	local root = Instance.new("Frame")
	root.Name = self.id
	root.Size = config.Size or UDim2.new(0, 220, 0, 44 + (#self._items * 36))
	root.Position = config.Position or UDim2.new(0, 24, 0, 24)
	root.BackgroundColor3 = context.theme.Default
	root.BorderSizePixel = 0
	root.Visible = false
	root.Parent = config.Parent or context.app:getOverlayHost():getRoot()
	self.view = root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = root

	local stroke = Instance.new("UIStroke")
	stroke.Color = context.theme.Border
	stroke.Thickness = 1
	stroke.Parent = root

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = root

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 4)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = root

	for _, item in ipairs(self._items) do
		createButton(root, context.theme, item, function()
			if item.callback then
				item.callback()
			end
			if item.autoClose ~= false then
				self:close()
			end
		end)
	end

	return self
end

function ContextMenuController:applyLayer(baseZIndex: number)
	LayerAuthority.applyGuiTreeZIndex(self.view, baseZIndex)
end

function ContextMenuController:_activateRuntime()
	self._context.interactionAuthority:tryAcquire("contextMenu", {
		id = self._claimId,
		priority = 45,
		allowSteal = true,
	})
	self._context.interactionAuthority:requestFocus({
		id = self.id,
		priority = 45,
	})
	self._context.layerAuthority:bringToFront(self.id)
end

function ContextMenuController:activate()
	local app = self._context.app
	if app and app.getBrain and app:getBrain() then
		app:requestSurfaceActivation(self, 45)
		return
	end
	self:_activateRuntime()
end

function ContextMenuController:_openRuntime()
	self.view.Visible = true
	self:_activateRuntime()
end

function ContextMenuController:openAt(position: UDim2)
	self.view.Position = position
	local app = self._context.app
	if app and app.getBrain and app:getBrain() then
		app:requestSurfaceOpen(self)
		app:requestSurfaceActivation(self, 45)
		return
	end
	self:_openRuntime()
end

function ContextMenuController:_closeRuntime()
	self.view.Visible = false
	self._context.interactionAuthority:release("contextMenu", self._claimId)
	self._context.interactionAuthority:releaseFocus(self.id)
end

function ContextMenuController:close()
	local app = self._context.app
	if app and app.getBrain and app:getBrain() then
		app:requestSurfaceClose(self)
		return
	end
	self:_closeRuntime()
end

function ContextMenuController:dispose()
	if self._context.app and self._context.app.unregisterSurface then
		self._context.app:unregisterSurface(self.id)
	end
	self:_closeRuntime()
	if self.view then
		self.view:Destroy()
	end
end

return ContextMenuController
