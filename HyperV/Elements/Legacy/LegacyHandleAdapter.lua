--!strict

type MethodBindingMap = { [string]: string }

export type LegacyHandle = {
	id: string,
	kind: string,
	title: string,
	view: Instance,
	contentFrame: Instance?,
	parentFrame: Instance?,
	dispose: (self: LegacyHandle) -> (),
	getPresetValue: (() -> any)?,
	applyPresetValue: ((value: any) -> ())?,
	[string]: any,
}

export type PresetSpec = {
	getValue: (viewObject: any) -> any,
	applyValue: (viewObject: any, value: any) -> (),
}?

export type HandleSpec = {
	id: string,
	kind: string,
	title: string,
	viewObject: any,
	parentFrame: Instance?,
	methods: MethodBindingMap?,
	preset: PresetSpec,
}

type PresetRegistryLike = {
	register: (self: PresetRegistryLike, handle: LegacyHandle) -> (),
}

local LegacyHandleAdapter = {}

local function bindMethod(viewObject: any, methodName: string)
	local method = viewObject[methodName]
	assert(type(method) == "function", ("Missing legacy method: %s"):format(methodName))

	return function(_: any, ...)
		return method(viewObject, ...)
	end
end

function LegacyHandleAdapter.create(spec: HandleSpec, presetRegistry: PresetRegistryLike?): LegacyHandle
	local view = spec.viewObject.Container or spec.viewObject.Frame or spec.viewObject
	local handle = {
		id = spec.id,
		kind = spec.kind,
		title = spec.title,
		view = view,
		contentFrame = spec.viewObject.Content or nil,
		parentFrame = spec.parentFrame,
		dispose = function(selfHandle: LegacyHandle)
			if selfHandle.view and selfHandle.view.Parent then
				selfHandle.view:Destroy()
			end
		end,
	} :: LegacyHandle

	for publicName, methodName in pairs(spec.methods or {}) do
		handle[publicName] = bindMethod(spec.viewObject, methodName)
	end

	if spec.preset then
		handle.getPresetValue = function()
			return spec.preset.getValue(spec.viewObject)
		end
		handle.applyPresetValue = function(value: any)
			spec.preset.applyValue(spec.viewObject, value)
		end

		if presetRegistry then
			presetRegistry:register(handle)
		end
	end

	return handle
end

return LegacyHandleAdapter
