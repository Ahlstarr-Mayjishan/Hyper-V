--!strict

export type LayoutSpec = {
	Name: string,
	WindowCorner: number,
	TitleBarHeight: number,
	TitleTextSize: number,
	ContentInset: number,
	TabBarHeight: number,
	TabButtonWidth: number,
	TabButtonHeight: number,
	SectionGap: number,
}

local layouts: { [string]: LayoutSpec } = {
	Default = {
		Name = "Default",
		WindowCorner = 10,
		TitleBarHeight = 42,
		TitleTextSize = 15,
		ContentInset = 10,
		TabBarHeight = 30,
		TabButtonWidth = 120,
		TabButtonHeight = 24,
		SectionGap = 8,
	},
	Cripware = {
		Name = "Cripware",
		WindowCorner = 4,
		TitleBarHeight = 30,
		TitleTextSize = 13,
		ContentInset = 8,
		TabBarHeight = 26,
		TabButtonWidth = 110,
		TabButtonHeight = 22,
		SectionGap = 6,
	},
}

local LayoutSpecs = {}

function LayoutSpecs.get(name: string?): LayoutSpec
	return layouts[name or "Default"] or layouts.Default
end

function LayoutSpecs.list(): { [string]: LayoutSpec }
	return layouts
end

return LayoutSpecs
