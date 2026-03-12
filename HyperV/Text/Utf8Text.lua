--!strict

local Utf8Text = {}

local function toText(value: any): string
	if value == nil then
		return ""
	end

	return tostring(value)
end

function Utf8Text.len(text: any): number
	local value = toText(text)
	local ok, length = pcall(utf8.len, value)
	if ok and length then
		return length
	end
	return #value
end

function Utf8Text.sub(text: any, startIndex: number?, endIndex: number?): string
	local value = toText(text)
	if value == "" then
		return ""
	end

	local length = Utf8Text.len(value)
	local first = startIndex or 1
	local last = endIndex or length

	if first < 0 then
		first = length + first + 1
	end

	if last < 0 then
		last = length + last + 1
	end

	first = math.clamp(first, 1, math.max(length, 1))
	last = math.clamp(last, 1, math.max(length, 1))

	if first > last then
		return ""
	end

	local okStart, startByte = pcall(utf8.offset, value, first)
	if not okStart or not startByte then
		return string.sub(value, first, last)
	end

	local okEnd, endByte = pcall(utf8.offset, value, last + 1)
	if okEnd and endByte then
		return string.sub(value, startByte, endByte - 1)
	end

	return string.sub(value, startByte)
end

function Utf8Text.truncate(text: any, maxChars: number, suffix: string?): string
	local value = toText(text)
	local tail = toText(suffix or "...")
	if maxChars <= 0 then
		return ""
	end

	if Utf8Text.len(value) <= maxChars then
		return value
	end

	local suffixLength = Utf8Text.len(tail)
	if suffixLength >= maxChars then
		return Utf8Text.sub(value, 1, maxChars)
	end

	return Utf8Text.sub(value, 1, maxChars - suffixLength) .. tail
end

function Utf8Text.contains(haystack: any, needle: any, caseInsensitive: boolean?): boolean
	local source = toText(haystack)
	local query = toText(needle)
	if query == "" then
		return true
	end

	if caseInsensitive then
		local loweredSource = string.lower(source)
		local loweredQuery = string.lower(query)
		if string.find(loweredSource, loweredQuery, 1, true) then
			return true
		end
	end

	return string.find(source, query, 1, true) ~= nil
end

function Utf8Text.compare(left: any, right: any, ascending: boolean?): boolean
	local first = toText(left)
	local second = toText(right)
	local normalizedFirst = string.lower(first)
	local normalizedSecond = string.lower(second)

	if normalizedFirst == normalizedSecond then
		normalizedFirst = first
		normalizedSecond = second
	end

	if ascending == false then
		return normalizedFirst > normalizedSecond
	end

	return normalizedFirst < normalizedSecond
end

return Utf8Text
