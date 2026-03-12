--!strict

local KeyFormatter = {}

function KeyFormatter.format(input: Enum.KeyCode | Enum.UserInputType): string
	local keyName = tostring(input)
	keyName = keyName:gsub("Enum%.UserInputType%.", "")
	keyName = keyName:gsub("Enum%.KeyCode%.", "")
	return keyName
end

return KeyFormatter
