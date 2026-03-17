-- HierarchyManager.luau
-- Orchestration Layer: Manages parent-child mounting and framework-owned stacking.
local HierarchyManager = {}

local ElementRegistry = require(script.Parent.ElementRegistry)

local ROOT_KEY = "__ROOT__"
local BASE_ZINDEX = 100
local ZINDEX_STEP = 10

type HierarchyState = {
    childrenByContainer: { [string]: { string } }
}

local hierarchyState: HierarchyState = {
    childrenByContainer = {}
}

local hierarchyProperties = {
    Parent = true
}

local function getContainerKey(parentId: string?): string
    return parentId or ROOT_KEY
end

local function ensureChildList(parentId: string?): { string }
    local key = getContainerKey(parentId)
    local childList = hierarchyState.childrenByContainer[key]
    if not childList then
        childList = {}
        hierarchyState.childrenByContainer[key] = childList
    end

    return childList
end

local function removeChildFromAllContainers(id: string)
    for _, childList in pairs(hierarchyState.childrenByContainer) do
        for index, childId in ipairs(childList) do
            if childId == id then
                table.remove(childList, index)
                break
            end
        end
    end
end

function HierarchyManager.IsHierarchyProperty(propertyName: string): boolean
    return hierarchyProperties[propertyName] == true
end

function HierarchyManager.ValidateHierarchyProperty(propertyName: string, value: any): (boolean, string?)
    if propertyName == "Parent" then
        if value == nil or typeof(value) == "string" then
            return true, nil
        end

        return false, "Parent must be nil or an element id string"
    end

    return false, string.format("'%s' is a framework-managed hierarchy property", propertyName)
end

function HierarchyManager.DistributeZIndex(containerId: string?)
    local childList = hierarchyState.childrenByContainer[getContainerKey(containerId)]
    if not childList then
        return
    end

    for index, childId in ipairs(childList) do
        local elementData = ElementRegistry.GetElement(childId)
        if elementData then
            local resolvedZIndex = BASE_ZINDEX + (index * ZINDEX_STEP)
            elementData.instance.ZIndex = resolvedZIndex
            ElementRegistry.SetDesiredProperty(childId, "ZIndex", resolvedZIndex)
        end
    end
end

function HierarchyManager.MountElement(id: string, parentId: string?): (boolean, string?)
    local elementData = ElementRegistry.GetElement(id)
    if not elementData then
        return false, string.format("Cannot mount unknown element '%s'", id)
    end

    local targetParent: Instance? = nil
    if parentId then
        local parentData = ElementRegistry.GetElement(parentId)
        if not parentData then
            return false, string.format("Cannot mount '%s' to unknown parent '%s'", id, parentId)
        end

        targetParent = parentData.instance
    end

    local previousParentId = ElementRegistry.GetParent(id)

    removeChildFromAllContainers(id)
    elementData.instance.Parent = targetParent
    ElementRegistry.SetParent(id, parentId)

    local childList = ensureChildList(parentId)
    table.insert(childList, id)

    HierarchyManager.DistributeZIndex(previousParentId)
    if previousParentId ~= parentId then
        HierarchyManager.DistributeZIndex(parentId)
    end

    return true, nil
end

function HierarchyManager.UnmountElement(id: string)
    local elementData = ElementRegistry.GetElement(id)
    if not elementData then
        return
    end

    local previousParentId = ElementRegistry.GetParent(id)
    removeChildFromAllContainers(id)
    elementData.instance.Parent = nil
    ElementRegistry.SetParent(id, nil)
    HierarchyManager.DistributeZIndex(previousParentId)
end

function HierarchyManager.UpdateHierarchyProperty(id: string, propertyName: string, value: any): boolean
    local isValid, reason = HierarchyManager.ValidateHierarchyProperty(propertyName, value)
    if not isValid then
        warn("[Hyper-V]", reason)
        return false
    end

    if propertyName == "Parent" then
        local success, mountReason = HierarchyManager.MountElement(id, value)
        if not success then
            warn("[Hyper-V]", mountReason)
            return false
        end

        return true
    end

    return false
end

return HierarchyManager
