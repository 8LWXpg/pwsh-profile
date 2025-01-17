# open folder with Explorer
function e {
	param (
		[Parameter(ValueFromPipeline, Mandatory)]
		[string]$path
	)
	explorer.exe (Resolve-Path $path).Path
}

# yazi
function yy {
	$tmp = [System.IO.Path]::GetTempFileName()
	yazi $args --cwd-file="$tmp"
	$cwd = Get-Content -Path $tmp
	if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
		Set-Location -LiteralPath $cwd
	}
	Remove-Item -Path $tmp
}

# sudo
function sudo {
	begin {
		function convertToBase64EncodedString([string]$cmdLine) {
			[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($cmdLine))
		}
	}
	end {
		switch ($args[0]) {
			{ $_ -is [scriptblock] } {
				$encoded = convertToBase64EncodedString $_
				sudo.exe pwsh -e $encoded
			}
			{ Get-Command $_ -Type Application -ErrorAction Ignore } {
				# pass as-is for native command
				sudo.exe $args
			}
			{ Get-Command $_ -Type Cmdlet, ExternalScript, Alias -ErrorAction Ignore } {
				$encoded = convertToBase64EncodedString "$args"
				sudo.exe pwsh -e $encoded
			}
			'!!' {
				$encoded = convertToBase64EncodedString "$(Get-History -c 1)"
				sudo.exe pwsh -e $encoded
			}
			default {
				throw "Cannot find '$_'"
			}
		}
	}
}

function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }