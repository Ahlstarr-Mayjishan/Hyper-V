--!strict

local DockPolicy = {}

local function makeCommand(commandType: string, payload: any)
	return {
		type = commandType,
		payload = payload,
	}
end

function DockPolicy.evaluate(intent)
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

	return nil, nil, nil
end

return DockPolicy
