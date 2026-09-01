# 🧠 Lumusitech AI Workspace

> Centralized AI workspace: Streamlined curated skills (~115), custom stack skills (Angular 22+, Spring Boot 4.x, Java 21/25, MercadoPago), planning skills (Wayfinder suite, WBS, estimate-costs, plan-phases), and 6 core MCP integrations (`context7`, `codegraph`, `codebase-memory`, `github`, `memory`, `playwright`) synced seamlessly across macOS, Linux, WSL2, and Windows (PowerShell 7).

This repository serves as the single source of truth for **OpenCode** and **Antigravity (TUI / IDE)**. It enforces strict architectural patterns, modern framework standards, zero-token security, and uncompromised code quality.

### 🌐 Language convention

- **File and folder names:** always English, ASCII (`snake_case` or `kebab-case`). No accents, `n`, or spaces.
- **Code and technical configs** (skills, plugins, hooks, configs): English.
- **Docs and team-facing communication** (PR comments, commit messages, README sections aimed at the team): Spanish when the team reads Spanish.
- A new document picks one language for its whole content; do not mix within the same file.

Full directives are in [`AGENTS.md`](AGENTS.md).

---

## 🏗️ Core Engineering Directives

All AI agents in this workspace operate under strict directives defined in [`AGENTS.md`](AGENTS.md):

1. **Code Quality & Architecture:** Strict adherence to **SOLID**, **KISS**, **SoC**, and **DRY**.
2. **TypeScript (Strict Mode):** Zero `any` policy.
3. **Modern Angular (v22+):** Zoneless by default (`provideExperimentalZonelessChangeDetection()`), Signal-driven state (`signal()`, `computed()`, `linkedSignal()`), and `resource()` API.
4. **Spring Boot (v4.x / 3.5 LTS) & Java (21/25 LTS):** Virtual Threads enabled by default (`spring.threads.virtual.enabled=true`), Spring AI integration, Declarative HTTP clients (`@HttpExchange`), and modern Java idioms.

---

## 🛠️ MCP (Model Context Protocol) Integrations

The workspace configures 6 MCP servers for OpenCode and Antigravity. They are **installed locally by `scripts/setup.sh` / `scripts/setup.ps1`** (from `package.json`, with `pnpm` → `corepack pnpm` → `npm` fallback) and exposed on `PATH` via `~/.local/bin`, so neither OpenCode nor Antigravity resolves or downloads packages from the registry at startup (no `npx -y`):

| Server | Binary | Package | Requires |
|---|---|---|---|
| `codegraph` | `codegraph-mcp` | `@astudioplus/codegraph-mcp` | — (native binary per platform) |
| `context7` | `context7-mcp` | `@upstash/context7-mcp` | — |
| `github` | `mcp-server-github` | `@modelcontextprotocol/server-github` | `GITHUB_TOKEN` from `~/.agent/.env` |
| `memory` | `mcp-server-memory` | `@modelcontextprotocol/server-memory` | — |
| `playwright` | `playwright-mcp` | `@playwright/mcp` | Chrome (installed) **or** Chromium (auto-downloaded) |
| `codebase-memory` | `codebase-memory-mcp` | `codebase-memory-mcp` | — |

- **`context7`**: Official documentation lookup for libraries, frameworks, and SDKs.
- **`codegraph`**: Graph-based repository symbol search and dependency tracking.
- **`codebase-memory`**: Graph-based code intelligence for AI agents. Its native runtime is fetched by the package's own postinstall (same pattern as `codegraph`).
- **`github`**: PR, issue, and workflow management authenticated via `{env:GITHUB_TOKEN}`.
- **`memory`**: Long-term persistent memory across chat sessions.
- **`playwright`**: End-to-end browser testing and UI visual inspection. Uses the **installed Chrome** when available, falling back to a downloaded **Chromium** otherwise (see below).

### Playwright browser (Chrome → Chromium fallback)

`scripts/setup.sh` / `scripts/setup.ps1` detect whether Google Chrome is installed and resolve the browser **automatically**, writing `PLAYWRIGHT_BROWSER` to `~/.agent/.env` (idempotent, re-resolved on every run):

- **macOS**: `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`
- **Linux**: `google-chrome`, `google-chrome-stable`, or `google-chrome-beta` on `PATH`
- **Windows**: `%ProgramFiles%\Google\Chrome\Application\chrome.exe`, the `(x86)` variant, or `%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe`

If Chrome is present the value is `chrome` (uses the system browser, no download); otherwise `chromium` (Playwright downloads Chromium to `~/.cache/ms-playwright/` on first use). The variable is consumed via `PLAYWRIGHT_MCP_BROWSER` (env var) in `config/opencode.jsonc` and `config/mcp.json`.

### Prerequisites per machine

- **Node.js 18+ and npm** — required to install the local MCP packages. Install via `nvm`, your distro package manager, or https://nodejs.org.
- **pnpm** (recommended) — used by `scripts/setup.sh` to install the local MCP packages. If absent, the setup falls back to `corepack enable pnpm`, then to `npm`.
- **Bun** — used by OpenCode to install the DCP plugin declared in `config/opencode.jsonc` (`"plugin": [...]`). Install via `curl -fsSL https://bun.sh/install | bash` or your package manager.
- **GitHub token** — `github` MCP requires `GITHUB_TOKEN`; see [Loading Credentials](#-loading-credentials-for-mcp-servers) below.

`scripts/setup.sh` installs the MCP packages and verifies their binaries are on `PATH` after setup, reporting any that are missing.

---

## 🧠 Context management

Models begin to degrade at approximately 40-44% of their context window (in a 1M model, ~400k tokens). Below that point, compaction is unnecessary and degrades useful context; above it, work takes place in the degradation zone.

**DCP** (`@tarquinen/opencode-dcp`) manages this as a guardrail, with native auto-compaction disabled (`compaction.auto: false`):

- **~40% del contexto** (`maxContextLimit: "40%"` en `config/dcp.jsonc`): DCP empieza a *empujar suavemente* al modelo a comprimir (`nudgeForce: "soft"`).
- **Ask the user:** the `compress` tool uses `permission: "ask"`, so the user decides whether to compact or continue (accepting the degradation risk).
- **No automatic compaction:** neither OpenCode (`compaction.auto: false`) nor DCP compacts on its own. The user always makes the decision.
- **Notification:** `pruneNotification: "detailed"` reports pruning in chat.

> **Why compaction is not performed earlier:** `magic-context` had a ~128k fallback that compacted prematurely in 1M-token models. It was removed; DCP with its 40% threshold is the single source of truth for context.

---

## 📂 Repository Structure

```text
~/.agent/
├── skills/                 # ~115 curated skills + 4 custom stack + 13 planning skills
│   ├── wayfinder/          # 🗺️ Wayfinder suite (Matt Pocock): wayfinder, setup-matt-pocock-skills,
│   │                       #    to-spec, grilling, grill-with-docs, research, triage
│   ├── ask-matt/           # 🧭 Router de skills (custom, reference /plan-phases-implement)
│   ├── to-tickets/         # 🎫 Tickets con blocking edges (custom, with GitHub mechanics)
│   ├── plan-phases-create/ # 📐 Phased planning: plan + contratos publicos (custom)
│   ├── plan-phases-implement/ # 🛠️ Implements one phase per invocation + STOP (custom)
│   ├── create-work-breakdown-structure/  # WBS + WBS Dictionary (agent-almanac)
│   ├── estimate-costs/     # 📊 CBS bottom-up con rate card (skill custom)
│   └── ...
├── .config/rates/          # Global rate card default para estimate-costs
├── config/skills.json             # Antigravity explicit skill discovery entry (~/.agent/skills)
├── config/hooks.json              # Antigravity lifecycle hooks (env-protection, notifications)
├── hooks/                  # Hook scripts (env-protection.sh, notify.sh)
├── agents/                 # OpenCode custom agents (architect.md, ...)
├── plugins/                # OpenCode custom plugins (env-protection, notifications, ...)
├── extensions/lumusitech/  # Antigravity / Gemini CLI extension (gemini-extension.json)
├── scripts/                # memory-setup.{sh,ps1}: per-user memory path written to .env
├── .gitattributes          # LF line endings + binary markers (cross-platform hardening)
├── .editorconfig           # UTF-8 / LF / trailing-newline for editors
├── .github/workflows/      # CI: validates JSON/JSONC + rejects BOM/CRLF on PRs
├── docs/en/AGENTS.md       # English global directives for OpenCode agents
├── docs/en/GEMINI.md       # English directives for Gemini CLI / Antigravity
├── config/opencode.jsonc          # OpenCode config: MCPs (local bins) + DCP plugin + skills paths
├── config/dcp.jsonc               # DCP plugin config: 40% threshold, permission "ask"
├── config/tui.json                # OpenCode TUI config (scroll acceleration)
├── package.json            # Local MCP packages installed by scripts/setup.sh (pnpm/npm)
├── config/mcp.json                # Antigravity shared MCP declarations
├── .env.template           # Template for environment variables (GITHUB_TOKEN, etc.)
├── .env                    # Local credentials file (ignored by Git)
├── scripts/setup.sh                # Portable setup script for Unix (macOS, Linux, WSL2)
├── scripts/setup.ps1               # Windows setup script (PowerShell 7)
├── scripts/setup.cmd               # Windows launcher (ExecutionPolicy bypass + pwsh check)
└── docs/en/README.md       # English workspace documentation
```

### Cross-platform hardening

Config files move between macOS, Linux, WSL2 and Windows through git. Three safeguards keep them valid everywhere:

- **`.gitattributes`** forces LF line endings on checkout (a Windows default of `core.autocrlf=true` would otherwise rewrite them to CRLF) and keeps `.cmd`/`.bat` on CRLF.
- **`.editorconfig`** pins `UTF-8` + `LF` + trailing newline in editors, avoiding BOM/encoding drift.
- **`.github/workflows/validate-config.yml`** validates every `.json`/`.jsonc` and rejects UTF-8 BOM and CRLF in config/scripts/docs on every PR, so invalid JSON never merges.

---

## 🔌 Plugins & Extensions

### OpenCode plugins

Custom local plugins live in `~/.agent/plugins/` and are auto-loaded by OpenCode via symlink (`~/.config/opencode/plugins`). Each file is an ESM module exporting a plugin:

| Plugin | Hook | Purpose |
|---|---|---|
| `env-protection.js` | `tool.execute.before` | Blocks reads/writes of `.env` files and `export VAR=...` shell assignments to prevent secret leaks |
| `notifications.js` | `event` | Native desktop notification when a session goes idle |
| `inject-env.js` | `shell.env` | Loads `~/.agent/.env` into every agent shell |
| `context-compaction.js` | `experimental.session.compacting` | Preserves task state across session compaction |

Third-party npm plugins are declared in `config/opencode.jsonc` under `"plugin"`:

- `@tarquinen/opencode-dcp` (pinned `@3.1.15`) — dynamic context pruning. Its `compress` tool replaces stale, closed conversation spans with technical summaries. Configured (see `config/dcp.jsonc`) to **nudge softly at ~40% of the model context** and to **ask the user** before compressing (`compress.permission: "ask"`).

> **Removed:** `@cortexkit/opencode-magic-context` was removed. Its hardcoded ~128k fallback triggered premature compaction in 1M-token models and its auto-update-checker failed at startup. Context management is now handled solely by DCP (see [Gestion de contexto](#-gestion-de-contexto)).

### Antigravity / Gemini CLI extension

`extensions/lumusitech/gemini-extension.json` exposes the 6 shared MCP servers to Gemini CLI / Antigravity and points `contextFileName` at `docs/en/GEMINI.md`. It is linked via `~/.gemini/extensions/lumusitech`. The MCP servers are also declared in `config/mcp.json` (linked to `~/.gemini/config/mcp.json` and `~/.gemini/config/mcp_config.json`) for broad compatibility.

Antigravity discovers the shared skills through **two redundant mechanisms** (double safety net):

- The `skills` symlink at `~/.gemini/config/skills` → `~/.agent/skills`
- An explicit `config/skills.json` at `~/.gemini/config/skills.json` declaring `{ "entries": [{ "path": "~/.agent/skills" }] }`

> **Discovery depth:** Antigravity reads skills only one level deep (`skills/<name>/SKILL.md`) and does **not** recurse into category subfolders. OpenCode does recurse. That is why the skills stay in a flat layout with `design-it` acting as a router, and why skills carrying `disable-model-invocation: true` (10 of them) are only reachable via slash command in the IDE. See [`skills/README.md`](skills/README.md#how-skills-are-discovered).

### Antigravity lifecycle hooks

`config/hooks.json` (linked to `~/.gemini/config/hooks.json`) ports two of the OpenCode custom plugins to Antigravity's hook system. Hooks receive a JSON payload on stdin and must emit a JSON result on stdout.

| Hook | Event | Script | Behaviour |
|---|---|---|---|
| env-protection | `PreToolUse` (matcher `.*`) | `hooks/env-protection.sh` | Denies file tools (`view_file`, `edit_file`, ...) targeting `.env` paths, shell commands referencing `.env`, and `export VAR=...` shell assignments |
| notifications | `Stop` | `hooks/notify.sh` | Sends a native desktop notification when the loop stops |

`inject-env` and `context-compaction` remain **OpenCode-only** — they rely on the OpenCode plugin API (`shell.env`, `experimental.session.compacting`) which has no Antigravity equivalent.

### Extension differences: OpenCode vs Antigravity

| Capability | OpenCode | Antigravity / Gemini |
|---|---|---|
| Skills discovery | `skills.paths` in `config/opencode.jsonc` | `~/.gemini/config/skills` symlink + `config/skills.json` |
| MCP servers | `mcp` in `config/opencode.jsonc` | `config/mcp.json` + `gemini-extension.json` |
| Global directives | `docs/en/AGENTS.md` | `docs/en/GEMINI.md` |
| Custom agents | `~/.config/opencode/agents/*.md` | Not supported (CLI/IDE rely on hooks + MCP) |
| Plugins | JS plugins (`plugins/`) + npm plugins | Not supported — use `config/hooks.json` |
| Lifecycle hooks | `tool.execute.*`, `event`, `shell.env`, ... | `config/hooks.json` (`PreToolUse`, `Stop`, ...) |

### MCP Memory (per-user, local)

The MCP memory server stores its knowledge graph (entities, relations, observations) in a **per-user local file** that is **never committed to the repo**. The location is injected via the `MEMORY_FILE_PATH` environment variable (see `config/opencode.jsonc` / `config/mcp.json`):

- Unix: `~/.local/share/opencode/memory/<user>.jsonl`
- Windows: `C:/Users/<user>/.local/share/opencode/memory/<user>.jsonl`

`scripts/memory-setup.{sh,ps1}` detects your identity, writes `MEMORY_FILE_PATH` into `~/.agent/.env`, and ensures your shell/PowerShell profile loads it.

> **Why forward slashes on Windows?** opencode substitutes `{env:MEMORY_FILE_PATH}` in `config/opencode.jsonc` **verbatim** (without JSON-escaping the value). A Windows path with backslashes (`C:\Users\...`) would inject invalid JSON escape sequences and make opencode fail with `config/opencode.jsonc is not valid JSON(C)`. `scripts/memory-setup.ps1` therefore normalizes the path to forward slashes (`/`), which Windows, PowerShell and Node all accept.

To move the graph to another machine, use the `/memory-export` and `/memory-import` skills (a Markdown document with an embedded JSONL block) — the file itself is never synced via git.

### OpenCode custom agents

Files in `~/.agent/agents/` are symlinked into `~/.config/opencode/agents/`. Each agent is a Markdown file with frontmatter (`description`, `mode`, `permission`).

---

## 🚀 Machine Setup Guide

### Unix (macOS / Linux / WSL2)

To sync this workspace to a new machine:

1. **Clone the repository:**
   ```bash
   git clone git@github.com:lumusitech/AI.join ~/.agent
   cd ~/.agent
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.template .env
   # Edit .env and set your GITHUB_TOKEN and tokens
   ```

3. **Run the setup script:**
   ```bash
   ./scripts/setup.sh
   ```

This script will automatically configure OpenCode (`~/.config/opencode/opencode.jsonc`) and Antigravity (`~/.gemini/config/skills` & `~/.gemini/config/mcp.json`) and clean up legacy paths.

### Windows (PowerShell 7)

> ⚠️ **PowerShell 7 (`pwsh`) is required** — the setup script does NOT run on Windows PowerShell 5.1. Install it from https://aka.ms/powershell or `winget install --id Microsoft.PowerShell --exact`.

Prerequisites: PowerShell 7, Git for Windows, Node.js 18+ (npm), Bun, GitHub CLI (`gh`). Missing pieces can be installed automatically by the setup with `-InstallPrerequisites`.

1. **Clone the repository:**
   ```powershell
   git clone git@github.com:lumusitech/AI.join "$HOME\.agent"
   cd "$HOME\.agent"
   ```

2. **Configure environment variables:**
   ```powershell
   Copy-Item .env.template .env
   # Edit .env and set your GITHUB_TOKEN and tokens
   ```

3. **Run the setup script:**
   ```cmd
   scripts/setup.cmd
   ```
   (or directly: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/setup.ps1`)

   Optional flags:
   - `scripts/setup.cmd -InstallPrerequisites` — installs missing Git/gh/Node/Bun via winget (idempotent: skips anything already installed).
   - `scripts/setup.cmd -ConfigureWindowsTerminal` — adds an "AI Workspace (pwsh 7)" profile to Windows Terminal and sets it as default (backs up `settings.json` first).
   - `scripts/setup.cmd --refresh-vendored-skills` — re-fetches vendored planning skills from upstream.

The script configures the same links as on Unix (`~/.config/opencode`, `~/.gemini/config`, `~/.gemini/extensions`) and generates `~/.gemini/config/hooks.json` pointing at the PowerShell 7 hooks (`.ps1`) with absolute paths.

**Links on Windows:** creating symbolic links requires Developer Mode (Settings → For developers) or an admin shell. `scripts/setup.ps1` detects the capability at startup: with symlink permission everything is linked live (a `git pull` propagates instantly); without it, directories use **junctions** (no admin needed) and files are **copied** — in that case re-run `scripts/setup.cmd` after every `git pull` to propagate updates.

**PowerShell profile:** the script adds a block to your pwsh profile (`$PROFILE`) that loads `~/.agent/.env` into every new terminal session, so OpenCode MCP servers see `GITHUB_TOKEN` and `MEMORY_FILE_PATH`:

```powershell
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
```

**Verify:** open a new terminal and run:

```powershell
if ($env:GITHUB_TOKEN) { "GITHUB_TOKEN: set (len=$($env:GITHUB_TOKEN.Length))" } else { "GITHUB_TOKEN: not set" }
```

**Antigravity notifications on Windows** (hooks + OpenCode plugin) use the [BurntToast](https://github.com/Windos/BurntToast) PowerShell module when available: `Install-Module BurntToast -Scope CurrentUser`. Without it, notifications are silently skipped.

### Verify vendored skills (both platforms)

The setup also verifies the **13 planning skills** are present (8 vendored + 5 custom) and can re-fetch the vendored ones from upstream:

```bash
./scripts/setup.sh                          # verify + configure
./scripts/setup.sh --refresh-vendored-skills # re-clone mattpocock/skills + agent-almanac and copy updates
```

```powershell
scripts/setup.cmd                          # verify + configure
scripts/setup.cmd --refresh-vendored-skills # re-clone mattpocock/skills + agent-almanac and copy updates
```

Planning skills come from two upstream sources (MIT) plus custom skills committed to this repo:

| Source | Skills |
|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | wayfinder, setup-matt-pocock-skills, to-spec, grilling, grill-with-docs, research, triage |
| [pjt222/agent-almanac](https://github.com/pjt222/agent-almanac) | create-work-breakdown-structure |
| Custom (never refreshed) | estimate-costs (rate card CBS), to-tickets (with GitHub mechanics), ask-matt (reference `/plan-phases-implement`), plan-phases-create, plan-phases-implement |

> **Note:** `to-tickets` and `ask-matt` are vendored upstream but are **customized here**. They were removed from the refresh list so `--refresh-vendored-skills` never overwrites our adaptations.

---

## 🗺️ Planning Workflow (Wayfinding + WBS + Costs)

For work larger than one agent session, the pipeline goes **document → decisions → WBS → costs → tickets**:

1. **`/grill-with-docs`** — interview the functional document, leaving `CONTEXT.md` + ADRs.
2. **`/to-spec`** — conversation → spec in the tracker.
3. **`/create-work-breakdown-structure`** — deliverables → WBS + `WBS-DICTIONARY.md` (person-days per work package).
4. **`/estimate-costs`** — Cost Breakdown Structure using a **rate card**. The agent **never invents rates**: it resolves `<repo>/.config/rates/rate-card.json` → global `~/.agent/.config/rates/rate-card.json`, and flags `RATE MISSING` for unknown roles.
5. **`/to-tickets`** — executable tickets with blocking edges.

Before using the Wayfinder suite in a repo, run **`/setup-matt-pocock-skills`** once per repo to pick the issue tracker (GitHub by default, or local files) — it writes the *Wayfinding operations* section into the repository directives.

Wayfinder rules: **1 ticket per session**, tickets resolve **decisions** (not build slices), and refer to maps/tickets **by name**. See `docs/en/AGENTS.md` for the full operating rules.

### 📐 Phase planning (Research → Plan → Implement)

For a single large task, once the plan/tickets exist, execute it phase by phase:

1. **`/plan-phases-create`** — interviews you, explores the codebase (delegated to subagents), and defines **vertical-slice phases with public contracts**. Optionally produces a `research.md` for large tasks. Writes `.agents/plans/{plan-name}/{plan-name}-plan.md` only after your approval.
2. **`/plan-phases-implement`** — implements **exactly one phase per invocation**, verifies (typecheck/lint/tests), updates the plan file, and **STOPs** suggesting 3 Spanish commit messages. Never commits or pushes automatically. If a step doesn't fit the plan, it returns to `/plan-phases-create` instead of forcing it.

---

## 🔑 Loading Credentials for MCP Servers

MCP servers that require authentication (e.g. `github`) reference tokens through environment variables in `config/opencode.jsonc`, like `{env:GITHUB_TOKEN}`. OpenCode reads **process environment variables**, not the `.env` file directly — so merely having `GITHUB_TOKEN` in `~/.agent/.env` is **not enough** for the MCP server to pick it up.

`scripts/setup.sh` sources `.env` only within its own execution, so it never persists into your shell. You must load `~/.agent/.env` into your shell profile so every new terminal (and every app launched from it, including OpenCode) has the tokens.

### Add to your shell profile

**Zsh** (macOS default, Ubuntu/Debian with zsh, WSL2):

```bash
# Load ~/.agent/.env credentials (GITHUB_TOKEN, etc.) for opencode MCP servers
if [ -f "$HOME/.agent/.env" ]; then
    set -a
    source "$HOME/.agent/.env"
    set +a
fi
```

Add the block above to `~/.zshrc`.

**Bash** (Ubuntu/Debian default, WSL2 default):

```bash
# Load ~/.agent/.env credentials (GITHUB_TOKEN, etc.) for opencode MCP servers
if [ -f "$HOME/.agent/.env" ]; then
    set -a
    source "$HOME/.agent/.env"
    set +a
fi
```

Add the block above to `~/.bashrc`.

**PowerShell 7** (Windows):

```powershell
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
```

Add the block above to your PowerShell profile (run `notepad $PROFILE` in pwsh). `scripts/setup.ps1` does this automatically.

### Verify

After adding the block, open a **new terminal** and run:

```bash
echo "GITHUB_TOKEN: ${GITHUB_TOKEN:+set (len=${#GITHUB_TOKEN})}${GITHUB_TOKEN:-not set}"
```

```powershell
# PowerShell 7
if ($env:GITHUB_TOKEN) { "GITHUB_TOKEN: set (len=$($env:GITHUB_TOKEN.Length))" } else { "GITHUB_TOKEN: not set" }
```

If it prints `set`, your MCP servers will have access. **Important:** OpenCode must be restarted from a terminal where the variable is loaded for the MCP servers to use it.

### ⚠️ `GITHUB_TOKEN` vs `git push --delete` (important)

Once `GITHUB_TOKEN` is exported in your shell, the GitHub CLI credential helper **prefers it over the full OAuth token** stored by `gh auth login`. If your `.env` uses a **fine-grained PAT** (`github_pat_...`), that token often lacks the `Contents: write` permission required to delete remote branches, so `git push --delete origin <branch>` fails with:

```
remote: Permission to <user>/<repo>.git denied to <user>.
```

**Fix:** make git ignore `GITHUB_TOKEN`/`GH_TOKEN` and always use gh's stored OAuth token:

```bash
git config --global credential.https://github.com.helper \
  '!env -u GITHUB_TOKEN -u GH_TOKEN gh auth git-credential'
git config --global credential.https://gist.github.com.helper \
  '!env -u GITHUB_TOKEN -u GH_TOKEN gh auth git-credential'
```

> **Automatic:** `scripts/setup.sh` applies this fix for you on every machine (it resolves the real `gh` binary path and configures both `github.com` and `gist.github.com`). On Windows, `scripts/setup.ps1` applies the equivalent fix (an `unset`-based sh helper, since Git for Windows ships no `env`). You only need the manual commands above if you're not running the setup script.

After applying, verify in a shell that loads `.env`:

```bash
# in a new terminal where GITHUB_TOKEN is set
printf 'protocol=https\nhost=github.com\n\n' | git credential fill
# expect username=lumusitech and password=gho_... (NOT github_pat_...)
```
