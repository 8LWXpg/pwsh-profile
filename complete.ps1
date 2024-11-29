#region winget
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
	$Local:word = $wordToComplete.Replace('"', '""')
	$Local:ast = $commandAst.ToString().Replace('"', '""')
	winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}
#endregion

#region dotnet
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
	dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}
#endregion

#region ssh
Register-ArgumentCompleter -CommandName ssh -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
	if ($commandAst.CommandElements.Count -eq 2 -and $wordToComplete -eq '' -or $commandAst.CommandElements.Count -gt 2) {
		return
	}
	$Local:ConfigFilePath = '~\.ssh\config'

	$Local:hosts = Select-String -Path $Local:ConfigFilePath -Pattern '^\s*Host\s+(\S+)' -AllMatches | ForEach-Object {
		$_.Matches[0].Groups[1].Value
	}

	$Local:hosts | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}
#endregion
