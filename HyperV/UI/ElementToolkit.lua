--!strict

local StyleToolkit = require(script.Parent.Toolkit.StyleToolkit)
local MotionToolkit = require(script.Parent.Toolkit.MotionToolkit)
local TextToolkit = require(script.Parent.Toolkit.TextToolkit)
local GeometryToolkit = require(script.Parent.Toolkit.GeometryToolkit)
local InteractionToolkit = require(script.Parent.Toolkit.InteractionToolkit)

local ElementToolkit = {}
ElementToolkit.__index = ElementToolkit

function ElementToolkit.new()
	return setmetatable({
		_style = StyleToolkit,
		_motion = MotionToolkit,
		_text = TextToolkit,
		_geometry = GeometryToolkit,
		_interaction = InteractionToolkit,
	}, ElementToolkit)
end

function ElementToolkit:CreateCorner(parent: Instance, radius: number)
	return self._style.createCorner(parent, radius)
end

function ElementToolkit:CreateStroke(parent: Instance, color: Color3, thickness: number?)
	return self._style.createStroke(parent, color, thickness)
end

function ElementToolkit:CreatePadding(parent: Instance, top: number?, bottom: number?, left: number?, right: number?)
	return self._style.createPadding(parent, top, bottom, left, right)
end

function ElementToolkit:TweenColor(object: Instance, color: Color3, duration: number?)
	return self._motion.tweenColor(object, color, duration)
end

function ElementToolkit:TweenPosition(object: Instance, position: UDim2, duration: number?)
	return self._motion.tweenPosition(object, position, duration)
end

function ElementToolkit:TweenSize(object: Instance, size: UDim2, duration: number?)
	return self._motion.tweenSize(object, size, duration)
end

function ElementToolkit:TweenProperty(object: Instance, property: string, value: any, duration: number?, delayTime: number?, easingStyle: Enum.EasingStyle?, easingDirection: Enum.EasingDirection?, onComplete: (() -> ())?)
	return self._motion.tweenProperty(object, property, value, duration, delayTime, easingStyle, easingDirection, onComplete)
end

function ElementToolkit:TextContains(haystack: any, needle: any, caseInsensitive: boolean?)
	return self._text.contains(haystack, needle, caseInsensitive)
end

function ElementToolkit:CompareText(left: any, right: any, ascending: boolean?)
	return self._text.compare(left, right, ascending)
end

function ElementToolkit:Utf8Len(text: any)
	return self._text.utf8Len(text)
end

function ElementToolkit:Utf8Sub(text: any, startIndex: number?, endIndex: number?)
	return self._text.utf8Sub(text, startIndex, endIndex)
end

function ElementToolkit:GetKeyName(key: Enum.KeyCode | Enum.UserInputType)
	return self._text.getKeyName(key)
end

function ElementToolkit:GetGuiBounds(guiObject: GuiObject)
	return self._geometry.getGuiBounds(guiObject)
end

function ElementToolkit:IsPointInBounds(point: Vector2, target: GuiObject | any)
	return self._geometry.isPointInBounds(point, target)
end

function ElementToolkit:MakeDraggable(frame: GuiObject, dragArea: GuiObject, options)
	return self._interaction.makeDraggable(self._interactionAuthority, frame, dragArea, options)
end

function ElementToolkit:MakeResizable(frame: GuiObject, handles, options)
	return self._interaction.makeResizable(self._interactionAuthority, frame, handles, options)
end

return ElementToolkit
