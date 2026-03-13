--!strict

local PreviewPolicy = {}

local function makeCommand(commandType: string, payload: any)
	return {
		type = commandType,
		payload = payload,
	}
end

function PreviewPolicy.evaluate(intent)
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

	return nil, nil, nil
end

return PreviewPolicy
