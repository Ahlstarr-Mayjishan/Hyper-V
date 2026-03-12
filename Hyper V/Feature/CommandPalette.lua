local UserInputService = game:GetService("UserInputService")

local CommandPalette = {}
CommandPalette.__index = CommandPalette

function CommandPalette.new(config, context)
    local self = setmetatable({}, CommandPalette)

    self.Name = config.Name or "CommandPalette"
    self.Title = config.Title or "Command Palette"
    self.Actions = config.Actions or {}
    self.Hotkey = config.Hotkey
    self.Parent = config.Parent or (context.HyperV or context.Rayfield).ScreenGui
    self.Theme = context.Theme
    self.Utilities = context.Utilities
    self.Connections = {}
    self.SelectedIndex = 1
    self.FilteredActions = {}

    self:Create()
    self:SetActions(self.Actions)
    return self
end

function CommandPalette:Create()
    local overlay = Instance.new("Frame")
    overlay.Name = self.Name .. "_Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.35
    overlay.BorderSizePixel = 0
    overlay.Visible = false
    overlay.Parent = self.Parent

    local panel = Instance.new("Frame")
    panel.Name = self.Name
    panel.Size = UDim2.new(0, 420, 0, 320)
    panel.Position = UDim2.new(0.5, -210, 0.18, 0)
    panel.BackgroundColor3 = self.Theme.Main
    panel.BorderSizePixel = 0
    panel.Parent = overlay
    self.Utilities:CreateCorner(panel, 10)
    self.Utilities:CreateStroke(panel, self.Theme.Border)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 22)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = self.Title
    title.TextColor3 = self.Theme.TitleText
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 0, 32)
    input.Position = UDim2.new(0, 10, 0, 34)
    input.BackgroundColor3 = self.Theme.Second
    input.BorderSizePixel = 0
    input.PlaceholderText = "Type a command..."
    input.Text = ""
    input.TextColor3 = self.Theme.Text
    input.PlaceholderColor3 = self.Theme.SecondText or self.Theme.Text
    input.TextSize = 12
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = panel
    self.Utilities:CreateCorner(input, 6)
    self.Utilities:CreateStroke(input, self.Theme.Border)

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -20, 1, -82)
    list.Position = UDim2.new(0, 10, 0, 72)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 4
    list.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = list
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end)

    self.Overlay = overlay
    self.Panel = panel
    self.Input = input
    self.List = list
    self.Layout = layout
    self.Buttons = {}

    table.insert(self.Connections, overlay.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 and inputObject.Target == overlay then
            self:Close()
        end
    end))

    table.insert(self.Connections, input:GetPropertyChangedSignal("Text"):Connect(function()
        self:ApplyFilter(input.Text)
    end))

    table.insert(self.Connections, input.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            self:Activate(self.SelectedIndex)
        end
    end))

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
        if gameProcessed then
            return
        end

        if self.Hotkey and inputObject.KeyCode == self.Hotkey then
            if self.Overlay.Visible then
                self:Close()
            else
                self:Open()
            end
            return
        end

        if not self.Overlay.Visible then
            return
        end

        if inputObject.KeyCode == Enum.KeyCode.Escape then
            self:Close()
        elseif inputObject.KeyCode == Enum.KeyCode.Down then
            self:MoveSelection(1)
        elseif inputObject.KeyCode == Enum.KeyCode.Up then
            self:MoveSelection(-1)
        elseif inputObject.KeyCode == Enum.KeyCode.Return or inputObject.KeyCode == Enum.KeyCode.KeypadEnter then
            self:Activate(self.SelectedIndex)
        end
    end))
end

function CommandPalette:SetActions(actions)
    self.Actions = actions or {}
    self:ApplyFilter(self.Input and self.Input.Text or "")
end

function CommandPalette:ApplyFilter(text)
    self.FilteredActions = {}
    local query = text or ""

    for _, action in ipairs(self.Actions) do
        local haystack = (action.Title or "") .. " " .. (action.Description or "")
        if self.Utilities:TextContains(haystack, query, true) then
            table.insert(self.FilteredActions, action)
        end
    end

    self.SelectedIndex = math.clamp(self.SelectedIndex, 1, math.max(1, #self.FilteredActions))
    self:RenderActions()
end

function CommandPalette:RenderActions()
    for _, child in ipairs(self.List:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end

    self.Buttons = {}

    if #self.FilteredActions == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 28)
        empty.BackgroundTransparency = 1
        empty.Text = "No commands"
        empty.TextColor3 = self.Theme.Text
        empty.TextSize = 12
        empty.Font = Enum.Font.Gotham
        empty.Parent = self.List
        return
    end

    for index, action in ipairs(self.FilteredActions) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 42)
        button.BackgroundColor3 = index == self.SelectedIndex and self.Theme.Accent or self.Theme.Second
        button.BorderSizePixel = 0
        button.Text = ""
        button.Parent = self.List
        self.Utilities:CreateCorner(button, 6)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -12, 0, 18)
        title.Position = UDim2.new(0, 8, 0, 4)
        title.BackgroundTransparency = 1
        title.Text = action.Title or ("Action " .. index)
        title.TextColor3 = index == self.SelectedIndex and Color3.new(1, 1, 1) or self.Theme.TitleText
        title.TextSize = 12
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = button

        local description = Instance.new("TextLabel")
        description.Size = UDim2.new(1, -12, 0, 14)
        description.Position = UDim2.new(0, 8, 0, 22)
        description.BackgroundTransparency = 1
        description.Text = action.Description or ""
        description.TextColor3 = index == self.SelectedIndex and Color3.new(0.92, 0.92, 0.92) or (self.Theme.SecondText or self.Theme.Text)
        description.TextSize = 10
        description.Font = Enum.Font.Gotham
        description.TextXAlignment = Enum.TextXAlignment.Left
        description.Parent = button

        button.MouseButton1Click:Connect(function()
            self.SelectedIndex = index
            self:RenderActions()
            self:Activate(index)
        end)

        self.Buttons[index] = button
    end
end

function CommandPalette:MoveSelection(delta)
    if #self.FilteredActions == 0 then
        return
    end
    self.SelectedIndex = math.clamp(self.SelectedIndex + delta, 1, #self.FilteredActions)
    self:RenderActions()
end

function CommandPalette:Activate(index)
    local action = self.FilteredActions[index]
    if not action then
        return
    end
    if action.Callback then
        action.Callback(action)
    end
    self:Close()
end

function CommandPalette:Open()
    self.Overlay.Visible = true
    self.Input.Text = ""
    self.SelectedIndex = 1
    self:ApplyFilter("")
    task.defer(function()
        if self.Input then
            self.Input:CaptureFocus()
        end
    end)
end

function CommandPalette:Close()
    self.Overlay.Visible = false
    if self.Input then
        self.Input:ReleaseFocus()
    end
end

return CommandPalette
