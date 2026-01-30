#region winget
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
	winget complete --word "$wordToComplete" --commandline "$commandAst" --position $cursorPosition | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_)
	}
}
#endregion

#region dotnet
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
	dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_)
	}
}
#endregion

. 'C:\Program Files\Packages\BurntSushi.ripgrep.MSVC_Microsoft.Winget.Source_8wekyb3d8bbwe\ripgrep-15.1.0-x86_64-pc-windows-msvc\complete\_rg.ps1'
. 'C:\Program Files\Packages\sharkdp.fd_Microsoft.Winget.Source_8wekyb3d8bbwe\fd-v10.3.0-x86_64-pc-windows-msvc\autocomplete\fd.ps1'

$env:CARAPACE_EXCLUDES = 'vi,vim,nvim'
$env:CARAPACE_NOSPACE = '*'
$env:CARAPACE_TOOLTIP = 1
Set-PSReadLineOption -Colors @{ 'Selection' = "`e[7m" }
(carapace _carapace) -join "`n" | Invoke-Expression
