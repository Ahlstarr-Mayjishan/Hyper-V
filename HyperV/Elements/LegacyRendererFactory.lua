--!strict

local LegacyRendererFactory = {}
LegacyRendererFactory.__index = LegacyRendererFactory

function LegacyRendererFactory.new(legacyRoot, theme, toolkit, presetRegistry)
	return setmetatable({
		legacyRoot = legacyRoot,
		theme = theme,
		toolkit = toolkit,
		presetRegistry = presetRegistry,
		modules = {},
	}, LegacyRendererFactory)
end

function LegacyRendererFactory:_require(path: string)
	if self.modules[path] then
		return self.modules[path]
	end

	local node = self.legacyRoot
	for _, part in ipairs(string.split(path, ".")) do
		node = node[part]
	end

	local loaded = require(node)
	self.modules[path] = loaded
	return loaded
end

function LegacyRendererFactory:_wrap(id: string, kind: string, title: string, viewObject, options)
	local handle = {
		id = id,
		kind = kind,
		title = title,
		view = viewObject.Container or viewObject.Frame or viewObject,
		contentFrame = viewObject.Content or nil,
		_impl = viewObject,
		parentFrame = options.Parent,
		dispose = function(selfHandle)
			if selfHandle.view and selfHandle.view.Parent then
				selfHandle.view:Destroy()
			end
		end,
	}

	setmetatable(handle, {
		__index = function(_, key)
			local value = viewObject[key]
			if type(value) == "function" then
				return function(_, ...)
					return value(viewObject, ...)
				end
			end
			return value
		end,
	})

	if options.getPresetValue and options.applyPresetValue then
		handle.getPresetValue = options.getPresetValue
		handle.applyPresetValue = options.applyPresetValue
		self.presetRegistry:register(handle)
	end

	return handle
end

function LegacyRendererFactory:createNumberInput(config)
	local module = self:_require("elements.Basics.NumberInput")
	local view = module.new(config, self.theme, self.toolkit)
	return self:_wrap(config.Name or "NumberInput", "numberInput", config.Title or config.Name or "Number Input", view, {
		Parent = config.Parent,
		getPresetValue = function()
			return view:GetValue()
		end,
		applyPresetValue = function(value)
			view:SetValue(value, true)
		end,
	})
end

function LegacyRendererFactory:createRangeSlider(config)
	local module = self:_require("elements.Extended.RangeSlider")
	local view = module.new(config, self.theme, self.toolkit)
	return self:_wrap(config.Name or "RangeSlider", "rangeSlider", config.Title or config.Name or "Range Slider", view, {
		Parent = config.Parent,
		getPresetValue = function()
			local minValue, maxValue = view:GetValue()
			return { minValue, maxValue }
		end,
		applyPresetValue = function(value)
			view:SetValue(value, true)
		end,
	})
end

function LegacyRendererFactory:createMultiSelectDropdown(config)
	local module = self:_require("elements.Extended.MultiSelectDropdown")
	local view = module.new(config, self.theme, self.toolkit)
	return self:_wrap(config.Name or "MultiSelectDropdown", "multiSelectDropdown", config.Title or config.Name or "Multi Select", view, {
		Parent = config.Parent,
		getPresetValue = function()
			return view:GetValue()
		end,
		applyPresetValue = function(value)
			view:SetValue(value, true)
		end,
	})
end

function LegacyRendererFactory:createCodeBlock(config)
	local module = self:_require("elements.Basics.CodeBlock")
	local view = module.new(config, self.theme, self.toolkit)
	return self:_wrap(config.Name or "CodeBlock", "codeBlock", config.Title or config.Name or "Code", view, {
		Parent = config.Parent,
		getPresetValue = function()
			return view:GetText()
		end,
		applyPresetValue = function(value)
			view:SetText(tostring(value))
		end,
	})
end

function LegacyRendererFactory:createSubTabs(config)
	local module = self:_require("elements.Extended.SubTabs")
	local view = module.new(config, self.theme, self.toolkit)
	return self:_wrap(config.Name or "SubTabs", "subTabs", config.Name or "SubTabs", view, {
		Parent = config.Parent,
	})
end

function LegacyRendererFactory:createVirtualList(config)
	local module = self:_require("elements.Advanced.VirtualList")
	local view = module.new(config, self.theme, self.toolkit)
	return self:_wrap(config.Name or "VirtualList", "virtualList", config.Title or config.Name or "Virtual List", view, {
		Parent = config.Parent,
	})
end

function LegacyRendererFactory:createTreeView(config)
	local module = self:_require("elements.Advanced.TreeView")
	local view = module.new(config, self.theme, self.toolkit)
	return self:_wrap(config.Name or "TreeView", "treeView", config.Title or config.Name or "Tree View", view, {
		Parent = config.Parent,
		getPresetValue = function()
			return view:GetSelectedKey()
		end,
		applyPresetValue = function(value)
			view:SetValue(value, true)
		end,
	})
end

return LegacyRendererFactory
