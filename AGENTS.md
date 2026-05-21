# AiLang Core Packages Agents

This repository contains official optional AiLang packages.

## Ownership

- Libraries belong under `packages/<name>/src`.
- Tools belong under `packages/<name>/tools`.
- Templates belong under `packages/<name>/templates`.
- Package metadata lives in `packages/<name>/package.toml`.

## Rules

- Keep the minimum standard library in `AiLang/src/std`, not here.
- Do not add backward compatibility shims for pre-release package paths.
- Package source must not assume every file in the package is bundled into app
  output.
- IMPORTANT: Until a major or minor release is officially released, all
  contracts, APIs, schemas, interfaces, and architectural decisions are
  considered negotiable and may change freely. Do not add backward
  compatibility layers, legacy adapters, or dual-path support unless explicitly
  requested. When changing direction, replace the old implementation completely
  and update the codebase consistently to the new contract. Patch releases are
  for bug fixes only.

## Verification

```bash
./scripts/validate-package-namespaces.sh
find packages -name package.toml -print
find packages -name '*.aos' -print
```
