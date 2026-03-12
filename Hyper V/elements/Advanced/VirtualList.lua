local VirtualList = {}
VirtualList.__index = VirtualList

function VirtualList.new(config, theme, utilities)
    local self = setmetatable({}, VirtualList)

    self.Name = config.Name or "VirtualList"
    self.Title = config.Title or config.Name or "Virtual List"
    self.Items = config.Items or {}
    self.Height = config.Height or 220
    self.Width = config.Width
    self.ItemHeight = math.max(20, config.ItemHeight or 28)
    self.Overscan = math.max(1, config.Overscan or 3)
    self.Parent = config.Parent
    self.OnItemClick = config.OnItemClick
    self.OnItemSelect = config.OnItemSelect
    self.RowRenderer = config.RowRenderer
    self.ResolveText = config.ResolveText
    self.Theme = theme
    self.Utilities = utilities

    self.RowPool = {}
    self.SelectedIndex = nil
    self.StartIndex = 1
    self.EndIndex = 0

    self:Create()
    self:SetItems(self.Items)
    return self
end

function VirtualList:Create()
    local container = Instance.new("Frame")
    container.Name = self.Name
    container.Size = self.Width and UDim2.new(0, self.Width, 0, self.Height) or UDim2.new(1, 0, 0, self.Height)
    container.BackgroundColor3 = self.Theme.Default
    container.BorderSizePixel = 0
    container.Parent = self.Parent
    self.Utilities:CreateCorner(container, 8)
    self.Utilities:CreateStroke(container, self.Theme.Border)

    local titleHeight = self.Title ~= "" and 26 or 0
    if self.Title ~= "" then
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -12, 0, 20)
        title.Position = UDim2.new(0, 6, 0, 5)
        title.BackgroundTransparency = 1
        title.Text = self.Title
        title.TextColor3 = self.Theme.TitleText
        title.TextSize = 13
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container
        self.TitleLabel = title
    end

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, -10, 1, -(titleHeight + 8))
    scrollFrame.Position = UDim2.new(0, 5, 0, titleHeight + 3)
    scrollFrame.BackgroundColor3 = self.Theme.Second
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = container
    self.Utilities:CreateCorner(scrollFrame, 6)

    self.Container = container
    self.ScrollFrame = scrollFrame

    scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        self:Refresh()
    end)

    scrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:EnsureRowPool()
        self:Refresh()
    end)
end

function VirtualList:GetItemText(item, index)
    if self.ResolveText then
        return self.ResolveText(item, index)
    end

    if type(item) == "table" then
        return item.text or item.Text or item.label or item.Label or tostring(index)
    end

    return tostring(item)
end

function VirtualList:CreateRow()
    local row = Instance.new("TextButton")
    row.Name = "Row"
    row.Size = UDim2.new(1, -4, 0, self.ItemHeight - 2)
    row.AnchorPoint = Vector2.new(0, 0)
    row.AutoButtonColor = false
    row.BorderSizePixel = 0
    row.BackgroundColor3 = self.Theme.Default
    row.Text = ""
    row.Parent = self.ScrollFrame
    self.Utilities:CreateCorner(row, 4)

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = self.Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    row._Label = label
    row.MouseButton1Click:Connect(function()
        local index = row._boundIndex
        if not index then
            return
        end

        self:SetValue(index)

        if self.OnItemClick then
            self.OnItemClick(self.Items[index], index)
        end
    end)

    return row
end

function VirtualList:EnsureRowPool()
    local viewportHeight = math.max(self.ScrollFrame.AbsoluteSize.Y, self.ItemHeight)
    local visibleCount = math.ceil(viewportHeight / self.ItemHeight) + (self.Overscan * 2)
    local targetCount = math.max(visibleCount, 1)

    while #self.RowPool < targetCount do
        table.insert(self.RowPool, self:CreateRow())
    end

    while #self.RowPool > targetCount do
        local row = table.remove(self.RowPool)
        row:Destroy()
    end
end

function VirtualList:GetVisibleRange()
    return self.StartIndex, self.EndIndex
end

function VirtualList:Refresh()
    if not self.ScrollFrame then
        return
    end

    self:EnsureRowPool()

    local itemCount = #self.Items
    self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, itemCount * self.ItemHeight)

    if itemCount == 0 then
        self.StartIndex = 1
        self.EndIndex = 0
        for _, row in ipairs(self.RowPool) do
            row.Visible = false
            row._boundIndex = nil
        end
        return
    end

    local viewportHeight = self.ScrollFrame.AbsoluteSize.Y
    local startIndex = math.max(1, math.floor(self.ScrollFrame.CanvasPosition.Y / self.ItemHeight) + 1 - self.Overscan)
    local visibleCount = math.ceil(viewportHeight / self.ItemHeight) + (self.Overscan * 2)
    local endIndex = math.min(itemCount, startIndex + visibleCount - 1)

    self.StartIndex = startIndex
    self.EndIndex = endIndex

    for poolIndex, row in ipairs(self.RowPool) do
        local itemIndex = startIndex + poolIndex - 1
        local item = self.Items[itemIndex]

        if item then
            local selected = itemIndex == self.SelectedIndex
            row.Visible = true
            row._boundIndex = itemIndex
            row.Position = UDim2.new(0, 2, 0, ((itemIndex - 1) * self.ItemHeight) + 1)
            row.BackgroundColor3 = selected and self.Theme.Accent or self.Theme.Default
            row._Label.Text = self:GetItemText(item, itemIndex)
            row._Label.TextColor3 = selected and Color3.new(1, 1, 1) or self.Theme.Text

            if self.RowRenderer then
                self.RowRenderer(row, row._Label, item, itemIndex, selected)
            end
        else
            row.Visible = false
            row._boundIndex = nil
        end
    end
end

function VirtualList:SetItems(items)
    self.Items = items or {}

    if self.SelectedIndex and self.SelectedIndex > #self.Items then
        self.SelectedIndex = nil
    end

    self:Refresh()
end

function VirtualList:AddItems(items)
    for _, item in ipairs(items or {}) do
        table.insert(self.Items, item)
    end
    self:Refresh()
end

function VirtualList:ScrollToIndex(index)
    local clamped = math.clamp(index or 1, 1, math.max(#self.Items, 1))
    self.ScrollFrame.CanvasPosition = Vector2.new(0, math.max(0, (clamped - 1) * self.ItemHeight))
    self:Refresh()
end

function VirtualList:GetValue()
    if not self.SelectedIndex then
        return nil, nil
    end

    return self.Items[self.SelectedIndex], self.SelectedIndex
end

function VirtualList:SetValue(index, silent)
    local nextIndex = tonumber(index)

    if nextIndex == nil or nextIndex < 1 or nextIndex > #self.Items then
        self.SelectedIndex = nil
        self:Refresh()
        return
    end

    self.SelectedIndex = nextIndex
    self:Refresh()

    if not silent and self.OnItemSelect then
        self.OnItemSelect(self.Items[nextIndex], nextIndex)
    end
end

return VirtualList
