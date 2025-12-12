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

$env:CARAPACE_EXCLUDES = 'vi,vim,nvim'
$env:CARAPACE_NOSPACE = '*'
$env:CARAPACE_TOOLTIP = 1
Set-PSReadLineOption -Colors @{ 'Selection' = "`e[7m" }
(carapace _carapace) -join "`n" | Invoke-Expression
