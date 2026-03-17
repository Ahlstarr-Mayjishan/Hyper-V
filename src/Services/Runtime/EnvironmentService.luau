-- EnvironmentService.luau
-- Runtime adapter for environment-sensitive UI hosting decisions.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local EnvironmentService = {}

local function tryGetExecutorHost(): Instance?
    local executorGetHui = gethui
    if type(executorGetHui) ~= "function" then
        return nil
    end

    local success, host = pcall(executorGetHui)
    if success and typeof(host) == "Instance" then
        return host
    end

    return nil
end

function EnvironmentService.IsStudio(): boolean
    return RunService:IsStudio()
end

function EnvironmentService.IsExecutorLike(): boolean
    return tryGetExecutorHost() ~= nil
end

function EnvironmentService.GetEnvironmentLabel(): string
    if EnvironmentService.IsExecutorLike() then
        return "Executor"
    end

    if EnvironmentService.IsStudio() then
        return "Studio"
    end

    return "RobloxClient"
end

function EnvironmentService.ResolveGuiParent(): Instance
    local executorHost = tryGetExecutorHost()
    if executorHost then
        return executorHost
    end

    local localPlayer = Players.LocalPlayer
    if localPlayer then
        local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            return playerGui
        end
    end

    return CoreGui
end

return EnvironmentService
