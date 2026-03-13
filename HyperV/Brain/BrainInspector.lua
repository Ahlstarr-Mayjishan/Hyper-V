--!strict

local RunService = game:GetService("RunService")

local BrainInspector = {}
BrainInspector.__index = BrainInspector

local function collectBlockedReasons(history)
	local blocked = {}
	for _, entry in ipairs(history) do
		if not entry.allowed then
			local reason = tostring(entry.reason or "unknown")
			blocked[reason] = (blocked[reason] or 0) + 1
		end
	end
	return blocked
end

local function collectSurfaceSummary(snapshot)
	local summary = {}
	for _, surface in pairs(snapshot.surfaces) do
		local kind = tostring(surface.kind or "surface")
		local entry = summary[kind]
		if not entry then
			entry = {
				total = 0,
				visible = 0,
			}
			summary[kind] = entry
		end
		entry.total += 1
		if surface.visible then
			entry.visible += 1
		end
	end
	return summary
end

local function collectIntentDomainSummary(history)
	local summary = {}
	for _, entry in ipairs(history) do
		local intent = entry.intent or {}
		local intentType = tostring(intent.type or "unknown")
		local domain = string.match(intentType, "^(.-)%.") or intentType
		local bucket = summary[domain]
		if not bucket then
			bucket = {
				total = 0,
				blocked = 0,
			}
			summary[domain] = bucket
		end
		bucket.total += 1
		if not entry.allowed then
			bucket.blocked += 1
		end
	end
	return summary
end

local function collectBlockedIntents(history)
	local blocked = {}
	for _, entry in ipairs(history) do
		if not entry.allowed then
			local intent = entry.intent or {}
			table.insert(blocked, string.format(
				"%s from %s -> %s",
				tostring(intent.type or "unknown"),
				tostring(intent.sourceId or "unknown"),
				tostring(entry.reason or "unknown")
			))
		end
	end
	return blocked
end

local function collectStaleSurfaces(app, snapshot)
	local staleBrainOnly = {}
	local staleHandleOnly = {}
	local handles = app._surfaceHandles or {}

	for id in pairs(snapshot.surfaces) do
		if handles[id] == nil then
			table.insert(staleBrainOnly, id)
		end
	end

	for id in pairs(handles) do
		if snapshot.surfaces[id] == nil then
			table.insert(staleHandleOnly, id)
		end
	end

	table.sort(staleBrainOnly)
	table.sort(staleHandleOnly)
	return staleBrainOnly, staleHandleOnly
end

local function formatState(app, brain)
	local snapshot = brain:getStateSnapshot()
	local authority = brain:getAuthoritySnapshot()
	local diagnostics = brain.getDiagnosticsSnapshot and brain:getDiagnosticsSnapshot() or nil
	local cleanupLog = app and app._surfaceMaintenanceLog or nil
	local cleanupHistory = app and app._surfaceMaintenanceHistory or nil
	local surfaceSummary = collectSurfaceSummary(snapshot)
	local lines = {
		"Focused Surface: " .. tostring(snapshot.focusedSurfaceId or "none"),
		"Active Modal: " .. tostring(snapshot.activeModalId or "none"),
		"",
		"Registered Surfaces:",
	}

	local surfaceCount = 0
	for id, surface in pairs(snapshot.surfaces) do
		surfaceCount += 1
		table.insert(lines, string.format("- %s [%s] visible=%s", id, tostring(surface.kind), tostring(surface.visible)))
	end

	if surfaceCount == 0 then
		table.insert(lines, "- none")
	end

	table.insert(lines, "")
	table.insert(lines, "Surface Summary:")
	if next(surfaceSummary) == nil then
		table.insert(lines, "- none")
	else
		for kind, info in pairs(surfaceSummary) do
			table.insert(lines, string.format("- %s: total=%d visible=%d", kind, info.total, info.visible))
		end
	end

	table.insert(lines, "")
	table.insert(lines, "Authority Claims:")
	if authority.focus then
		table.insert(lines, string.format("- focus: %s (p=%s)", authority.focus.id, tostring(authority.focus.priority)))
	else
		table.insert(lines, "- focus: none")
	end
	local hasClaims = false
	for domain, claim in pairs(authority.claims) do
		hasClaims = true
		table.insert(lines, string.format("- %s: %s (p=%s)", domain, claim.id, tostring(claim.priority)))
	end
	if not hasClaims then
		table.insert(lines, "- claims: none")
	end

	local history = brain:getLastIntents(10)
	local blockedReasons = collectBlockedReasons(history)
	local blockedIntents = collectBlockedIntents(history)
	local domainSummary = collectIntentDomainSummary(history)
	table.insert(lines, "")
	table.insert(lines, "Blocked Reasons:")
	if next(blockedReasons) == nil then
		table.insert(lines, "- none")
	else
		for reason, count in pairs(blockedReasons) do
			table.insert(lines, string.format("- %s x%d", reason, count))
		end
	end

	if diagnostics then
		table.insert(lines, "")
		table.insert(lines, "Policy Diagnostics:")
		if next(diagnostics.policyCounts) == nil then
			table.insert(lines, "- none")
		else
			for policyCode, count in pairs(diagnostics.policyCounts) do
				table.insert(lines, string.format("- %s x%d", tostring(policyCode), count))
			end
		end
	end

	table.insert(lines, "")
	table.insert(lines, "Intent Domains:")
	if next(domainSummary) == nil then
		table.insert(lines, "- none")
	else
		for domain, info in pairs(domainSummary) do
			table.insert(lines, string.format("- %s: total=%d blocked=%d", domain, info.total, info.blocked))
		end
	end

	table.insert(lines, "")
	table.insert(lines, "Blocked Intents:")
	if #blockedIntents == 0 then
		table.insert(lines, "- none")
	else
		for _, entry in ipairs(blockedIntents) do
			table.insert(lines, "- " .. entry)
		end
	end

	table.insert(lines, "")
	table.insert(lines, "Recent Intents:")
	if #history == 0 then
		table.insert(lines, "- none")
	else
		for _, entry in ipairs(history) do
			local intentType = entry.intent and entry.intent.type or "unknown"
			local status = if entry.allowed then "ok" else ("blocked: " .. tostring(entry.reason))
			table.insert(lines, string.format("- %s (%s)", tostring(intentType), status))
		end
	end

	if app then
		local staleBrainOnly, staleHandleOnly = collectStaleSurfaces(app, snapshot)
		table.insert(lines, "")
		table.insert(lines, "Stale Surfaces:")
		if #staleBrainOnly == 0 and #staleHandleOnly == 0 then
			table.insert(lines, "- none")
		else
			for _, id in ipairs(staleBrainOnly) do
				table.insert(lines, "- brain-only: " .. id)
			end
			for _, id in ipairs(staleHandleOnly) do
				table.insert(lines, "- handle-only: " .. id)
			end
		end

		table.insert(lines, "")
		table.insert(lines, "Cleanup Activity:")
		if cleanupLog then
			table.insert(lines, string.format("- lastRunAt: %.2f", cleanupLog.lastRunAt or 0))
			table.insert(lines, string.format("- handleOnlyRemoved: %d", cleanupLog.handleOnlyRemoved or 0))
			table.insert(lines, string.format("- brainOnlyRemoved: %d", cleanupLog.brainOnlyRemoved or 0))
		else
			table.insert(lines, "- none")
		end

		table.insert(lines, "")
		table.insert(lines, "Cleanup History:")
		if cleanupHistory and #cleanupHistory > 0 then
			for _, entry in ipairs(cleanupHistory) do
				table.insert(lines, string.format(
					"- %.2f h=%d b=%d",
					entry.lastRunAt or 0,
					entry.handleOnlyRemoved or 0,
					entry.brainOnlyRemoved or 0
				))
			end
		else
			table.insert(lines, "- none")
		end
	end

	if snapshot.activeModalId then
		table.insert(lines, "")
		table.insert(lines, "Policy Conflicts:")
		table.insert(lines, "- modal blocks: surface.activate, surface.open, preview.*, dock.*")
	end

	return table.concat(lines, "\n")
end

function BrainInspector.new(app)
	local self = setmetatable({}, BrainInspector)
	self._app = app
	self._window = app:createDetachedWindow({
		Id = "BrainInspector",
		Name = "BrainInspector",
		Title = "Brain Inspector",
		Size = Vector2.new(460, 380),
	})

	local label = Instance.new("TextLabel")
	label.Name = "BrainInspectorText"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -16, 1, -16)
	label.Position = UDim2.new(0, 8, 0, 8)
	label.Font = Enum.Font.Code
	label.TextSize = 14
	label.TextColor3 = app.theme.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = false
	label.TextScaled = false
	label.RichText = false
	label.Text = ""
	label.Parent = self._window.contentFrame
	self._label = label

	self._connection = RunService.Heartbeat:Connect(function()
		if self._window.view.Visible then
			self._label.Text = formatState(app, app:getBrain())
		end
	end)

	self._label.Text = formatState(app, app:getBrain())
	return self
end

function BrainInspector:open()
	self._window:open()
	self._label.Text = formatState(self._app, self._app:getBrain())
end

function BrainInspector:close()
	self._window:close()
end

function BrainInspector:dispose()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	self._window:dispose()
end

return BrainInspector
