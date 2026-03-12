--!strict

local Utf8Text = require(script.Parent.Parent.Parent.Text.Utf8Text)

export type CommandAction = {
	id: string,
	title: string,
	description: string?,
	callback: (action: CommandAction) -> (),
}

export type CommandPaletteState = {
	setActions: (self: CommandPaletteState, actions: { CommandAction }) -> (),
	setQuery: (self: CommandPaletteState, query: string) -> (),
	moveSelection: (self: CommandPaletteState, delta: number) -> (),
	getSelected: (self: CommandPaletteState) -> CommandAction?,
	getFiltered: (self: CommandPaletteState) -> { CommandAction },
}

local CommandPaletteState = {}
CommandPaletteState.__index = CommandPaletteState

function CommandPaletteState.new(actions: { CommandAction }?): CommandPaletteState
	return setmetatable({
		actions = actions or {},
		filtered = {},
		query = "",
		selectedIndex = 1,
	}, CommandPaletteState) :: any
end

function CommandPaletteState:_rebuild()
	local filtered = {}
	for _, action in ipairs((self :: any).actions) do
		local haystack = string.format("%s %s", action.title or "", action.description or "")
		if Utf8Text.contains(haystack, (self :: any).query, true) then
			table.insert(filtered, action)
		end
	end

	(self :: any).filtered = filtered
	(self :: any).selectedIndex = math.clamp((self :: any).selectedIndex, 1, math.max(#filtered, 1))
end

function CommandPaletteState:setActions(actions: { CommandAction })
	(self :: any).actions = actions
	self:_rebuild()
end

function CommandPaletteState:setQuery(query: string)
	(self :: any).query = query
	self:_rebuild()
end

function CommandPaletteState:moveSelection(delta: number)
	local filtered = (self :: any).filtered
	if #filtered == 0 then
		return
	end
	(self :: any).selectedIndex = math.clamp((self :: any).selectedIndex + delta, 1, #filtered)
end

function CommandPaletteState:getSelected(): CommandAction?
	return (self :: any).filtered[(self :: any).selectedIndex]
end

function CommandPaletteState:getFiltered(): { CommandAction }
	return (self :: any).filtered
end

return CommandPaletteState
