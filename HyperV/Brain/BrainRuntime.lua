--!strict

local BrainRuntime = {}
BrainRuntime.__index = BrainRuntime

function BrainRuntime.new()
	local self = setmetatable({}, BrainRuntime)
	self._handlers = {} :: { [string]: (any) -> any }
	return self
end

function BrainRuntime:register(commandType: string, handler: (any) -> any)
	self._handlers[commandType] = handler
end

function BrainRuntime:execute(command)
	local handler = self._handlers[command.type]
	if handler then
		return handler(command.payload)
	end
	return nil
end

return BrainRuntime
