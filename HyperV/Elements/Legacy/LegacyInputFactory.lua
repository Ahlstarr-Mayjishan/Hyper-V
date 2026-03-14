--!strict

local LegacyInputFactory = {}

function LegacyInputFactory.createNumberInput(factory, config)
	return factory:_createHandle("numberInput", config, {
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

function LegacyInputFactory.createRangeSlider(factory, config)
	return factory:_createHandle("rangeSlider", config, {
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

function LegacyInputFactory.createMultiSelectDropdown(factory, config)
	return factory:_createHandle("multiSelectDropdown", config, {
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

function LegacyInputFactory.createCodeBlock(factory, config)
	return factory:_createHandle("codeBlock", config, {
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

return LegacyInputFactory
