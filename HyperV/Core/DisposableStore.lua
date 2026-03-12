--!strict

local DisposableStore = {}
DisposableStore.__index = DisposableStore

export type Disposable =
	RBXScriptConnection | Instance | { dispose: (self: any) -> () } | { Dispose: (self: any) -> () } | { destroy: (self: any) -> () } | { Destroy: (self: any) -> () } | (() -> ())

export type DisposableStore = {
	add: (self: DisposableStore, disposable: Disposable?) -> Disposable?,
	cleanup: (self: DisposableStore) -> (),
}

function DisposableStore.new(): DisposableStore
	return setmetatable({
		_items = {},
	}, DisposableStore) :: any
end

function DisposableStore:add(disposable: Disposable?): Disposable?
	if disposable == nil then
		return nil
	end

	table.insert((self :: any)._items, disposable)
	return disposable
end

function DisposableStore:cleanup()
	local items = (self :: any)._items
	;(self :: any)._items = {}

	for index = #items, 1, -1 do
		local disposable = items[index]
		local kind = typeof(disposable)

		if kind == "RBXScriptConnection" then
			(disposable :: RBXScriptConnection):Disconnect()
		elseif kind == "Instance" then
			(disposable :: Instance):Destroy()
		elseif kind == "function" then
			(disposable :: () -> ())()
		elseif type(disposable) == "table" then
			local object = disposable :: any
			if type(object.dispose) == "function" then
				object:dispose()
			elseif type(object.Dispose) == "function" then
				object:Dispose()
			elseif type(object.destroy) == "function" then
				object:destroy()
			elseif type(object.Destroy) == "function" then
				object:Destroy()
			end
		end
	end
end

return DisposableStore
