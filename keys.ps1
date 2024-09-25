using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace Microsoft.PowerShell

# This key handler shows the entire or filtered history using Out-ConsoleGridView. The
# typed text is used as the substring pattern for filtering. A selected command
# is inserted to the command line without invoking. Multiple command selection
# is supported, e.g. selected by Ctrl + Click.

Set-PSReadLineKeyHandler -Key '"', "'" `
	-BriefDescription SmartInsertQuote `
	-LongDescription "Insert paired quotes if not already in a quote" `
	-ScriptBlock {
	param($key, $arg)

	$quote = $key.KeyChar

	$selectionStart = $null
	$selectionLength = $null
	[PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

	$line = $null
	$cursor = $null
	[PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	# If text is selected, just quote it without any smarts
	if ($selectionStart -ne -1) {
		[PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
		[PSConsoleReadLine]::SetCursorPosition($cursor + 1)
		return
	}

	$ast = $null
	$tokens = $null
	$parseErrors = $null
	[PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

	function FindToken {
		param($tokens, $cursor)

		foreach ($token in $tokens) {
			if ($cursor -lt $token.Extent.StartOffset) { continue }
			if ($cursor -lt $token.Extent.EndOffset) {
				$result = $token
				$token = $token -as [StringExpandableToken]
				if ($token) {
					$nested = FindToken $token.NestedTokens $cursor
					if ($nested) { $result = $nested }
				}

				return $result
			}
		}
		return $null
	}

	$token = FindToken $tokens $cursor

	# If we're on or inside a **quoted** string token (so not generic), we need to be smarter
	if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
		# If we're at the start of the string, assume we're inserting a new string
		if ($token.Extent.StartOffset -eq $cursor) {
			[PSConsoleReadLine]::Insert("$quote$quote ")
			[PSConsoleReadLine]::SetCursorPosition($cursor + 1)
			return
		}

		# If we're at the end of the string, move over the closing quote if present.
		if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
			[PSConsoleReadLine]::SetCursorPosition($cursor + 1)
			return
		}
	}

	if ($null -eq $token -or
		$token.Kind -eq [TokenKind]::RParen -or $token.Kind -eq [TokenKind]::RCurly -or $token.Kind -eq [TokenKind]::RBracket) {
		if ($line[0..$cursor].Where{ $_ -eq $quote }.Count % 2 -eq 1) {
			# Odd number of quotes before the cursor, insert a single quote
			[PSConsoleReadLine]::Insert($quote)
		} else {
			# Insert matching quotes, move cursor to be in between the quotes
			[PSConsoleReadLine]::Insert("$quote$quote")
			[PSConsoleReadLine]::SetCursorPosition($cursor + 1)
		}
		return
	}

	[PSConsoleReadLine]::Insert($quote)
}

Set-PSReadLineKeyHandler -Key '(', '{', '[' `
	-BriefDescription InsertPairedBraces `
	-LongDescription "Insert matching braces" `
	-ScriptBlock {
	param($key, $arg)

	[char]$closeChar = switch ($key.KeyChar) {
		'(' { ')' }
		'{' { '}' }
		'[' { ']' }
	}

	$selectionStart = $null
	$selectionLength = $null
	[PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

	$line = $null
	$cursor = $null
	[PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($selectionStart -ne -1) {
		# Text is selected, wrap it in brackets
		[PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
		[PSConsoleReadLine]::SetCursorPosition($cursor + 1)
	} else {
		# No text is selected, insert a pair
		[PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
		[PSConsoleReadLine]::SetCursorPosition($cursor + 1)
	}
}

Set-PSReadLineKeyHandler -Key ')', ']', '}' `
	-BriefDescription SmartClosingBrace `
	-LongDescription "Insert matching brace or move cursor past existing one" `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($line[$cursor] -eq $key.KeyChar) {
		[PSConsoleReadLine]::SetCursorPosition($cursor + 1)
	} else {
		[PSConsoleReadLine]::Insert($key.KeyChar)
	}
}

Set-PSReadLineKeyHandler -Key 'BackSpace' `
	-BriefDescription DeletePair `
	-LongDescription "Delete matching brace or quote" `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($cursor -lt $line.Length -and $cursor -gt 0 -and $line.Substring($cursor - 1, 2) -in "''", '""', '()', '[]', '{}') {
		[PSConsoleReadLine]::Delete($cursor - 1, 2)
	} else {
		[PSConsoleReadLine]::BackwardDeleteChar()
	}
}
