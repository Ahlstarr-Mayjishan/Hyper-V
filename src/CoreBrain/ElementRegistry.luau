-- ElementRegistry.luau
-- State Layer: Owns canonical UI state, identity, and lifecycle metadata.
local ElementRegistry = {}

export type PropertyMap = { [string]: any }

export type ElementData = {
    id: string,
    instance: Instance,
    type: string,
    registeredAt: number,
    desiredProperties: PropertyMap,
    parentId: string?
}

local elements: { [string]: ElementData } = {}

local function cloneProperties(properties: PropertyMap?): PropertyMap
    local copy: PropertyMap = {}
    if not properties then
        return copy
    end

    for key, value in pairs(properties) do
        copy[key] = value
    end

    return copy
end

function ElementRegistry.AddElement(
    id: string,
    instance: Instance,
    elementType: string,
    desiredProperties: PropertyMap?,
    parentId: string?
): boolean
    if elements[id] then
        return false
    end

    elements[id] = {
        id = id,
        instance = instance,
        type = elementType,
        registeredAt = os.time(),
        desiredProperties = cloneProperties(desiredProperties),
        parentId = parentId
    }

    return true
end

function ElementRegistry.GetElement(id: string): ElementData?
    return elements[id]
end

function ElementRegistry.SetDesiredProperty(id: string, propertyName: string, value: any): boolean
    local element = elements[id]
    if not element then
        return false
    end

    element.desiredProperties[propertyName] = value
    return true
end

function ElementRegistry.GetDesiredProperties(id: string): PropertyMap?
    local element = elements[id]
    if not element then
        return nil
    end

    return cloneProperties(element.desiredProperties)
end

function ElementRegistry.SetParent(id: string, parentId: string?): boolean
    local element = elements[id]
    if not element then
        return false
    end

    element.parentId = parentId
    return true
end

function ElementRegistry.GetParent(id: string): string?
    local element = elements[id]
    if not element then
        return nil
    end

    return element.parentId
end

function ElementRegistry.RemoveElement(id: string)
    elements[id] = nil
end

function ElementRegistry.GetAllElements(): { [string]: ElementData }
    return elements
end

return ElementRegistry
