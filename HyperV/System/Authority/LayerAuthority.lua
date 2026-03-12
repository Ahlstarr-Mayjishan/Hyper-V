--!strict

export type LayerCallback = (baseZIndex: number) -> ()

type SurfaceEntry = {
	id: string,
	priority: number,
	order: number,
	apply: LayerCallback,
}

local ROOT_Z_INDEX = 10
local SURFACE_GAP = 40

local LayerAuthority = {}
LayerAuthority.__index = LayerAuthority

local function sortEntries(left: SurfaceEntry, right: SurfaceEntry): boolean
	if left.priority == right.priority then
		return left.order < right.order
	end

	return left.priority < right.priority
end

local function applyBaseZIndex(instance: Instance, baseZIndex: number)
	if instance:IsA("GuiObject") then
		local stored = instance:GetAttribute("HyperVBaseZIndex")
		local source = if type(stored) == "number" then stored else instance.ZIndex
		if type(stored) ~= "number" then
			instance:SetAttribute("HyperVBaseZIndex", source)
		end
		instance.ZIndex = baseZIndex + source
	end

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			local stored = descendant:GetAttribute("HyperVBaseZIndex")
			local source = if type(stored) == "number" then stored else descendant.ZIndex
			if type(stored) ~= "number" then
				descendant:SetAttribute("HyperVBaseZIndex", source)
			end
			descendant.ZIndex = baseZIndex + source
		end
	end
end

function LayerAuthority.new()
	local self = setmetatable({}, LayerAuthority)
	self._surfaces = {} :: { [string]: SurfaceEntry }
	self._order = 0
	return self
end

function LayerAuthority:_nextOrder(): number
	self._order += 1
	return self._order
end

function LayerAuthority:_applyLayers()
	local entries = {}
	for _, entry in pairs(self._surfaces) do
		table.insert(entries, entry)
	end
	table.sort(entries, sortEntries)

	for index, entry in ipairs(entries) do
		entry.apply(ROOT_Z_INDEX + ((index - 1) * SURFACE_GAP))
	end
end

function LayerAuthority:registerSurface(id: string, priority: number, apply: LayerCallback): () -> ()
	self._surfaces[id] = {
		id = id,
		priority = priority,
		order = self:_nextOrder(),
		apply = apply,
	}
	self:_applyLayers()

	return function()
		self:unregisterSurface(id)
	end
end

function LayerAuthority:unregisterSurface(id: string)
	if self._surfaces[id] ~= nil then
		self._surfaces[id] = nil
		self:_applyLayers()
	end
end

function LayerAuthority:bringToFront(id: string)
	local entry = self._surfaces[id]
	if not entry then
		return
	end

	entry.order = self:_nextOrder()
	self:_applyLayers()
end

function LayerAuthority.applyGuiTreeZIndex(instance: Instance, baseZIndex: number)
	applyBaseZIndex(instance, baseZIndex)
end

return LayerAuthority
