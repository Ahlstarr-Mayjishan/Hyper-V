--!strict

local UserInputService = game:GetService("UserInputService")
local resolveLegacyRoot = require(script.Parent.Parent.Legacy.LegacyRoot)
local legacyRoot = resolveLegacyRoot(script)
local DragLock = require(legacyRoot.core.DragLock)

export type DragCallbacks = {
	canDrag: (() -> boolean)?,
	onDragStart: ((input: InputObject, startPosition: UDim2) -> ())?,
	onDragMove: ((input: InputObject, newPosition: UDim2, delta: Vector3) -> ())?,
	onDragEnd: ((input: InputObject, endPosition: UDim2) -> ())?,
}

local DragController = {}

function DragController.attach(frame: GuiObject, dragArea: GuiObject, callbacks: DragCallbacks?): () -> ()
	local options = callbacks or {}
	local ownerId = tostring(frame:GetDebugId())
	local dragging = false
	local dragInput: InputObject? = nil
	local dragStart: Vector3? = nil
	local startPosition: UDim2? = nil
	local activePointerType: Enum.UserInputType? = nil

	local began = dragArea.InputBegan:Connect(function(input)
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
			startPosition = frame.Position
			dragInput = input

			if options.onDragStart and startPosition then
				options.onDragStart(input, startPosition)
			end
		end
	end)

	local changed = dragArea.InputChanged:Connect(function(input)
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
		if not dragging or not dragStart or not startPosition then
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
		local nextPosition = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)

		frame.Position = nextPosition
		if options.onDragMove then
			options.onDragMove(input, nextPosition, delta)
		end
	end)

	local ended = UserInputService.InputEnded:Connect(function(input)
		if dragging and input.UserInputType == activePointerType then
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
		began:Disconnect()
		changed:Disconnect()
		inputChanged:Disconnect()
		ended:Disconnect()
	end
end

return DragController
