--!strict

local BrainPolicy = {}
local SurfaceLifecyclePolicy = require(script.Parent.SurfaceLifecyclePolicy)
local PreviewPolicy = require(script.Parent.PreviewPolicy)
local DockPolicy = require(script.Parent.DockPolicy)

local MODAL_BLOCKED_INTENTS = {
	["surface.activate"] = true,
	["surface.open"] = true,
	["preview.patch"] = true,
	["preview.set"] = true,
	["preview.reset"] = true,
	["preview.commit"] = true,
	["preview.target"] = true,
	["dock.attach"] = true,
	["dock.detach"] = true,
}

local function deny(policyCode: string, message: string)
	return false, string.format("policy.%s: %s", policyCode, message), nil
end

function BrainPolicy.evaluate(stateSnapshot, intent)
	local activeModalId = stateSnapshot.activeModalId
	if activeModalId and MODAL_BLOCKED_INTENTS[intent.type] and intent.sourceId ~= activeModalId then
		return deny("activeModal", "Blocked by active modal")
	end

	local handled, reason, commands = SurfaceLifecyclePolicy.evaluate(stateSnapshot, intent)
	if handled ~= nil then
		return handled, reason, commands
	end

	handled, reason, commands = PreviewPolicy.evaluate(intent)
	if handled ~= nil then
		return handled, reason, commands
	end

	handled, reason, commands = DockPolicy.evaluate(intent)
	if handled ~= nil then
		return handled, reason, commands
	end

	return false, "Unknown brain intent: " .. tostring(intent.type), nil
end

return BrainPolicy
