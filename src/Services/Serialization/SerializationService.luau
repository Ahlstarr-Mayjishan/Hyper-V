-- SerializationService.luau
-- Domain Layer: Handles converting internal UI state to JSON strings for sharing and importing.
local HttpService = game:GetService("HttpService")

local SerializationService = {}

-- Assume we have a reference to the CoreBrain.
-- In a real Roblox environment, we would require paths relative to this service.
local CoreBrainFolder = script.Parent.Parent.Parent:WaitForChild("CoreBrain")
local Administrator = require(CoreBrainFolder:WaitForChild("Administrator"))
local ElementRegistry = require(CoreBrainFolder:WaitForChild("ElementRegistry"))
local PropertyManager = require(CoreBrainFolder:WaitForChild("PropertyManager"))

type SerializedElement = {
    id: string,
    type: string,
    properties: { [string]: any },
    parentId: string?
}

-- Extract safe properties from canonical desired state using the schema contract.
local function extractProperties(elementData: any): { [string]: any }
    local props = {}
    local schemaDef = PropertyManager.GetSchema(elementData.type)
    local desiredProperties = ElementRegistry.GetDesiredProperties(elementData.id) or {}
    
    if not schemaDef or type(schemaDef.Properties) ~= "table" then
        return props -- Schema missing, cannot serialize safely
    end
    
    -- Export only what the schema allows, pulling from the registry's canonical state.
    for prop, _ in pairs(schemaDef.Properties) do
        local val = desiredProperties[prop]
        if val ~= nil then
            if typeof(val) == "Color3" then
                props[prop] = val:ToHex()
            elseif typeof(val) == "UDim2" then
                props[prop] = {
                    X = {Scale = val.X.Scale, Offset = val.X.Offset},
                    Y = {Scale = val.Y.Scale, Offset = val.Y.Offset}
                }
            elseif typeof(val) == "Vector2" then
                props[prop] = { X = val.X, Y = val.Y }
            else
                props[prop] = val
            end
        end
    end
    return props
end

-- [EXPORT LOGIC]
function SerializationService.ExportUI(): (boolean, string?)
    local allElements = ElementRegistry.GetAllElements()
    local exportData = {}
    
    for id, elementData in pairs(allElements) do
        table.insert(exportData, {
            id = elementData.id,
            type = elementData.type,
            properties = extractProperties(elementData),
            parentId = ElementRegistry.GetParent(id)
        })
    end
    
    local success, result = pcall(function()
        return HttpService:JSONEncode(exportData)
    end)
    
    if success then
        return true, result
    else
        warn("[Hyper-V] Failed to export UI:", result)
        return false, nil
    end
end

-- Reconstruct primitive JSON data to Roblox Data Types
local function reconstructValue(val: any): any
    if typeof(val) == "table" then
        if val.Scale and val.Offset then -- X or Y component of UDim2 shouldn't be here directly.
           return val 
        end
        if val.X and val.Y then
            if type(val.X) == "table" and val.X.Scale and val.X.Offset then
                return UDim2.new(val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset)
            elseif type(val.X) == "number" and type(val.Y) == "number" then
                return Vector2.new(val.X, val.Y)
            end
        end
    elseif typeof(val) == "string" and #val == 6 and val:match("%x%x%x%x%x%x") then
        return Color3.fromHex(val)
    end
    return val
end

-- [IMPORT LOGIC]
function SerializationService.ImportUI(jsonString: string): boolean
    local success, importedData = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    if not success or type(importedData) ~= "table" then
        warn("[Hyper-V] Failed to import UI: Invalid JSON")
        return false
    end
    
    for _, elementData in ipairs(importedData) do
        local id = elementData.id
        local elementType = elementData.type
        if not ElementRegistry.GetElement(id) then
            local schemaDef = PropertyManager.GetSchema(elementType)
            if not schemaDef or not schemaDef.BaseInstance then
                warn(string.format("[Hyper-V] Import failed for %s: Unknown type '%s'", id, tostring(elementType)))
                continue
            end
            
            local successCreate, instance = pcall(function()
                return Instance.new(schemaDef.BaseInstance)
            end)
            
            if not successCreate or not instance then
                warn(string.format("[Hyper-V] Import failed for %s: Could not instantiate %s", id, schemaDef.BaseInstance))
                continue
            end

            local successReg = Administrator.RegisterElement(id, instance, elementType)
            if not successReg then
                continue
            end
        end
    end

    for _, elementData in ipairs(importedData) do
        local id = elementData.id
        local parentId = elementData.parentId
        if parentId ~= nil then
            Administrator.SetProperty(id, "Parent", parentId, true)
        end

        local properties = elementData.properties
        if type(properties) == "table" then
            for propName, rawValue in pairs(properties) do
                Administrator.SetProperty(id, propName, reconstructValue(rawValue), false)
            end
        end
    end
    
    -- Force UISync to commit the imported UI layout
    Administrator.Sync()
    print("[Hyper-V] Successfully imported UI from code.")
    return true
end

return SerializationService
