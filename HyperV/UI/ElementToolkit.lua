--!strict

local CornerFactory = require(script.Parent.Primitives.CornerFactory)
local StrokeFactory = require(script.Parent.Primitives.StrokeFactory)
local PaddingFactory = require(script.Parent.Primitives.PaddingFactory)
local Bounds = require(script.Parent.Primitives.Bounds)
local TweenDriver = require(script.Parent.Primitives.TweenDriver)
local Utf8Text = require(script.Parent.Parent.Text.Utf8Text)
local KeyFormatter = require(script.Parent.Parent.Input.KeyFormatter)
local DragController = require(script.Parent.Parent.Input.DragController)
local ResizeController = require(script.Parent.Parent.Input.ResizeController)

local ElementToolkit = {}
ElementToolkit.__index = ElementToolkit

function ElementToolkit.new()
	return setmetatable({}, ElementToolkit)
end

function ElementToolkit:CreateCorner(parent: Instance, radius: number)
	return CornerFactory.apply(parent, radius)
end

function ElementToolkit:CreateStroke(parent: Instance, color: Color3, thickness: number?)
	return StrokeFactory.apply(parent, color, thickness)
end

function ElementToolkit:CreatePadding(parent: Instance, top: number?, bottom: number?, left: number?, right: number?)
	return PaddingFactory.apply(parent, top, bottom, left, right)
end

function ElementToolkit:TweenColor(object: Instance, color: Color3, duration: number?)
	return TweenDriver.to(object, { BackgroundColor3 = color }, duration)
end

function ElementToolkit:TweenPosition(object: Instance, position: UDim2, duration: number?)
	return TweenDriver.to(object, { Position = position }, duration)
end

function ElementToolkit:TweenSize(object: Instance, size: UDim2, duration: number?)
	return TweenDriver.to(object, { Size = size }, duration)
end

function ElementToolkit:TweenProperty(object: Instance, property: string, value: any, duration: number?, delayTime: number?, easingStyle: Enum.EasingStyle?, easingDirection: Enum.EasingDirection?, onComplete: (() -> ())?)
	local function play()
		local tween = TweenDriver.to(object, { [property] = value }, duration, easingStyle, easingDirection)
		if onComplete then
			tween.Completed:Connect(onComplete)
		end
		return tween
	end

	if delayTime and delayTime > 0 then
		task.delay(delayTime, play)
		return nil
	end

	return play()
end

function ElementToolkit:TextContains(haystack: any, needle: any, caseInsensitive: boolean?)
	return Utf8Text.contains(haystack, needle, caseInsensitive)
end

function ElementToolkit:CompareText(left: any, right: any, ascending: boolean?)
	return Utf8Text.compare(left, right, ascending)
end

function ElementToolkit:Utf8Len(text: any)
	return Utf8Text.len(text)
end

function ElementToolkit:Utf8Sub(text: any, startIndex: number?, endIndex: number?)
	return Utf8Text.sub(text, startIndex, endIndex)
end

function ElementToolkit:GetKeyName(key: Enum.KeyCode | Enum.UserInputType)
	return KeyFormatter.format(key)
end

function ElementToolkit:GetGuiBounds(guiObject: GuiObject)
	return Bounds.get(guiObject)
end

function ElementToolkit:IsPointInBounds(point: Vector2, target: GuiObject | any)
	return Bounds.contains(point, target)
end

function ElementToolkit:MakeDraggable(frame: GuiObject, dragArea: GuiObject, options)
	local nextOptions = if options then table.clone(options) else {}
	if nextOptions.authority == nil then
		nextOptions.authority = self._interactionAuthority
	end
	return DragController.attach(frame, dragArea, nextOptions)
end

function ElementToolkit:MakeResizable(frame: GuiObject, handles, options)
	local nextOptions = if options then table.clone(options) else {}
	if nextOptions.authority == nil then
		nextOptions.authority = self._interactionAuthority
	end
	return ResizeController.attach(frame, handles, nextOptions)
end

return ElementToolkit
