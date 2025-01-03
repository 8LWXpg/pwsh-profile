# prevent loading profile in scripts
$temp = ([System.Environment]::GetCommandLineArgs())
if ($temp.Count -gt 1 -and
	$temp -notcontains '-NoExit' -and
	$temp -notcontains '-NoLogo' -and
	$temp -notcontains '-noe' -and
	$temp -notcontains '-nol') {
	return
}
Remove-Variable temp

Import-Module Terminal-Icons
Import-Module Microsoft.WinGet.CommandNotFound
Import-Module PSFzf

Set-PSReadLineOption -PredictionSource History -EditMode Windows -HistoryNoDuplicates
if ($Host.UI.RawUI.WindowSize.Height -lt 15 -or $Host.UI.RawUI.WindowSize.Width -lt 54) {
	Set-PSReadLineOption -PredictionViewStyle InlineView
} else {
	Set-PSReadLineOption -PredictionViewStyle ListView
}
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r' -EnableAliasFuzzySetLocation

Set-PSReadLineKeyHandler -Chord Ctrl+d -Function DeleteCharOrExit

$ProfileFolder = 'E:\ps1\profile'
. "$ProfileFolder\keys.ps1"
. "$ProfileFolder\scripts.ps1"
. "$ProfileFolder\complete.ps1"
Get-ChildItem $ProfileFolder\generated -Exclude generate.ps1 | ForEach-Object { . $_.FullName }
Remove-Variable ProfileFolder
