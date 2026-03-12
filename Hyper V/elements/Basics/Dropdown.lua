--[[
    Hyper-V - Dropdown Component
    Menu thả xuống cho phép chọn một tùy chọn
]]

local TweenService = game:GetService("TweenService")

local function CreateDropdown(config, theme, utilities)
    local options = config.Options or {"Option 1", "Option 2", "Option 3"}
    local selectedOption = config.Default or options[1]
    
    local Dropdown = Instance.new("Frame")
    Dropdown.Name = "Dropdown"
    Dropdown.Size = UDim2.new(1, 0, 0, 40)
    Dropdown.BackgroundColor3 = theme.Second
    Dropdown.BorderSizePixel = 0
    Dropdown.Parent = config.Parent
    utilities:CreateCorner(Dropdown, 6)
    utilities:CreateStroke(Dropdown, theme.Border)
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = config.Name or "Dropdown"
    Title.TextColor3 = theme.Text
    Title.TextSize = 13
    Title.Font = Enum.Font.Gotham
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Dropdown
    
    -- Selected value display
    local Selected = Instance.new("TextLabel")
    Selected.Name = "Selected"
    Selected.Size = UDim2.new(1, -40, 1, 0)
    Selected.Position = UDim2.new(0, 10, 0, 0)
    Selected.BackgroundTransparency = 1
    Selected.Text = selectedOption
    Selected.TextColor3 = theme.TitleText
    Selected.TextSize = 13
    Selected.Font = Enum.Font.GothamBold
    Selected.TextXAlignment = Enum.TextXAlignment.Left
    Selected.Parent = Dropdown
    
    -- Arrow icon
    local Arrow = Instance.new("TextLabel")
    Arrow.Name = "Arrow"
    Arrow.Size = UDim2.new(0, 30, 0, 30)
    Arrow.Position = UDim2.new(1, -30, 0.5, 0)
    Arrow.AnchorPoint = Vector2.new(1, 0.5)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▼"
    Arrow.TextColor3 = theme.Text
    Arrow.TextSize = 10
    Arrow.Font = Enum.Font.GothamBold
    Arrow.Parent = Dropdown
    
    -- Options frame (hidden by default)
    local OptionsFrame = Instance.new("Frame")
    OptionsFrame.Name = "OptionsFrame"
    OptionsFrame.Size = UDim2.new(1, 0, 0, 0)
    OptionsFrame.Position = UDim2.new(0, 0, 1, 5)
    OptionsFrame.BackgroundColor3 = theme.Default
    OptionsFrame.BorderSizePixel = 0
    OptionsFrame.ClipsDescendants = true
    OptionsFrame.Visible = false
    OptionsFrame.Parent = Dropdown
    utilities:CreateCorner(OptionsFrame, 6)
    utilities:CreateStroke(OptionsFrame, theme.Border)
    
    local OptionsList = Instance.new("UIListLayout")
    OptionsList.Padding = UDim.new(0, 2)
    OptionsList.Parent = OptionsFrame
    
    local OptionsPadding = Instance.new("UIPadding")
    OptionsPadding.PaddingTop = UDim.new(0, 5)
    OptionsPadding.PaddingLeft = UDim.new(0, 5)
    OptionsPadding.PaddingRight = UDim.new(0, 5)
    OptionsPadding.PaddingBottom = UDim.new(0, 5)
    OptionsPadding.Parent = OptionsFrame
    
    local isOpen = false
    local optionButtons = {}
    
    -- Create option buttons
    for _, option in ipairs(options) do
        local OptionBtn = Instance.new("TextButton")
        OptionBtn.Name = option
        OptionBtn.Size = UDim2.new(1, -10, 0, 30)
        OptionBtn.AutomaticSize = Enum.AutomaticSize.Y
        OptionBtn.BackgroundColor3 = theme.Second
        OptionBtn.Text = option
        OptionBtn.TextColor3 = theme.Text
        OptionBtn.TextSize = 13
        OptionBtn.Font = Enum.Font.Gotham
        OptionBtn.Parent = OptionsFrame
        utilities:CreateCorner(OptionBtn, 4)
        
        -- Hover effect
        OptionBtn.MouseEnter:Connect(function()
            TweenService:Create(OptionBtn, TweenInfo.new(0.1), {
                BackgroundColor3 = theme.Accent
            }):Play()
        end)
        
        OptionBtn.MouseLeave:Connect(function()
            if option ~= selectedOption then
                TweenService:Create(OptionBtn, TweenInfo.new(0.1), {
                    BackgroundColor3 = theme.Second
                }):Play()
            end
        end)
        
        -- Click effect
        OptionBtn.MouseButton1Click:Connect(function()
            selectedOption = option
            Selected.Text = option
            isOpen = false
            OptionsFrame.Visible = false
            
            TweenService:Create(Arrow, TweenInfo.new(0.15), {
                Rotation = 0
            }):Play()
            
            -- Reset all options color
            for _, btn in ipairs(optionButtons) do
                btn.BackgroundColor3 = theme.Second
            end
            OptionBtn.BackgroundColor3 = theme.Accent
            
            if config.OnChange then
                config.OnChange(option)
            end
        end)
        
        table.insert(optionButtons, OptionBtn)
        
        -- Highlight default option
        if option == selectedOption then
            OptionBtn.BackgroundColor3 = theme.Accent
        end
    end
    
    -- Update options frame size
    local totalHeight = #options * 32 + 10
    OptionsFrame.Size = UDim2.new(1, 0, 0, totalHeight)
    
    -- Toggle dropdown
    local function ToggleDropdown()
        isOpen = not isOpen
        OptionsFrame.Visible = isOpen
        
        if isOpen then
            TweenService:Create(Arrow, TweenInfo.new(0.15), {
                Rotation = 180
            }):Play()
        else
            TweenService:Create(Arrow, TweenInfo.new(0.15), {
                Rotation = 0
            }):Play()
        end
    end
    
    Dropdown.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            ToggleDropdown()
        end
    end)
    
    -- Close dropdown when clicking outside
    local function CloseDropdown()
        if isOpen then
            isOpen = false
            OptionsFrame.Visible = false
            TweenService:Create(Arrow, TweenInfo.new(0.15), {
                Rotation = 0
            }):Play()
        end
    end
    
    -- Set options function
    function Dropdown:SetOptions(newOptions)
        options = newOptions
        -- Clear old options
        for _, child in ipairs(OptionsFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        optionButtons = {}
        
        -- Create new options
        for _, option in ipairs(options) do
            local OptionBtn = Instance.new("TextButton")
            OptionBtn.Name = option
            OptionBtn.Size = UDim2.new(1, -10, 0, 30)
            OptionBtn.AutomaticSize = Enum.AutomaticSize.Y
            OptionBtn.BackgroundColor3 = theme.Second
            OptionBtn.Text = option
            OptionBtn.TextColor3 = theme.Text
            OptionBtn.TextSize = 13
            OptionBtn.Font = Enum.Font.Gotham
            OptionBtn.Parent = OptionsFrame
            utilities:CreateCorner(OptionBtn, 4)
            
            OptionBtn.MouseEnter:Connect(function()
                TweenService:Create(OptionBtn, TweenInfo.new(0.1), {
                    BackgroundColor3 = theme.Accent
                }):Play()
            end)
            
            OptionBtn.MouseLeave:Connect(function()
                if option ~= selectedOption then
                    TweenService:Create(OptionBtn, TweenInfo.new(0.1), {
                        BackgroundColor3 = theme.Second
                    }):Play()
                end
            end)
            
            OptionBtn.MouseButton1Click:Connect(function()
                selectedOption = option
                Selected.Text = option
                isOpen = false
                OptionsFrame.Visible = false
                
                TweenService:Create(Arrow, TweenInfo.new(0.15), {
                    Rotation = 0
                }):Play()
                
                for _, btn in ipairs(optionButtons) do
                    btn.BackgroundColor3 = theme.Second
                end
                OptionBtn.BackgroundColor3 = theme.Accent
                
                if config.OnChange then
                    config.OnChange(option)
                end
            end)
            
            table.insert(optionButtons, OptionBtn)
            
            if option == selectedOption then
                OptionBtn.BackgroundColor3 = theme.Accent
            end
        end
        
        totalHeight = #options * 32 + 10
        OptionsFrame.Size = UDim2.new(1, 0, 0, totalHeight)
    end
    
    -- Get selected value
    function Dropdown:GetValue()
        return selectedOption
    end
    
    return Dropdown, CloseDropdown
end

return CreateDropdown
