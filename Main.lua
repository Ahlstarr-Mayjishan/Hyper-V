--!strict

local packageRoot = script.Parent
local runtimeRoot = packageRoot:FindFirstChild("HyperV") or script:FindFirstChild("HyperV")

assert(runtimeRoot ~= nil, "Main bootstrap could not find HyperV package folder")

return require(runtimeRoot)
