# std-cli

Command-line interface framework for AiLang applications.

## Overview

`std-cli` is an optional package that provides utilities and conventions for building command-line interface tools in AiLang. It is maintained as part of the `ailang-core-packages` repository and can be used by any AiLang project.

## Installation

Add `std-cli` as a dependency in your `project.aiproj`:

```xml
Project(
  name="YourCLI"
  entryFile="src/app.aos"
  entryExport="main"
  version="1.0.0"
) {
  Include(package="std-cli" version="^0.0.1-alpha.1")
}
```

## Usage

Import the CLI utilities in your AiLang source files:

```aos
Program {
  Import(path="std-cli")

  Let(name=main) {
    Fn(params=args) {
      Block {
        Let(name=cmd) { Call(target=readArg) { Var(name=args) Lit(value=0) } }
        // Your CLI logic here
      }
    }
  }
}
```

## Exported Functions

### Cross-Platform Argument Parsing (POSIX/GNU + DOS/Windows)

**New in 0.0.1-alpha.1**: Full POSIX Utility Syntax Guidelines and GNU Command-Line Extensions support, with automatic DOS/Windows convention support.

- **`parseArgs(args, optionDefs)`** - Parse arguments following POSIX/GNU or DOS conventions (auto-detected)
  - Returns structured result with `options`, `flags`, `positional`, and `errors`
  - `optionDefs`: Map of option names to `true` if they take values
- **`getOption(parsedArgs, name, defaultValue)`** - Get option value from parsed result
- **`hasFlag(parsedArgs, name)`** - Check if flag is set in parsed result
- **`getPositional(parsedArgs, index)`** - Get positional argument by index
- **`getPositionalCount(parsedArgs)`** - Get count of positional arguments
- **`getAllPositional(parsedArgs)`** - Get all positional arguments as list
- **`isHelpRequested(parsedArgs)`** - Check if help was requested (`--help`, `-h`, `/?`)
- **`isVersionRequested(parsedArgs)`** - Check if version was requested (`--version`, `-V`)

**Supported POSIX/GNU syntax:**
- `-v` - Short flag
- `-abc` - Combined short flags (equivalent to `-a -b -c`)
- `-o value` - Short option with value
- `-ovalue` - Short option with attached value
- `--verbose` - Long flag
- `--output value` - Long option with value
- `--output=value` - Long option with `=` syntax
- `--` - End of options marker (everything after is positional)

**Supported DOS/Windows syntax:**
- `/v` - Flag
- `/output:value` - Option with value using `:`
- `/output value` - Option with value using space

**Platform detection:** Automatically detects which convention to use based on argument patterns (defaults to POSIX unless `/` prefix detected).

### File I/O

- **`writeTextFile(path, text)`** - Write text to file
- **`readTextFile(path)`** - Read text from file
- **`readOptionalLockText(path)`** - Read lock file if it exists, return empty string otherwise

### Help and Version Formatting

- **`formatHelp(appInfo, commands, options)`** - Format complete help message with usage, commands, and options
- **`formatCommandList(commands)`** - Format command list section
- **`formatUsage(appName)`** - Format usage line
- **`formatVersion(appInfo)`** - Format version information
- **`showHelp(appInfo, commands, options)`** - Display help and exit with code 0
- **`showVersion(appInfo)`** - Display version and exit with code 0

**Help message format:**
```
myapp - Description of your application

USAGE:
  myapp <command> [options] [args]

COMMANDS:
  clean           Clean build artifacts
  build           Build the project
  run             Run the application

OPTIONS:
  -h, --help      Show this help message
  -V, --version   Show version information
  -v, --verbose   Enable verbose output
```

### Error Handling

- **`missingPath(command)`** - Report missing path error (returns exit code 1)
- **`buildError(code, message, nodeId)`** - Report build error with code and message (returns exit code 1)
- **`unknownCommand(command)`** - Report unknown command error (returns exit code 1)
- **`notImplemented(command)`** - Report not implemented error (returns exit code 1)

## Examples

### POSIX/GNU Style CLI with Options and Flags

```aos
Program {
  Import(package="std-cli" namespace="std.cli.args")
  Export(name=main)

  Let(name=main) {
    Fn(params=args) {
      Block {
        // Define which options take values
        Let(name=optionDefs) {
          Map {
            Entry { Lit(value="name") Lit(value=true) }
            Entry { Lit(value="n") Lit(value=true) }
            Entry { Lit(value="output") Lit(value=true) }
            Entry { Lit(value="o") Lit(value=true) }
          }
        }

        // Parse arguments
        Let(name=parsed) { Call(target=parseArgs) { Var(name=args) Var(name=optionDefs) } }

        // Get options with defaults
        Let(name=name) { Call(target=getOption) { Var(name=parsed) Lit(value="name") Lit(value="World") } }
        Let(name=output) { Call(target=getOption) { Var(name=parsed) Lit(value="output") Lit(value="") } }

        // Check flags (both short and long names work)
        Let(name=verbose) { Call(target=hasFlag) { Var(name=parsed) Lit(value="v") } }
        Let(name=verboseLong) { Call(target=hasFlag) { Var(name=parsed) Lit(value="verbose") } }
        Let(name=isVerbose) { Or { Var(name=verbose) Var(name=verboseLong) } }

        // Get positional arguments
        Let(name=command) { Call(target=getPositional) { Var(name=parsed) Lit(value=0) } }

        // Execute command
        If {
          Eq { Var(name=command) Lit(value="greet") }
          Block {
            Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="Hello, ") Var(name=name) } }

            If {
              Var(name=isVerbose)
              Block { Call(target=sys.stdout.writeLine) { Lit(value="Verbose mode enabled") } }
              Block { Lit(value=0) }
            }

            Return { Lit(value=0) }
          }
          Block { Return { Call(target=unknownCommand) { Var(name=command) } } }
        }
      }
    }
  }
}
```

**Usage examples:**
```bash
# POSIX/GNU style (Unix/Linux/macOS)
myapp greet --name Alice -v
myapp greet -n Alice --verbose
myapp greet --name=Alice -v
myapp greet -vn Alice

# DOS/Windows style
myapp greet /name:Alice /v
myapp greet /name Alice /verbose

# With positional arguments
myapp greet Alice Bob Charlie --verbose
# Positional: ["Alice", "Bob", "Charlie"]

# End of options marker
myapp process --verbose -- --file-that-looks-like-flag.txt
# Positional: ["--file-that-looks-like-flag.txt"]
```

### CLI with Help and Version Support

```aos
Program {
  Import(package="std-cli" namespace="std.cli.args")
  Import(package="std-cli" namespace="std.cli.help")
  Export(name=main)

  Let(name=main) {
    Fn(params=args) {
      Block {
        // Define application info
        Let(name=appInfo) {
          Map {
            Entry { Lit(value="name") Lit(value="myapp") }
            Entry { Lit(value="version") Lit(value="1.0.0") }
            Entry { Lit(value="description") Lit(value="My awesome CLI application") }
            Entry { Lit(value="author") Lit(value="Your Name") }
          }
        }

        // Define which options take values
        Let(name=optionDefs) {
          Map {
            Entry { Lit(value="output") Lit(value=true) }
            Entry { Lit(value="o") Lit(value=true) }
          }
        }

        // Parse arguments
        Let(name=parsed) { Call(target=parseArgs) { Var(name=args) Var(name=optionDefs) } }

        // Handle help request
        If {
          Call(target=isHelpRequested) { Var(name=parsed) }
          Block {
            Let(name=commands) {
              List {
                Map {
                  Entry { Lit(value="command") Lit(value="build") }
                  Entry { Lit(value="summary") Lit(value="Build the project") }
                }
                Map {
                  Entry { Lit(value="command") Lit(value="run") }
                  Entry { Lit(value="summary") Lit(value="Run the application") }
                }
              }
            }

            Let(name=options) {
              List {
                Map {
                  Entry { Lit(value="short") Lit(value="h") }
                  Entry { Lit(value="name") Lit(value="help") }
                  Entry { Lit(value="description") Lit(value="Show this help message") }
                  Entry { Lit(value="takesValue") Lit(value=false) }
                }
                Map {
                  Entry { Lit(value="short") Lit(value="V") }
                  Entry { Lit(value="name") Lit(value="version") }
                  Entry { Lit(value="description") Lit(value="Show version information") }
                  Entry { Lit(value="takesValue") Lit(value=false) }
                }
              }
            }

            Return { Call(target=showHelp) { Var(name=appInfo) Var(name=commands) Var(name=options) } }
          }
          Block { Lit(value=0) }
        }

        // Handle version request
        If {
          Call(target=isVersionRequested) { Var(name=parsed) }
          Block { Return { Call(target=showVersion) { Var(name=appInfo) } } }
          Block { Lit(value=0) }
        }

        // Normal command processing
        Let(name=command) { Call(target=getPositional) { Var(name=parsed) Lit(value=0) } }
        
        If {
          Eq { Var(name=command) Lit(value="build") }
          Block {
            Call(target=sys.stdout.writeLine) { Lit(value="Building...") }
            Return { Lit(value=0) }
          }
          Block { Return { Call(target=unknownCommand) { Var(name=command) } } }
        }
      }
    }
  }
}
```

**Usage examples:**
```bash
# Show help
myapp --help
myapp -h
myapp /?        # Windows style

# Show version
myapp --version
myapp -V

# Output:
# myapp version 1.0.0
```

## Project Structure

std-cli supports modular subcommand architecture with automatic dispatch and separate compilation:

### Source Structure
```
AiLang/
  | project.aiproj
  | command.md              # Main app metadata
  L src/
    | app.aos               # Main entry point
    L cli/
      L Build/
        | command.md        # Build command metadata
        L build.aos         # Build command implementation
      L Run/
        | command.md
        L run.aos
      ...
```

### Published Structure
```
ailang/
  | ailang*                 # Main executable
  L lib/
    | ailang.aibc1          # Main app bytecode
    L command/
      | build.aibc1         # Build subcommand bytecode
      | run.aibc1           # Run subcommand bytecode
      ...
```

## Command Metadata Format

Each command should have a `command.md` file with YAML front matter:

```markdown
---
command: build
summary: Compile a source file into a binary
usage: build [options] <source_file>
options:
  - short: o
    name: output
    description: Output file path
    takesValue: true
  - short: v
    name: verbose
    description: Enable verbose output
    takesValue: false
---

# Build Command

Additional documentation goes here after the front matter.
This content is preserved and can be used for detailed help.
```

**Required front matter fields:**
- `command`: Command name
- `summary`: Short one-line description
- `usage`: Usage pattern (optional, auto-generated if omitted)
- `options`: List of command-specific options (optional)

## Automatic Dispatch

The generated `dispatchCommand` function automatically handles:
- Help flag detection (`--help`, `-h`, `/?`)
- Version flag detection (`--version`, `-V`)
- Command lookup and execution
- Unknown command errors

**Generated code (commands.g.aos):**
```aos
Let(name=dispatchCommand) {
  Fn(params=appInfo,options,args) {
    Block {
      Return { 
        Call(target=dispatch) { 
          Var(name=appInfo) 
          Call(target=commandRegistry) { Lit(value=0) } 
          Var(name=options) 
          Var(name=getCommandFunction) 
          Var(name=args) 
        } 
      }
    }
  }
}
```

## Subcommand Compilation

Build each subcommand into separate `.aibc1` files for fast loading:

```aos
Import(package="std-cli" namespace="std.cli.build")

Let(name=buildResult) {
  Call(target=buildSubcommands) {
    Lit(value="src/cli")           // CLI source directory
    Lit(value="build/lib/command")  // Output directory
  }
}
```

**What it does:**
1. Scans `src/cli` for command directories
2. Compiles each `command.aos` to `.aibc1`
3. Outputs to `build/lib/command/build.aibc1`, etc.
4. Returns build status and list of built commands

## Current Status

**Version**: 0.0.1-alpha.1

This is an early alpha release. The API may change in future versions.

### Currently Available

- ✅ **POSIX/GNU compliant argument parsing** - Full support for short/long options, combined flags, `--option=value` syntax, `--` end-of-options
- ✅ **DOS/Windows argument parsing** - `/option:value` and `/flag` support with automatic detection
- ✅ **Cross-platform detection** - Automatically chooses POSIX or DOS mode based on argument patterns
- ✅ **Help message formatting** - Professional help output with usage, commands, and options sections
- ✅ **Version display** - Standard version information formatting
- ✅ **Help/version detection** - Automatic detection of `--help`, `-h`, `/?`, `--version`, `-V`
- ✅ **Command metadata parsing** - Parse `command.md` YAML front matter
- ✅ **Command directory scanning** - Discover commands in CLI directory structure
- ✅ **Code generation** - Generate command registry from command metadata
- ✅ **File I/O helpers** - Text file read/write utilities
- ✅ **Standard error reporting** - Consistent error message formatting

### Planned Features (Future Releases)

- 🔜 Type-safe argument validation
- 🔜 Command composition and delegation
- 🔜 Shell completion generation (bash, zsh, PowerShell)
- 🔜 Colorized output support

## Used By

- **AiLang CLI** - The official AiLang compiler command-line interface (planned integration)

## Contributing

Contributions are welcome! This package is maintained in the `ailang-core-packages` repository:

https://github.com/AiLangCore/ailang-core-packages

## License

Same license as AiLang.

## See Also

- [AiLang Documentation](https://ailangcore.github.io)
- [Package Registry](https://github.com/AiLangCore/ailang-packages)
- [Core Packages Repository](https://github.com/AiLangCore/ailang-core-packages)
