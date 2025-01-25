# generate completion script instead of calling executable directly

Set-Location $PSScriptRoot
Push-Location

gh completion -s powershell > gh.ps1
zoxide init powershell > zoxide.ps1
starship init powershell --print-full-init > starship.ps1
uv generate-shell-completion powershell > uv.ps1

Pop-Location