# generate completion script instead of calling executable directly

Push-Location $PSScriptRoot

zoxide init powershell > zoxide.ps1
starship init powershell > starship.ps1
uv generate-shell-completion powershell > uv.ps1
komac complete powershell > komac.ps1

Pop-Location
