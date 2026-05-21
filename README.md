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

For example, AiVectra is expected to expose UI libraries, design/build tools,
and application templates from the same package.

## Layout

```text
packages/
  std-http/
    package.toml
    src/
      net/
        http.aos
```

Current packages:

- `std-http`: `src/net/http.aos`
- `std-image`: `src/media/image.aos`
- `std-json`: `src/format/json.aos`
- `std-net`: `src/net/udp.aos`
- `std-ui-input`: `src/ui/input.aos`

## Rules

- Do not duplicate minimum stdlib modules here.
- A package may depend on AiLang core libraries through package imports.
- Package descriptors use TOML and schema `ailang.package-source.v1`.
- Package source paths should be nested by domain. For example, format codecs
  live under `src/format/`, network helpers live under `src/net/`, media helpers
  live under `src/media/`, and UI helpers live under `src/ui/`.
- Package source must be reachable-code friendly: examples, tests, templates,
  and tools are not included in app output unless explicitly referenced or
  selected by publish/template commands.

## Publishing Workflow

1. Update the package under `packages/<name>/`.
2. Keep importable library source under `src/`.
3. Keep optional package templates under `templates/projects/` or
   `templates/files/`.
4. Update `packages/<name>/package.toml` with the package version and exposed
   library/tool/template metadata.
5. Run package validation and any example that imports the package.
6. Commit and tag the source repository.
7. Update `AiLangCore/ailang-packages` with the package version, readable ref,
   exact commit, and package root.

The package registry owns discovery. This repository owns package source.
