# install.ps1 — hub-guide plugin installer for Claude Code (Windows)
#
# Usage:
#   .\install.ps1                  # Install to %USERPROFILE%\.claude\plugins\
#   .\install.ps1 -Project       # Install to .claude\plugins\ (project-scoped)
#   .\install.ps1 -Link          # Symlink (PowerShell Admin/Dev mode)
#   .\install.ps1 -NoHooks       # Skills only
#   .\install.ps1 clean-code testing  # Install specific skills

param(
  [switch]$Project,
  [switch]$Link,
  [switch]$NoHooks,
  [Parameter(Position=0, ValueFromRemainingArguments=$true)]
  [string[]]$SkillFilter
)

$PluginName = "hub-guide"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Determine target
if ($Project) {
  $TargetDir = Join-Path (Get-Location) ".claude\plugins"
} else {
  $TargetDir = Join-Path $env:USERPROFILE ".claude\plugins"
}

$PluginDir = Join-Path $TargetDir $PluginName

Write-Host "📐 hub-guide installer" -ForegroundColor Cyan

# Ensure target exists
New-Item -ItemType Directory -Force -Path $PluginDir | Out-Null

# Install manifest
Copy-Item -Path (Join-Path $ScriptDir ".claude-plugin") -Destination $PluginDir -Recurse -Force

# Install hooks
if (-not $NoHooks) {
  Write-Host "  hooks/ → $PluginDir\hooks\"
  if ($Link) {
    New-Item -ItemType SymbolicLink -Path "$PluginDir\hooks" -Target (Join-Path $ScriptDir "hooks") -Force | Out-Null
  } else {
    Copy-Item -Path (Join-Path $ScriptDir "hooks") -Destination $PluginDir -Recurse -Force
  }
}

# Install skills
if ($SkillFilter.Count -gt 0) {
  $SkillDir = Join-Path $PluginDir "skills"
  New-Item -ItemType Directory -Force -Path $SkillDir | Out-Null
  foreach ($skill in $SkillFilter) {
    $skillName = Split-Path $skill -Leaf
    $src = Join-Path $ScriptDir "skills" $skillName
    if (Test-Path $src) {
      Write-Host "  skills/$skillName/ → $SkillDir"
      if ($Link) {
        New-Item -ItemType SymbolicLink -Path (Join-Path $SkillDir $skillName) -Target $src -Force | Out-Null
      } else {
        Copy-Item -Path $src -Destination $SkillDir -Recurse -Force
      }
    } else {
      Write-Host "  ⚠️  Skill '$skillName' not found at $src" -ForegroundColor Yellow
    }
  }
} else {
  Write-Host "  skills/ (all) → $PluginDir\skills\"
  if ($Link) {
    New-Item -ItemType SymbolicLink -Path (Join-Path $PluginDir "skills") -Target (Join-Path $ScriptDir "skills") -Force | Out-Null
  } else {
    Copy-Item -Path (Join-Path $ScriptDir "skills") -Destination $PluginDir -Recurse -Force
  }
}

Write-Host ""
Write-Host "✅ hub-guide installed to $PluginDir" -ForegroundColor Green
if ($Link) {
  Write-Host "   (symlink — edits in this repo are live)"
}
Write-Host ""
Write-Host "   Restart Claude Code or run /reload to activate."
Write-Host "   Skills auto-trigger when you work — no commands needed."
