<#
.SYNOPSIS
  Bootstrap the centralized coding-agent configuration on native Windows.
.EXAMPLE
  .\install.ps1
  .\install.ps1 -Agent claude
  .\install.ps1 -ProfileName backend          # core + backend-spring + data-platform
  .\install.ps1 -Bundles core,backend-spring -DryRun
  .\install.ps1 -NoCodegraph                  # skip the codegraph code-index MCP server
.NOTES
  Copies config (symlinks on Windows need admin/developer mode). Idempotent:
  re-run after `git pull`. Mirrors install.sh. Profiles come from profiles.conf;
  -Bundles overrides a profile. Per-skill/subagent/command filtering (the
  harness.selection categories other than `profile`) is not yet supported here.
#>
[CmdletBinding()]
param(
  [string[]] $Agent,
  [string[]] $Bundles,
  [string]   $ProfileName,
  [switch]   $NoCodegraph,
  [switch]   $DryRun
)
$Codegraph = -not $NoCodegraph

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Log($m)  { Write-Host "[harness] $m" -ForegroundColor Blue }
function Ok($m)   { Write-Host "[harness] $m" -ForegroundColor Green }
function Warn($m) { Write-Warning "[harness] $m" }

function Backup-Path($p) {
  if (Test-Path $p) {
    Warn "backing up $p -> $p.bak.$Stamp"
    if (-not $DryRun) { Move-Item -Force $p "$p.bak.$Stamp" }
  }
}
function Copy-Into($src, $dst) {
  $parent = Split-Path -Parent $dst
  if (-not (Test-Path $parent)) { if (-not $DryRun) { New-Item -ItemType Directory -Force $parent | Out-Null } }
  Backup-Path $dst
  if ($DryRun) { Write-Host "  would copy $src -> $dst" } else { Copy-Item -Recurse -Force $src $dst }
}

# Merge a single MCP server entry into a JSON config file under $topKey.
# Idempotent: the entry is (re)written each run; unrelated config is preserved.
function Merge-McpJson($file, $topKey, $name, $value) {
  if ($DryRun) { Write-Host "  would add MCP server '$name' to $file ($topKey)"; return }
  $parent = Split-Path -Parent $file
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force $parent | Out-Null }
  $cfg = @{}
  if (Test-Path $file) {
    try { $cfg = Get-Content -Raw $file | ConvertFrom-Json -AsHashtable } catch { $cfg = @{} }
    if ($null -eq $cfg) { $cfg = @{} }
  }
  if (-not ($cfg[$topKey] -is [hashtable])) { $cfg[$topKey] = @{} }
  $cfg[$topKey][$name] = $value
  ($cfg | ConvertTo-Json -Depth 32) | Set-Content -Encoding UTF8 $file
  Ok "added MCP server '$name' to $file"
}

# codegraph code-index MCP server is wired into each agent below; warn once if
# the binary isn't installed (we never auto-download it).
function Test-Codegraph {
  if (Get-Command codegraph -ErrorAction SilentlyContinue) { return }
  Warn "codegraph not on PATH - the code-index MCP server is configured but won't start until you install it: 'irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex' (or 'npx @colbymchenry/codegraph'), then run 'codegraph init -i' in each repo. https://github.com/colbymchenry/codegraph"
}

# --- read selection manifest (only the `profile` line is honored here) -------
function Resolve-Profile($want) {
  $pf = Join-Path $RepoRoot 'profiles.conf'
  if (-not (Test-Path $pf)) { throw "profiles.conf not found; cannot resolve -ProfileName $want" }
  $names = @()
  foreach ($line in Get-Content $pf) {
    $line = ($line -replace '#.*$', '').Trim()
    if (-not $line) { continue }
    $tok = $line -split '\s+'
    $names += $tok[0]
    if ($tok[0] -eq $want) { return $tok[1..($tok.Count - 1)] }
  }
  throw "unknown profile '$want'. Available: $($names -join ', ')"
}

$ManifestProfile = ''
$SelectionFile = if ($env:HARNESS_SELECTION) { $env:HARNESS_SELECTION } else { Join-Path $RepoRoot 'harness.selection' }
if (Test-Path $SelectionFile) {
  Log "selection: $SelectionFile"
  $sawFilter = $false
  foreach ($line in Get-Content $SelectionFile) {
    $line = ($line -replace '#.*$', '').Trim()
    if (-not $line) { continue }
    $tok = $line -split '\s+'
    switch ($tok[0]) {
      'profile'   { if ($tok.Count -ge 2) { $ManifestProfile = $tok[1] } }
      'skills'    { $sawFilter = $true }
      'subagents' { $sawFilter = $true }
      'commands'  { $sawFilter = $true }
    }
  }
  if ($sawFilter) { Warn "skills/subagents/commands filters in $SelectionFile are ignored on Windows (install.ps1 installs all of those); use install.sh for fine-grained selection" }
}

# --- resolve bundles (explicit -Bundles > profile > all) ---------------------
$wantProfile = if ($ProfileName) { $ProfileName } elseif ($ManifestProfile) { $ManifestProfile } else { '' }
if ($Bundles) {
  if ($wantProfile) { Warn "-Bundles given; ignoring profile '$wantProfile'" }
} elseif ($wantProfile) {
  $Bundles = Resolve-Profile $wantProfile
  Log "profile: $wantProfile"
} else {
  $Bundles = Get-ChildItem -Directory (Join-Path $RepoRoot 'bundles') | ForEach-Object { $_.Name }
}
Log "bundles: $($Bundles -join ', ')"

# --- resolve agents ----------------------------------------------------------
if (-not $Agent) {
  $Agent = @()
  foreach ($a in 'claude','codex','opencode','antigravity') {
    if (Get-Command $a -ErrorAction SilentlyContinue) { $Agent += $a }
  }
  if (-not $Agent) { Warn "no agent on PATH; defaulting to all four"; $Agent = @('claude','codex','opencode','antigravity') }
}
Log "agents: $($Agent -join ', ')"
if ($DryRun) { Warn "dry-run: no files will be changed" }
if ($Codegraph) { Test-Codegraph }

function Assemble-Rules($outFile) {
  $lines = @('<!-- BEGIN harness-managed rules. Generated by install.ps1; edits here are overwritten. -->',
             '# Engineering rules (centralized)', '')
  foreach ($b in $Bundles) {
    $rdir = Join-Path $RepoRoot "bundles/$b/rules"
    if (Test-Path $rdir) {
      foreach ($f in Get-ChildItem -File "$rdir/*.md") {
        $lines += "<!-- source: bundles/$b/$($f.Name) -->"
        $lines += (Get-Content -Raw $f.FullName)
        $lines += ''
      }
    }
  }
  $lines += '<!-- END harness-managed rules. -->'
  if ($DryRun) { Write-Host "  would write assembled rules -> $outFile" ; return }
  $parent = Split-Path -Parent $outFile
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force $parent | Out-Null }
  Backup-Path $outFile
  $lines -join "`n" | Set-Content -Encoding UTF8 $outFile
  Ok "wrote $outFile"
}

function Copy-BundleArtifacts($base, $agentsSub, $commandsSub) {
  foreach ($b in $Bundles) {
    $bd = Join-Path $RepoRoot "bundles/$b"
    if ($agentsSub -and (Test-Path "$bd/agents")) {
      foreach ($f in Get-ChildItem -File "$bd/agents/*.md") { Copy-Into $f.FullName (Join-Path $base "$agentsSub/$b-$($f.Name)") }
    }
    if ($commandsSub -and (Test-Path "$bd/commands")) {
      foreach ($f in Get-ChildItem -File "$bd/commands/*.md") { Copy-Into $f.FullName (Join-Path $base "$commandsSub/$b-$($f.Name)") }
    }
  }
}

function Install-Claude {
  $base = Join-Path $HOME '.claude'
  Assemble-Rules (Join-Path $base 'CLAUDE.md')
  Copy-BundleArtifacts $base 'agents' 'commands'
  foreach ($b in $Bundles) {
    $sk = Join-Path $RepoRoot "bundles/$b/skills"
    if (Test-Path $sk) { foreach ($d in Get-ChildItem -Directory $sk) { Copy-Into $d.FullName (Join-Path $base "skills/$($d.Name)") } }
  }
  $hsrc = Join-Path $RepoRoot 'bundles/core/hooks'
  if (Test-Path $hsrc) {
    foreach ($f in Get-ChildItem -File "$hsrc/*.sh") { Copy-Into $f.FullName (Join-Path $base "harness/hooks/$($f.Name)") }
    Warn "hooks copied to $base\harness\hooks; on Windows they need Git Bash/WSL to execute. Add them to $base\settings.json under hooks.PostToolUse/Stop."
  }
  if ($Codegraph) { Merge-McpJson (Join-Path $HOME '.claude.json') 'mcpServers' 'codegraph' @{ type = 'stdio'; command = 'codegraph'; args = @('serve', '--mcp') } }
  Ok "Claude Code configured at $base"
  Write-Host "  Native marketplace alternative: claude plugin marketplace add <internal-gitlab-url>/coding-agent-harness-setup"
}

function Install-Codex {
  $base = Join-Path $HOME '.codex'
  Assemble-Rules (Join-Path $base 'AGENTS.md')
  Copy-BundleArtifacts $base $null 'prompts'
  $block = Join-Path $RepoRoot 'adapters/codex/config.toml'
  if (Test-Path $block) { Copy-Into $block (Join-Path $base 'config.harness.toml'); Warn "review $base\config.harness.toml and merge into config.toml" }
  if ($Codegraph) {
    $h = Join-Path $base 'config.harness.toml'
    if ($DryRun) { Write-Host "  would add codegraph MCP server to $h" }
    elseif (-not ((Test-Path $h) -and (Select-String -Quiet -SimpleMatch '[mcp_servers.codegraph]' $h))) {
      Add-Content -Path $h -Value "`n[mcp_servers.codegraph]`ncommand = `"codegraph`"`nargs = [`"serve`", `"--mcp`"]"
      Ok "added codegraph MCP server to $h"
    }
  }
  Ok "Codex CLI configured at $base"
}

function Test-OpenCodeLsp {
  foreach ($b in $Bundles) {
    switch ($b) {
      'frontend-nextjs' {
        if (-not (Get-Command typescript-language-server -ErrorAction SilentlyContinue)) {
          Warn "LSP: 'typescript-language-server' not on PATH - TS/JS intellisense in OpenCode will be inactive (npm i -g typescript-language-server typescript)"
        }
      }
      'backend-spring' {
        if (-not (Get-Command jdtls -ErrorAction SilentlyContinue)) {
          Warn "LSP: 'jdtls' not on PATH - Java intellisense in OpenCode will be inactive (install Eclipse JDT language server)"
        }
      }
    }
  }
}

function Install-OpenCode {
  $base = Join-Path $HOME '.config/opencode'
  Assemble-Rules (Join-Path $base 'AGENTS.md')
  Copy-BundleArtifacts $base 'agent' 'command'

  # superpowers plugin: must be a symlink so the plugin's `../../skills` lookup
  # still resolves to the vendored skills dir (a plain copy would break that).
  $spPlugin = Join-Path $RepoRoot 'vendor/superpowers/.opencode/plugins/superpowers.js'
  if (Test-Path $spPlugin) {
    $dst = Join-Path $base 'plugin/superpowers.js'
    if ($DryRun) {
      Write-Host "  would link $spPlugin -> $dst"
    } else {
      $pdir = Split-Path -Parent $dst
      if (-not (Test-Path $pdir)) { New-Item -ItemType Directory -Force $pdir | Out-Null }
      try {
        if (Test-Path $dst) { Remove-Item -Force $dst }
        New-Item -ItemType SymbolicLink -Path $dst -Target $spPlugin -Force | Out-Null
        Ok "linked superpowers plugin -> $dst"
      } catch {
        Warn "could not symlink superpowers plugin (Windows symlinks need Developer Mode or admin). Enable it and re-run, or add the git-backed plugin spec from vendor/superpowers/.opencode/INSTALL.md to opencode.json."
      }
    }
  }

  Test-OpenCodeLsp

  $tmpl = Join-Path $RepoRoot 'adapters/opencode/opencode.json'
  if (Test-Path $tmpl) { Copy-Into $tmpl (Join-Path $base 'opencode.harness.json'); Warn "merge opencode.harness.json into opencode.json (set the format hook path)" }
  if ($Codegraph) { Merge-McpJson (Join-Path $base 'opencode.json') 'mcp' 'codegraph' @{ type = 'local'; command = @('codegraph', 'serve', '--mcp'); enabled = $true } }
  Ok "OpenCode configured at $base"
}

function Install-Antigravity {
  # Gemini-CLI-based: rules -> ~/.gemini/GEMINI.md (shared with Gemini CLI),
  # skills -> ~/.gemini/antigravity/skills (native SKILL.md format).
  $base = Join-Path $HOME '.gemini'
  Assemble-Rules (Join-Path $base 'GEMINI.md')
  foreach ($b in $Bundles) {
    $sk = Join-Path $RepoRoot "bundles/$b/skills"
    if (Test-Path $sk) { foreach ($d in Get-ChildItem -Directory $sk) { Copy-Into $d.FullName (Join-Path $base "antigravity/skills/$($d.Name)") } }
  }
  if ($Codegraph) { Merge-McpJson (Join-Path $base 'settings.json') 'mcpServers' 'codegraph' @{ command = 'codegraph'; args = @('serve', '--mcp') } }
  Ok "Antigravity CLI configured at $base (rules: GEMINI.md, skills: antigravity\skills)"
}

foreach ($a in $Agent) {
  switch ($a) {
    'claude'      { Log 'configuring claude ...';      Install-Claude }
    'codex'       { Log 'configuring codex ...';       Install-Codex }
    'opencode'    { Log 'configuring opencode ...';    Install-OpenCode }
    'antigravity' { Log 'configuring antigravity ...'; Install-Antigravity }
    default       { Warn "no module for agent '$a'; skipping" }
  }
}
Ok "done. Re-run after 'git pull' to update."
