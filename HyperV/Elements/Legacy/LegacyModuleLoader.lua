--!strict

local LEGACY_MODULE_PATHS = {
	numberInput = { "elements", "Basics", "NumberInput" },
	rangeSlider = { "elements", "Extended", "RangeSlider" },
	multiSelectDropdown = { "elements", "Extended", "MultiSelectDropdown" },
	codeBlock = { "elements", "Basics", "CodeBlock" },
	subTabs = { "elements", "Extended", "SubTabs" },
	virtualList = { "elements", "Advanced", "VirtualList" },
	treeView = { "elements", "Advanced", "TreeView" },
}

export type ModuleKey =
	"numberInput"
	| "rangeSlider"
	| "multiSelectDropdown"
	| "codeBlock"
	| "subTabs"
	| "virtualList"
	| "treeView"

type LegacyModuleLoader = {
	legacyRoot: Instance,
	_cache: { [ModuleKey]: any },
	requireModule: (self: LegacyModuleLoader, moduleKey: ModuleKey) -> any,
}

local LegacyModuleLoader = {}
LegacyModuleLoader.__index = LegacyModuleLoader

function LegacyModuleLoader.new(legacyRoot: Instance): LegacyModuleLoader
	return setmetatable({
		legacyRoot = legacyRoot,
		_cache = {},
	}, LegacyModuleLoader) :: any
end

function LegacyModuleLoader:requireModule(moduleKey: ModuleKey)
	local cached = self._cache[moduleKey]
	if cached ~= nil then
		return cached
	end

	local path = LEGACY_MODULE_PATHS[moduleKey]
	assert(path ~= nil, ("Unknown legacy module key: %s"):format(moduleKey))

	local node: any = self.legacyRoot
	for _, part in ipairs(path) do
		node = node[part]
	end

	local loaded = require(node)
	self._cache[moduleKey] = loaded
	return loaded
end

return LegacyModuleLoader
