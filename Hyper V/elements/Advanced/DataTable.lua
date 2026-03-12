--[[
    Hyper-V - DataTable Component
    Bảng dữ liệu với sorting, filtering, pagination
]]

local DataTable = {}

function DataTable.new(config, theme, utilities)
    local self = setmetatable({}, {__index = DataTable})
    
    self.Name = config.Name or "DataTable"
    self.Title = config.Title or ""
    self.Columns = config.Columns or {}  -- { {key = "name", title = "Name", width = 100}, ... }
    self.Data = config.Data or {}  -- { {name = "Player1", level = 50}, ... }
    self.Width = config.Width or 500
    self.Height = config.Height or 300
    self.PageSize = config.PageSize or 10
    self.ShowSearch = config.ShowSearch or true
    self.ShowPagination = config.ShowPagination or true
    self.RowHeight = config.RowHeight or 28
    self.HeaderHeight = config.HeaderHeight or 32
    self.Parent = config.Parent
    
    self.Theme = theme
    self.Utilities = utilities
    
    -- State
    self.CurrentPage = 1
    self.SortColumn = nil
    self.SortAscending = true
    self.FilterText = ""
    self.FilteredData = {}
    
    return self
end

function DataTable:Create()
    local containerHeight = self.Height + (self.Title ~= "" and 25 or 0) + (self.ShowPagination and 40 or 0)
    
    local Container = Instance.new("Frame")
    Container.Name = self.Name
    Container.Size = UDim2.new(0, self.Width, 0, containerHeight)
    Container.BackgroundColor3 = self.Theme.Default
    Container.BorderSizePixel = 0
    Container.Parent = self.Parent
    self.Utilities:CreateCorner(Container, 8)
    self.Utilities:CreateStroke(Container, self.Theme.Border)
    
    self.Container = Container
    local contentY = 0
    
    -- Title
    if self.Title ~= "" then
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -10, 0, 20)
        Title.Position = UDim2.new(0, 5, 0, 5)
        Title.BackgroundTransparency = 1
        Title.Text = self.Title
        Title.TextColor3 = self.Theme.TitleText
        Title.TextSize = 13
        Title.Font = Enum.Font.GothamBold
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Container
        contentY = 25
    end
    
    -- Search bar
    if self.ShowSearch then
        local searchBox = self:CreateSearchBox()
        searchBox.Position = UDim2.new(0, 5, 0, contentY + 5)
        searchBox.Parent = Container
        contentY = contentY + 35
    end
    
    -- Header
    local headerFrame = self:CreateHeader()
    headerFrame.Position = UDim2.new(0, 5, 0, contentY + 5)
    headerFrame.Parent = Container
    contentY = contentY + self.HeaderHeight + 5
    
    -- Table body (ScrollingFrame)
    local tableHeight = self.Height - contentY - (self.ShowPagination and 45 or 0) - 10
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 0, tableHeight)
    scrollFrame.Position = UDim2.new(0, 5, 0, contentY)
    scrollFrame.BackgroundColor3 = self.Theme.Default
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = self.Theme.Accent
    scrollFrame.Parent = Container
    self.ScrollFrame = scrollFrame
    
    -- Grid layout
    local gridLayout = Instance.new("UIListLayout")
    gridLayout.Padding = UDim.new(0, 2)
    gridLayout.Parent = scrollFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.Parent = scrollFrame
    
    -- Store original data and filter
    self:ApplyFilter()
    self:RenderRows()
    
    -- Pagination
    if self.ShowPagination then
        self:CreatePagination()
    end
    
    return Container
end

function DataTable:CreateSearchBox()
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(1, -10, 0, 28)
    searchFrame.BackgroundColor3 = self.Theme.Second
    searchFrame.BorderSizePixel = 0
    self.Utilities:CreateCorner(searchFrame, 6)
    self.Utilities:CreateStroke(searchFrame, self.Theme.Border)
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 4, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Text = "🔍"
    icon.TextSize = 12
    icon.Parent = searchFrame
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -35, 1, 0)
    textBox.Position = UDim2.new(0, 30, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.PlaceholderText = "Search..."
    textBox.PlaceholderColor3 = self.Theme.SecondText
    textBox.TextColor3 = self.Theme.Text
    textBox.TextSize = 12
    textBox.Font = Enum.Font.Gotham
    textBox.Parent = searchFrame
    
    textBox.Focused:Connect(function()
        self.Utilities:TweenColor(textBox, self.Theme.Accent)
    end)
    
    textBox.FocusLost:Connect(function()
        self.FilterText = textBox.Text
        self:ApplyFilter()
        self:RenderRows()
    end)
    
    return searchFrame
end

function DataTable:CreateHeader()
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, -10, 0, self.HeaderHeight)
    headerFrame.BackgroundColor3 = self.Theme.Second
    headerFrame.BorderSizePixel = 0
    self.Utilities:CreateCorner(headerFrame, 6)
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 0)
    layout.Parent = headerFrame
    
    local totalWidth = 0
    for _, col in ipairs(self.Columns) do
        totalWidth = totalWidth + col.width
    end
    
    for _, col in ipairs(self.Columns) do
        local headerBtn = Instance.new("TextButton")
        headerBtn.Size = UDim2.new(0, col.width, 1, 0)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = col.title
        headerBtn.TextColor3 = self.Theme.TitleText
        headerBtn.TextSize = 12
        headerBtn.Font = Enum.Font.GothamBold
        headerBtn.TextXAlignment = Enum.TextXAlignment.Center
        headerBtn.Parent = headerFrame
        
        headerBtn.MouseButton1Click:Connect(function()
            self:Sort(col.key)
        end)
    end
    
    return headerFrame
end

function DataTable:RenderRows()
    -- Clear existing rows
    for _, v in ipairs(self.ScrollFrame:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end
    
    local startIndex = (self.CurrentPage - 1) * self.PageSize + 1
    local endIndex = math.min(startIndex + self.PageSize - 1, #self.FilteredData)
    
    for i = startIndex, endIndex do
        local rowData = self.FilteredData[i]
        if rowData then
            self:CreateRow(rowData, i)
        end
    end
end

function DataTable:CreateRow(data, index)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, self.RowHeight)
    row.BackgroundColor3 = (index % 2 == 0) and self.Theme.Default or self.Theme.Second
    row.BorderSizePixel = 0
    self.Utilities:CreateCorner(row, 4)
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 0)
    layout.Parent = row
    
    local isHovered = false
    row.MouseEnter:Connect(function()
        isHovered = true
        self.Utilities:TweenColor(row, self.Theme.Accent:Lerp(Color3.new(0,0,0), 0.8))
    end)
    
    row.MouseLeave:Connect(function()
        isHovered = false
        row.BackgroundColor3 = (index % 2 == 0) and self.Theme.Default or self.Theme.Second
    end)
    
    for _, col in ipairs(self.Columns) do
        local cell = Instance.new("TextLabel")
        cell.Size = UDim2.new(0, col.width, 1, 0)
        cell.BackgroundTransparency = 1
        cell.Text = tostring(data[col.key] or "")
        cell.TextColor3 = self.Theme.Text
        cell.TextSize = 11
        cell.Font = Enum.Font.Gotham
        cell.TextXAlignment = Enum.TextXAlignment.Center
        cell.TextTruncate = Enum.TextTruncate.AtEnd
        cell.Parent = row
    end
    
    row.Parent = self.ScrollFrame
end

function DataTable:Sort(columnKey)
    if self.SortColumn == columnKey then
        self.SortAscending = not self.SortAscending
    else
        self.SortColumn = columnKey
        self.SortAscending = true
    end
    
    table.sort(self.FilteredData, function(a, b)
        local valA = a[columnKey]
        local valB = b[columnKey]
        
        if type(valA) == "number" and type(valB) == "number" then
            return self.SortAscending and valA < valB or valA > valB
        else
            return self.Utilities:CompareText(valA, valB, self.SortAscending)
        end
    end)
    
    self.CurrentPage = 1
    self:RenderRows()
end

function DataTable:ApplyFilter()
    self.FilteredData = {}
    
    if self.FilterText == "" then
        self.FilteredData = table.clone(self.Data)
    else
        for _, row in ipairs(self.Data) do
            local match = false
            for _, col in ipairs(self.Columns) do
                local value = tostring(row[col.key] or "")
                if self.Utilities:TextContains(value, self.FilterText, true) then
                    match = true
                    break
                end
            end
            if match then
                table.insert(self.FilteredData, row)
            end
        end
    end
    
    -- Apply current sort
    if self.SortColumn then
        self:Sort(self.SortColumn)
    end
end

function DataTable:CreatePagination()
    local pageInfo = self:GetPageInfo()
    
    local pageFrame = Instance.new("Frame")
    pageFrame.Size = UDim2.new(1, -10, 0, 35)
    pageFrame.Position = UDim2.new(0, 5, 1, -40)
    pageFrame.BackgroundTransparency = 1
    pageFrame.Parent = self.Container
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 5)
    layout.Parent = pageFrame
    
    -- Info text
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(0, 150, 1, 0)
    infoText.BackgroundTransparency = 1
    infoText.Text = string.format("Page %d/%d (%d items)", self.CurrentPage, pageInfo.totalPages, #self.FilteredData)
    infoText.TextColor3 = self.Theme.SecondText
    infoText.TextSize = 11
    infoText.Font = Enum.Font.Gotham
    infoText.TextXAlignment = Enum.TextXAlignment.Right
    infoText.Parent = pageFrame
    
    -- Prev button
    local prevBtn = self:CreatePageButton("◀", self.CurrentPage > 1)
    prevBtn.Parent = pageFrame
    
    -- Next button
    local nextBtn = self:CreatePageButton("▶", self.CurrentPage < pageInfo.totalPages)
    nextBtn.Parent = pageFrame
end

function DataTable:CreatePageButton(text, enabled)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 30, 0, 25)
    btn.BackgroundColor3 = enabled and self.Theme.Accent or self.Theme.Second
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = self.Theme.Text
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    self.Utilities:CreateCorner(btn, 4)
    
    if not enabled then
        btn.AutoButtonColor = false
        btn.TextColor3 = self.Theme.SecondText
    else
        btn.MouseButton1Click:Connect(function()
            if text == "◀" then
                self.CurrentPage = self.CurrentPage - 1
            else
                self.CurrentPage = self.CurrentPage + 1
            end
            self:RenderRows()
            -- Recreate pagination to update buttons
            for _, v in ipairs(self.Container:GetChildren()) do
                if v:IsA("Frame") and v.Size.Y.Offset == 35 then
                    v:Destroy()
                end
            end
            self:CreatePagination()
        end)
    end
    
    return btn
end

function DataTable:GetPageInfo()
    local totalPages = math.max(1, math.ceil(#self.FilteredData / self.PageSize))
    return {
        currentPage = self.CurrentPage,
        totalPages = totalPages,
        totalItems = #self.FilteredData,
        pageSize = self.PageSize
    }
end

-- Public methods to update data
function DataTable:SetData(newData)
    self.Data = newData
    self:ApplyFilter()
    self.CurrentPage = 1
    self:RenderRows()
    if self.ShowPagination then
        for _, v in ipairs(self.Container:GetChildren()) do
            if v:IsA("Frame") and v.Size.Y.Offset == 35 then
                v:Destroy()
            end
        end
        self:CreatePagination()
    end
end

function DataTable:AddRow(rowData)
    table.insert(self.Data, rowData)
    self:ApplyFilter()
    self:RenderRows()
end

function DataTable:ClearRows()
    self.Data = {}
    self.FilteredData = {}
    self:RenderRows()
end

return DataTable
