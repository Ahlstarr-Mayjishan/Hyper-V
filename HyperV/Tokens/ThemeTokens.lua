--!strict

export type Theme = {
	Name: string,
	Default: Color3,
	Main: Color3,
	Second: Color3,
	Accent: Color3,
	Text: Color3,
	TitleText: Color3,
	SecondText: Color3,
	Border: Color3,
	Success: Color3,
	Warning: Color3,
	Error: Color3,
}

local themes: { [string]: Theme } = {
	Default = {
		Name = "Default",
		Default = Color3.fromRGB(34, 35, 40),
		Main = Color3.fromRGB(24, 25, 29),
		Second = Color3.fromRGB(45, 48, 56),
		Accent = Color3.fromRGB(84, 160, 255),
		Text = Color3.fromRGB(220, 224, 232),
		TitleText = Color3.fromRGB(245, 247, 250),
		SecondText = Color3.fromRGB(150, 156, 170),
		Border = Color3.fromRGB(63, 67, 78),
		Success = Color3.fromRGB(40, 175, 95),
		Warning = Color3.fromRGB(232, 174, 73),
		Error = Color3.fromRGB(220, 82, 82),
	},
}

local ThemeTokens = {}

function ThemeTokens.getTheme(name: string?): Theme
	return themes[name or "Default"] or themes.Default
end

function ThemeTokens.createTheme(name: string, overrides: { [string]: any }): Theme
	local base = ThemeTokens.getTheme("Default")
	local nextTheme = table.clone(base) :: any
	for key, value in pairs(overrides) do
		nextTheme[key] = value
	end
	nextTheme.Name = name
	themes[name] = nextTheme
	return nextTheme
end

return ThemeTokens
