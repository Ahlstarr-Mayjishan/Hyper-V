-- UIRootHost.luau
-- Environment-aware host for top-level UI surfaces.
local UIRootHost = {}

local RuntimeFolder = script.Parent
local EnvironmentService = require(RuntimeFolder:WaitForChild("EnvironmentService"))

local DEFAULT_ROOT_NAME = "HyperVRoot"

local function findExistingRoot(hostParent: Instance, rootName: string): ScreenGui?
    local existing = hostParent:FindFirstChild(rootName)
    if existing and existing:IsA("ScreenGui") then
        return existing
    end

    return nil
end

function UIRootHost.EnsureRoot(rootName: string?): ScreenGui
    local resolvedRootName = rootName or DEFAULT_ROOT_NAME
    local hostParent = EnvironmentService.ResolveGuiParent()
    local existingRoot = findExistingRoot(hostParent, resolvedRootName)
    if existingRoot then
        return existingRoot
    end

    local root = Instance.new("ScreenGui")
    root.Name = resolvedRootName
    root.ResetOnSpawn = false
    root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    root.Parent = hostParent

    return root
end

function UIRootHost.Mount(instance: Instance, rootName: string?): Instance
    if instance:IsA("ScreenGui") then
        instance.Parent = EnvironmentService.ResolveGuiParent()
        return instance
    end

    local root = UIRootHost.EnsureRoot(rootName)
    instance.Parent = root
    return root
end

function UIRootHost.Unmount(instance: Instance)
    instance.Parent = nil
end

function UIRootHost.GetDefaultRootName(): string
    return DEFAULT_ROOT_NAME
end

return UIRootHost
