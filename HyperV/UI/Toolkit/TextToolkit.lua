--!strict

local Utf8Text = require(script.Parent.Parent.Parent.Text.Utf8Text)
local KeyFormatter = require(script.Parent.Parent.Parent.Input.KeyFormatter)

local TextToolkit = {}

function TextToolkit.contains(haystack: any, needle: any, caseInsensitive: boolean?)
	return Utf8Text.contains(haystack, needle, caseInsensitive)
end

function TextToolkit.compare(left: any, right: any, ascending: boolean?)
	return Utf8Text.compare(left, right, ascending)
end

function TextToolkit.utf8Len(text: any)
	return Utf8Text.len(text)
end

function TextToolkit.utf8Sub(text: any, startIndex: number?, endIndex: number?)
	return Utf8Text.sub(text, startIndex, endIndex)
end

function TextToolkit.getKeyName(key: Enum.KeyCode | Enum.UserInputType)
	return KeyFormatter.format(key)
end

return TextToolkit
