--!strict

local TweenDriver = require(script.Parent.Parent.Primitives.TweenDriver)

local MotionToolkit = {}

function MotionToolkit.tweenColor(object: Instance, color: Color3, duration: number?)
	return TweenDriver.to(object, { BackgroundColor3 = color }, duration)
end

function MotionToolkit.tweenPosition(object: Instance, position: UDim2, duration: number?)
	return TweenDriver.to(object, { Position = position }, duration)
end

function MotionToolkit.tweenSize(object: Instance, size: UDim2, duration: number?)
	return TweenDriver.to(object, { Size = size }, duration)
end

function MotionToolkit.tweenProperty(
	object: Instance,
	property: string,
	value: any,
	duration: number?,
	delayTime: number?,
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?,
	onComplete: (() -> ())?
)
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

return MotionToolkit
