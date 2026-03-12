--!strict

local function resolveLegacyRoot(fromInstance: Instance): Instance
	local current: Instance? = fromInstance

	while current do
		local parent = current.Parent
		if parent then
			local candidate = parent:FindFirstChild("Hyper V")
			if candidate then
				return candidate
			end
		end
		current = parent
	end

	error("HyperV could not resolve legacy root 'Hyper V' from current package layout")
end

return resolveLegacyRoot
