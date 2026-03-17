-- RunCoreBrainSmokeTest.luau
-- Convenience runner for invoking the core smoke test with a readable report.
local RuntimeFolder = script.Parent.Parent:WaitForChild("Services"):WaitForChild("Runtime")

local EnvironmentService = require(RuntimeFolder:WaitForChild("EnvironmentService"))
local CoreBrainSmokeTest = require(script.Parent:WaitForChild("CoreBrainSmokeTest"))

local RunCoreBrainSmokeTest = {}

function RunCoreBrainSmokeTest.Run(): (boolean, { string })
    local environmentLabel = EnvironmentService.GetEnvironmentLabel()
    local success, failures = CoreBrainSmokeTest.Run()

    if success then
        print(string.format("[Hyper-V][SmokeTest][%s] PASS", environmentLabel))
    else
        warn(string.format("[Hyper-V][SmokeTest][%s] FAIL (%d issues)", environmentLabel, #failures))
        for index, failure in ipairs(failures) do
            warn(string.format("[Hyper-V][SmokeTest][%d] %s", index, failure))
        end
    end

    return success, failures
end

return RunCoreBrainSmokeTest
