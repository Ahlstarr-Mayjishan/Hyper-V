--!strict

local LegacyHandleAdapter = require(script.Parent.Legacy.LegacyHandleAdapter)
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
	return self:_createHandle("numberInput", config, {
		id = config.Name or "NumberInput",
		kind = "numberInput",
		title = config.Title or config.Name or "Number Input",
		methods = {
			getValue = "GetValue",
			setValue = "SetValue",
		},
		preset = {
			getValue = function(view)
				return view:GetValue()
			end,
			applyValue = function(view, value)
				view:SetValue(value, true)
			end,
		},
	})
end

function LegacyRendererFactory:createRangeSlider(config)
	return self:_createHandle("rangeSlider", config, {
		id = config.Name or "RangeSlider",
		kind = "rangeSlider",
		title = config.Title or config.Name or "Range Slider",
		methods = {
			getValue = "GetValue",
			setValue = "SetValue",
		},
		preset = {
			getValue = function(view)
				local minValue, maxValue = view:GetValue()
				return { minValue, maxValue }
			end,
			applyValue = function(view, value)
				view:SetValue(value, true)
			end,
		},
	})
end

function LegacyRendererFactory:createMultiSelectDropdown(config)
	return self:_createHandle("multiSelectDropdown", config, {
		id = config.Name or "MultiSelectDropdown",
		kind = "multiSelectDropdown",
		title = config.Title or config.Name or "Multi Select",
		methods = {
			getValue = "GetValue",
			setValue = "SetValue",
		},
		preset = {
			getValue = function(view)
				return view:GetValue()
			end,
			applyValue = function(view, value)
				view:SetValue(value, true)
			end,
		},
	})
end

function LegacyRendererFactory:createCodeBlock(config)
	return self:_createHandle("codeBlock", config, {
		id = config.Name or "CodeBlock",
		kind = "codeBlock",
		title = config.Title or config.Name or "Code",
		methods = {
			getText = "GetText",
			setText = "SetText",
		},
		preset = {
			getValue = function(view)
				return view:GetText()
			end,
			applyValue = function(view, value)
				view:SetText(tostring(value))
			end,
		},
	})
end

function LegacyRendererFactory:createSubTabs(config)
	return self:_createHandle("subTabs", config, {
		id = config.Name or "SubTabs",
		kind = "subTabs",
		title = config.Name or "SubTabs",
		methods = {
			select = "Select",
			getTab = "GetTab",
		},
	})
end

function LegacyRendererFactory:createVirtualList(config)
	return self:_createHandle("virtualList", config, {
		id = config.Name or "VirtualList",
		kind = "virtualList",
		title = config.Title or config.Name or "Virtual List",
		methods = {
			getValue = "GetValue",
			setValue = "SetValue",
			setItems = "SetItems",
			addItems = "AddItems",
			scrollToIndex = "ScrollToIndex",
			getVisibleRange = "GetVisibleRange",
		},
	})
end

function LegacyRendererFactory:createTreeView(config)
	return self:_createHandle("treeView", config, {
		id = config.Name or "TreeView",
		kind = "treeView",
		title = config.Title or config.Name or "Tree View",
		methods = {
			getValue = "GetValue",
			getSelectedKey = "GetSelectedKey",
			setValue = "SetValue",
			setNodes = "SetNodes",
			expand = "Expand",
			collapse = "Collapse",
			toggle = "Toggle",
			expandAll = "ExpandAll",
			collapseAll = "CollapseAll",
		},
		preset = {
			getValue = function(view)
				return view:GetSelectedKey()
			end,
			applyValue = function(view, value)
				view:SetValue(value, true)
			end,
		},
	})
end

return LegacyRendererFactory
