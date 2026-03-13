--!strict

local BrainPolicy = require(script.Parent.BrainPolicy)

local BrainResolver = {}

function BrainResolver.resolve(stateSnapshot, intent)
	local allowed, reason, commands = BrainPolicy.evaluate(stateSnapshot, intent)
	return {
		allowed = allowed,
		reason = reason,
		commands = commands or {},
	}
end

return BrainResolver
