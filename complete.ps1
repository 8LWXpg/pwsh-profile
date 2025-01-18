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

Invoke-Expression ((gh completion -s powershell) -join "`n")
Invoke-Expression ((zoxide init powershell) -join "`n")
Invoke-Expression ((starship init powershell --print-full-init) -join "`n")
Invoke-Expression ((uv generate-shell-completion powershell) -join "`n")
