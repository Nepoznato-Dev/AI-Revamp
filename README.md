# 🧠 Lumusitech AI Workspace

> Centralized AI workspace: Custom skills, strict coding agents (OpenCode/Antigravity), and configurations synced seamlessly across macOS and WSL2 development environments.

This repository serves as the single source of truth for my personal AI coding assistants. It enforces strict architectural patterns, modern framework standards, and uncompromised code quality across all projects, from high-performance backends to mobile applications.

---

## 🏗️ Core Engineering Directives

The agents and skills within this workspace operate under a strict, non-negotiable set of engineering principles:

### 1. Code Quality & Architecture (The Foundation)

- **Standards:** Absolute adherence to **SOLID**, **KISS**, **SoC** (Separation of Concerns), and **DRY**.
- **Pragmatism:** No over-engineering. We don't use a cannon to kill a mosquito.

### 2. TypeScript (Strict Mode)

- **Zero `any` Policy:** The use of `any` is strictly prohibited.
- **Type Safety:** Prioritize abstractions, interfaces, and utility types. Fall back to `unknown` with explicit type guards only when absolutely necessary.

### 3. Modern Angular (v22+)

- **Signals First:** State management is driven by `computed` and `linkedSignals`.
- **Reactivity:** Avoid `effect` unless explicitly required for edge-case DOM manipulations.
- **RxJS Reduction:** Eager architecture for API queries and resource management; avoid RxJS where native Signals solve the problem.
- **MCP Integration:** Agents must always use MCP to review the latest Angular documentation before implementation.

### 4. Pragmatic NestJS Backend

- **Dynamic Architecture:** Use NestJS's default infrastructure for straightforward APIs to avoid unnecessary boilerplate.
- **Domain-Driven Design:** Escalate to strict Clean Architecture (Hexagonal, DDD, CQRS) _only_ when business logic complexity demands it.

---

## 📂 Repository Structure

```text
~/.agent/
├── agents/                 # Custom personas and cognitive architectures
├── skills/                 # Global tools, scripts, and MCP integrations
├── .env.template           # Template for API keys and local tokens
├── .gitignore              # Strict exclusions for Java, Android (.jks), and environments
├── AGENTS.md               # Global directives and behavioral rules for IAs
└── README.md               # You are here
```
