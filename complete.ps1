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
	dotnet complete --position $cursorPosition $commandAst.ToString() | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, $_)
	}
}
#endregion

#region ssh
Register-ArgumentCompleter -CommandName ssh -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
	if ($commandAst.CommandElements.Count -eq 2 -and $wordToComplete -eq '' -or $commandAst.CommandElements.Count -gt 2) {
		return
	}
	$Local:ConfigFilePath = "~\.ssh\config"

	$Local:hosts = Select-String -Path $Local:ConfigFilePath -Pattern '^\s*Host\s+(\S+)' -AllMatches | ForEach-Object {
		$_.Matches[0].Groups[1].Value
	}

	$Local:hosts | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}
#endregion

#region gh
function __gh_debug {
	if ($env:BASH_COMP_DEBUG_FILE) {
		"$args" | Out-File -Append -FilePath "$env:BASH_COMP_DEBUG_FILE"
	}
}

filter __gh_escapeStringWithSpecialChars {
	$_ -replace '\s|#|@|\$|;|,|''|\{|\}|\(|\)|"|`|\||<|>|&', '`$&'
}

[scriptblock]${__ghCompleterBlock} = {
	param(
		$WordToComplete,
		$CommandAst,
		$CursorPosition
	)

	# Get the current command line and convert into a string
	$Command = $CommandAst.CommandElements
	$Command = "$Command"

	__gh_debug ""
	__gh_debug "========= starting completion logic =========="
	__gh_debug "WordToComplete: $WordToComplete Command: $Command CursorPosition: $CursorPosition"

	# The user could have moved the cursor backwards on the command-line.
	# We need to trigger completion from the $CursorPosition location, so we need
	# to truncate the command-line ($Command) up to the $CursorPosition location.
	# Make sure the $Command is longer then the $CursorPosition before we truncate.
	# This happens because the $Command does not include the last space.
	if ($Command.Length -gt $CursorPosition) {
		$Command = $Command.Substring(0, $CursorPosition)
	}
	__gh_debug "Truncated command: $Command"

	$ShellCompDirectiveError = 1
	$ShellCompDirectiveNoSpace = 2
	$ShellCompDirectiveNoFileComp = 4
	$ShellCompDirectiveFilterFileExt = 8
	$ShellCompDirectiveFilterDirs = 16
	$ShellCompDirectiveKeepOrder = 32

	# Prepare the command to request completions for the program.
	# Split the command at the first space to separate the program and arguments.
	$Program, $Arguments = $Command.Split(" ", 2)

	$RequestComp = "$Program __complete $Arguments"
	__gh_debug "RequestComp: $RequestComp"

	# we cannot use $WordToComplete because it
	# has the wrong values if the cursor was moved
	# so use the last argument
	if ($WordToComplete -ne "" ) {
		$WordToComplete = $Arguments.Split(" ")[-1]
	}
	__gh_debug "New WordToComplete: $WordToComplete"


	# Check for flag with equal sign
	$IsEqualFlag = ($WordToComplete -Like "--*=*" )
	if ( $IsEqualFlag ) {
		__gh_debug "Completing equal sign flag"
		# Remove the flag part
		$Flag, $WordToComplete = $WordToComplete.Split("=", 2)
	}

	if ( $WordToComplete -eq "" -And ( -Not $IsEqualFlag )) {
		# If the last parameter is complete (there is a space following it)
		# We add an extra empty parameter so we can indicate this to the go method.
		__gh_debug "Adding extra empty parameter"
		# PowerShell 7.2+ changed the way how the arguments are passed to executables,
		# so for pre-7.2 or when Legacy argument passing is enabled we need to use
		# `"`" to pass an empty argument, a "" or '' does not work!!!
		if ($PSVersionTable.PsVersion -lt [version]'7.2.0' -or
            ($PSVersionTable.PsVersion -lt [version]'7.3.0' -and -not [ExperimentalFeature]::IsEnabled("PSNativeCommandArgumentPassing")) -or
            (($PSVersionTable.PsVersion -ge [version]'7.3.0' -or [ExperimentalFeature]::IsEnabled("PSNativeCommandArgumentPassing")) -and
			$PSNativeCommandArgumentPassing -eq 'Legacy')) {
			$RequestComp = "$RequestComp" + ' `"`"'
		} else {
			$RequestComp = "$RequestComp" + ' ""'
		}
	}

	__gh_debug "Calling $RequestComp"
	# First disable ActiveHelp which is not supported for Powershell
	${env:GH_ACTIVE_HELP} = 0

	#call the command store the output in $out and redirect stderr and stdout to null
	# $Out is an array contains each line per element
	Invoke-Expression -OutVariable out "$RequestComp" 2>&1 | Out-Null

	# get directive from last line
	[int]$Directive = $Out[-1].TrimStart(':')
	if ($Directive -eq "") {
		# There is no directive specified
		$Directive = 0
	}
	__gh_debug "The completion directive is: $Directive"

	# remove directive (last element) from out
	$Out = $Out | Where-Object { $_ -ne $Out[-1] }
	__gh_debug "The completions are: $Out"

	if (($Directive -band $ShellCompDirectiveError) -ne 0 ) {
		# Error code.  No completion.
		__gh_debug "Received error from custom completion go code"
		return
	}

	$Longest = 0
	[Array]$Values = $Out | ForEach-Object {
		#Split the output in name and description
		$Name, $Description = $_.Split("`t", 2)
		__gh_debug "Name: $Name Description: $Description"

		# Look for the longest completion so that we can format things nicely
		if ($Longest -lt $Name.Length) {
			$Longest = $Name.Length
		}

		# Set the description to a one space string if there is none set.
		# This is needed because the CompletionResult does not accept an empty string as argument
		if (-Not $Description) {
			$Description = " "
		}
		@{Name = "$Name"; Description = "$Description" }
	}


	$Space = " "
	if (($Directive -band $ShellCompDirectiveNoSpace) -ne 0 ) {
		# remove the space here
		__gh_debug "ShellCompDirectiveNoSpace is called"
		$Space = ""
	}

	if ((($Directive -band $ShellCompDirectiveFilterFileExt) -ne 0 ) -or
       (($Directive -band $ShellCompDirectiveFilterDirs) -ne 0 )) {
		__gh_debug "ShellCompDirectiveFilterFileExt ShellCompDirectiveFilterDirs are not supported"

		# return here to prevent the completion of the extensions
		return
	}

	$Values = $Values | Where-Object {
		# filter the result
		$_.Name -like "$WordToComplete*"

		# Join the flag back if we have an equal sign flag
		if ( $IsEqualFlag ) {
			__gh_debug "Join the equal sign flag back to the completion value"
			$_.Name = $Flag + "=" + $_.Name
		}
	}

	# we sort the values in ascending order by name if keep order isn't passed
	if (($Directive -band $ShellCompDirectiveKeepOrder) -eq 0 ) {
		$Values = $Values | Sort-Object -Property Name
	}

	if (($Directive -band $ShellCompDirectiveNoFileComp) -ne 0 ) {
		__gh_debug "ShellCompDirectiveNoFileComp is called"

		if ($Values.Length -eq 0) {
			# Just print an empty string here so the
			# shell does not start to complete paths.
			# We cannot use CompletionResult here because
			# it does not accept an empty string as argument.
			""
			return
		}
	}

	# Get the current mode
	$Mode = (Get-PSReadLineKeyHandler | Where-Object { $_.Key -eq "Tab" }).Function
	__gh_debug "Mode: $Mode"

	$Values | ForEach-Object {

		# store temporary because switch will overwrite $_
		$comp = $_

		# PowerShell supports three different completion modes
		# - TabCompleteNext (default windows style - on each key press the next option is displayed)
		# - Complete (works like bash)
		# - MenuComplete (works like zsh)
		# You set the mode with Set-PSReadLineKeyHandler -Key Tab -Function <mode>

		# CompletionResult Arguments:
		# 1) CompletionText text to be used as the auto completion result
		# 2) ListItemText   text to be displayed in the suggestion list
		# 3) ResultType     type of completion result
		# 4) ToolTip        text for the tooltip with details about the object

		switch ($Mode) {

			# bash like
			"Complete" {

				if ($Values.Length -eq 1) {
					__gh_debug "Only one completion left"

					# insert space after value
					[System.Management.Automation.CompletionResult]::new($($comp.Name | __gh_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")

				} else {
					# Add the proper number of spaces to align the descriptions
					while ($comp.Name.Length -lt $Longest) {
						$comp.Name = $comp.Name + " "
					}

					# Check for empty description and only add parentheses if needed
					if ($($comp.Description) -eq " " ) {
						$Description = ""
					} else {
						$Description = "  ($($comp.Description))"
					}

					[System.Management.Automation.CompletionResult]::new("$($comp.Name)$Description", "$($comp.Name)$Description", 'ParameterValue', "$($comp.Description)")
				}
			}

			# zsh like
			"MenuComplete" {
				# insert space after value
				# MenuComplete will automatically show the ToolTip of
				# the highlighted value at the bottom of the suggestions.
				[System.Management.Automation.CompletionResult]::new($($comp.Name | __gh_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
			}

			# TabCompleteNext and in case we get something unknown
			Default {
				# Like MenuComplete but we don't want to add a space here because
				# the user need to press space anyway to get the completion.
				# Description will not be shown because that's not possible with TabCompleteNext
				[System.Management.Automation.CompletionResult]::new($($comp.Name | __gh_escapeStringWithSpecialChars), "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
			}
		}

	}
}

Register-ArgumentCompleter -CommandName 'gh' -ScriptBlock ${__ghCompleterBlock}
#endregion

#region zoxide
# =============================================================================
#
# Utility functions for zoxide.
#

# Call zoxide binary, returning the output as UTF-8.
function global:__zoxide_bin {
	$encoding = [Console]::OutputEncoding
	try {
		[Console]::OutputEncoding = [System.Text.Utf8Encoding]::new()
		$result = zoxide @args
		return $result
	} finally {
		[Console]::OutputEncoding = $encoding
	}
}

# pwd based on zoxide's format.
function global:__zoxide_pwd {
	$cwd = Get-Location
	if ($cwd.Provider.Name -eq "FileSystem") {
		$cwd.ProviderPath
	}
}

# cd + custom logic based on the value of _ZO_ECHO.
function global:__zoxide_cd($dir, $literal) {
	$dir = if ($literal) {
		Set-Location -LiteralPath $dir -Passthru -ErrorAction Stop
	} else {
		if ($dir -eq '-' -and ($PSVersionTable.PSVersion -lt 6.1)) {
			Write-Error "cd - is not supported below PowerShell 6.1. Please upgrade your version of PowerShell."
		} elseif ($dir -eq '+' -and ($PSVersionTable.PSVersion -lt 6.2)) {
			Write-Error "cd + is not supported below PowerShell 6.2. Please upgrade your version of PowerShell."
		} else {
			Set-Location -Path $dir -Passthru -ErrorAction Stop
		}
	}
}

# =============================================================================
#
# Hook configuration for zoxide.
#

# Hook to add new entries to the database.
$global:__zoxide_oldpwd = __zoxide_pwd
function global:__zoxide_hook {
	$result = __zoxide_pwd
	if ($result -ne $global:__zoxide_oldpwd) {
		if ($null -ne $result) {
			zoxide add "--" $result
		}
		$global:__zoxide_oldpwd = $result
	}
}

# Initialize hook.
$global:__zoxide_hooked = (Get-Variable __zoxide_hooked -ErrorAction SilentlyContinue -ValueOnly)
if ($global:__zoxide_hooked -ne 1) {
	$global:__zoxide_hooked = 1
	$global:__zoxide_prompt_old = $function:prompt

	function global:prompt {
		if ($null -ne $__zoxide_prompt_old) {
			& $__zoxide_prompt_old
		}
		$null = __zoxide_hook
	}
}

# =============================================================================
#
# When using zoxide with --no-cmd, alias these internal functions as desired.
#

# Jump to a directory using only keywords.
function global:__zoxide_z {
	if ($args.Length -eq 0) {
		__zoxide_cd ~ $true
	} elseif ($args.Length -eq 1 -and ($args[0] -eq '-' -or $args[0] -eq '+')) {
		__zoxide_cd $args[0] $false
	} elseif ($args.Length -eq 1 -and (Test-Path $args[0] -PathType Container)) {
		__zoxide_cd $args[0] $true
	} else {
		$result = __zoxide_pwd
		if ($null -ne $result) {
			$result = __zoxide_bin query --exclude $result "--" @args
		} else {
			$result = __zoxide_bin query "--" @args
		}
		if ($LASTEXITCODE -eq 0) {
			__zoxide_cd $result $true
		}
	}
}

# Jump to a directory using interactive search.
function global:__zoxide_zi {
	$result = __zoxide_bin query -i "--" @args
	if ($LASTEXITCODE -eq 0) {
		__zoxide_cd $result $true
	}
}

# =============================================================================
#
# Commands for zoxide. Disable these using --no-cmd.
#

Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force

# =============================================================================
#
# To initialize zoxide, add this to your configuration (find it by running
# `echo $profile` in PowerShell):
#
# Invoke-Expression (& { (zoxide init powershell | Out-String) })
#endregion
