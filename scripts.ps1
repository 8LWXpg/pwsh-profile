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

# nvim: switch to nvim cwd after exit
function nvim {
	$tmp = [System.IO.Path]::GetTempFileName()
	$env:NVIM_LAST_DIR_FILE = $tmp
	nvim.exe @args
	$cwd = Get-Content -Path $tmp
	if (-not [string]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
		Set-Location -LiteralPath $cwd
	}
	Remove-Item $tmp
}
Set-Alias vi nvim

function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
