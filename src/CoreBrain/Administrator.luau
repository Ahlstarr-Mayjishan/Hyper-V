-- Administrator.luau
-- Central Orchestrator: The single entry point for registration, mutation, and removal.
local Administrator = {}

local ElementRegistry = require(script.Parent.ElementRegistry)
local PropertyManager = require(script.Parent.PropertyManager)
local HierarchyManager = require(script.Parent.HierarchyManager)
local UISync = require(script.Parent.UISync)

function Administrator.RegisterElement(id: string, instance: Instance, elementType: string, parentId: string?): boolean
    local isElementValid, validationReason = PropertyManager.ValidateElement(instance, elementType)
    if not isElementValid then
        warn("[Hyper-V]", validationReason)
        return false
    end

    local desiredProperties = PropertyManager.CaptureSchemaProperties(instance, elementType)
    local didRegister = ElementRegistry.AddElement(id, instance, elementType, desiredProperties, nil)
    if not didRegister then
        warn(string.format("[Hyper-V] Cannot register duplicate element id '%s'", id))
        return false
    end

    if parentId then
        local didMount = HierarchyManager.UpdateHierarchyProperty(id, "Parent", parentId)
        if not didMount then
            ElementRegistry.RemoveElement(id)
            return false
        end
    else
        HierarchyManager.MountElement(id, nil)
    end

    return true
end

function Administrator.SetProperty(elementId: string, propertyName: string, value: any, immediate: boolean?): boolean
    local elementData = ElementRegistry.GetElement(elementId)
    if not elementData then
        warn("[Hyper-V] Cannot set property. Element not found:", elementId)
        return false
    end

    if HierarchyManager.IsHierarchyProperty(propertyName) then
        return HierarchyManager.UpdateHierarchyProperty(elementId, propertyName, value)
    end

    local isValid, validationReason = PropertyManager.ValidateProperty(elementData.type, propertyName, value)
    if not isValid then
        warn("[Hyper-V]", validationReason)
        return false
    end

    if immediate then
        return UISync.ApplyImmediate(elementId, propertyName, value)
    end

    local didQueue = UISync.QueueUpdate(elementId, propertyName, value)
    if didQueue then
        UISync.ScheduleCommit()
    end

    return didQueue
end

function Administrator.Sync()
    UISync.Commit()
end

function Administrator.RemoveElement(elementId: string)
    local elementData = ElementRegistry.GetElement(elementId)
    if not elementData then
        return
    end

    HierarchyManager.UnmountElement(elementId)
    UISync.ClearElementQueue(elementId)
    ElementRegistry.RemoveElement(elementId)
    elementData.instance:Destroy()
    print("[Hyper-V] Removed element:", elementId)
end

return Administrator
