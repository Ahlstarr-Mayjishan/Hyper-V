--!strict

local DragController = require(script.Parent.Parent.Parent.Input.DragController)
local ResizeController = require(script.Parent.Parent.Parent.Input.ResizeController)

local InteractionToolkit = {}

function InteractionToolkit.makeDraggable(interactionAuthority, frame: GuiObject, dragArea: GuiObject, options)
	local nextOptions = if options then table.clone(options) else {}
	if nextOptions.authority == nil then
		nextOptions.authority = interactionAuthority
	end
	return DragController.attach(frame, dragArea, nextOptions)
end

function InteractionToolkit.makeResizable(interactionAuthority, frame: GuiObject, handles, options)
	local nextOptions = if options then table.clone(options) else {}
	if nextOptions.authority == nil then
		nextOptions.authority = interactionAuthority
	end
	return ResizeController.attach(frame, handles, nextOptions)
end

return InteractionToolkit
