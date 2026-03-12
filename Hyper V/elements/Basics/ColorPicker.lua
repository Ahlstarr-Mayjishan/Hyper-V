local function CreateColorPicker(config, theme, utilities)
    local picker = Instance.new("TextButton")
    picker.Name = config.Name or "ColorPicker"
    picker.Size = UDim2.new(1, 0, 0, 36)
    picker.BackgroundColor3 = config.Default or theme.Accent
    picker.BorderSizePixel = 0
    picker.Text = config.Name or "Color Picker"
    picker.TextColor3 = theme.TitleText
    picker.TextSize = 13
    picker.Font = Enum.Font.GothamBold
    picker.Parent = config.Parent
    utilities:CreateCorner(picker, 6)
    utilities:CreateStroke(picker, theme.Border, 1)

    local currentColor = config.Default or theme.Accent
    local palette = {
        Color3.fromRGB(255, 85, 85),
        Color3.fromRGB(255, 170, 0),
        Color3.fromRGB(0, 170, 255),
        Color3.fromRGB(0, 200, 120),
        Color3.fromRGB(170, 85, 255),
    }
    local index = 1

    picker.MouseButton1Click:Connect(function()
        index = index % #palette + 1
        currentColor = palette[index]
        picker.BackgroundColor3 = currentColor
        if config.OnChange then
            config.OnChange(currentColor)
        end
    end)

    if config.OnChange then
        task.defer(function()
            config.OnChange(currentColor)
        end)
    end

    return picker
end

return CreateColorPicker
