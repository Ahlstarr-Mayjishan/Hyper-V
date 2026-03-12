--[[
    Hyper-V - Utilities Module
    Các hàm tiện ích dùng chung
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Utf8 = utf8
local DragLock = require(script.Parent.DragLock)

local Utilities = {}

local function toText(value)
	if value == nil then
		return ""
	end

	return tostring(value)
end

-- Tạo UICorner
function Utilities:CreateCorner(parent, radius, topLeft, topRight, bottomRight, bottomLeft)
	local Corner = parent:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	local resolvedRadius = radius

	for _, value in ipairs({ topLeft, topRight, bottomRight, bottomLeft }) do
		if type(value) == "number" then
			resolvedRadius = value
			break
		end
	end

	Corner.CornerRadius = UDim.new(0, resolvedRadius or 0)
	Corner.Parent = parent
	return Corner
end

-- Tạo UIStroke
function Utilities:CreateStroke(parent, color, thickness)
	local Stroke = Instance.new("UIStroke")
	Stroke.Color = color or Color3.fromRGB(60, 60, 60)
	Stroke.Thickness = thickness or 1
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = parent
	return Stroke
end

-- Tạo UIListLayout
function Utilities:CreateListLayout(parent, padding)
	local ListLayout = Instance.new("UIListLayout")
	ListLayout.Padding = UDim.new(0, padding or 5)
	ListLayout.Parent = parent
	return ListLayout
end

-- Tạo UIPadding
function Utilities:CreatePadding(parent, top, bottom, left, right)
	local Padding = Instance.new("UIPadding")
	if top then
		Padding.PaddingTop = UDim.new(0, top)
	end
	if bottom then
		Padding.PaddingBottom = UDim.new(0, bottom)
	end
	if left then
		Padding.PaddingLeft = UDim.new(0, left)
	end
	if right then
		Padding.PaddingRight = UDim.new(0, right)
	end
	Padding.Parent = parent
	return Padding
end

-- Animation fade
function Utilities:FadeIn(object, duration)
	duration = duration or 0.2
	TweenService:Create(object, TweenInfo.new(duration), {
		BackgroundTransparency = 0,
	}):Play()
end

function Utilities:FadeOut(object, duration)
	duration = duration or 0.2
	TweenService:Create(object, TweenInfo.new(duration), {
		BackgroundTransparency = 1,
	}):Play()
end

-- Animation color
function Utilities:TweenColor(object, color, duration)
	duration = duration or 0.15
	TweenService:Create(object, TweenInfo.new(duration), {
		BackgroundColor3 = color,
	}):Play()
end

-- Animation position
function Utilities:TweenPosition(object, position, duration)
	duration = duration or 0.15
	TweenService:Create(object, TweenInfo.new(duration), {
		Position = position,
	}):Play()
end

-- Animation size
function Utilities:TweenSize(object, size, duration)
	duration = duration or 0.15
	TweenService:Create(object, TweenInfo.new(duration), {
		Size = size,
	}):Play()
end

function Utilities:TweenProperty(object, property, value, duration, delayTime, arg6, arg7, arg8)
	duration = duration or 0.15
	delayTime = delayTime or 0
	local easingStyle = Enum.EasingStyle.Quad
	local easingDirection = Enum.EasingDirection.Out
	local onComplete = nil

	if typeof(arg6) == "function" then
		onComplete = arg6
	elseif typeof(arg6) == "EnumItem" and arg6.EnumType == Enum.EasingStyle then
		easingStyle = arg6
		if typeof(arg7) == "EnumItem" and arg7.EnumType == Enum.EasingDirection then
			easingDirection = arg7
			if typeof(arg8) == "function" then
				onComplete = arg8
			end
		elseif typeof(arg7) == "function" then
			onComplete = arg7
		end
	elseif typeof(arg6) == "EnumItem" and arg6.EnumType == Enum.EasingDirection then
		easingDirection = arg6
		if typeof(arg7) == "function" then
			onComplete = arg7
		end
	end

	local tween = TweenService:Create(object, TweenInfo.new(duration, easingStyle, easingDirection), {
		[property] = value,
	})

	if onComplete then
		tween.Completed:Connect(function()
			onComplete()
		end)
	end

	if delayTime > 0 then
		task.delay(delayTime, function()
			if object and object.Parent then
				tween:Play()
			end
		end)
	else
		tween:Play()
	end

	return tween
end

-- Get key name from Enum
function Utilities:GetKeyName(key)
	local keyName = tostring(key)
	keyName = keyName:gsub("Enum%.UserInputType%.", "")
	keyName = keyName:gsub("Enum%.KeyCode%.", "")
	return keyName
end

function Utilities:SupportsUTF8()
	return Utf8 ~= nil
end

function Utilities:Utf8Len(text)
	local value = toText(text)
	if not Utf8 then
		return #value
	end

	local ok, length = pcall(Utf8.len, value)
	if ok and length then
		return length
	end

	return #value
end

function Utilities:Utf8Sub(text, startIndex, endIndex)
	local value = toText(text)
	if value == "" then
		return ""
	end

	if not Utf8 then
		return string.sub(value, startIndex or 1, endIndex)
	end

	local length = self:Utf8Len(value)
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

	local okStart, startByte = pcall(Utf8.offset, value, first)
	if not okStart or not startByte then
		return string.sub(value, first, last)
	end

	local okEnd, endByte = pcall(Utf8.offset, value, last + 1)
	if okEnd and endByte then
		return string.sub(value, startByte, endByte - 1)
	end

	return string.sub(value, startByte)
end

function Utilities:Utf8Truncate(text, maxChars, suffix)
	local value = toText(text)
	local limit = math.max(0, tonumber(maxChars) or 0)
	local tail = toText(suffix)

	if limit == 0 then
		return ""
	end

	if self:Utf8Len(value) <= limit then
		return value
	end

	local tailLength = self:Utf8Len(tail)
	if tailLength >= limit then
		return self:Utf8Sub(value, 1, limit)
	end

	return self:Utf8Sub(value, 1, limit - tailLength) .. tail
end

function Utilities:TextContains(haystack, needle, caseInsensitive)
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

function Utilities:CompareText(left, right, ascending)
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

-- Check if is mobile
function Utilities:IsMobile()
	return UserInputService.TouchEnabled
end

function Utilities:GetGuiBounds(guiObject)
	return {
		Position = guiObject.AbsolutePosition,
		Size = guiObject.AbsoluteSize,
	}
end

function Utilities:IsPointInBounds(point, target)
	local bounds = target.AbsolutePosition and self:GetGuiBounds(target) or target
	local minX = bounds.Position.X
	local minY = bounds.Position.Y
	local maxX = minX + bounds.Size.X
	local maxY = minY + bounds.Size.Y

	return point.X >= minX and point.X <= maxX and point.Y >= minY and point.Y <= maxY
end

-- Create draggable frame
function Utilities:MakeDraggable(frame, dragArea, options)
	options = options or {}
	local ownerId = tostring(frame:GetDebugId())

	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPos = nil
	local activePointerType = nil

	local inputBegan = dragArea.InputBegan:Connect(function(input)
		if options.canDrag and options.canDrag() == false then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if not DragLock.TryAcquire(ownerId, input) then
				return
			end

			dragging = true
			activePointerType = input.UserInputType
			dragStart = input.Position
			startPos = frame.Position
			dragInput = input

			if options.onDragStart then
				options.onDragStart(input, startPos)
			end
		end
	end)

	local dragAreaChanged = dragArea.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			dragInput = input
		end
	end)

	local inputChanged = UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if not DragLock.IsOwner(ownerId) then
			dragging = false
			dragInput = nil
			activePointerType = nil
			return
		end

		if dragInput and input ~= dragInput then
			return
		end

		if
			activePointerType == Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.MouseMovement
		then
			return
		end

		if activePointerType == Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - dragStart
		local newPosition =
			UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)

		frame.Position = newPosition

		if options.onDragMove then
			options.onDragMove(input, newPosition, delta)
		end
	end)

	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType == activePointerType then
			dragging = false
			dragInput = nil
			activePointerType = nil
			DragLock.Release(ownerId)

			if options.onDragEnd then
				options.onDragEnd(input, frame.Position)
			end
		end
	end)

	return function()
		DragLock.Release(ownerId)
		inputBegan:Disconnect()
		dragAreaChanged:Disconnect()
		inputEnded:Disconnect()
		inputChanged:Disconnect()
	end
end

-- Round number
function Utilities:Round(num, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(num * mult + 0.5) / mult
end

-- Clamp value
function Utilities:Clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

-- Lerp color
function Utilities:LerpColor(color1, color2, alpha)
	return Color3.new(
		color1.R + (color2.R - color1.R) * alpha,
		color1.G + (color2.G - color1.G) * alpha,
		color1.B + (color2.B - color1.B) * alpha
	)
end

return Utilities
