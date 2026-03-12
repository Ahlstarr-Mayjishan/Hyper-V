local DockPanel = {}
DockPanel.__index = DockPanel

function DockPanel.new(config, context)
    local self = setmetatable({}, DockPanel)

    self.Config = config or {}
    self.HyperV = context.HyperV or context.Rayfield
    self.Rayfield = self.HyperV
    self.Theme = context.Theme
    self.Utilities = context.Utilities
    self.Name = self.Config.Name or "DockPanel"
    self.Title = self.Config.Title or self.Name
    self.Accept = self.Config.Accept or "Both"
    self.HiddenWhenEmpty = self.Config.HiddenWhenEmpty == true
    self.Items = {}
    self.Slots = {}
    self.Connections = {}

    self:Create()
    return self
end

function DockPanel:Create()
    local frame = Instance.new("Frame")
    frame.Name = self.Name
    frame.Size = self.Config.Size or UDim2.new(0, 220, 0, 180)
    frame.Position = self.Config.Position or UDim2.new(1, -240, 0, 50)
    frame.BackgroundColor3 = self.Theme.Default
    frame.BorderSizePixel = 0
    frame.Visible = not self.HiddenWhenEmpty
    frame.Parent = self.Config.Parent
    self.Utilities:CreateCorner(frame, 8)
    local stroke = self.Utilities:CreateStroke(frame, self.Theme.Border, 1)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundColor3 = self.Theme.Second
    header.BorderSizePixel = 0
    header.Parent = frame
    self.Utilities:CreateCorner(header, 8)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -12, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = self.Title
    title.TextColor3 = self.Theme.TitleText
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -10, 1, -38)
    content.Position = UDim2.new(0, 5, 0, 33)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageTransparency = 0.3
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 6)
    padding.Parent = content

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
    end)

    self.Frame = frame
    self.Stroke = stroke
    self.Header = header
    self.TitleLabel = title
    self.Content = content
    self.Layout = layout
end

function DockPanel:GetItemTitle(state)
    if state.Title and state.Title ~= "" then
        return state.Title
    end
    if state.Handle and state.Handle.Title then
        return state.Handle.Title
    end
    if state.Frame then
        return state.Frame.Name
    end
    return "Docked Item"
end

function DockPanel:SetHighlighted(active)
    if self.Stroke then
        self.Stroke.Color = active and self.Theme.Accent or self.Theme.Border
    end
end

function DockPanel:RefreshVisibility()
    if self.HiddenWhenEmpty and self.Frame then
        self.Frame.Visible = #self.Items > 0
    end
end

function DockPanel:AttachState(state)
    local slot = Instance.new("Frame")
    slot.Name = state.Id .. "_Slot"
    slot.Size = UDim2.new(1, 0, 0, 0)
    slot.AutomaticSize = Enum.AutomaticSize.Y
    slot.BackgroundColor3 = self.Theme.Main
    slot.BorderSizePixel = 0
    slot.Parent = self.Content
    self.Utilities:CreateCorner(slot, 6)
    self.Utilities:CreateStroke(slot, self.Theme.Border, 1)

    local header = Instance.new("Frame")
    header.Name = "SlotHeader"
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundColor3 = self.Theme.Second
    header.BorderSizePixel = 0
    header.Parent = slot
    self.Utilities:CreateCorner(header, 6)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -58, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = self:GetItemTitle(state)
    title.TextColor3 = self.Theme.Text
    title.TextSize = 12
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local undockButton = Instance.new("TextButton")
    undockButton.Size = UDim2.new(0, 50, 0, 18)
    undockButton.Position = UDim2.new(1, -54, 0.5, -9)
    undockButton.BackgroundColor3 = self.Theme.Accent
    undockButton.BorderSizePixel = 0
    undockButton.Text = "Undock"
    undockButton.TextColor3 = Color3.new(1, 1, 1)
    undockButton.TextSize = 10
    undockButton.Font = Enum.Font.GothamBold
    undockButton.Parent = header
    self.Utilities:CreateCorner(undockButton, 5)

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, -10, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Position = UDim2.new(0, 5, 0, 29)
    body.BackgroundTransparency = 1
    body.Parent = slot

    local itemFrame = state.ActiveFrame or state.Frame
    itemFrame.Parent = body
    itemFrame.Position = UDim2.new(0, 0, 0, 0)
    itemFrame.Visible = true

    if state.Kind == "window" or state.Kind == "section" then
        itemFrame.Size = UDim2.new(1, 0, 0, state.DockHeight or state.RestoreSize.Y.Offset)
    end

    local slotHandle = {
        Frame = slot,
        Body = body,
        State = state,
        Panel = self,
    }

    table.insert(self.Slots, slotHandle)
    table.insert(self.Items, state)
    state.DockSlot = slotHandle
    state.DockPanel = self

    table.insert(self.Connections, undockButton.MouseButton1Click:Connect(function()
        if self.Config.OnUndock then
            self.Config.OnUndock(self, state)
        end
    end))

    self:RefreshVisibility()
    return slotHandle
end

function DockPanel:RemoveState(state)
    local nextItems = {}
    for _, item in ipairs(self.Items) do
        if item ~= state then
            table.insert(nextItems, item)
        end
    end
    self.Items = nextItems

    local nextSlots = {}
    for _, slot in ipairs(self.Slots) do
        if slot.State == state then
            if state.Frame then
                state.Frame.Parent = self.Frame
            end
            slot.Frame:Destroy()
        else
            table.insert(nextSlots, slot)
        end
    end
    self.Slots = nextSlots

    state.DockSlot = nil
    state.DockPanel = nil
    self:RefreshVisibility()
end

function DockPanel:Dock(item, options)
    if self.Config.OnDock then
        return self.Config.OnDock(self, item, options)
    end
end

function DockPanel:Undock(item)
    if self.Config.OnUndock then
        return self.Config.OnUndock(self, item)
    end
end

function DockPanel:GetItems()
    return self.Items
end

function DockPanel:Destroy()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    self.Connections = {}

    if self.Frame then
        self.Frame:Destroy()
        self.Frame = nil
    end
end

return DockPanel
