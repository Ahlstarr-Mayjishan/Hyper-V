--[[
    Hyper-V - Theme Module
    Quản lý màu sắc và giao diện
]]

local Theme = {}

-- Default theme (giống giao diện Hyper-V gốc)
Theme.Default = {
    Default = Color3.fromRGB(35, 35, 35),
    Main = Color3.fromRGB(25, 25, 25),
    Second = Color3.fromRGB(45, 45, 45),
    Border = Color3.fromRGB(60, 60, 60),
    TitleText = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(200, 200, 200),
    SecondText = Color3.fromRGB(140, 140, 140),
    Accent = Color3.fromRGB(0, 85, 255),
    Success = Color3.fromRGB(0, 170, 0),
    Warning = Color3.fromRGB(255, 170, 0),
    Error = Color3.fromRGB(255, 50, 50),
}

-- Dark theme
Theme.Dark = {
    Default = Color3.fromRGB(30, 30, 30),
    Main = Color3.fromRGB(20, 20, 20),
    Second = Color3.fromRGB(40, 40, 40),
    Border = Color3.fromRGB(55, 55, 55),
    TitleText = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(180, 180, 180),
    SecondText = Color3.fromRGB(130, 130, 130),
    Accent = Color3.fromRGB(0, 120, 255),
    Success = Color3.fromRGB(0, 200, 0),
    Warning = Color3.fromRGB(255, 150, 0),
    Error = Color3.fromRGB(255, 60, 60),
}

-- Light theme
Theme.Light = {
    Default = Color3.fromRGB(230, 230, 230),
    Main = Color3.fromRGB(245, 245, 245),
    Second = Color3.fromRGB(255, 255, 255),
    Border = Color3.fromRGB(200, 200, 200),
    TitleText = Color3.fromRGB(20, 20, 20),
    Text = Color3.fromRGB(60, 60, 60),
    SecondText = Color3.fromRGB(120, 120, 120),
    Accent = Color3.fromRGB(0, 100, 220),
    Success = Color3.fromRGB(0, 150, 0),
    Warning = Color3.fromRGB(220, 140, 0),
    Error = Color3.fromRGB(220, 40, 40),
}

-- Chọn theme mặc định
Theme.Current = Theme.Default

function Theme:setTheme(themeName)
    if Theme[themeName] then
        Theme.Current = Theme[themeName]
    end
end

function Theme:getColor(colorName)
    return Theme.Current[colorName] or Theme.Default[colorName]
end

return Theme
