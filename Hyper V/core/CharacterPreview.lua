--[[
    CharacterPreview - Preview character với các tùy chỉnh
    Bao gồm: Transparency, Highlight, Skeleton ESP, Charms
]]

local CharacterPreview = {}
CharacterPreview.__index = CharacterPreview

export type PreviewConfig = {
    PlayerId: number?,
    TargetCharacter: Model?,
    OnApply: ((config: CharacterConfig) -> ())?,
    OnCancel: (() -> ())?,
}

export type CharacterConfig = {
    Transparency: number,          -- 0-1
    HighlightEnabled: boolean,
    HighlightColor: Color3,
    HighlightFillColor: Color3,
    SkeletonEnabled: boolean,
    SkeletonColor: Color3,
    ShowCharms: boolean,
    CharmsColor: Color3?,
    OutlineEnabled: boolean,
    OutlineColor: Color3?,
}

local function getDefaultConfig(): CharacterConfig
    return {
        Transparency = 0,
        HighlightEnabled = false,
        HighlightColor = Color3.fromRGB(0, 85, 255),
        HighlightFillColor = Color3.fromRGB(0, 85, 255),
        SkeletonEnabled = false,
        SkeletonColor = Color3.fromRGB(255, 255, 255),
        ShowCharms = true,
        CharmsColor = nil,
        OutlineEnabled = false,
        OutlineColor = nil,
    }
end

function CharacterPreview.new(config: PreviewConfig?)
    local self = setmetatable({}, CharacterPreview)
    
    self.Config = config or {}
    self.PreviewCharacter = nil
    self.OriginalCharacter = nil
    self.SkeletonParts = {}
    self.HighlightObj = nil
    self.IsPreviewing = false
    self.PreviewFrame = nil
    
    -- Store original states để restore
    self.OriginalStates = {}
    
    return self
end

-- Load character từ PlayerId hoặc sử dụng local character
function CharacterPreview:LoadCharacter(playerId: number?)
    local Players = game:GetService("Players")
    
    if playerId then
        -- Try to get player by userId
        local success, player = pcall(function()
            return Players:GetPlayerByUserId(playerId)
        end)
        
        if success and player then
            self.OriginalCharacter = player.Character
        else
            -- Character chưa loaded, có thể cần spawn
            warn("[CharacterPreview] Player not found or character not loaded")
            return false
        end
    else
        -- Use local player character
        self.OriginalCharacter = Players.LocalPlayer.Character
    end
    
    if not self.OriginalCharacter then
        return false
    end
    
    -- Clone for preview
    self.PreviewCharacter = self.OriginalCharacter:Clone()
    return true
end

-- Tạo preview UI frame
function CharacterPreview:CreatePreviewFrame(parent: Instance): Frame
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    
    -- Main preview container
    local PreviewFrame = Instance.new("Frame")
    PreviewFrame.Name = "CharacterPreview"
    PreviewFrame.Size = UDim2.new(0, 200, 0, 300)
    PreviewFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    PreviewFrame.BorderSizePixel = 0
    PreviewFrame.Parent = parent
    
    -- Corner
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = PreviewFrame
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Title.Text = "Character Preview"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.Parent = PreviewFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = Title
    
    -- Viewport frame for 3D preview
    local ViewportFrame = Instance.new("ViewportFrame")
    ViewportFrame.Name = "Viewport"
    ViewportFrame.Size = UDim2.new(1, -20, 1, -80)
    ViewportFrame.Position = UDim2.new(0, 10, 0, 40)
    ViewportFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ViewportFrame.BorderSizePixel = 0
    ViewportFrame.Parent = PreviewFrame
    
    local ViewportCorner = Instance.new("UICorner")
    ViewportCorner.CornerRadius = UDim.new(0, 6)
    ViewportCorner.Parent = ViewportFrame
    
    -- Add camera
    local Camera = Instance.new("Camera")
    Camera.CFrame = CFrame.new(Vector3.new(0, 2, 8), Vector3.new(0, 1, 0))
    ViewportFrame.CurrentCamera = Camera
    Camera.Parent = ViewportFrame
    
    self.PreviewFrame = PreviewFrame
    self.ViewportFrame = ViewportFrame
    self.Camera = Camera
    
    return PreviewFrame
end

-- Apply transparency to preview character
function CharacterPreview:SetTransparency(value: number)
    if not self.PreviewCharacter then return end
    
    value = math.clamp(value, 0, 1)
    
    for _, part in ipairs(self.PreviewCharacter:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = value
        elseif part:IsA("Accesory") or part:IsA("Accessory") then
            for _, child in ipairs(part:GetDescendants()) do
                if child:IsA("BasePart") then
                    child.Transparency = value
                end
            end
        end
    end
end

-- Add/Remove highlight
function CharacterPreview:SetHighlight(enabled: boolean, fillColor: Color3?, outlineColor: Color3?)
    if not self.PreviewCharacter then return end
    
    if enabled then
        if not self.HighlightObj then
            self.HighlightObj = Instance.new("Highlight")
            self.HighlightObj.Adornee = self.PreviewCharacter
            self.HighlightObj.FillColor = fillColor or Color3.fromRGB(0, 85, 255)
            self.HighlightObj.OutlineColor = outlineColor or Color3.fromRGB(255, 255, 255)
            self.HighlightObj.FillTransparency = 0.5
            self.HighlightObj.OutlineTransparency = 0
            self.HighlightObj.Parent = self.PreviewCharacter
        else
            self.HighlightObj.FillColor = fillColor or self.HighlightObj.FillColor
            self.HighlightObj.OutlineColor = outlineColor or self.HighlightObj.OutlineColor
            self.HighlightObj.Visible = true
        end
    else
        if self.HighlightObj then
            self.HighlightObj.Visible = false
        end
    end
end

-- Create skeleton ESP
function CharacterPreview:SetSkeleton(enabled: boolean, skeletonColor: Color3?)
    if not self.PreviewCharacter then return end
    
    -- Clear existing skeleton
    for _, part in ipairs(self.SkeletonParts) do
        part:Destroy()
    end
    self.SkeletonParts = {}
    
    if not enabled then return end
    
    local color = skeletonColor or Color3.fromRGB(255, 255, 255)
    
    -- Define skeleton connections (limb to limb)
    local skeletonConnections = {
        {"Head", "Torso"},
        {"Torso", "LeftArm"},
        {"Torso", "RightArm"},
        {"Torso", "LeftLeg"},
        {"Torso", "RightLeg"},
    }
    
    -- Get body parts
    local bodyParts = {}
    for _, part in ipairs(self.PreviewCharacter:GetChildren()) do
        if part:IsA("BasePart") then
            bodyParts[part.Name] = part
        end
    end
    
    -- Create skeleton lines
    for _, connection in ipairs(skeletonConnections) do
        local partA = bodyParts[connection[1]]
        local partB = bodyParts[connection[2]]
        
        if partA and partB then
            local distance = (partA.Position - partB.Position).Magnitude
            local midPoint = (partA.Position + partB.Position) / 2
            
            local line = Instance.new("Frame")
            line.Name = "SkeletonLine"
            line.Size = UDim2.new(0, distance, 0, 2)
            line.Position = UDim2.new(0, 0, 0, 0)
            line.BackgroundColor3 = color
            line.BorderSizePixel = 0
            line.AnchorPoint = Vector2.new(0.5, 0.5)
            
            -- Rotate to face target
            local direction = (partB.Position - partA.Position).Unit
            local angle = math.atan2(direction.X, direction.Z)
            local rotation = math.deg(angle)
            
            -- Use BillboardGui for 3D effect
            local billboard = Instance.new("BillboardGui")
            billboard.Size = UDim2.new(0, distance, 0, 2)
            billboard.Adornee = partA
            billboard.AlwaysInFront = true
            billboard.SizeOffset = Vector2.new(0.5, 0)
            
            line.Parent = billboard
            billboard.Parent = self.PreviewCharacter
            
            table.insert(self.SkeletonParts, billboard)
        end
    end
    
    -- Add joint dots
    for _, part in ipairs(self.PreviewCharacter:GetChildren()) do
        if part:IsA("BasePart") and (part.Name == "Head" or part.Name == "Torso" or part.Name:match("Arm") or part.Name:match("Leg")) then
            local dot = Instance.new("Frame")
            dot.Name = "SkeletonJoint"
            dot.Size = UDim2.new(0, 6, 0, 6)
            dot.BackgroundColor3 = color
            dot.BorderSizePixel = 0
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            
            local billboard = Instance.new("BillboardGui")
            billboard.Size = UDim2.new(0, 6, 0, 6)
            billboard.Adornee = part
            billboard.AlwaysInFront = true
            
            dot.Parent = billboard
            billboard.Parent = self.PreviewCharacter
            
            table.insert(self.SkeletonParts, billboard)
        end
    end
end

-- Toggle charms/accessories visibility
function CharacterPreview:SetCharms(visible: boolean, customColor: Color3?)
    if not self.PreviewCharacter then return end
    
    for _, child in ipairs(self.PreviewCharacter:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Hat") then
            child.Visible = visible
            
            if customColor and visible then
                for _, part in ipairs(child:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "Handle" then
                        part.Color = customColor
                    end
                end
            end
        end
    end
end

-- Apply full config
function CharacterPreview:ApplyConfig(config: CharacterConfig)
    self:SetTransparency(config.Transparency)
    self:SetHighlight(config.HighlightEnabled, config.HighlightFillColor, config.HighlightColor)
    self:SetSkeleton(config.SkeletonEnabled, config.SkeletonColor)
    self:SetCharms(config.ShowCharms, config.CharmsColor)
end

-- Start preview mode
function CharacterPreview:StartPreview(config: CharacterConfig?)
    if self.IsPreviewing then return end
    
    config = config or getDefaultConfig()
    self.CurrentConfig = config
    self.IsPreviewing = true
    
    -- Load character if not loaded
    if not self.PreviewCharacter then
        local success = self:LoadCharacter(self.Config.PlayerId)
        if not success then
            warn("[CharacterPreview] Failed to load character")
            return false
        end
    end
    
    -- Add to viewport if available
    if self.ViewportFrame and self.PreviewCharacter then
        self.PreviewCharacter.Parent = self.ViewportFrame
        
        -- Position character
        local hrp = self.PreviewCharacter:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(0, 0, 0)
        end
        
        -- Apply config
        self:ApplyConfig(config)
    end
    
    return true
end

-- Stop preview and cleanup
function CharacterPreview:StopPreview()
    if not self.IsPreviewing then return end
    
    self.IsPreviewing = false
    
    -- Destroy preview character
    if self.PreviewCharacter then
        self.PreviewCharacter:Destroy()
        self.PreviewCharacter = nil
    end
    
    -- Clear skeleton
    for _, part in ipairs(self.SkeletonParts) do
        part:Destroy()
    end
    self.SkeletonParts = {}
    
    self.HighlightObj = nil
end

-- Confirm apply - gọi OnApply callback
function CharacterPreview:ConfirmApply()
    if self.Config.OnApply and self.CurrentConfig then
        self.Config.OnApply(self.CurrentConfig)
    end
    self:StopPreview()
end

-- Cancel - gọi OnCancel callback
function CharacterPreview:Cancel()
    if self.Config.OnCancel then
        self.Config.OnCancel()
    end
    self:StopPreview()
end

-- Get current config
function CharacterPreview:GetConfig(): CharacterConfig
    return self.CurrentConfig or getDefaultConfig()
end

-- Create full preview UI with controls
function CharacterPreview:CreatePreviewUI(parent: Instance): Frame
    local TweenService = game:GetService("TweenService")
    
    -- Main container
    local Container = self:CreatePreviewFrame(parent)
    
    -- Controls section
    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.Size = UDim2.new(1, -20, 0, 35)
    Controls.Position = UDim2.new(0, 10, 1, -45)
    Controls.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Controls.BorderSizePixel = 0
    Controls.Parent = Container
    
    local ControlsCorner = Instance.new("UICorner")
    ControlsCorner.CornerRadius = UDim.new(0, 6)
    ControlsCorner.Parent = Controls
    
    -- Cancel button
    local CancelBtn = Instance.new("TextButton")
    CancelBtn.Name = "CancelBtn"
    CancelBtn.Size = UDim2.new(0.5, -6, 1, -6)
    CancelBtn.Position = UDim2.new(0, 3, 0, 3)
    CancelBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
    CancelBtn.Text = "Cancel"
    CancelBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
    CancelBtn.TextSize = 12
    CancelBtn.Font = Enum.Font.Gotham
    CancelBtn.Parent = Controls
    
    local CancelCorner = Instance.new("UICorner")
    CancelCorner.CornerRadius = UDim.new(0, 4)
    CancelCorner.Parent = CancelBtn
    
    CancelBtn.MouseButton1Click:Connect(function()
        self:Cancel()
    end)
    
    -- Apply button
    local ApplyBtn = Instance.new("TextButton")
    ApplyBtn.Name = "ApplyBtn"
    ApplyBtn.Size = UDim2.new(0.5, -6, 1, -6)
    ApplyBtn.Position = UDim2.new(0.5, 3, 0, 3)
    ApplyBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
    ApplyBtn.Text = "Apply"
    ApplyBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
    ApplyBtn.TextSize = 12
    ApplyBtn.Font = Enum.Font.Gotham
    ApplyBtn.Parent = Controls
    
    local ApplyCorner = Instance.new("UICorner")
    ApplyCorner.CornerRadius = UDim.new(0, 4)
    ApplyCorner.Parent = ApplyBtn
    
    ApplyBtn.MouseButton1Click:Connect(function()
        self:ConfirmApply()
    end)
    
    return Container
end

return CharacterPreview

