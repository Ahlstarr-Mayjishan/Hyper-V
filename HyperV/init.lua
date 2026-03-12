--!strict

local App = require(script.App.App)
local HyperVAPI = require(script.Parent["Hyper V"].core.API.RayfieldAPI)
local GarbageCollector = require(script.Parent["Hyper V"].core.GarbageCollector.GarbageCollector)
local AnimationEngine = require(script.Parent["Hyper V"].core.Animation.AnimationEngine)

local HyperV = {}

-- Singleton instances
local _app = nil
local _api = nil
local _gc = nil
local _animation = nil

function HyperV.createApp(config)
	_app = App.new(config or {})
	_api = _app:getAPI()
	_gc = _app:getGC()
	_animation = AnimationEngine
	return _app
end

function HyperV:getAPI()
	if not _api and _app then
		_api = _app:getAPI()
	end
	return _api
end

function HyperV:getGC()
	if not _gc and _app then
		_gc = _app:getGC()
	end
	return _gc
end

function HyperV:getAnimation()
	if not _animation then
		_animation = AnimationEngine
	end
	return _animation
end

-- Aliases
HyperV.GetAPI = HyperV.getAPI
HyperV.GetGC = HyperV.getGC
HyperV.GetAnimation = HyperV.getAnimation

-- Direct exports for convenience
HyperV.Tween = function(...)
	return AnimationEngine.Tween(...)
end

HyperV.FadeIn = function(...)
	return AnimationEngine.FadeIn(...)
end

HyperV.FadeOut = function(...)
	return AnimationEngine.FadeOut(...)
end

HyperV.SlideIn = function(...)
	return AnimationEngine.SlideIn(...)
end

HyperV.Scale = function(...)
	return AnimationEngine.Scale(...)
end

HyperV.Shake = function(...)
	return AnimationEngine.Shake(...)
end

HyperV.Pulse = function(...)
	return AnimationEngine.Pulse(...)
end

HyperV.Bounce = function(...)
	return AnimationEngine.Bounce(...)
end

HyperV.Group = function(...)
	return AnimationEngine.Group(...)
end

HyperV.Sequence = function(...)
	return AnimationEngine.Sequence(...)
end

return HyperV
