-- CoreBrainSmokeTest.luau
-- Minimal runtime smoke test for the core registration, mutation, sync, and export pipeline.
local HttpService = game:GetService("HttpService")

local CoreBrainFolder = script.Parent.Parent:WaitForChild("CoreBrain")
local ServicesFolder = script.Parent.Parent:WaitForChild("Services")

local Administrator = require(CoreBrainFolder:WaitForChild("Administrator"))
local ElementRegistry = require(CoreBrainFolder:WaitForChild("ElementRegistry"))
local SerializationService = require(
    ServicesFolder:WaitForChild("Serialization"):WaitForChild("SerializationService")
)

local CoreBrainSmokeTest = {}

local function createId(prefix: string): string
    return string.format("%s_%s", prefix, HttpService:GenerateGUID(false))
end

local function expect(condition: boolean, message: string, failures: { string })
    if not condition then
        table.insert(failures, message)
    end
end

local function cleanup(id: string, instance: Instance)
    local elementData = ElementRegistry.GetElement(id)
    if elementData then
        Administrator.RemoveElement(id)
        return
    end

    if instance.Parent ~= nil then
        instance.Parent = nil
    end
    instance:Destroy()
end

function CoreBrainSmokeTest.Run(): (boolean, { string })
    local failures = {}

    local windowId = createId("window")
    local buttonId = createId("button")

    local window = Instance.new("Frame")
    local button = Instance.new("TextButton")

    local didRegisterWindow = Administrator.RegisterElement(windowId, window, "Window")
    expect(didRegisterWindow, "Window registration failed", failures)

    local didRegisterButton = Administrator.RegisterElement(buttonId, button, "Button", windowId)
    expect(didRegisterButton, "Button registration with parent failed", failures)

    local queuedWindowSize = Administrator.SetProperty(windowId, "Size", UDim2.fromOffset(320, 180), false)
    local queuedWindowColor = Administrator.SetProperty(windowId, "BackgroundColor3", Color3.fromRGB(12, 34, 56), false)
    local queuedButtonText = Administrator.SetProperty(buttonId, "Text", "Smoke Test", false)
    local immediateButtonAnchor = Administrator.SetProperty(buttonId, "AnchorPoint", Vector2.new(0.5, 0.5), true)

    expect(queuedWindowSize, "Queued window size update failed", failures)
    expect(queuedWindowColor, "Queued window background update failed", failures)
    expect(queuedButtonText, "Queued button text update failed", failures)
    expect(immediateButtonAnchor, "Immediate button anchor update failed", failures)

    local childDataBeforeSync = ElementRegistry.GetElement(buttonId)
    expect(childDataBeforeSync ~= nil, "Button missing from registry before sync", failures)
    if childDataBeforeSync then
        expect(
            childDataBeforeSync.parentId == windowId,
            "Canonical parent state was not recorded",
            failures
        )
        expect(
            childDataBeforeSync.desiredProperties.Text == "Smoke Test",
            "Queued desired property did not reach canonical state before sync",
            failures
        )
        expect(
            childDataBeforeSync.desiredProperties.AnchorPoint == Vector2.new(0.5, 0.5),
            "Immediate property did not reach canonical state",
            failures
        )
    end

    Administrator.Sync()

    expect(window.Size == UDim2.fromOffset(320, 180), "Window size was not committed to instance", failures)
    expect(
        window.BackgroundColor3 == Color3.fromRGB(12, 34, 56),
        "Window background color was not committed to instance",
        failures
    )
    expect(button.Text == "Smoke Test", "Button text was not committed to instance", failures)
    expect(button.Parent == window, "Button parent was not mounted correctly", failures)

    local exportSuccess, encoded = SerializationService.ExportUI()
    expect(exportSuccess and encoded ~= nil, "ExportUI failed after sync", failures)

    if exportSuccess and encoded then
        local decoded = HttpService:JSONDecode(encoded)
        local exportedById = {}
        for _, entry in ipairs(decoded) do
            exportedById[entry.id] = entry
        end

        local exportedWindow = exportedById[windowId]
        local exportedButton = exportedById[buttonId]

        expect(exportedWindow ~= nil, "Export payload is missing the window element", failures)
        expect(exportedButton ~= nil, "Export payload is missing the button element", failures)

        if exportedWindow then
            expect(
                exportedWindow.properties.BackgroundColor3 == Color3.fromRGB(12, 34, 56):ToHex(),
                "Exported window color did not come from canonical state",
                failures
            )
        end

        if exportedButton then
            expect(exportedButton.parentId == windowId, "Exported parent relationship is incorrect", failures)
            expect(exportedButton.properties.Text == "Smoke Test", "Exported button text is incorrect", failures)
        end
    end

    cleanup(buttonId, button)
    cleanup(windowId, window)

    return #failures == 0, failures
end

return CoreBrainSmokeTest
