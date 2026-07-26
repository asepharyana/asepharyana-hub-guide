# install.ps1 — code-guide plugin installer for Claude Code (Windows)
#
# Usage:
#   .\install.ps1                  # Install to %USERPROFILE%\.claude\skills\
#   .\install.ps1 -Link           # Symlink (PowerShell Admin/Dev mode)

param(
  [switch]$Link
)

$PluginName = "code-guide"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetDir = Join-Path $env:USERPROFILE ".claude\skills"
$PluginDir = Join-Path $TargetDir $PluginName

Write-Host "code-guide installer" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

if ($Link) {
  Write-Host "  symlink mode"
  Remove-Item -Path $PluginDir -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType SymbolicLink -Path $PluginDir -Target $ScriptDir -Force | Out-Null
  Write-Host "  (symlink — edits in this repo are live)"
} else {
  Write-Host "  copy mode"
  Remove-Item -Path $PluginDir -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item -Path $ScriptDir -Destination $PluginDir -Recurse -Force
}

Write-Host ""
Write-Host "Done. Restart Claude Code or run /reload."
Write-Host "Skills auto-trigger. Hooks auto-load from hooks/hooks.json."
