--!strict

local TweenService = game:GetService("TweenService")

local TweenDriver = {}

function TweenDriver.to(object: Instance, goals: { [string]: any }, duration: number?, easingStyle: Enum.EasingStyle?, easingDirection: Enum.EasingDirection?): Tween
	local tween = TweenService:Create(
		object,
		TweenInfo.new(duration or 0.15, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out),
		goals
	)
	tween:Play()
	return tween
end

return TweenDriver
