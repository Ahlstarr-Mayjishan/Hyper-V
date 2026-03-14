--!strict

local AppElementFactory = require(script.Parent.AppElementFactory)
local AppSurfaceFactory = require(script.Parent.AppSurfaceFactory)

local AppFactory = {}

function AppFactory.createWindow(self, config)
	return AppSurfaceFactory.createWindow(self, config)
end

function AppFactory.createButton(self, config, parentOverride)
	return AppElementFactory.createButton(self, config, parentOverride)
end

function AppFactory.createLabel(self, config, parentOverride)
	return AppElementFactory.createLabel(self, config, parentOverride)
end

function AppFactory.createSection(self, config)
	return AppElementFactory.createSection(self, config)
end

function AppFactory.createAccordionSection(self, config)
	return AppElementFactory.createAccordionSection(self, config)
end

function AppFactory.createDockPanel(self, config)
	return AppSurfaceFactory.createDockPanel(self, config)
end

function AppFactory.createDetachedWindow(self, config)
	return AppSurfaceFactory.createDetachedWindow(self, config)
end

function AppFactory.createCommandPalette(self, config)
	return AppSurfaceFactory.createCommandPalette(self, config)
end

function AppFactory.createModal(self, config)
	return AppSurfaceFactory.createModal(self, config)
end

function AppFactory.createContextMenu(self, config)
	return AppSurfaceFactory.createContextMenu(self, config)
end

function AppFactory.createBrainInspector(self)
	return AppSurfaceFactory.createBrainInspector(self)
end

function AppFactory.createNumberInput(self, config)
	return AppElementFactory.createNumberInput(self, config)
end

function AppFactory.createRangeSlider(self, config)
	return AppElementFactory.createRangeSlider(self, config)
end

function AppFactory.createMultiSelectDropdown(self, config)
	return AppElementFactory.createMultiSelectDropdown(self, config)
end

function AppFactory.createCodeBlock(self, config)
	return AppElementFactory.createCodeBlock(self, config)
end

function AppFactory.createColorPicker(self, config)
	return AppElementFactory.createColorPicker(self, config)
end

function AppFactory.createSubTabs(self, config, parentOverride)
	return AppElementFactory.createSubTabs(self, config, parentOverride)
end

function AppFactory.createTreeView(self, config)
	return AppElementFactory.createTreeView(self, config)
end

function AppFactory.createVirtualList(self, config)
	return AppElementFactory.createVirtualList(self, config)
end

function AppFactory.createPresetManager(self, config)
	return AppElementFactory.createPresetManager(self, config)
end

function AppFactory.createCharacterPreview(self, config)
	return AppSurfaceFactory.createCharacterPreview(self, config)
end

function AppFactory.registerCommand(self, command)
	self.commandRegistry:register({
		id = command.id or command.Name or command.Title,
		title = command.title or command.Title,
		description = command.description or command.Description,
		callback = command.callback or command.Callback,
	})
end

function AppFactory.notify(self, config)
	return self.overlayHost:notify(config)
end

function AppFactory.notifyInfo(self, title, content, duration)
	return self:notify({
		Title = title,
		Content = content,
		Type = "info",
		Duration = duration or 3,
	})
end

function AppFactory.notifySuccess(self, title, content, duration)
	return self:notify({
		Title = title,
		Content = content,
		Type = "success",
		Duration = duration or 3,
	})
end

return AppFactory
