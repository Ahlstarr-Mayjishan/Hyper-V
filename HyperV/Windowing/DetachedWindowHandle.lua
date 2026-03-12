--!strict

local resolveLegacyRoot = require(script.Parent.Parent.Legacy.LegacyRoot)

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
	return self
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

function DetachedWindowHandle:open()
	if self._legacy and self._legacy.BringToFront then
		self._legacy:BringToFront()
	end
	self.view.Visible = true
end

function DetachedWindowHandle:close()
	self.view.Visible = false
end

function DetachedWindowHandle:dispose()
	if self._responsiveCleanup then
		self._responsiveCleanup()
		self._responsiveCleanup = nil
	end
	self._legacy:Destroy()
end

return DetachedWindowHandle
