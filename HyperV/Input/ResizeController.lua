--!strict

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local resolveLegacyRoot = require(script.Parent.Parent.Legacy.LegacyRoot)
local legacyRoot = resolveLegacyRoot(script)
local DragLock = require(legacyRoot.core.DragLock)

export type ResizeCallbacks = {
	authority: any?,
	claimantId: string?,
	interactionPriority: number?,
	domain: string?,
	minSize: Vector2?,
	maxSize: Vector2?,
	canResize: (() -> boolean)?,
	onResizeStart: ((input: InputObject, startSize: Vector2) -> ())?,
	onResize: ((input: InputObject, nextSize: Vector2, delta: Vector3) -> ())?,
	onResizeEnd: ((input: InputObject, endSize: Vector2) -> ())?,
	viewportMargin: number?,
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

local function getViewportSize(): Vector2
	local camera = Workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(1920, 1080)
end

function ResizeController.attach(frame: GuiObject, handles: ResizeHandles, callbacks: ResizeCallbacks?): () -> ()
	local options = callbacks or {}
	local authority = options.authority
	local ownerId = options.claimantId
		or (if type(frame:GetAttribute("HyperVSurfaceId")) == "string" then frame:GetAttribute("HyperVSurfaceId") else nil)
		or createOwnerId(frame)
	local priority = options.interactionPriority
		or (if type(frame:GetAttribute("HyperVSurfacePriority")) == "number" then frame:GetAttribute("HyperVSurfacePriority") else nil)
		or 0
	local domain = options.domain or "resize"
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

		if authority then
			if not authority:tryAcquire(domain, {
				id = ownerId,
				priority = priority,
			}) then
				return
			end
		else
			if not DragLock.TryAcquire(ownerId, input) then
				return
			end
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

		if authority then
			if not authority:isOwner(domain, ownerId) then
				activeHandle = nil
				dragInput = nil
				dragStart = nil
				startSize = nil
				return
			end
		else
			if not DragLock.IsOwner(ownerId) then
				activeHandle = nil
				dragInput = nil
				dragStart = nil
				startSize = nil
				return
			end
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
		local viewport = getViewportSize()
		local margin = options.viewportMargin or 20
		local framePosition = frame.AbsolutePosition
		local maxViewportWidth = math.max(minSize.X, viewport.X - framePosition.X - margin)
		local maxViewportHeight = math.max(minSize.Y, viewport.Y - framePosition.Y - margin)
		local clampedSize = Vector2.new(
			math.clamp(nextWidth, minSize.X, math.min(maxSize.X, maxViewportWidth)),
			math.clamp(nextHeight, minSize.Y, math.min(maxSize.Y, maxViewportHeight))
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
			if authority then
				authority:release(domain, ownerId)
			else
				DragLock.Release(ownerId)
			end

			if options.onResizeEnd then
				options.onResizeEnd(input, endSize)
			end
		end
	end))

	return function()
		if authority then
			authority:release(domain, ownerId)
		else
			DragLock.Release(ownerId)
		end
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end
end

return ResizeController
