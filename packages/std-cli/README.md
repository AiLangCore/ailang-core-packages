# std.cli

`std-cli` provides the `std.cli` AiLang package for deterministic command-line
applications. Applications explicitly construct an application descriptor,
register command descriptors, and call `run`.

The package owns command lookup, parsing, validation, intrinsic help/version,
diagnostics, canonical rendering, and exit-result handling. The host supplies
only process arguments and standard streams.

```aos
Program {
  Import(package="std-cli" namespace="std.cli")
  Export(name=start)

  Let(name=cliCommandHandler) {
    Fn(params=invocation) {
      Block {
        Call(target=sys.stdout.writeLine) {
          Call(target=invocationPositional) {
            Var(name=invocation)
            Lit(value=0)
            Lit(value="world")
          }
        }
        Return { Lit(value=0) }
      }
    }
  }

  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=command0) {
          Call(target=createCommand) {
            Lit(value="greet")
            Lit(value="Greet a person")
            Lit(value="greet")
          }
        }
        Let(name=command1) {
          Call(target=commandWithArgument) {
            Var(name=command0)
            Call(target=createArgument) {
              Lit(value="name")
              Lit(value=true)
              Lit(value="Person to greet")
            }
          }
        }
        Let(name=app0) {
          Call(target=createApplication) {
            Lit(value="sample")
            Lit(value="1.0.0")
            Lit(value="Sample CLI")
          }
        }
        Let(name=app1) {
          Call(target=registerCommand) {
            Var(name=app0)
            Var(name=command1)
          }
        }
        Return { Call(target=run) { Var(name=app1) Var(name=args) } }
      }
    }
  }
}
```

The current self-hosted compiler does not lower first-class function values.
For that reason descriptors carry a stable handler name and the application
implements the statically linked `cliCommandHandler(invocation)` entrypoint.
The invocation contains both `command` and `handler`. This keeps handler
selection in AiLang and gives future generated registration the same public
descriptor API.

See [SPEC.md](SPEC.md) for the normative parsing, rendering, diagnostic, and
exit-code contract.
