# sudo
function sudo {
	begin {
		function convertToBase64EncodedString([string]$cmdLine) {
			[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($cmdLine))
		}
	}
	end {
		switch ($args[0]) {
			$null {
				sudo.exe pwsh -nol
				break
			}
			'!!' {
				$encoded = convertToBase64EncodedString "$(Get-History -c 1)"
				sudo.exe pwsh -e $encoded
				break
			}
			{ $_ -is [scriptblock] } {
				$encoded = convertToBase64EncodedString $_
				sudo.exe pwsh -e $encoded
				break
			}
			{ Get-Command $_ -Type Application -ErrorAction Ignore } {
				# pass as-is for native command
				sudo.exe $args
				break
			}
			{ Get-Command $_ -Type Cmdlet, ExternalScript, Alias -ErrorAction Ignore } {
				$encoded = convertToBase64EncodedString "$args"
				sudo.exe pwsh -e $encoded
				break
			}
			default {
				throw "Cannot find '$_'"
			}
		}
	}
}

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

Import-Module PSFzf

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
Get-ChildItem $ProfileFolder\generated -Exclude generate.ps1, gh.ps1 | ForEach-Object { & $_.FullName }
. $ProfileFolder\generated\gh.ps1
Remove-Variable ProfileFolder
