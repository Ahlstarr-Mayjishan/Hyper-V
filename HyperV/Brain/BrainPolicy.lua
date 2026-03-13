--!strict

local BrainPolicy = {}
local SurfaceLifecyclePolicy = require(script.Parent.SurfaceLifecyclePolicy)

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

local function makeCommand(commandType: string, payload: any)
	return {
		type = commandType,
		payload = payload,
	}
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

	if intent.type == "preview.patch" then
		return true, nil, {
			makeCommand("runtime.preview.patch", intent),
			makeCommand("state.preview.patch", {
				sourceId = intent.sourceId,
				patch = intent.patch,
			}),
		}
	end

	if intent.type == "preview.set" or intent.type == "preview.reset" then
		return true, nil, {
			makeCommand("runtime.preview.set", intent),
			makeCommand("state.preview.set", {
				sourceId = intent.sourceId,
				config = intent.config,
			}),
		}
	end

	if intent.type == "preview.commit" then
		return true, nil, {
			makeCommand("runtime.preview.commit", intent),
			makeCommand("state.preview.commit", {
				sourceId = intent.sourceId,
				snapshot = intent.snapshot,
			}),
		}
	end

	if intent.type == "preview.target" then
		return true, nil, {
			makeCommand("runtime.preview.target", intent),
			makeCommand("state.preview.target", {
				sourceId = intent.sourceId,
				model = intent.model,
			}),
		}
	end

	if intent.type == "dock.attach" then
		return true, nil, {
			makeCommand("runtime.dock.attach", intent),
			makeCommand("state.dock.attach", {
				handleId = intent.handleId,
				targetId = intent.targetId,
			}),
		}
	end

	if intent.type == "dock.detach" then
		return true, nil, {
			makeCommand("runtime.dock.detach", intent),
			makeCommand("state.dock.detach", {
				handleId = intent.handleId,
			}),
		}
	end

	return false, "Unknown brain intent: " .. tostring(intent.type), nil
end

return BrainPolicy
