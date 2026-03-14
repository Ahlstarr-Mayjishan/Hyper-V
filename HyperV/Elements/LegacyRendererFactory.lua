--!strict

local LegacyDataFactory = require(script.Parent.Legacy.LegacyDataFactory)
local LegacyHandleAdapter = require(script.Parent.Legacy.LegacyHandleAdapter)
local LegacyInputFactory = require(script.Parent.Legacy.LegacyInputFactory)
local LegacyModuleLoader = require(script.Parent.Legacy.LegacyModuleLoader)

local LegacyRendererFactory = {}
LegacyRendererFactory.__index = LegacyRendererFactory

function LegacyRendererFactory.new(legacyRoot, theme, toolkit, presetRegistry)
	return setmetatable({
		theme = theme,
		toolkit = toolkit,
		presetRegistry = presetRegistry,
		moduleLoader = LegacyModuleLoader.new(legacyRoot),
	}, LegacyRendererFactory)
end

function LegacyRendererFactory:_createHandle(moduleKey, config, handleSpec)
	local module = self.moduleLoader:requireModule(moduleKey)
	local view = module.new(config, self.theme, self.toolkit)
	return LegacyHandleAdapter.create({
		id = handleSpec.id,
		kind = handleSpec.kind,
		title = handleSpec.title,
		viewObject = view,
		parentFrame = config.Parent,
		methods = handleSpec.methods,
		preset = handleSpec.preset,
	}, self.presetRegistry)
end

function LegacyRendererFactory:createNumberInput(config)
	return LegacyInputFactory.createNumberInput(self, config)
end

function LegacyRendererFactory:createRangeSlider(config)
	return LegacyInputFactory.createRangeSlider(self, config)
end

function LegacyRendererFactory:createMultiSelectDropdown(config)
	return LegacyInputFactory.createMultiSelectDropdown(self, config)
end

function LegacyRendererFactory:createCodeBlock(config)
	return LegacyInputFactory.createCodeBlock(self, config)
end

function LegacyRendererFactory:createSubTabs(config)
	return LegacyDataFactory.createSubTabs(self, config)
end

function LegacyRendererFactory:createVirtualList(config)
	return LegacyDataFactory.createVirtualList(self, config)
end

function LegacyRendererFactory:createTreeView(config)
	return LegacyDataFactory.createTreeView(self, config)
end

return LegacyRendererFactory
