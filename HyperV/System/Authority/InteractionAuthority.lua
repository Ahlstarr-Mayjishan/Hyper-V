--!strict

export type ClaimConfig = {
	id: string,
	priority: number?,
	allowSteal: boolean?,
}

type ActiveClaim = {
	id: string,
	priority: number,
	allowSteal: boolean,
	sequence: number,
}

type FocusClaim = {
	id: string,
	priority: number,
	sequence: number,
}

local InteractionAuthority = {}
InteractionAuthority.__index = InteractionAuthority

function InteractionAuthority.new()
	local self = setmetatable({}, InteractionAuthority)
	self._claims = {} :: { [string]: ActiveClaim }
	self._focus = nil :: FocusClaim?
	self._sequence = 0
	return self
end

function InteractionAuthority:_nextSequence(): number
	self._sequence += 1
	return self._sequence
end

function InteractionAuthority:tryAcquire(domain: string, config: ClaimConfig): boolean
	local nextPriority = config.priority or 0
	local existing = self._claims[domain]

	if existing and existing.id ~= config.id then
		if not config.allowSteal then
			return false
		end

		if nextPriority < existing.priority then
			return false
		end
	end

	self._claims[domain] = {
		id = config.id,
		priority = nextPriority,
		allowSteal = config.allowSteal == true,
		sequence = self:_nextSequence(),
	}
	return true
end

function InteractionAuthority:release(domain: string, claimantId: string)
	local existing = self._claims[domain]
	if existing and existing.id == claimantId then
		self._claims[domain] = nil
	end
end

function InteractionAuthority:isOwner(domain: string, claimantId: string): boolean
	local existing = self._claims[domain]
	return existing ~= nil and existing.id == claimantId
end

function InteractionAuthority:requestFocus(config: ClaimConfig): boolean
	local nextPriority = config.priority or 0
	local existing = self._focus

	if existing and existing.id ~= config.id and nextPriority < existing.priority then
		return false
	end

	self._focus = {
		id = config.id,
		priority = nextPriority,
		sequence = self:_nextSequence(),
	}
	return true
end

function InteractionAuthority:releaseFocus(claimantId: string)
	if self._focus and self._focus.id == claimantId then
		self._focus = nil
	end
end

function InteractionAuthority:getFocusedId(): string?
	return if self._focus then self._focus.id else nil
end

function InteractionAuthority:clearOwner(claimantId: string)
	for domain, claim in pairs(self._claims) do
		if claim.id == claimantId then
			self._claims[domain] = nil
		end
	end

	self:releaseFocus(claimantId)
end

return InteractionAuthority
