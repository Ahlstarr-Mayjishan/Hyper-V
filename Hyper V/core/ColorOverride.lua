--[[
    ColorOverride - Cho phép custom color cho từng element
    Merge custom color với theme default
]]

local ColorOverride = {}

-- Color type aliases
export type ColorConfig = {
    BackgroundColor3: Color3?,
    TextColor3: Color3?,
    AccentColor3: Color3?,
    BorderColor3: Color3?,
    -- Extended colors
    Success: Color3?,
    Warning: Color3?,
    Error: Color3?,
    Info: Color3?,
}

-- Merge custom color config với theme
function ColorOverride:Merge(theme, customColors: ColorConfig?)
    if not customColors then
        return theme
    end
    
    -- Create a copy of theme
    local merged = {}
    for key, value in pairs(theme) do
        merged[key] = value
    end
    
    -- Override with custom colors
    if customColors.BackgroundColor3 then
        merged.Default = customColors.BackgroundColor3
        merged.Main = customColors.BackgroundColor3
        merged.Second = customColors.BackgroundColor3
    end
    
    if customColors.TextColor3 then
        merged.Text = customColors.TextColor3
        merged.TitleText = customColors.TextColor3
    end
    
    if customColors.AccentColor3 then
        merged.Accent = customColors.AccentColor3
    end
    
    if customColors.BorderColor3 then
        merged.Border = customColors.BorderColor3
    end
    
    -- Extended colors
    if customColors.Success then merged.Success = customColors.Success end
    if customColors.Warning then merged.Warning = customColors.Warning end
    if customColors.Error then merged.Error = customColors.Error end
    if customColors.Info then merged.Info = customColors.Info end
    
    return merged
end

-- Apply color directly to instance
function ColorOverride:Apply(instance: Instance, colors: ColorConfig)
    if not instance or not colors then return end
    
    local success, err = pcall(function()
        -- GuiObject colors
        if instance:IsA("GuiObject") then
            if colors.BackgroundColor3 then
                instance.BackgroundColor3 = colors.BackgroundColor3
            end
        end
        
        -- Text element colors
        if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            if colors.TextColor3 then
                instance.TextColor3 = colors.TextColor3
            end
        end
        
        -- Apply to children recursively
        for _, child in ipairs(instance:GetChildren()) do
            self:Apply(child, colors)
        end
    end)
    
    if not success then
        warn("[ColorOverride] Apply failed:", err)
    end
end

-- Interpolate between two colors (lerp)
function ColorOverride:Lerp(color1: Color3, color2: Color3, alpha: number)
    return Color3.new(
        color1.R + (color2.R - color1.R) * alpha,
        color1.G + (color2.G - color1.G) * alpha,
        color1.B + (color2.B - color1.B) * alpha
    )
end

-- Create gradient colors
function ColorOverride:Gradient(colors: {Color3}, steps: number)
    local result = {}
    local count = #colors
    
    for i = 1, steps do
        local t = (i - 1) / (steps - 1)
        local segment = t * (count - 1)
        local index = math.floor(segment) + 1
        local localT = segment - math.floor(segment)
        
        local c1 = colors[math.min(index, count)]
        local c2 = colors[math.min(index + 1, count)]
        
        table.insert(result, self:Lerp(c1, c2, localT))
    end
    
    return result
end

-- Parse hex color string to Color3
function ColorOverride:FromHex(hex: string): Color3?
    hex = hex:gsub("#", "")
    
    if #hex == 6 then
        local r = tonumber(hex:sub(1, 2), 16) / 255
        local g = tonumber(hex:sub(3, 4), 16) / 255
        local b = tonumber(hex:sub(5, 6), 16) / 255
        return Color3.new(r, g, b)
    elseif #hex == 3 then
        local r = tonumber(hex:sub(1, 1):rep(2), 16) / 255
        local g = tonumber(hex:sub(2, 2):rep(2), 16) / 255
        local b = tonumber(hex:sub(3, 3):rep(2), 16) / 255
        return Color3.new(r, g, b)
    end
    
    return nil
end

-- Convert Color3 to hex string
function ColorOverride:ToHex(color: Color3): string
    local r = math.floor(color.R * 255)
    local g = math.floor(color.G * 255)
    local b = math.floor(color.B * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

-- Darken/Lighten color
function ColorOverride:Darken(color: Color3, amount: number)
    return self:Lerp(color, Color3.new(0, 0, 0), amount)
end

function ColorOverride:Lighten(color: Color3, amount: number)
    return self:Lerp(color, Color3.new(1, 1, 1), amount)
end

-- Get contrasting text color (black or white)
function ColorOverride:ContrastColor(background: Color3)
    local luminance = 0.299 * background.R + 0.587 * background.G + 0.114 * background.B
    return luminance > 0.5 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
end

-- Preset color palettes
ColorOverride.Palettes = {
    -- Dracula theme
    Dracula = {
        Background = Color3.fromRGB(40, 42, 54),
        CurrentLine = Color3.fromRGB(68, 71, 90),
        Foreground = Color3.fromRGB(248, 248, 242),
        Comment = Color3.fromRGB(98, 114, 164),
        Cyan = Color3.fromRGB(139, 233, 253),
        Green = Color3.fromRGB(80, 250, 123),
        Orange = Color3.fromRGB(255, 184, 108),
        Pink = Color3.fromRGB(255, 121, 198),
        Purple = Color3.fromRGB(189, 147, 249),
        Red = Color3.fromRGB(255, 85, 85),
        Yellow = Color3.fromRGB(241, 250, 140),
    },
    
    -- Nord theme
    Nord = {
        PolarNight = Color3.fromRGB(46, 52, 64),
        SnowStorm = Color3.fromRGB(216, 222, 233),
        Frost = Color3.fromRGB(136, 192, 208),
        Aurora = Color3.fromRGB(129, 161, 193),
        Red = Color3.fromRGB(191, 97, 106),
        Orange = Color3.fromRGB(235, 203, 139),
        Green = Color3.fromRGB(163, 190, 140),
        Purple = Color3.fromRGB(180, 142, 173),
    },
    
    -- Ocean theme
    Ocean = {
        Deep = Color3.fromRGB(0, 30, 60),
        Light = Color3.fromRGB(0, 120, 200),
        Accent = Color3.fromRGB(0, 200, 255),
        Text = Color3.fromRGB(240, 248, 255),
    },
    
    -- Forest theme
    Forest = {
        Dark = Color3.fromRGB(20, 40, 20),
        Medium = Color3.fromRGB(40, 80, 40),
        Light = Color3.fromRGB(60, 120, 60),
        Accent = Color3.fromRGB(100, 200, 100),
    },
    
    -- Sunset theme
    Sunset = {
        Dark = Color3.fromRGB(30, 10, 20),
        Purple = Color3.fromRGB(100, 50, 150),
        Orange = Color3.fromRGB(255, 150, 50),
        Yellow = Color3.fromRGB(255, 220, 100),
        Pink = Color3.fromRGB(255, 100, 150),
    },
    
    -- Neon theme
    Neon = {
        Background = Color3.fromRGB(10, 10, 20),
        Cyan = Color3.fromRGB(0, 255, 255),
        Magenta = Color3.fromRGB(255, 0, 255),
        Green = Color3.fromRGB(0, 255, 100),
        Yellow = Color3.fromRGB(255, 255, 0),
    },
}

-- Get palette by name
function ColorOverride:GetPalette(name: string): any
    return self.Palettes[name]
end

-- Create color config from palette
function ColorOverride:FromPalette(paletteName: string, colorKey: string): Color3?
    local palette = self.Palettes[paletteName]
    if palette then
        return palette[colorKey]
    end
    return nil
end

return ColorOverride

