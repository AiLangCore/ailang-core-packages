# target-aios-gui

`target-aios-gui` adds the `aios-gui` package target to AiLang projects.

The target publishes an AiLang/AiVectra app into a small Linux initramfs and
runs it with QEMU. The guest boots directly into the app instead of a shell.

The current `x86_64` base uses glibc so it can run the Linux x64 runtime
artifacts staged by the AiLang SDK. A musl/static runtime profile can be added
later, but the base and runtime libc must match.

## Splash Assets

AiOS consumes the canonical AiVectra splash asset pair when present:

```text
src/Assets/Splash/background.svg
src/Assets/Splash/foreground.svg
```

These are app-owned cross-target assets. Other target packages, such as future
iOS and Android targets, should consume the same pair and transform it into
their platform-native launch or loading surfaces.

## Base Image Model

AiOS base images are versioned and cached:

```text
$AIOS_CACHE_ROOT/base/aios-gui/<aios-version>/<arch>/
  manifest.toml
  bzImage
  rootfs.cpio.gz
```

Application publish/run injects the current app payload and Linux runtime
artifacts into that cached base. It does not rebuild Buildroot for every app.

## Build Host

`build-base` requires a Linux build host because Buildroot base creation is a
Linux-hosted operation. macOS developers should consume a cached base produced
by CI or another Linux builder.

## Commands

Fetch the pinned Buildroot checkout:

```sh
ailang aios fetch-buildroot --buildroot-version 2026.02.3
```

Build a reusable AiOS GUI base on Linux:

```sh
ailang aios build-base \
  --target aios-gui \
  --version 0.0.1-alpha.1 \
  --arch x86_64 \
  --buildroot-version 2026.02.3
```

Verify the cached base:

```sh
ailang aios verify-base \
  --target aios-gui \
  --version 0.0.1-alpha.1 \
  --arch x86_64
```

Import a base artifact downloaded from CI:

```sh
ailang aios import-base \
  --target aios-gui \
  --version 0.0.1-alpha.1 \
  --arch x86_64 \
  --from ./aios-gui-0.0.1-alpha.1-x86_64
```

Run an app with the cached base:

```sh
ailang run . \
  --target aios-gui \
  --target-version 0.0.1-alpha.1 \
  --boot qemu-kernel \
  --image cpio.gz \
  --partition none
```

The QEMU window should show kernel and AiOS launch diagnostics during boot. If
the app runtime exits, AiOS drops to a shell instead of panicking so the boot
state can be inspected.

For terminal diagnostics, pass QEMU serial flags after `--`:

```sh
ailang run . \
  --target aios-gui \
  --target-version 0.0.1-alpha.1 \
  -- -display none -serial stdio -no-reboot
```

Publish an app image without starting QEMU:

```sh
ailang publish . \
  --target aios-gui \
  --type img \
  --target-version 0.0.1-alpha.1 \
  --boot qemu-kernel \
  --image cpio.gz \
  --partition none \
  --out dist-aios
```

## Target Options

Implemented:

```text
--arch x86_64
--boot qemu-kernel
--image cpio.gz
--partition none
--feature network
--splash-background <svg>
--splash-foreground <svg>
```

Generic target-option spelling is also supported:

```sh
ailang publish . \
  --target aios-gui \
  --target-option boot=qemu-kernel \
  --target-option image=cpio.gz \
  --target-option partition=none
```

Declared but not implemented yet:

```text
--arch aarch64
--boot disk
--boot iso
--boot uefi
--image ext4
--image squashfs
--image tar.gz
--image iso
--partition mbr
--partition gpt
--feature printer
--feature audio
--feature wifi
--feature bluetooth
--feature gpu
--feature storage
```

Unsupported or not-yet-implemented options fail deterministically before image
publish or base build begins.
