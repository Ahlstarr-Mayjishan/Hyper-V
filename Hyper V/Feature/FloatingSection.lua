local DetachedWindow = require(script.Parent.DetachedWindow)

local FloatingSection = {}
FloatingSection.__index = FloatingSection

function FloatingSection.new(config, context)
    local self = setmetatable({}, FloatingSection)

    self.Config = config or {}
    self.HyperV = context.HyperV or context.Rayfield
    self.Rayfield = self.HyperV
    self.Theme = context.Theme
    self.Utilities = context.Utilities
    self.State = self.Config.State
    self.SectionFrame = self.Config.SectionFrame or (self.State and self.State.Frame)
    self.Title = self.Config.Title or (self.State and self.State.Title) or self.SectionFrame.Name

    self:CreateWindow()
    return self
end

function FloatingSection:CreateWindow()
    self.Window = DetachedWindow.new({
        Name = (self.State and self.State.Id or self.SectionFrame.Name) .. "_Floating",
        Title = self.Title,
        Size = self.Config.Size or UDim2.new(0, 320, 0, 220),
        Position = self.Config.Position,
        Parent = self.Config.Parent or self.HyperV.ScreenGui,
        StackContent = false,
        Content = self.SectionFrame,
        GetDockTargets = function()
            if self.Config.GetDockTargets then
                return self.Config.GetDockTargets(self)
            end
            return {}
        end,
        OnDockTargetSelected = function(_, target)
            if self.Config.OnDockTargetSelected then
                self.Config.OnDockTargetSelected(self, target)
            end
        end,
        OnCloseRequested = function()
            if self.Config.OnCloseRequested then
                return self.Config.OnCloseRequested(self)
            end
        end,
        OnDragStart = function(_, input, startPos)
            if self.Config.OnDragStart then
                self.Config.OnDragStart(self, input, startPos)
            end
        end,
        OnDragMove = function(_, input, newPosition, delta)
            if self.Config.OnDragMove then
                self.Config.OnDragMove(self, input, newPosition, delta)
            end
        end,
        OnDragEnd = function(_, input, endPosition)
            if self.Config.OnDragEnd then
                self.Config.OnDragEnd(self, input, endPosition)
            end
        end,
    }, {
        HyperV = self.HyperV,
        Rayfield = self.Rayfield,
        Theme = self.Theme,
        Utilities = self.Utilities,
    })

    self.Frame = self.Window.Frame
    self.Content = self.Window.Content

    self.SectionFrame.Size = UDim2.new(1, 0, 1, 0)
    self.SectionFrame.Position = UDim2.new(0, 0, 0, 0)
    self.SectionFrame.Parent = self.Window.Content
end

function FloatingSection:Dock(target)
    if self.Config.OnDockTargetSelected then
        self.Config.OnDockTargetSelected(self, target)
    end
end

function FloatingSection:DockBack()
    if self.Config.OnDockBack then
        self.Config.OnDockBack(self)
    end
end

function FloatingSection:SetTitle(title)
    self.Title = title
    if self.Window then
        self.Window:SetTitle(title)
    end
end

function FloatingSection:Destroy()
    if self.Window then
        self.Window:Destroy()
        self.Window = nil
        self.Frame = nil
    end
end

return FloatingSection
