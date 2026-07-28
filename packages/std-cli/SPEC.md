# std.cli Package Contract

Status: initial explicit-registration contract.

## Descriptors and registration

`createApplication(name, version, summary)` creates an empty application.
`createCommand(name, summary, handler)` creates a command. Arguments and options
are appended explicitly with `commandWithArgument` and `commandWithOption`.
`commandWithUsage` supplies canonical usage text and `commandAllowTrailing`
permits additional positional values.

`registerCommand` is immutable: callers retain its returned application.
Registration order is semantic and is preserved in help output. This is the
canonical presentation order for the initial version. Name normalization is
the identity function: names are case-sensitive ordinal strings and no locale
normalization or aliases are inferred.

The intrinsic names `help` and `version`, long options `--help` and `--version`,
and alias `-h` are reserved. Duplicate command names, option names, and short
aliases are rejected before dispatch.

## Parsing

The first token selects a command. The remaining tokens use these rules:

- `--name value` supplies a value option.
- `--flag` supplies a Boolean flag.
- `-n value` and `-f` use an explicitly registered one-character alias.
- `--name=value`, grouped short flags, and inferred spellings are rejected.
- `--` ends option parsing. Later tokens are exposed as `remaining`.
- Every option may occur at most once.
- A value option consumes exactly the next token.
- Required positional arguments are validated before invocation.
- Extra positionals are rejected unless `commandAllowTrailing` was applied.
- Unknown options before `--` are never forwarded to the handler.

`invocationPositional`, `invocationOption`, `invocationHasFlag`,
`invocationRemaining`, and `invocationRawArgs` provide host-independent access
to the normalized invocation.

## Intrinsics

Empty input, `help`, and `--help` render root help. `help <command>` and
`<command> --help` render command help. `version` and `--version` render
`<name> <version>`. Intrinsics cannot be overridden.

Help is UTF-8 text with LF line endings, no ANSI styling, no host-width
detection, and no localization. Descriptor and registration order fully
determine its bytes.

## Handlers and results

The application defines `cliCommandHandler(invocation)`. The descriptor's
stable handler name is present in the invocation. The handler returns an integer
exit code, which `std.cli` preserves.

`commandAsExecutable(command, executable, argumentPrefix)` changes a fully
configured command to executable invocation. The executable is passed directly
to `std.process.runCaptured`; it is not interpreted as a shell command.
`argumentPrefix` is an ordered argument node. Parsed raw arguments after the
command-name token are appended in their original order. The child exit code is
preserved, captured stdout is returned as command output, and captured stderr is
forwarded before that output.

Descriptor construction methods must be applied before
`commandAsExecutable`. This keeps the initial immutable descriptor copier small
and makes invocation selection the final registration decision.

Framework success uses exit code `0`. Registration and input failures use exit
code `2`. Framework diagnostics are written as `<code>: <message>`.

## Diagnostics

- `CLI001`: unknown command
- `CLI002`: duplicate command
- `CLI003`: unknown option
- `CLI004`: missing option value
- `CLI005`: duplicate option
- `CLI006`: missing required argument
- `CLI007`: unexpected argument
- `CLI008`: reserved command name
- `CLI009`: duplicate option alias
- `CLI010`: invalid command descriptor

Messages contain only stable descriptor/input values. They never include host
paths, locale-sensitive data, pointer values, exceptions, or stack traces.

## Exclusions

This version has no scanning, markdown parsing, source generation,
`commands.g.aos`, external command installation, shell completion, reflection,
typed conversion, implicit shell execution, or host-side command semantics.
