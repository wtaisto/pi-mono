# Install pi (fork: wtaisto/pi-mono) from GitHub Releases.
#
# Usage (one-liner):
#   irm https://raw.githubusercontent.com/wtaisto/pi-mono/main/install.ps1 | iex
#
# Parameters can also be passed via env vars: PI_VERSION, PI_INSTALL_DIR, PI_REPO.

[CmdletBinding()]
param(
    [string]$Version    = $(if ($env:PI_VERSION)     { $env:PI_VERSION }     else { 'latest' }),
    [string]$InstallDir = $(if ($env:PI_INSTALL_DIR) { $env:PI_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'Programs\pi' }),
    [string]$Repo       = $(if ($env:PI_REPO)        { $env:PI_REPO }        else { 'wtaisto/pi-mono' })
)

$ErrorActionPreference = 'Stop'

if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'Only 64-bit Windows is supported.'
}

$archive = 'pi-windows-x64.zip'
$url = if ($Version -eq 'latest') {
    "https://github.com/$Repo/releases/latest/download/$archive"
} else {
    "https://github.com/$Repo/releases/download/$Version/$archive"
}

Write-Host "==> Downloading $url"

$tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "pi-install-$(Get-Random)")
try {
    $zip = Join-Path $tmp.FullName $archive
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

    Write-Host '==> Extracting'
    if (Test-Path $InstallDir) {
        Remove-Item -Recurse -Force $InstallDir
    }
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
    Expand-Archive -Path $zip -DestinationPath $InstallDir -Force

    Write-Host "==> Installed pi to $InstallDir"

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $pathEntries = if ($userPath) { $userPath -split ';' } else { @() }
    if ($pathEntries -notcontains $InstallDir) {
        $newPath = if ($userPath) { "$userPath;$InstallDir" } else { $InstallDir }
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Host "==> Added $InstallDir to user PATH (open a new shell to pick it up)"
    } else {
        Write-Host "==> $InstallDir already on user PATH"
    }

    Write-Host ''
    try { & (Join-Path $InstallDir 'pi.exe') --version } catch {}
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
