--!strict

export type SurfaceKind = "window" | "modal" | "commandPalette" | "characterPreview" | "surface"

export type IntentType =
	"surface.register"
	| "surface.unregister"
	| "surface.activate"
	| "preview.patch"
	| "preview.set"
	| "preview.reset"
	| "preview.commit"
	| "preview.target"
	| "dock.attach"
	| "dock.detach"

export type BrainIntent = {
	type: IntentType,
	sourceId: string?,
	surfaceId: string?,
	priority: number?,
	kind: SurfaceKind?,
	title: string?,
	surface: any?,
	patch: any?,
	config: any?,
	snapshot: any?,
	model: Model?,
	handleId: string?,
	targetId: string?,
	apply: ((BrainIntent) -> any)?,
}

export type BrainCommand = {
	type: string,
	payload: any,
}

return nil
