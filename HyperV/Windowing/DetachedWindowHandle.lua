--!strict

local resolveLegacyRoot = require(script.Parent.Parent.Legacy.LegacyRoot)
local LayerAuthority = require(script.Parent.Parent.System.LayerAuthority)

local legacyRoot = resolveLegacyRoot(script)
local LegacyDetachedWindow = require(legacyRoot.Feature.DetachedWindow)

local DetachedWindowHandle = {}
DetachedWindowHandle.__index = DetachedWindowHandle

function DetachedWindowHandle.new(config, context)
	local self = setmetatable({}, DetachedWindowHandle)
	self.id = config.Id or config.Name or ("Detached_" .. tostring(os.clock()))
	self.kind = "window"
	self.title = config.Title or "Detached Window"
	self.parentFrame = config.Parent
	self._context = context
	self._content = config.Content
	self._minSize = config.MinSize or Vector2.new(420, 320)
	self._maxSize = config.MaxSize or Vector2.new(1440, 1040)
	self._dockMenuClaimId = self.id .. ":dockMenu"

	local legacy = LegacyDetachedWindow.new({
		Name = self.id,
		Title = self.title,
		Size = config.Size,
		Position = config.Position,
		Parent = config.Parent,
		Content = config.Content,
		GetDockTargets = function()
			return context.dockRegistry:listTargets()
		end,
		OnDockTargetSelected = function(_, target)
			context.dockRegistry:dock(self, target.Id)
		end,
		OnCloseRequested = function()
			if config.OnCloseRequested then
				return config.OnCloseRequested(self)
			end
			return true
		end,
	}, {
		HyperV = context.app,
		Theme = context.theme,
		Utilities = context.toolkit,
	})

	self._legacy = legacy
	self.view = legacy.Frame
	self.contentFrame = legacy.Content
	self._resizeRight = Instance.new("Frame")
	self._resizeRight.Name = "ResizeRight"
	self._resizeRight.Size = UDim2.new(0, 10, 1, -12)
	self._resizeRight.Position = UDim2.new(1, -10, 0, 0)
	self._resizeRight.BackgroundTransparency = 1
	self._resizeRight.BorderSizePixel = 0
	self._resizeRight.Active = true
	self._resizeRight.Parent = self.view

	self._resizeBottom = Instance.new("Frame")
	self._resizeBottom.Name = "ResizeBottom"
	self._resizeBottom.Size = UDim2.new(1, -12, 0, 10)
	self._resizeBottom.Position = UDim2.new(0, 0, 1, -10)
	self._resizeBottom.BackgroundTransparency = 1
	self._resizeBottom.BorderSizePixel = 0
	self._resizeBottom.Active = true
	self._resizeBottom.Parent = self.view

	self._resizeCorner = Instance.new("Frame")
	self._resizeCorner.Name = "ResizeCorner"
	self._resizeCorner.Size = UDim2.new(0, 18, 0, 18)
	self._resizeCorner.Position = UDim2.new(1, -18, 1, -18)
	self._resizeCorner.BackgroundColor3 = context.theme.Second
	self._resizeCorner.BackgroundTransparency = 0.15
	self._resizeCorner.BorderSizePixel = 0
	self._resizeCorner.Active = true
	self._resizeCorner.Parent = self.view
	context.toolkit:CreateCorner(self._resizeCorner, 6)

	self._resizeCleanup = context.toolkit:MakeResizable(self.view, {
		corner = self._resizeCorner,
		right = self._resizeRight,
		bottom = self._resizeBottom,
	}, {
		authority = context.interactionAuthority,
		claimantId = self.id,
		interactionPriority = 20,
		minSize = self._minSize,
		maxSize = self._maxSize,
		onResizeStart = function()
			self:activate()
		end,
		onResize = function(_, nextSize)
			self:_setBaseSize(nextSize)
		end,
	})

	if self._legacy.TitleBar then
		self._legacy.TitleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				self:activate()
			end
		end)
	end

	self.view.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self:activate()
		end
	end)

	if self._legacy.DockMenu then
		self._legacy.DockMenu:GetPropertyChangedSignal("Visible"):Connect(function()
			if self._legacy.DockMenu.Visible then
				self._context.interactionAuthority:tryAcquire("dockMenu", {
					id = self._dockMenuClaimId,
					priority = 30,
					allowSteal = true,
				})
				self:activate()
			else
				self._context.interactionAuthority:release("dockMenu", self._dockMenuClaimId)
			end
		end)
	end
	return self
end

function DetachedWindowHandle:_setBaseSize(nextSize: Vector2)
	self._baseSize = nextSize
	self.view.Size = UDim2.new(0, nextSize.X, 0, nextSize.Y)
end

function DetachedWindowHandle:dock(target)
	local targetId = target
	if type(target) ~= "string" then
		targetId = target.id
	end
	self._context.dockRegistry:dock(self, targetId)
end

function DetachedWindowHandle:undock()
	self._context.dockRegistry:undock(self)
end

function DetachedWindowHandle:setTitle(title: string)
	self.title = title
	self._legacy:SetTitle(title)
end

function DetachedWindowHandle:applyTheme(theme)
	self._context.theme = theme
	self._legacy.Theme = theme

	self.view.BackgroundColor3 = theme.Main
	if self._legacy.Stroke then
		self._legacy.Stroke.Color = theme.Border
	end
	if self._legacy.TitleBar then
		self._legacy.TitleBar.BackgroundColor3 = theme.Default
	end
	if self._legacy.TitleLabel then
		self._legacy.TitleLabel.TextColor3 = theme.TitleText
	end
	if self._legacy.DockButton then
		self._legacy.DockButton.BackgroundColor3 = theme.Second
		self._legacy.DockButton.TextColor3 = theme.Text
	end
	if self._legacy.CloseButton then
		self._legacy.CloseButton.BackgroundColor3 = theme.Second
	end
	if self._resizeCorner then
		self._resizeCorner.BackgroundColor3 = theme.Second
	end
	if self._legacy.DockMenu then
		self._legacy.DockMenu.BackgroundColor3 = theme.Default
		for _, child in ipairs(self._legacy.DockMenu:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = theme.Second
				child.TextColor3 = theme.Text
			elseif child:IsA("TextLabel") then
				child.TextColor3 = theme.Text
			elseif child:IsA("UIStroke") then
				child.Color = theme.Border
			end
		end
	end
end

function DetachedWindowHandle:applyLayer(baseZIndex: number)
	LayerAuthority.applyGuiTreeZIndex(self.view, baseZIndex)
end

function DetachedWindowHandle:activate()
	self._context.interactionAuthority:requestFocus({
		id = self.id,
		priority = 20,
	})
	self._context.layerAuthority:bringToFront(self.id)
end

function DetachedWindowHandle:applyWhitespace(scale)
	local spacingScale = scale or 1
	local buttonSize = math.floor(32 * spacingScale + 0.5)
	local rightInset = math.floor(8 * spacingScale + 0.5)

	if self._legacy.DockButton then
		self._legacy.DockButton.Size = UDim2.new(0, math.floor(92 * spacingScale + 0.5), 0, buttonSize)
		self._legacy.DockButton.Position = UDim2.new(1, -(self._legacy.DockButton.Size.X.Offset + buttonSize + rightInset + 8), 0, rightInset)
	end
	if self._legacy.CloseButton then
		self._legacy.CloseButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
		self._legacy.CloseButton.Position = UDim2.new(1, -(buttonSize + rightInset), 0, rightInset)
	end
	if self._legacy.TitleLabel then
		self._legacy.TitleLabel.Position = UDim2.new(0, math.floor(14 * spacingScale + 0.5), 0, 0)
	end
end

function DetachedWindowHandle:open()
	self:activate()
	self.view.Visible = true
end

function DetachedWindowHandle:close()
	self.view.Visible = false
	self._context.interactionAuthority:release("dockMenu", self._dockMenuClaimId)
	self._context.interactionAuthority:releaseFocus(self.id)
end

function DetachedWindowHandle:dispose()
	if self._responsiveCleanup then
		self._responsiveCleanup()
		self._responsiveCleanup = nil
	end
	if self._resizeCleanup then
		self._resizeCleanup()
		self._resizeCleanup = nil
	end
	if self._layerCleanup then
		self._layerCleanup()
		self._layerCleanup = nil
	end
	self._context.interactionAuthority:release("dockMenu", self._dockMenuClaimId)
	self._context.interactionAuthority:clearOwner(self.id)
	self._legacy:Destroy()
end

return DetachedWindowHandle
