--!strict

export type Command = {
	id: string,
	title: string,
	description: string?,
	callback: (command: Command) -> (),
}

local CommandRegistry = {}
CommandRegistry.__index = CommandRegistry

function CommandRegistry.new()
	return setmetatable({
		_commands = {},
	}, CommandRegistry)
end

function CommandRegistry:register(command: Command)
	(self :: any)._commands[command.id] = command
end

function CommandRegistry:list(): { Command }
	local commands = {}
	for _, command in pairs((self :: any)._commands) do
		table.insert(commands, command)
	end
	table.sort(commands, function(left, right)
		return left.title < right.title
	end)
	return commands
end

return CommandRegistry
