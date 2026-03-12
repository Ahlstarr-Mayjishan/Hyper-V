--!strict

export type ValidationResult = (boolean, string?)
export type Validator = (request: any) -> ValidationResult
export type MutationHandler = (request: any) -> any

type RuleEntry = {
	validate: Validator?,
}

local ProtectionGate = {}
ProtectionGate.__index = ProtectionGate

function ProtectionGate.new()
	local self = setmetatable({}, ProtectionGate)
	self._rules = {} :: { [string]: RuleEntry }
	return self
end

function ProtectionGate:register(domain: string, config: { validate: Validator? })
	self._rules[domain] = {
		validate = config.validate,
	}
end

function ProtectionGate:canExecute(domain: string, request: any): ValidationResult
	local rule = self._rules[domain]
	if not rule or not rule.validate then
		return true, nil
	end

	return rule.validate(request)
end

function ProtectionGate:execute(domain: string, request: any, handler: MutationHandler)
	local allowed, reason = self:canExecute(domain, request)
	if not allowed then
		return nil, reason or ("Denied by protection gate for " .. domain)
	end

	return handler(request), nil
end

return ProtectionGate
