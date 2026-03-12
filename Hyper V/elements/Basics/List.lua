--[[
    Hyper-V - List Component
    Danh sách có thể scroll
]]

local List = {}

function List.new(config, theme, utilities)
    local self = setmetatable({}, {__index = List})
    
    self.Name = config.Name or "List"
    self.Items = config.Items or {}
    self.Height = config.Height or 200
    self.ItemHeight = config.ItemHeight or 30
    self.ShowIcons = config.ShowIcons or false
    self.OnItemClick = config.OnItemClick
    self.OnItemSelect = config.OnItemSelect
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    return self
end

function List:Create()
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(1, 0, 0, self.Height)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 6)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -10, 0, 25)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = self.Name
    Title.TextColor3 = self.Theme.TitleText
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Container
    
    -- ScrollingFrame
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -10, 1, -35)
    ScrollFrame.Position = UDim2.new(0, 5, 0, 30)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.ScrollBarImageColor3 = self.Theme.Accent
    ScrollFrame.ScrollBarImageTransparency = 0.5
    ScrollFrame.Parent = Container
    
    -- ListLayout
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 2)
    ListLayout.Parent = ScrollFrame
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingBottom = UDim.new(0, 5)
    Padding.Parent = ScrollFrame
    
    -- CanvasSize
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
    end)
    
    self.ScrollFrame = ScrollFrame
    self.ListLayout = ListLayout
    
    -- Add items
    for _, item in ipairs(self.Items) do
        self:AddItem(item)
    end
    
    return Container
end

function List:AddItem(item)
    local itemFrame = Instance.new("Frame")
    itemFrame.Size = UDim2.new(1, 0, 0, self.ItemHeight)
    itemFrame.BackgroundColor3 = self.Theme.Second
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = self.ScrollFrame
    self.Utilities:CreateCorner(itemFrame, 4)
    
    -- Icon (optional)
    if self.ShowIcons and item.icon then
        local Icon = Instance.new("TextLabel")
        Icon.Size = UDim2.new(0, 25, 0, 25)
        Icon.Position = UDim2.new(0, 5, 0.5, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Text = item.icon
        Icon.TextSize = 14
        Icon.Parent = itemFrame
    end
    
    -- Text
    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.new(1, -30, 1, 0)
    Text.Position = UDim2.new(0, 10, 0, 0)
    Text.BackgroundTransparency = 1
    Text.Text = item.text or item
    Text.TextColor3 = self.Theme.Text
    Text.TextSize = 12
    Text.Font = Enum.Font.Gotham
    Text.TextXAlignment = Enum.TextXAlignment.Left
    Text.Parent = itemFrame
    
    -- Hover effect
    local isSelected = false
    
    itemFrame.MouseEnter:Connect(function()
        if not isSelected then
            itemFrame.BackgroundColor3 = self.Theme.Accent
        end
    end)
    
    itemFrame.MouseLeave:Connect(function()
        if not isSelected then
            itemFrame.BackgroundColor3 = self.Theme.Second
        end
    end)
    
    -- Click event
    local function onClick()
        -- Deselect all
        for _, v in ipairs(self.ScrollFrame:GetChildren()) do
            if v:IsA("Frame") then
                v.BackgroundColor3 = self.Theme.Second
            end
        end
        
        -- Select this
        isSelected = true
        itemFrame.BackgroundColor3 = self.Theme.Accent
        
        if self.OnItemClick then
            self.OnItemClick(item)
        end
        
        if self.OnItemSelect then
            self.OnItemSelect(item)
        end
    end
    
    local ClickDetector = Instance.new("ClickDetector")
    ClickDetector.Parent = itemFrame
    ClickDetector.MouseClick:Connect(onClick)
    
    return itemFrame
end

function List:Clear()
    for _, v in ipairs(self.ScrollFrame:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end
end

function List:AddItems(items)
    for _, item in ipairs(items) do
        self:AddItem(item)
    end
end

function List:RemoveItem(item)
    for _, v in ipairs(self.ScrollFrame:GetChildren()) do
        if v:IsA("Frame") then
            local Text = v:FindFirstChildWhichIsA("TextLabel")
            if Text and Text.Text == (item.text or item) then
                v:Destroy()
                break
            end
        end
    end
end

return List
