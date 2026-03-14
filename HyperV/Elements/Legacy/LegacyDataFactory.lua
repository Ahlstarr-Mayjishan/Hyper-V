--!strict

local LegacyDataFactory = {}

function LegacyDataFactory.createSubTabs(factory, config)
	return factory:_createHandle("subTabs", config, {
		id = config.Name or "SubTabs",
		kind = "subTabs",
		title = config.Name or "SubTabs",
		methods = {
			select = "Select",
			getTab = "GetTab",
		},
	})
end

function LegacyDataFactory.createVirtualList(factory, config)
	return factory:_createHandle("virtualList", config, {
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

function LegacyDataFactory.createTreeView(factory, config)
	return factory:_createHandle("treeView", config, {
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

return LegacyDataFactory
