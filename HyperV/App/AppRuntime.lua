--!strict

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local AppRuntime = {}

AppRuntime.DEFAULT_WINDOW_MARGIN = 24
AppRuntime.MIN_WINDOW_SIZE = Vector2.new(360, 260)

function AppRuntime.getViewportSize(): Vector2
	local camera = Workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1280, 720)
end

function AppRuntime.computeWhitespaceScale(): number
	local viewport = AppRuntime.getViewportSize()
	local shortestSide = math.min(viewport.X, viewport.Y)
	if shortestSide <= 720 then
		return 0.92
	end

	if shortestSide >= 1440 then
		return 1.18
	end

	local alpha = (shortestSide - 720) / (1440 - 720)
	return 0.92 + (0.26 * alpha)
end

function AppRuntime.createScreenGui(name: string): ScreenGui
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild(name)
	if existing and existing:IsA("ScreenGui") then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	return screenGui
end

function AppRuntime.vectorFromSize(sizeValue: any, fallback: Vector2): Vector2
	if typeof(sizeValue) == "Vector2" then
		return sizeValue
	end

	if typeof(sizeValue) == "UDim2" then
		return Vector2.new(sizeValue.X.Offset, sizeValue.Y.Offset)
	end

	return fallback
end

function AppRuntime.centeredPosition(size: Vector2): UDim2
	return UDim2.new(0.5, math.floor(-size.X * 0.5), 0.5, math.floor(-size.Y * 0.5))
end

function AppRuntime.clampPosition(position: UDim2, scaledSize: Vector2, margin: number): UDim2
	local viewport = AppRuntime.getViewportSize()
	local maxX = math.max(margin, viewport.X - scaledSize.X - margin)
	local maxY = math.max(margin, viewport.Y - scaledSize.Y - margin)

	return UDim2.new(
		position.X.Scale,
		math.clamp(position.X.Offset, margin, maxX),
		position.Y.Scale,
		math.clamp(position.Y.Offset, margin, maxY)
	)
end

function AppRuntime.resolveResponsiveRect(
	sizeValue: any,
	positionValue: UDim2?,
	fallbackSize: Vector2,
	margin: number?
): (Vector2, UDim2, number)
	local baseSize = AppRuntime.vectorFromSize(sizeValue, fallbackSize)
	local viewport = AppRuntime.getViewportSize()
	local safeMargin = margin or AppRuntime.DEFAULT_WINDOW_MARGIN
	local availableWidth = math.max(AppRuntime.MIN_WINDOW_SIZE.X, viewport.X - (safeMargin * 2))
	local availableHeight = math.max(AppRuntime.MIN_WINDOW_SIZE.Y, viewport.Y - (safeMargin * 2))
	local scale = math.min(1, availableWidth / baseSize.X, availableHeight / baseSize.Y)
	local scaledSize = Vector2.new(baseSize.X * scale, baseSize.Y * scale)
	local resolvedPosition = AppRuntime.clampPosition(
		positionValue or AppRuntime.centeredPosition(scaledSize),
		scaledSize,
		safeMargin
	)

	return baseSize, resolvedPosition, scale
end

function AppRuntime.resolveDefaultPreviewPosition(window, requestedSize: Vector2?): UDim2
	local fallback = UDim2.new(0, 40, 0, 80)
	if not window or not window.root then
		return fallback
	end

	local root = window.root
	local width = if requestedSize then requestedSize.X else 760
	local height = if requestedSize then requestedSize.Y else 560
	local gap = 24
	local candidate = UDim2.new(
		root.Position.X.Scale,
		root.Position.X.Offset + root.AbsoluteSize.X + gap,
		root.Position.Y.Scale,
		root.Position.Y.Offset
	)

	local camera = Workspace.CurrentCamera
	if not camera then
		return candidate
	end

	local viewport = camera.ViewportSize
	if candidate.X.Offset + width > viewport.X then
		return fallback
	end

	if candidate.Y.Offset + height > viewport.Y then
		return UDim2.new(0, math.max(24, viewport.X - width - 24), 0, math.max(24, viewport.Y - height - 24))
	end

	return candidate
end

function AppRuntime.attachResponsiveWindow(handle, baseSize: Vector2, margin: number?): () -> ()
	local frame = handle.view
	local safeMargin = margin or AppRuntime.DEFAULT_WINDOW_MARGIN
	local uiScale = frame:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	uiScale.Parent = frame
	handle._baseSize = baseSize

	local applying = false
	local viewportConnection = nil

	local function update()
		if applying or not frame.Parent then
			return
		end

		applying = true
		local targetSize = handle._baseSize or baseSize
		local viewport = AppRuntime.getViewportSize()
		local availableWidth = math.max(AppRuntime.MIN_WINDOW_SIZE.X, viewport.X - (safeMargin * 2))
		local availableHeight = math.max(AppRuntime.MIN_WINDOW_SIZE.Y, viewport.Y - (safeMargin * 2))
		local scale = math.min(1, availableWidth / targetSize.X, availableHeight / targetSize.Y)
		local scaledSize = Vector2.new(targetSize.X * scale, targetSize.Y * scale)
		uiScale.Scale = scale
		frame.Position = AppRuntime.clampPosition(frame.Position, scaledSize, safeMargin)
		applying = false
	end

	local cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if viewportConnection then
			viewportConnection:Disconnect()
			viewportConnection = nil
		end

		local camera = Workspace.CurrentCamera
		if camera then
			viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
		end

		update()
	end)

	if Workspace.CurrentCamera then
		viewportConnection = Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end

	update()

	return function()
		cameraConnection:Disconnect()
		if viewportConnection then
			viewportConnection:Disconnect()
		end
	end
end

return AppRuntime
