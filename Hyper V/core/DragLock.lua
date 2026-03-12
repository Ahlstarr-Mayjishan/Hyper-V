local DragLock = {}

local activeOwner = nil
local activePointerType = nil

function DragLock.TryAcquire(ownerId, input)
	if activeOwner and activeOwner ~= ownerId then
		return false
	end

	activeOwner = ownerId
	activePointerType = input and input.UserInputType or nil
	return true
end

function DragLock.IsOwner(ownerId)
	return activeOwner == ownerId
end

function DragLock.Release(ownerId)
	if activeOwner == ownerId then
		activeOwner = nil
		activePointerType = nil
	end
end

function DragLock.GetPointerType()
	return activePointerType
end

function DragLock.GetOwner()
	return activeOwner
end

return DragLock
