# AiLang Core Packages

This repository contains official AiLang packages that are useful but not part
of the minimum standard library.

The package registry points at this repository. Package source lives here.

## Status

These packages are first-party optional packages for the beta SDK. They are not
part of the minimum standard library and should only be included in an app when
referenced by package restore/build/publish.

This repository uses `main` as its public default branch. Package source changes
land here first, then immutable released package versions are added to
[AiLangCore/ailang-packages](https://github.com/AiLangCore/ailang-packages).

Public roadmap:

- https://ailang.codes/docs/roadmap.html

## Package Types

An AiLang package can contain one or more package item types:

- `library`: importable AiLang source.
- `tool`: executable command or project tool.
- `template`: project, file, or agent template content.
- `target`: build/publish/run target metadata, runner recipes, and host tool requirements.

For example, AiVectra is expected to expose UI libraries, design/build tools,
and application templates from the same package. AiOS targets are expected to
expose target metadata plus package tools/templates for service or GUI image
creation.

## Layout

```text
packages/
  std-http/
    package.toml
    src/
      net/
        http.aos
  target-aios-service/
    package.toml
```

Current packages:

- `std-app`: `std.app`, `std.app.event`, `std.app.next`,
  `std.app.command`, `std.app.worker`, `src/app/*.aos`
- `std-http`: `std.net.http`, `src/net/http.aos`
- `std-image`: `std.media.image`, `src/media/image.aos`
- `std-json`: `std.format.json`, `src/format/json.aos`
- `std-net`: `std.net.udp`, `src/net/udp.aos`
- `std-ui-input`: `std.ui.input`, `src/ui/input.aos`
- `target-aios-service`: `aios-service` target metadata and QEMU runner requirement contract
- `target-aios-gui`: `aios-gui` target metadata and QEMU runner requirement contract

## Rules

- Do not duplicate minimum stdlib modules here.
- A package may depend on AiLang core libraries through package imports.
- Package descriptors use TOML and schema `ailang.package-source.v1`.
- Package source paths should be nested by domain. For example, format codecs
  live under `src/format/`, network helpers live under `src/net/`, media helpers
  live under `src/media/`, and UI helpers live under `src/ui/`.
- Library descriptors must declare a dotted semantic `namespace`. Package names
  remain dashed for registry identity; source namespaces use dots.
- Target descriptors must declare stable target ids, supported artifact types,
  and any external tool requirements needed by `build`, `publish`, `run`,
  `test`, `doctor`, or device flows.
- Package source must be reachable-code friendly: examples, tests, templates,
  and tools are not included in app output unless explicitly referenced or
  selected by publish/template commands.
- Application lifecycle semantics belong in `std-app`, not compiler, VM, UI
  libraries, or host code. The long-term lifecycle model is
  `State + Event -> Next`.
- CLI, HTTP, services, workers, and GUI are runtime profiles over the same
  `std-app` lifecycle model.
- Packages should expose context, event, message, command, and worker contracts
  without exposing host threads, locks, mutexes, semaphores, or async/await
  primitives.
- GUI runtimes such as AiVectra are profile adapters: they adapt GUI host events
  into `std-app` events and consume `std-app` commands. AiVM and host code own
  only mechanical scheduling, syscall execution, and transport plumbing.

## Target Package Requirement Shape

Target packages may declare external tool requirements. The CLI must detect
missing requirements and print deterministic install hints, but it must not
silently install host tools.

```toml
[requirements.tools.qemu]
name = "qemu"
requiredFor = ["run", "test"]
commands = ["qemu-system-x86_64"]

[requirements.tools.qemu.installHints]
macos = "brew install qemu"
linux = "Install qemu-system with the distro package manager."
windows = "winget install SoftwareFreedomConservancy.QEMU"
```

## Publishing Workflow

1. Update the package under `packages/<name>/`.
2. Keep importable library source under `src/`.
3. Keep optional package templates under `templates/projects/` or
   `templates/files/`.
4. Update `packages/<name>/package.toml` with the package version and exposed
   library/tool/template/target metadata.
5. Run package validation and any example that imports the package.
6. Commit and tag the source repository.
7. Update `AiLangCore/ailang-packages` with the package version, readable ref,
   exact commit, and package root.

The package registry owns discovery. This repository owns package source.

## Verification

```bash
./scripts/validate-package-namespaces.sh
find packages -name package.toml -print
find packages -name '*.aos' -print
```
