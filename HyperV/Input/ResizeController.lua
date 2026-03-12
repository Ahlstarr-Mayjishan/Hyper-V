--!strict

local UserInputService = game:GetService("UserInputService")
local resolveLegacyRoot = require(script.Parent.Parent.Legacy.LegacyRoot)
local legacyRoot = resolveLegacyRoot(script)
local DragLock = require(legacyRoot.core.DragLock)

export type ResizeCallbacks = {
	minSize: Vector2?,
	maxSize: Vector2?,
	canResize: (() -> boolean)?,
	onResizeStart: ((input: InputObject, startSize: Vector2) -> ())?,
	onResize: ((input: InputObject, nextSize: Vector2, delta: Vector3) -> ())?,
	onResizeEnd: ((input: InputObject, endSize: Vector2) -> ())?,
}

export type ResizeHandles = {
	corner: GuiObject?,
	right: GuiObject?,
	bottom: GuiObject?,
}

local ResizeController = {}
local resizeOwnerCounter = 0

local function createOwnerId(frame: GuiObject): string
	resizeOwnerCounter += 1
	return string.format("resize:%s:%d", frame.Name, resizeOwnerCounter)
end

function ResizeController.attach(frame: GuiObject, handles: ResizeHandles, callbacks: ResizeCallbacks?): () -> ()
	local options = callbacks or {}
	local ownerId = createOwnerId(frame)
	local activeHandle: string? = nil
	local dragInput: InputObject? = nil
	local dragStart: Vector3? = nil
	local startSize: Vector2? = nil

	local connections = {}

	local function beginResize(handleName: string, input: InputObject)
		if options.canResize and options.canResize() == false then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		if not DragLock.TryAcquire(ownerId, input) then
			return
		end

		activeHandle = handleName
		dragInput = input
		dragStart = input.Position
		startSize = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)

		if options.onResizeStart and startSize then
			options.onResizeStart(input, startSize)
		end
	end

	local function bindHandle(handleName: string, handle: GuiObject?)
		if not handle then
			return
		end

		table.insert(connections, handle.InputBegan:Connect(function(input)
			beginResize(handleName, input)
		end))

		table.insert(connections, handle.InputChanged:Connect(function(input)
			if
				activeHandle
				and (
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				)
			then
				dragInput = input
			end
		end))
	end

	bindHandle("corner", handles.corner)
	bindHandle("right", handles.right)
	bindHandle("bottom", handles.bottom)

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if not activeHandle or not dragStart or not startSize or not dragInput then
			return
		end

		if input ~= dragInput then
			return
		end

		if not DragLock.IsOwner(ownerId) then
			activeHandle = nil
			dragInput = nil
			dragStart = nil
			startSize = nil
			return
		end

		local delta = input.Position - dragStart
		local nextWidth = startSize.X
		local nextHeight = startSize.Y

		if activeHandle == "corner" or activeHandle == "right" then
			nextWidth += delta.X
		end

		if activeHandle == "corner" or activeHandle == "bottom" then
			nextHeight += delta.Y
		end

		local minSize = options.minSize or Vector2.new(320, 220)
		local maxSize = options.maxSize or Vector2.new(4096, 4096)
		local clampedSize = Vector2.new(
			math.clamp(nextWidth, minSize.X, maxSize.X),
			math.clamp(nextHeight, minSize.Y, maxSize.Y)
		)

		frame.Size = UDim2.new(0, clampedSize.X, 0, clampedSize.Y)

		if options.onResize then
			options.onResize(input, clampedSize, delta)
		end
	end))

	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if activeHandle and dragInput and input.UserInputType == dragInput.UserInputType then
			local endSize = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
			activeHandle = nil
			dragInput = nil
			dragStart = nil
			startSize = nil
			DragLock.Release(ownerId)

			if options.onResizeEnd then
				options.onResizeEnd(input, endSize)
			end
		end
	end))

	return function()
		DragLock.Release(ownerId)
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end
end

return ResizeController
