--!strict

local ResolvedState = {}

function ResolvedState.getVisualConfig(snapshot)
	return {
		transparency = snapshot.transparency,
		highlight = snapshot.highlight,
		trail = snapshot.trail,
		particles = snapshot.particles,
		forceField = snapshot.forceField,
		sound = snapshot.sound,
		charms = snapshot.charms,
	}
end

function ResolvedState.resolve(snapshot, runtime)
	return {
		visual = ResolvedState.getVisualConfig(snapshot),
		espBox = {
			bounds = runtime.projectedBounds,
			config = snapshot.espBox,
		},
		espInfo = {
			bounds = runtime.projectedBounds,
			config = snapshot.espInfo,
			characterName = runtime.characterName,
			distance = runtime.distance,
			healthText = runtime.healthText,
		},
		tracer = {
			bounds = runtime.projectedBounds,
			config = snapshot.tracer,
		},
	}
end

return ResolvedState
