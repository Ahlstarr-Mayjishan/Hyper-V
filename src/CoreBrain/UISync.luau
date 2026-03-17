-- UISync.luau
-- Observation Layer: Queues desired changes and commits them to Instances in batches.
local UISync = {}

local ElementRegistry = require(script.Parent.ElementRegistry)

type SyncQueue = {
    [string]: { [string]: any }
}

local updateQueue: SyncQueue = {}
local isCommitScheduled = false

function UISync.QueueUpdate(elementId: string, propertyName: string, value: any): boolean
    local elementData = ElementRegistry.GetElement(elementId)
    if not elementData then
        return false
    end

    if not updateQueue[elementId] then
        updateQueue[elementId] = {}
    end

    updateQueue[elementId][propertyName] = value
    ElementRegistry.SetDesiredProperty(elementId, propertyName, value)
    return true
end

function UISync.ApplyImmediate(elementId: string, propertyName: string, value: any): boolean
    local elementData = ElementRegistry.GetElement(elementId)
    if not elementData then
        return false
    end

    ElementRegistry.SetDesiredProperty(elementId, propertyName, value)
    (elementData.instance :: any)[propertyName] = value
    return true
end

function UISync.SyncElement(elementId: string)
    local elementData = ElementRegistry.GetElement(elementId)
    local pendingChanges = updateQueue[elementId]
    if not elementData or not pendingChanges then
        return
    end

    local instance = elementData.instance
    for propertyName, value in pairs(pendingChanges) do
        (instance :: any)[propertyName] = value
    end

    updateQueue[elementId] = nil
end

function UISync.Commit()
    for elementId, _ in pairs(updateQueue) do
        UISync.SyncElement(elementId)
    end

    updateQueue = {}
    isCommitScheduled = false
end

function UISync.ScheduleCommit()
    if isCommitScheduled then
        return
    end

    isCommitScheduled = true
    task.defer(UISync.Commit)
end

function UISync.ClearElementQueue(elementId: string)
    updateQueue[elementId] = nil
end

return UISync
