#Requires -Version 7.0
# ==============================================================================
# Memory Setup — per-user local memory database for the MCP memory server.
# Windows / PowerShell 7 counterpart of scripts/memory-setup.sh.
# ==============================================================================
# Detects the GitHub/user identity, picks a local (never committed) location for
# the knowledge-graph file, writes MEMORY_FILE_PATH into ~/.agent/.env, ensures
# the PowerShell profile loads that .env, and optionally migrates a legacy
# repo-tracked memory.jsonl into the new per-user location.
#
# Usage:
#   pwsh -File scripts/memory-setup.ps1              # interactive (defaults on non-TTY)
#   pwsh -File scripts/memory-setup.ps1 -NonInteractive   # use defaults, never prompt
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'

$REPO_DIR = Split-Path -Parent $PSScriptRoot
$ENV_FILE = Join-Path $REPO_DIR '.env'
$INTERACTIVE = (-not $NonInteractive) -and (-not [Console]::IsInputRedirected) -and (-not [Console]::IsOutputRedirected)

function Prompt-Value {
    # Prompt-Value <message> <default> ; returns the chosen value
    param([string]$Message, [string]$Default)
    if (-not $INTERACTIVE) { return $Default }
    $answer = Read-Host "${Message} [${Default}]"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return $answer
}

function Confirm-Choice {
    # Confirm-Choice <message> <default_yes and/n> ; returns $true if yes
    param([string]$Message, [string]$Default)
    if (-not $INTERACTIVE) { return ($Default -in @('and', 'Y')) }
    $answer = Read-Host "${Message} (and/n) [${Default}]"
    if ([string]::IsNullOrWhiteSpace($answer)) { $answer = $Default }
    return ($answer -in @('and', 'Y'))
}

function Sanitize-Name {
    # sanitize a user id into a safe [a-z0-9-] slug
    param([string]$Value)
    ($Value.ToLowerInvariant() -replace '[^a-z0-9]', '-' -replace '-+', '-').Trim('-')
}

# --- 1. Detect user ----------------------------------------------------------
function Detect-User {
    $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghCmd) {
        $login = (& gh api user -q .login 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $login) { return $login }
    }
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $name = (& git config --get user.name 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $name) { return $name }
    }
    return $env:USERNAME
}

$USER_SLUG = Sanitize-Name (Detect-User)
if ([string]::IsNullOrWhiteSpace($USER_SLUG)) {
    Write-Error "❌ No se pudo detectar el user of the system."
    exit 1
}
Write-Host "👤 Detected user: ${USER_SLUG}"

# --- 2. Pick memory location -------------------------------------------------
$DEFAULT_MEM_FILE = (Join-Path $HOME ".local\share\opencode\memory\${USER_SLUG}.jsonl").Replace('\', '/')

$MEM_FILE = $null
if (-not [string]::IsNullOrWhiteSpace($env:MEMORY_FILE_PATH)) {
    # Respect an already-set value (from environment)
    $MEM_FILE = $env:MEMORY_FILE_PATH
    Write-Host "ℹ️  Usando MEMORY_FILE_PATH existing: ${MEM_FILE}"
} elseif (Test-Path -LiteralPath $ENV_FILE) {
    # Respect a value already persisted in .env (idempotent re-run)
    $envMatch = [System.Text.RegularExpressions.Regex]::Match(
        [System.IO.File]::ReadAllText($ENV_FILE), '(?m)^\s*MEMORY_FILE_PATH=(.*?)\s*$')
    if ($envMatch.Success -and -not [string]::IsNullOrWhiteSpace($envMatch.Groups[1].Value)) {
        $MEM_FILE = $envMatch.Groups[1].Value.Trim().Trim('"')
        Write-Host "ℹ️  Usando MEMORY_FILE_PATH de ${ENV_FILE}: ${MEM_FILE}"
    }
}
if (-not $MEM_FILE) {
    $MEM_FILE = Prompt-Value "Ubicacion de la memory local de '${USER_SLUG}'?" $DEFAULT_MEM_FILE
    # expand leading ~ if provided
    if ($MEM_FILE -like '~*') { $MEM_FILE = $HOME + $MEM_FILE.Substring(1) }
}

# opencode substitutes {env:MEMORY_FILE_PATH} verbatim (no JSON escaping), so a
# Windows path with backslashes would produce invalid JSON escape sequences and
# fail with "config/opencode.jsonc is not valid JSON(C)". Forward slashes are valid on
# Windows (PowerShell, .NET and Node all accept them), so we normalize here.
$MEM_FILE = $MEM_FILE.Replace('\', '/')

$MEM_DIR = Split-Path -Parent $MEM_FILE
try {
    New-Item -ItemType Directory -Path $MEM_DIR -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Warning "Could not create '${MEM_DIR}': $($_.Exception.Message). Usando la location by default."
    $MEM_FILE = $DEFAULT_MEM_FILE
    $MEM_DIR = Split-Path -Parent $MEM_FILE
    New-Item -ItemType Directory -Path $MEM_DIR -Force | Out-Null
}

# --- 3. Write MEMORY_FILE_PATH into ~/.agent/.env ---------------------------
function Set-EnvValue {
    # Replaces KEY=... (LF or CRLF, anywhere in the file) or appends it.
    # Uses a MatchEvaluator so '$' or '\' inside $Value stay literal.
    param([string]$File, [string]$Key, [string]$Value)

    $text = ''
    if (Test-Path -LiteralPath $File) {
        $text = [System.IO.File]::ReadAllText($File)
    }
    $pattern = '(?m)^[ \t]*' + [System.Text.RegularExpressions.Regex]::Escape($Key) + '=.*?$'
    $regex = [System.Text.RegularExpressions.Regex]::new($pattern)
    $present = $regex.IsMatch($text)
    $evaluator = [System.Text.RegularExpressions.MatchEvaluator] { param($match) "${Key}=${Value}" }

    if ($present) {
        $newText = $regex.Replace($text, $evaluator)
    } else {
        # key not present: append
        $newText = $text
        if ($newText.Length -gt 0 -and -not $newText.EndsWith("`n")) { $newText += "`n" }
        $newText += "${Key}=${Value}`n"
    }

    [System.IO.File]::WriteAllText($File, $newText, (New-Object System.Text.UTF8Encoding($false)))
}

Set-EnvValue -File $ENV_FILE -Key 'MEMORY_FILE_PATH' -Value $MEM_FILE
# Keep the current session consistent: if the profile loaded a stale backslash
# path, opencode launched from this same session would read that obsolete value.
$env:MEMORY_FILE_PATH = $MEM_FILE
Write-Host "✅ MEMORY_FILE_PATH=${MEM_FILE} written in ${ENV_FILE}"

# --- 4. Ensure the PowerShell profile loads ~/.agent/.env --------------------
$PROFILE_FILE = $PROFILE
$MARKER = '# >>> lumusitech agent env >>>'

if ([string]::IsNullOrWhiteSpace($PROFILE_FILE)) {
    Write-Host "⚠️  No se pudo determinar el perfil de PowerShell. Configure la carga de ~/.agent/.env manually."
} else {
    $profileDir = Split-Path -Parent $PROFILE_FILE
    $profileExists = Test-Path -LiteralPath $PROFILE_FILE
    $profileText = if ($profileExists) { [System.IO.File]::ReadAllText($PROFILE_FILE) } else { '' }

    if ($profileText.Contains($MARKER)) {
        Write-Host "✅ ${PROFILE_FILE} already loads ~/.agent/.env"
    } else {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        $block = @'

# >>> lumusitech agent env >>>
# Load ~/.agent/.env credentials (GITHUB_TOKEN, MEMORY_FILE_PATH, ...) for opencode MCP servers
if (Test-Path "$HOME\.agent\.env") {
    Get-Content "$HOME\.agent\.env" | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim().Trim('"'), 'Process')
        }
    }
}
# <<< lumusitech agent env <<<
'@
        $newProfile = $profileText
        if ($newProfile.Length -gt 0 -and -not $newProfile.EndsWith("`n")) { $newProfile += "`n" }
        $newProfile += $block + "`n"
        [System.IO.File]::WriteAllText($PROFILE_FILE, $newProfile, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "✅ Bloque de carga added a ${PROFILE_FILE} (abre a terminal nuevo for aplicarlo)"
    }
}

# --- 5. Seed + migrate legacy memory.jsonl ----------------------------------
$LINE_COUNT = {
    if (Test-Path -LiteralPath $MEM_FILE) {
        @(Get-Content -LiteralPath $MEM_FILE).Count
    } else { 0 }
}

if ((Test-Path -LiteralPath $MEM_FILE) -and ((Get-Item -LiteralPath $MEM_FILE).Length -gt 0)) {
    Write-Host "✅ Base de memory per-user ya existe: ${MEM_FILE} ($(& $LINE_COUNT) lines)"
} elseif (Test-Path -LiteralPath (Join-Path $REPO_DIR 'memory.jsonl')) {
    if (Confirm-Choice "Migrar el memory.jsonl legacy of the repo a ${MEM_FILE}?" 'and') {
        Copy-Item -Path (Join-Path $REPO_DIR 'memory.jsonl') -Destination $MEM_FILE -Force
        Write-Host "✅ Migrated memory.jsonl legacy → ${MEM_FILE} ($(& $LINE_COUNT) lines)"
        if (Confirm-Choice "Eliminar el memory.jsonl of the repo (for no commitear memorias)?" 'and') {
            Remove-Item -Path (Join-Path $REPO_DIR 'memory.jsonl') -Force
            Write-Host "✅ Removed $(Join-Path $REPO_DIR 'memory.jsonl')"
        }
    } else {
        [System.IO.File]::WriteAllText($MEM_FILE, '', (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "ℹ️  Empty database created in ${MEM_FILE} (legacy file was not migrated)"
    }
} else {
    [System.IO.File]::WriteAllText($MEM_FILE, '', (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "✅ Base de memory creada: ${MEM_FILE}"
}

Write-Host ""
Write-Host "🎉 Memoria per-user lista:"
Write-Host "   • Archivo:   ${MEM_FILE}"
Write-Host "   • Variable:  MEMORY_FILE_PATH (in ${ENV_FILE})"
Write-Host "   • Profile:   $(if ($PROFILE_FILE) { $PROFILE_FILE } else { 'no configurado' })"
Write-Host "   • Next step: restart opencode for that el MCP memory use la nueva ruta."
