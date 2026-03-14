--!strict

local AppBrainRuntime = {}

local function validatePreviewTarget(request)
	if request == nil then
		return false, "Missing preview target request"
	end

	if request.model == nil then
		return true, nil
	end

	if typeof(request.model) ~= "Instance" or not request.model:IsA("Model") then
		return false, "Preview target must be a Model"
	end

	return true, nil
end

local function validatePreviewPatch(request)
	if request == nil or type(request.sourceId) ~= "string" or type(request.patch) ~= "table" then
		return false, "Invalid preview patch request"
	end

	return true, nil
end

local function validatePreviewConfig(request)
	if request == nil or type(request.sourceId) ~= "string" or type(request.config) ~= "table" then
		return false, "Invalid preview config request"
	end

	return true, nil
end

local function validatePreviewCommit(request)
	if request == nil or type(request.sourceId) ~= "string" or type(request.snapshot) ~= "table" then
		return false, "Invalid preview commit request"
	end

	return true, nil
end

local function validateDockAttach(request)
	if request == nil or request.handle == nil or request.target == nil then
		return false, "Invalid dock attach request"
	end

	if not request.handle.view or typeof(request.handle.view) ~= "Instance" then
		return false, "Dock handle must expose a view"
	end

	if request.target.supportsHandle and request.target:supportsHandle(request.handle) == false then
		return false, "Dock target rejected handle"
	end

	return true, nil
end

local function validateDockDetach(request)
	if request == nil or request.handle == nil then
		return false, "Invalid dock detach request"
	end

	return true, nil
end

function AppBrainRuntime.buildContext(app)
	return {
		app = app,
		theme = app.theme,
		layout = app.layout,
		whitespaceScale = app._context and app._context.whitespaceScale or 1,
		toolkit = app.toolkit,
		presetRegistry = app.presetRegistry,
		commandRegistry = app.commandRegistry,
		dockRegistry = app.dockRegistry,
		interactionAuthority = app.interactionAuthority,
		layerAuthority = app.layerAuthority,
		protectionGate = app.protectionGate,
		brain = app.brain,
		gc = app.gc,
		api = app.api,
		animation = nil :: any,
	}
end

function AppBrainRuntime.registerProtectionRules(app)
	app.protectionGate:register("dock.attach", {
		validate = validateDockAttach,
	})
	app.protectionGate:register("dock.detach", {
		validate = validateDockDetach,
	})
	app.protectionGate:register("preview.patch", {
		validate = validatePreviewPatch,
	})
	app.protectionGate:register("preview.set", {
		validate = validatePreviewConfig,
	})
	app.protectionGate:register("preview.commit", {
		validate = validatePreviewCommit,
	})
	app.protectionGate:register("preview.target", {
		validate = validatePreviewTarget,
	})
end

function AppBrainRuntime.initialize(app)
	app.brain:attachAuthority(app.interactionAuthority)
	app.toolkit._interactionAuthority = app.interactionAuthority
	AppBrainRuntime.registerProtectionRules(app)
end

return AppBrainRuntime
