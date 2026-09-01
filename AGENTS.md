# Global Agent Directives

This repository is the source of truth for OpenCode and Antigravity across all supported platforms.

## Engineering standards
- Follow SOLID, KISS, separation of concerns, and DRY.
- Use strict TypeScript with no `any`; prefer interfaces, generics, and `unknown` with type guards.
- Use modern Angular signals, resources, control flow, and zoneless change detection.
- Use modern Spring Boot and Java LTS features, virtual threads, Spring AI, and declarative HTTP clients.

## MCP and tooling
- Use Context7 for current external library and API documentation.
- Use CodeGraph for repository symbol navigation and dependency analysis.
- Use GitHub MCP for GitHub operations; use the CLI only when MCP is unavailable.
- Use Memory MCP for persistent project knowledge and Playwright MCP for browser verification.

## Context management
DCP is the sole context-management authority. It gently nudges at approximately 40% of the model context and asks the user before compression. Automatic compaction remains disabled.

## Git and communication
Never commit directly to `main`; every change goes through a focused pull request. Keep technical code and configuration in English. New documents must use one language throughout.

## Planning
Use the Wayfinder pipeline for larger work: research, specification, work breakdown, cost estimation, tickets, and phased implementation. Implement one phase per invocation and stop for verification.
