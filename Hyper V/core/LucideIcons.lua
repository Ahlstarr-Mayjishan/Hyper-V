--[[
    LucideIcons - Lucide Icon Support cho Roblox
    Sử dụng spritesheet approach
]]

local LucideIcons = {}

-- Sprite sheet configuration
local SPRITE_SIZE = 16  -- 16x16 icons
local SHEET_SIZE = 512  -- 512x512 spritesheet (32x32 icons)

-- Icon name -> (x, y) position mapping on spritesheet
-- Positions are in grid coordinates (0-31)
local ICON_MAP = {
    -- Navigation
    ["home"] = {0, 0},
    ["search"] = {1, 0},
    ["settings"] = {2, 0},
    ["menu"] = {3, 0},
    ["bell"] = {4, 0},
    ["bell-off"] = {5, 0},
    ["user"] = {6, 0},
    ["users"] = {7, 0},
    
    -- Actions
    ["plus"] = {0, 1},
    ["minus"] = {1, 1},
    ["x"] = {2, 1},
    ["check"] = {3, 1},
    ["copy"] = {4, 1},
    ["edit"] = {5, 1},
    ["trash"] = {6, 1},
    ["save"] = {7, 1},
    ["download"] = {8, 1},
    ["upload"] = {9, 1},
    ["refresh"] = {10, 1},
    ["rotate-ccw"] = {11, 1},
    ["rotate-cw"] = {12, 1},
    
    -- UI Elements
    ["eye"] = {0, 2},
    ["eye-off"] = {1, 2},
    ["lock"] = {2, 2},
    ["unlock"] = {3, 2},
    ["star"] = {4, 2},
    ["star-filled"] = {4, 2},  -- Same as star
    ["heart"] = {5, 2},
    ["heart-filled"] = {5, 2},
    ["bookmark"] = {6, 2},
    ["flag"] = {7, 2},
    ["alert-circle"] = {8, 2},
    ["alert-triangle"] = {9, 2},
    ["info"] = {10, 2},
    ["help-circle"] = {11, 2},
    
    -- Arrows
    ["arrow-up"] = {0, 3},
    ["arrow-down"] = {1, 3},
    ["arrow-left"] = {2, 3},
    ["arrow-right"] = {3, 3},
    ["chevron-up"] = {4, 3},
    ["chevron-down"] = {5, 3},
    ["chevron-left"] = {6, 3},
    ["chevron-right"] = {7, 3},
    ["chevrons-up"] = {8, 3},
    ["chevrons-down"] = {9, 3},
    ["chevrons-left"] = {10, 3},
    ["chevrons-right"] = {11, 3},
    
    -- Media
    ["play"] = {0, 4},
    ["pause"] = {1, 4},
    ["skip-forward"] = {2, 4},
    ["skip-back"] = {3, 4},
    ["volume"] = {4, 4},
    ["volume-x"] = {5, 4},
    ["volume-1"] = {6, 4},
    ["volume-2"] = {7, 4},
    ["mic"] = {8, 4},
    ["mic-off"] = {9, 4},
    ["camera"] = {10, 4},
    ["camera-off"] = {11, 4},
    
    -- Files & Folders
    ["file"] = {0, 5},
    ["file-text"] = {1, 5},
    ["folder"] = {2, 5},
    ["folder-open"] = {3, 5},
    ["file-plus"] = {4, 5},
    ["file-minus"] = {5, 5},
    ["trash-2"] = {6, 5},
    
    -- Status
    ["circle"] = {0, 6},
    ["check-circle"] = {1, 6},
    ["x-circle"] = {2, 6},
    ["alert-circle"] = {3, 6},
    ["loader"] = {4, 6},
    ["zap"] = {5, 6},
    
    -- Misc
    ["gift"] = {0, 7},
    ["link"] = {1, 7},
    ["link-2"] = {2, 7},
    ["calendar"] = {3, 7},
    ["clock"] = {4, 7},
    ["map-pin"] = {5, 7},
    ["globe"] = {6, 7},
    ["command"] = {7, 7},
    ["key"] = {8, 7},
    ["keyboard"] = {9, 7},
    
    -- Gaming
    ["gamepad-2"] = {0, 8},
    ["crosshair"] = {1, 8},
    ["target"] = {2, 8},
    ["mouse"] = {3, 8},
    ["cursor"] = {4, 8},
    
    -- Weather & Nature
    ["sun"] = {0, 9},
    ["moon"] = {1, 9},
    ["cloud"] = {2, 9},
    ["cloud-rain"] = {3, 9},
    ["snowflake"] = {4, 9},
    ["wind"] = {5, 9},
    ["thermometer"] = {6, 9},
    
    -- Tools
    ["wrench"] = {0, 10},
    ["hammer"] = {1, 10},
    ["tool"] = {2, 10},
    ["scissors"] = {3, 10},
    ["pocket-knife"] = {4, 10},
    
    -- Security
    ["shield"] = {0, 11},
    ["shield-check"] = {1, 11},
    ["shield-alert"] = {2, 11},
    ["lock"] = {3, 11},
    ["unlock"] = {4, 11},
    
    -- Communication
    ["message-circle"] = {0, 12},
    ["message-square"] = {1, 12},
    ["mail"] = {2, 12},
    ["phone"] = {3, 12},
    ["phone-call"] = {4, 12},
    ["phone-off"] = {5, 12},
}

-- Get icon position from spritesheet
function LucideIcons:GetOffset(iconName: string): Vector2?
    local pos = ICON_MAP[iconName:lower()]
    if not pos then
        return nil
    end
    
    -- Convert grid position to pixel offset
    return Vector2.new(pos[1] * SPRITE_SIZE, pos[2] * SPRITE_SIZE)
end

-- Create an ImageLabel with the icon
function LucideIcons:Create(iconName: string, config: {
    Size: UDim2?,
    Color: Color3?,
    Parent: Instance?,
    Position: UDim2?,
}?): ImageLabel?
    local offset = self:GetOffset(iconName)
    if not offset then
        warn("[LucideIcons] Icon not found:", iconName)
        return nil
    end
    
    local icon = Instance.new("ImageLabel")
    icon.Name = "LucideIcon_" .. iconName
    icon.Size = config and config.Size or UDim2.new(0, 16, 0, 16)
    icon.Position = config and config.Position or UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel = 0
    
    -- Use a default icon spritesheet (you can replace with your own)
    -- This uses a blank/transparent image as placeholder
    icon.Image = "rbxassetid://7733658504"  -- Lucide icons spritesheet placeholder
    icon.ImageRectOffset = offset
    icon.ImageRectSize = Vector2.new(SPRITE_SIZE, SPRITE_SIZE)
    icon.ScaleType = Enum.ScaleType.Fit
    
    if config and config.Color then
        icon.ImageColor3 = config.Color
    end
    
    if config and config.Parent then
        icon.Parent = config.Parent
    end
    
    return icon
end

-- Create icon with automatic styling for buttons
function LucideIcons:CreateButtonIcon(iconName: string, parent: Instance, color: Color3?): ImageLabel?
    local icon = self:Create(iconName, {
        Size = UDim2.new(0, 16, 0, 16),
        Color = color,
        Parent = parent,
    })
    
    if icon then
        icon.ResetsOnSpawn = false
    end
    
    return icon
end

-- Get all available icon names
function LucideIcons:GetAvailableIcons(): {string}
    local icons = {}
    for name, _ in pairs(ICON_MAP) do
        table.insert(icons, name)
    end
    table.sort(icons)
    return icons
end

-- Check if icon exists
function LucideIcons:HasIcon(iconName: string): boolean
    return ICON_MAP[iconName:lower()] ~= nil
end

-- Register custom icon
function LucideIcons:RegisterIcon(iconName: string, gridX: number, gridY: number)
    ICON_MAP[iconName:lower()] = {gridX, gridY}
end

return LucideIcons

