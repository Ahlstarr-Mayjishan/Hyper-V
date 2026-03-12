local CodeBlock = {}
CodeBlock.__index = CodeBlock

function CodeBlock.new(config, theme, utilities)
    local self = setmetatable({}, CodeBlock)

    self.Name = config.Name or "CodeBlock"
    self.Title = config.Title or config.Name or "Code"
    self.Content = config.Content or config.Text or ""
    self.Wrap = config.Wrap == true
    self.Height = config.Height or 140
    self.Language = config.Language or "text"
    self.Parent = config.Parent
    self.Theme = theme
    self.Utilities = utilities

    self:Create()
    return self
end

function CodeBlock.newCopyField(config, theme, utilities)
    config = config or {}
    config.Height = config.Height or 52
    config.Wrap = false
    return CodeBlock.new(config, theme, utilities)
end

function CodeBlock:Create()
    local container = Instance.new("Frame")
    container.Name = self.Name
    container.Size = UDim2.new(1, 0, 0, self.Height)
    container.BackgroundColor3 = self.Theme.Default
    container.BorderSizePixel = 0
    container.Parent = self.Parent
    self.Utilities:CreateCorner(container, 8)
    self.Utilities:CreateStroke(container, self.Theme.Border)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundColor3 = self.Theme.Second
    header.BorderSizePixel = 0
    header.Parent = container
    self.Utilities:CreateCorner(header, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -88, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = self.Title .. " [" .. self.Language .. "]"
    title.TextColor3 = self.Theme.TitleText
    title.TextSize = 12
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local wrapButton = Instance.new("TextButton")
    wrapButton.Size = UDim2.new(0, 28, 0, 20)
    wrapButton.Position = UDim2.new(1, -62, 0.5, -10)
    wrapButton.BackgroundColor3 = self.Theme.Default
    wrapButton.BorderSizePixel = 0
    wrapButton.Text = "W"
    wrapButton.TextColor3 = self.Theme.Text
    wrapButton.TextSize = 11
    wrapButton.Font = Enum.Font.GothamBold
    wrapButton.Parent = header
    self.Utilities:CreateCorner(wrapButton, 5)

    local copyButton = Instance.new("TextButton")
    copyButton.Size = UDim2.new(0, 28, 0, 20)
    copyButton.Position = UDim2.new(1, -30, 0.5, -10)
    copyButton.BackgroundColor3 = self.Theme.Accent
    copyButton.BorderSizePixel = 0
    copyButton.Text = "C"
    copyButton.TextColor3 = Color3.new(1, 1, 1)
    copyButton.TextSize = 11
    copyButton.Font = Enum.Font.GothamBold
    copyButton.Parent = header
    self.Utilities:CreateCorner(copyButton, 5)

    local body = Instance.new("ScrollingFrame")
    body.Size = UDim2.new(1, -12, 1, -40)
    body.Position = UDim2.new(0, 6, 0, 34)
    body.BackgroundColor3 = self.Theme.Main
    body.BorderSizePixel = 0
    body.ScrollBarThickness = 4
    body.Parent = container
    self.Utilities:CreateCorner(body, 6)

    local text = Instance.new("TextBox")
    text.Size = UDim2.new(1, -12, 1, -12)
    text.Position = UDim2.new(0, 6, 0, 6)
    text.BackgroundTransparency = 1
    text.ClearTextOnFocus = false
    text.MultiLine = true
    text.TextEditable = false
    text.Text = self.Content
    text.TextWrapped = self.Wrap
    text.TextColor3 = self.Theme.Text
    text.TextSize = 12
    text.Font = Enum.Font.Code
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.Parent = body

    local layoutWatcher = function()
        local height = text.TextBounds.Y + 12
        text.Size = UDim2.new(1, -12, 0, math.max(height, body.AbsoluteSize.Y - 12))
        body.CanvasSize = UDim2.new(0, 0, 0, text.AbsoluteSize.Y + 8)
    end
    text:GetPropertyChangedSignal("TextBounds"):Connect(layoutWatcher)

    wrapButton.MouseButton1Click:Connect(function()
        self.Wrap = not self.Wrap
        text.TextWrapped = self.Wrap
        layoutWatcher()
    end)

    copyButton.MouseButton1Click:Connect(function()
        if setclipboard then
            pcall(setclipboard, text.Text)
        end
        copyButton.Text = "OK"
        task.delay(0.7, function()
            if copyButton and copyButton.Parent then
                copyButton.Text = "C"
            end
        end)
    end)

    self.Container = container
    self.TextBox = text
    self.CopyButton = copyButton
    layoutWatcher()
end

function CodeBlock:SetText(text)
    self.Content = text
    if self.TextBox then
        self.TextBox.Text = text
    end
end

function CodeBlock:GetText()
    return self.Content
end

return CodeBlock
