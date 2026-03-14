--!strict

local workspace = game:GetService("Workspace")

local ThemeTokens = require(script.Parent.Parent.Tokens.ThemeTokens)
local AppRuntime = require(script.Parent.AppRuntime)

local AppStyleRuntime = {}

function AppStyleRuntime.refreshWhitespace(app)
	app._context.whitespaceScale = AppRuntime.computeWhitespaceScale()
	local activeStylables = {}
	for _, stylable in ipairs(app._stylables) do
		if stylable and stylable.view and stylable.view.Parent then
			if stylable.applyWhitespace then
				stylable:applyWhitespace(app._context.whitespaceScale)
			end
			table.insert(activeStylables, stylable)
		end
	end
	app._stylables = activeStylables
end

function AppStyleRuntime.attachWhitespaceObserver(app)
	local viewportConnection = nil

	local function refresh()
		AppStyleRuntime.refreshWhitespace(app)
	end

	local cameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if viewportConnection then
			viewportConnection:Disconnect()
			viewportConnection = nil
		end

		local camera = workspace.CurrentCamera
		if camera then
			viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
		end

		refresh()
	end)

	if workspace.CurrentCamera then
		viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
	end

	refresh()

	return function()
		cameraConnection:Disconnect()
		if viewportConnection then
			viewportConnection:Disconnect()
		end
	end
end

function AppStyleRuntime.applyTheme(app, name: string)
	app.theme = ThemeTokens.getTheme(name)
	app._context.theme = app.theme
	app.legacyRendererFactory.theme = app.theme
	app.overlayHost._theme = app.theme

	local activeStylables = {}
	for _, stylable in ipairs(app._stylables) do
		if stylable and stylable.view and stylable.view.Parent and stylable.applyTheme then
			stylable:applyTheme(app.theme, app.layout)
			table.insert(activeStylables, stylable)
		end
	end
	app._stylables = activeStylables
end

return AppStyleRuntime
