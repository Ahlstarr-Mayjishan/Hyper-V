$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function New-Finding {
	param(
		[string]$Severity,
		[string]$File,
		[int]$Line,
		[string]$Rule,
		[string]$Message
	)

	[PSCustomObject]@{
		Severity = $Severity
		File = $File
		Line = $Line
		Rule = $Rule
		Message = $Message
	}
}

$findings = New-Object System.Collections.Generic.List[object]

function Add-Finding {
	param(
		[string]$Severity,
		[string]$File,
		[int]$Line,
		[string]$Rule,
		[string]$Message
	)

	$findings.Add((New-Finding -Severity $Severity -File $File -Line $Line -Rule $Rule -Message $Message))
}

function Get-RelativePath {
	param([string]$Path)

	$rootUri = New-Object System.Uri(($repoRoot.TrimEnd('\') + '\'))
	$fileUri = New-Object System.Uri($Path)
	$relativeUri = $rootUri.MakeRelativeUri($fileUri)
	return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('/', '\')
}

function Test-StyluaSyntax {
	param([string]$FilePath)

	$previousPreference = $ErrorActionPreference
	$ErrorActionPreference = "Continue"
	$raw = & stylua --check --color Never $FilePath 2>&1
	$ErrorActionPreference = $previousPreference
	$exitCode = $LASTEXITCODE
	$output = ($raw | Out-String).Trim()

	if ($exitCode -eq 0) {
		return
	}

	if ($output -match "parse_error" -or $output -match "^error:") {
		Add-Finding "error" (Get-RelativePath $FilePath) 0 "stylua-parse" $output
	}
}

function Scan-Patterns {
	param(
		[string]$FilePath,
		[string[]]$Lines
	)

	for ($index = 0; $index -lt $Lines.Length; $index++) {
		$lineNumber = $index + 1
		$line = $Lines[$index]
		$relative = Get-RelativePath $FilePath

		if ($line -match 'require\(script\.(types|pool|collectors|strategies)\.') {
			Add-Finding "error" $relative $lineNumber "bad-relative-require" "Use script.Parent for sibling folders under a ModuleScript."
		}

		if ($line -match 'require\(script\.[A-Za-z_][A-Za-z0-9_]*\)') {
			Add-Finding "warning" $relative $lineNumber "bare-script-require" "Bare require(script.X) is fragile in Rojo/Studio; verify X is a real child of the ModuleScript, not a sibling."
		}

		if ($line -match ':: \{string,') {
			Add-Finding "error" $relative $lineNumber "bad-dictionary-type" "Dictionary type syntax must use { [string]: T }."
		}

		if ($line -match '^\s*\(self :: any\)') {
			Add-Finding "warning" $relative $lineNumber "ambiguous-cast-statement" "Line starts with (self :: any); this has caused Luau parser ambiguity in Studio."
		}

		if ($line -match '^\s*self\.[A-Za-z_][A-Za-z0-9_]*\s*:\s*.+\s*=') {
			Add-Finding "error" $relative $lineNumber "invalid-field-annotation" "Roblox parser rejects field annotations like self.Field: Type = value; cast the value instead."
		}

		if ($line -match '\bEnum\.EasingDirection\.Loop\b') {
			Add-Finding "error" $relative $lineNumber "invalid-enum" "Enum.EasingDirection.Loop does not exist."
		}

		if ($line -match '\bGetAllBindings\b') {
			Add-Finding "error" $relative $lineNumber "unknown-controller-method" "GameController exposes GetBindings, not GetAllBindings."
		}

		if ($line -match '\bInputBegin\b') {
			Add-Finding "error" $relative $lineNumber "input-typo" "Possible typo: InputBegin should usually be InputBegan."
		}

		if ($line -match 'table\.sort\(.*function\(') {
			$windowEnd = [Math]::Min($index + 6, $Lines.Length - 1)
			$foundEnd = $false
			$foundBareClose = $false
			for ($probe = $index + 1; $probe -le $windowEnd; $probe++) {
				if ($Lines[$probe] -match 'end\)') {
					$foundEnd = $true
					break
				}
				if ($Lines[$probe] -match '^\s*\)\s*$') {
					$foundBareClose = $true
				}
			}
			if (-not $foundEnd -and $foundBareClose) {
				Add-Finding "error" $relative $lineNumber "table-sort-callback" "Possible missing 'end)' in table.sort callback."
			}
		}
	}
}

$allFiles = Get-ChildItem -Path $repoRoot -Recurse -File -Include *.lua,*.luau |
	Where-Object {
		$full = $_.FullName
		$full -notmatch '\\\.git\\' -and
		$full -notmatch '\\Hyper-V loader\\\.git\\'
	}

foreach ($file in $allFiles) {
	Test-StyluaSyntax -FilePath $file.FullName
	$lines = Get-Content $file.FullName
	Scan-Patterns -FilePath $file.FullName -Lines $lines
}

$errors = @($findings | Where-Object { $_.Severity -eq "error" })
$warnings = @($findings | Where-Object { $_.Severity -eq "warning" })

Write-Host ""
Write-Host "Hyper-V Preflight Check" -ForegroundColor Cyan
Write-Host "Root: $repoRoot"
Write-Host "Files scanned: $($allFiles.Count)"
Write-Host "Errors: $($errors.Count) | Warnings: $($warnings.Count)"
Write-Host ""

if ($findings.Count -gt 0) {
	$findings |
		Sort-Object Severity, File, Line |
		Format-Table Severity, File, Line, Rule, Message -AutoSize
	Write-Host ""
}

if ($errors.Count -gt 0) {
	exit 1
}

exit 0
