<#
Repo audit script — prints a quick overview of repository health and patterns to check.
Run in project root with PowerShell.
#>

Write-Host "Repository audit starting..."

Write-Host "Finding archive files (.zip, .rbxm, .rbxmx, .rbx)"
Get-ChildItem -Path . -Recurse -Include *.zip,*.rbxm,*.rbxmx,*.rbx -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_.FullName }

Write-Host "\nChecking for Remotes references in scripts (Attack, CombatEvent, UseSkill, RequestDodge)"
Select-String -Path .\src\**\*.lua -Pattern 'CombatEvent|Attack|UseSkill|RequestDodge' -SimpleMatch -List | ForEach-Object { Write-Host $_.Filename ':' $_.LineNumber ':' $_.Line }

Write-Host "\nSearching for WaitForChild risks (literal strings)"
Select-String -Path .\src\**\*.lua -Pattern 'WaitForChild\(' -SimpleMatch | ForEach-Object { Write-Host $_.Filename ':' $_.LineNumber ':' $_.Line }

Write-Host "\nListing ServerScriptService files"
Get-ChildItem -Path .\src\ServerScriptService -Recurse -File | ForEach-Object { Write-Host $_.FullName }

Write-Host "\nAudit complete. Suggest running: git status ; git add . ; git commit -m 'chore: repo audit run'"
