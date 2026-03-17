-- PropertyManager.luau
-- Authority Layer: Defines strict schemas and validates property changes.
local PropertyManager = {}

export type ElementSchema = {
    BaseInstance: string,
    Properties: { [string]: string }
}

local Schema: { [string]: ElementSchema } = {
    Window = {
        BaseInstance = "Frame",
        Properties = {
            Size = "UDim2",
            Position = "UDim2",
            Title = "string",
            Visible = "boolean",
            BackgroundColor3 = "Color3",
            AnchorPoint = "Vector2"
        }
    },
    Button = {
        BaseInstance = "TextButton",
        Properties = {
            Size = "UDim2",
            Position = "UDim2",
            Text = "string",
            BackgroundColor3 = "Color3",
            Interactable = "boolean",
            AnchorPoint = "Vector2"
        }
    },
    SquirclePanel = {
        BaseInstance = "Frame",
        Properties = {
            Size = "UDim2",
            Position = "UDim2",
            BackgroundColor3 = "Color3",
            CornerRadius = "number",
            Visible = "boolean",
            AnchorPoint = "Vector2"
        }
    }
}

local function readSchema(elementType: string): ElementSchema?
    return Schema[elementType]
end

function PropertyManager.ValidateElement(instance: Instance, elementType: string): (boolean, string?)
    local elementSchema = readSchema(elementType)
    if not elementSchema then
        return false, "Unknown elementType: " .. tostring(elementType)
    end

    if typeof(instance) ~= "Instance" then
        return false, "Passed object is not a Roblox Instance"
    end

    if not instance:IsA(elementSchema.BaseInstance) then
        return false, string.format(
            "Instance type mismatch for '%s'. Expected %s, got %s",
            elementType,
            elementSchema.BaseInstance,
            instance.ClassName
        )
    end

    return true, nil
end

function PropertyManager.ValidateProperty(elementType: string, propertyName: string, value: any): (boolean, string?)
    local elementSchema = readSchema(elementType)
    if not elementSchema then
        return false, "Unknown elementType: " .. tostring(elementType)
    end

    local expectedType = elementSchema.Properties[propertyName]
    if not expectedType then
        return false, string.format("Property '%s' is not approved for '%s'", propertyName, elementType)
    end

    if typeof(value) ~= expectedType then
        return false, string.format(
            "Property '%s' on '%s' expects %s, got %s",
            propertyName,
            elementType,
            expectedType,
            typeof(value)
        )
    end

    return true, nil
end

function PropertyManager.GetSchema(elementType: string): ElementSchema?
    return readSchema(elementType)
end

function PropertyManager.CaptureSchemaProperties(instance: Instance, elementType: string): { [string]: any }
    local elementSchema = readSchema(elementType)
    local captured: { [string]: any } = {}
    if not elementSchema then
        return captured
    end

    for propertyName, _ in pairs(elementSchema.Properties) do
        local success, value = pcall(function()
            return (instance :: any)[propertyName]
        end)

        if success and value ~= nil then
            captured[propertyName] = value
        end
    end

    return captured
end

return PropertyManager
