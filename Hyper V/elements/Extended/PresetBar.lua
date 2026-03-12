local HttpService = game:GetService("HttpService")

local PresetBar = {}
PresetBar.__index = PresetBar

local elementRegistry = {}

function PresetBar.RegisterElement(elementType, elementName, getFunc, setFunc)
    if not elementName or not getFunc or not setFunc then
        return
    end

    local key = elementType .. ":" .. elementName
    elementRegistry[key] = {
        type = elementType,
        name = elementName,
        get = getFunc,
        set = setFunc,
    }
end

function PresetBar.GetRegistry()
    return elementRegistry
end

function PresetBar.new(config, theme, utilities)
    local self = setmetatable({}, PresetBar)

    self.Name = config.Name or "PresetManager"
    self.Title = config.Title or "Presets"
    self.Presets = config.Presets or {"Default", "Profile 2", "Profile 3"}
    self.MaxPresets = config.MaxPresets or #self.Presets
    self.CurrentPreset = config.Default or 1
    self.Callback = config.Callback
    self.Description = config.Description or ""
    self.Parent = config.Parent
    self.Theme = theme
    self.Utilities = utilities
    self.PresetButtons = {}
    self.PresetData = {}

    self:Create()
    return self
end

function PresetBar:Create()
    local container = Instance.new("Frame")
    container.Name = self.Name
    container.Size = UDim2.new(1, 0, 0, 70)
    container.BackgroundColor3 = self.Theme.Default
    container.BorderSizePixel = 0
    container.Parent = self.Parent
    self.Utilities:CreateCorner(container, 8)
    self.Utilities:CreateStroke(container, self.Theme.Border)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -110, 0, 18)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = self.Title
    title.TextColor3 = self.Theme.TitleText
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    local exportButton = Instance.new("TextButton")
    exportButton.Size = UDim2.new(0, 44, 0, 20)
    exportButton.Position = UDim2.new(1, -100, 0, 5)
    exportButton.BackgroundColor3 = self.Theme.Second
    exportButton.BorderSizePixel = 0
    exportButton.Text = "Exp"
    exportButton.TextColor3 = self.Theme.Text
    exportButton.TextSize = 10
    exportButton.Font = Enum.Font.GothamBold
    exportButton.Parent = container
    self.Utilities:CreateCorner(exportButton, 5)

    local importButton = Instance.new("TextButton")
    importButton.Size = UDim2.new(0, 44, 0, 20)
    importButton.Position = UDim2.new(1, -52, 0, 5)
    importButton.BackgroundColor3 = self.Theme.Second
    importButton.BorderSizePixel = 0
    importButton.Text = "Imp"
    importButton.TextColor3 = self.Theme.Text
    importButton.TextSize = 10
    importButton.Font = Enum.Font.GothamBold
    importButton.Parent = container
    self.Utilities:CreateCorner(importButton, 5)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -20, 0, 28)
    list.Position = UDim2.new(0, 10, 0, 30)
    list.BackgroundTransparency = 1
    list.Parent = container

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.Parent = list

    self.Container = container
    self.ExportButton = exportButton
    self.ImportButton = importButton
    self.ButtonHost = list

    for index, preset in ipairs(self.Presets) do
        self.PresetData[index] = self.PresetData[index] or {}
        local button = self:_CreatePresetButton(preset, index)
        table.insert(self.PresetButtons, button)
    end

    exportButton.MouseButton1Click:Connect(function()
        local payload = self:ExportPreset(self.CurrentPreset)
        if setclipboard then
            pcall(setclipboard, payload)
        end
        exportButton.Text = "Done"
        task.delay(0.8, function()
            if exportButton and exportButton.Parent then
                exportButton.Text = "Exp"
            end
        end)
    end)

    importButton.MouseButton1Click:Connect(function()
        importButton.Text = "Use API"
        task.delay(1, function()
            if importButton and importButton.Parent then
                importButton.Text = "Imp"
            end
        end)
    end)

    return container
end

function PresetBar:_CreatePresetButton(label, index)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 84, 0, 28)
    button.BackgroundColor3 = index == self.CurrentPreset and self.Theme.Accent or self.Theme.Second
    button.BorderSizePixel = 0
    button.Text = label
    button.TextColor3 = index == self.CurrentPreset and Color3.new(1, 1, 1) or self.Theme.Text
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.Parent = self.ButtonHost
    self.Utilities:CreateCorner(button, 6)

    button.MouseButton1Click:Connect(function()
        self:Select(index)
    end)
    button.MouseButton2Click:Connect(function()
        self:Save(index)
    end)

    return button
end

function PresetBar:_CollectState()
    local snapshot = {}
    for key, entry in pairs(elementRegistry) do
        local ok, value = pcall(entry.get)
        if ok then
            snapshot[key] = value
        end
    end
    return snapshot
end

function PresetBar:_ApplyState(snapshot)
    for key, value in pairs(snapshot or {}) do
        local entry = elementRegistry[key]
        if entry then
            pcall(entry.set, value)
        end
    end
end

function PresetBar:UpdateButtonVisual(index, selected)
    local button = self.PresetButtons[index]
    if not button then
        return
    end
    button.BackgroundColor3 = selected and self.Theme.Accent or self.Theme.Second
    button.TextColor3 = selected and Color3.new(1, 1, 1) or self.Theme.Text
end

function PresetBar:Select(index)
    if not self.Presets[index] then
        return
    end
    local old = self.CurrentPreset
    self.CurrentPreset = index
    self:UpdateButtonVisual(old, false)
    self:UpdateButtonVisual(index, true)
    self:Load(index)
    if self.Callback then
        self.Callback(index, self.Presets[index], "select")
    end
end

function PresetBar:Save(index)
    if not self.Presets[index] then
        return
    end
    self.PresetData[index] = self:_CollectState()
    if self.Callback then
        self.Callback(index, self.Presets[index], "save")
    end
end

function PresetBar:Load(index)
    if not self.Presets[index] then
        return
    end
    self:_ApplyState(self.PresetData[index])
    if self.Callback then
        self.Callback(index, self.Presets[index], "load")
    end
end

function PresetBar:ExportPreset(index)
    local payload = {
        preset = self.Presets[index],
        state = self.PresetData[index] or {},
    }
    return HttpService:JSONEncode(payload)
end

function PresetBar:ImportPreset(index, encoded)
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(encoded)
    end)

    if not ok or type(decoded) ~= "table" then
        return false
    end

    self.PresetData[index] = decoded.state or {}
    self:Load(index)
    return true
end

function PresetBar:SaveCurrent(name)
    local index = self.CurrentPreset
    if name then
        for i, presetName in ipairs(self.Presets) do
            if presetName == name then
                index = i
                break
            end
        end
    end
    self:Save(index)
end

function PresetBar:LoadPreset(name)
    for i, presetName in ipairs(self.Presets) do
        if presetName == name then
            self:Select(i)
            break
        end
    end
end

function PresetBar:GetPresets()
    local list = {}
    for index, name in ipairs(self.Presets) do
        list[index] = {
            name = name,
            hasData = next(self.PresetData[index] or {}) ~= nil,
        }
    end
    return list
end

function PresetBar:GetCurrentPreset()
    return self.CurrentPreset, self.Presets[self.CurrentPreset]
end

function PresetBar:ClearPreset(index)
    self.PresetData[index] = {}
end

function PresetBar:ClearAllPresets()
    for index = 1, #self.Presets do
        self.PresetData[index] = {}
    end
end

return PresetBar
