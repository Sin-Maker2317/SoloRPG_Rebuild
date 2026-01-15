<#
Generate a lightweight smoke report.json based on repository artifacts.
This is a filesystem-side report (not runtime). It scans Net.lua for remotes and Workspace folder structure.
Run from project root in PowerShell: `.	emplates\generate_smoke_report.ps1` or `pwsh .\scripts\generate_smoke_report.ps1`
#>

$out = @{ generated = (Get-Date).ToString(); remotes = @(); workspace = @{ enemies = $false } }

$netFile = Join-Path -Path . -ChildPath 'src\ReplicatedStorage\Shared\Net.lua'
if (Test-Path $netFile) {
    $lines = Get-Content $netFile
    foreach ($l in $lines) {
        if ($l -match 'Net\.(\w+)\s*=\s*"(\w+)"') {
            $name = $matches[2]
            $out.remotes += $name
        }
    }
}

$enemiesFolder = Join-Path -Path . -ChildPath 'src\Workspace\Enemies'
$out.workspace.enemies = Test-Path $enemiesFolder

$json = $out | ConvertTo-Json -Depth 5
$dest = Join-Path -Path . -ChildPath 'tmp_backup\smoke_report.json'
New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
Set-Content -Path $dest -Value $json -Force
Write-Host "Smoke report written to" $dest
