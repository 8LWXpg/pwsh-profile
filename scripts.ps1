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

# uv with system
function uvs {
	uv $args --system
}

function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }