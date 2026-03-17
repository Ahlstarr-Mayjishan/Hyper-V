-- IconService.luau
-- Domain Layer: Resolves abstract icon names into usable UI data (Image IDs or UTF-8 Text).
-- Wraps the community 'lucide-roblox' package for seamless icon delivery.
local IconService = {}

-- Assuming lucide-roblox is installed via Wally and placed in ReplicatedStorage or Packages
-- In a real project, adjust this require path to point to your Packages/Lucide folder
local LucideSuccess, LucideLib = pcall(function()
    return require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Lucide"))
end)

export type IconType = "Image" | "Text" | "Lucide"

export type IconResult = {
    Type: IconType,
    Data: string, -- Can be rbxassetid:// URI or a utf8 char code string
    Font: Font?,   -- Optional if using a text-based Icon Font
    LucideMetadata: any? -- Data returned directly from lucide-roblox
}

-- Registry to hold mapping tables
local ImageIcons: { [string]: string } = {}
local TextIcons: { [string]: { code: string, font: Font } } = {}

-- Load default mappings
local function initializeDefaults()
    -- Example Default Images
    ImageIcons["Home"] = "rbxassetid://123456789"
    ImageIcons["Settings"] = "rbxassetid://987654321"
    ImageIcons["Close"] = "rbxassetid://1122334455"
end

initializeDefaults()

-- [API] Register a new Image Icon dynamically
function IconService.RegisterImageIcon(name: string, assetId: string)
    ImageIcons[name] = assetId
end

-- [API] Register a new UTF-8 Text Icon dynamically
function IconService.RegisterTextIcon(name: string, utf8Code: number, font: Font)
    TextIcons[name] = {
        code = utf8.char(utf8Code),
        font = font
    }
end

-- [API] Resolve an icon name into an actionable result
function IconService.GetIcon(name: string): IconResult?
    -- 1. Check if it's a known Lucide prefix and route to the Community Package
    if name:sub(1, 7) == "lucide-" then
        if not LucideSuccess then
            warn("[Hyper-V] Cannot resolve Lucide icon. 'lucide-roblox' package not found in ReplicatedStorage.Packages.")
            return nil
        end
        
        -- Strip the prefix for the library query
        local libName = name:sub(8) 
        local assetData = LucideLib.GetAsset(libName) -- Adjust to library's actual API
        
        if assetData then
            return {
                Type = "Lucide",
                Data = assetData, -- This might be a string or a table depending on the library's exact API
                LucideMetadata = assetData
            }
        else
            warn(string.format("[Hyper-V] Lucide Icon '%s' not found via the lucide-roblox library.", libName))
            return nil
        end
    end

    -- 2. Prioritize Image icons first
    if ImageIcons[name] then
        return {
            Type = "Image",
            Data = ImageIcons[name]
        }
    end
    
    -- 3. Fallback to registered Custom Text icons
    local textInfo = TextIcons[name]
    if textInfo then
        return {
            Type = "Text",
            Data = textInfo.code,
            Font = textInfo.font
        }
    end
    
    -- Icon not found
    warn(string.format("[Hyper-V] IconService: Icon '%s' not found.", name))
    return nil
end

-- [API] Helper to apply an icon directly to an instance (e.g., ImageLabel or TextLabel)
function IconService.ApplyIconToInstance(name: string, targetInstance: Instance): boolean
    local result = IconService.GetIcon(name)
    if not result then return false end
    
    if result.Type == "Image" and targetInstance:IsA("ImageLabel") then
        targetInstance.Image = result.Data
        return true
        
    elseif result.Type == "Text" and targetInstance:IsA("TextLabel") then
        targetInstance.Text = result.Data
        if result.Font then
            targetInstance.FontFace = result.Font
        end
        return true
        
    elseif result.Type == "Lucide" and targetInstance:IsA("ImageLabel") then
        -- Integrate directly with lucide-roblox API for applying properties
        -- E.g., The library might return a spritesheet ID and Rect sizes
        if type(result.LucideMetadata) == "table" and result.LucideMetadata.Image then
             targetInstance.Image = result.LucideMetadata.Image
             targetInstance.ImageRectOffset = result.LucideMetadata.ImageRectOffset or Vector2.zero
             targetInstance.ImageRectSize = result.LucideMetadata.ImageRectSize or Vector2.zero
        elseif type(result.LucideMetadata) == "string" then
             targetInstance.Image = result.LucideMetadata
        end
        return true
    else
        warn(string.format("[Hyper-V] IconService: Instance type mismatch. Cannot apply %s to %s", result.Type, targetInstance.ClassName))
        return false
    end
end

return IconService

