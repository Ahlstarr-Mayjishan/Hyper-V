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
	local state = self :: any
	local filtered = {}
	for _, action in ipairs(state.actions) do
		local haystack = string.format("%s %s", action.title or "", action.description or "")
		if Utf8Text.contains(haystack, state.query, true) then
			table.insert(filtered, action)
		end
	end

	state.filtered = filtered
	state.selectedIndex = math.clamp(state.selectedIndex, 1, math.max(#filtered, 1))
end

function CommandPaletteState:setActions(actions: { CommandAction })
	local state = self :: any
	state.actions = actions
	self:_rebuild()
end

function CommandPaletteState:setQuery(query: string)
	local state = self :: any
	state.query = query
	self:_rebuild()
end

function CommandPaletteState:moveSelection(delta: number)
	local state = self :: any
	local filtered = state.filtered
	if #filtered == 0 then
		return
	end
	state.selectedIndex = math.clamp(state.selectedIndex + delta, 1, #filtered)
end

function CommandPaletteState:getSelected(): CommandAction?
	local state = self :: any
	return state.filtered[state.selectedIndex]
end

function CommandPaletteState:getFiltered(): { CommandAction }
	local state = self :: any
	return state.filtered
end

return CommandPaletteState
