# target-aios-gui

`target-aios-gui` adds the `aios-gui` package target to AiLang projects.

The target publishes an AiLang/AiVectra app into a small Linux initramfs and
runs it with QEMU. The guest boots directly into the app instead of a shell.

The current `x86_64` and `aarch64` bases use glibc so they can run the matching
Linux runtime artifacts staged by the AiLang SDK. A musl/static runtime profile
can be added later, but the base and runtime libc must match.

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

`bzImage` is the stable cached kernel filename used by the target package. For
`aarch64` builds, the Buildroot `Image` output is copied into that slot.

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

Build reusable AiOS GUI bases on Linux:

```sh
ailang aios build-base \
  --target aios-gui \
  --version 0.0.1-alpha.1 \
  --arch x86_64 \
  --buildroot-version 2026.02.3

ailang aios build-base \
  --target aios-gui \
  --version 0.0.1-alpha.1 \
  --arch aarch64 \
  --buildroot-version 2026.02.3
```

Verify the cached base:

```sh
ailang aios verify-base \
  --target aios-gui \
  --version 0.0.1-alpha.1 \
  --arch x86_64

ailang aios verify-base \
  --target aios-gui \
  --version 0.0.1-alpha.1 \
  --arch aarch64
```

Import a base artifact downloaded from CI:

```sh
ailang aios import-base \
  --target aios-gui \
  --version 0.0.1-alpha.1 \
  --arch x86_64 \
  --from ./aios-gui-0.0.1-alpha.1-x86_64

ailang aios import-base \
  --target aios-gui \
  --version 0.0.1-alpha.1 \
  --arch aarch64 \
  --from ./aios-gui-0.0.1-alpha.1-aarch64
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

To keep the QEMU window and mirror the serial boot/app log into the terminal:

```sh
ailang run . \
  --target aios-gui \
  --target-version 0.0.1-alpha.1 \
  --target-option debug-console=stdio
```

For terminal-only diagnostics, pass QEMU display flags after `--`:

```sh
ailang run . \
  --target aios-gui \
  --target-version 0.0.1-alpha.1 \
  --target-option debug-console=stdio \
  -- -display none -no-reboot
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

## Runtime Backend

AiOS GUI uses the SDK `runtimes/linux-*/aivectra` slot as a framebuffer host.
It does not require X11, Wayland, or a desktop shell in the base image. Generic
Linux desktop targets may use an X11 backend separately; AiOS intentionally
draws directly to `/dev/fb0`.

The Buildroot bases apply architecture-specific kernel fragments that enable the
QEMU framebuffer path (`/dev/fb0`) and framebuffer console support. If these
fragments change, rebuild or import a fresh cached AiOS base before testing
application changes.

Implemented:

```text
--arch x86_64
--arch aarch64
--boot qemu-kernel
--image cpio.gz
--partition none
--feature network
--splash-background <svg>
--splash-foreground <svg>
--target-option debug-console=stdio
--target-option runtime-log-level=<off|error|info|trace>
--target-option display-backend=<auto|framebuffer|drm>
--target-option drm-trace=<0|1>
```

`display-backend=auto` is the default. The launcher requests
`AILANG_AIOS_DISPLAY_BACKEND=drm` when `/dev/dri/card0` exists in the guest and
requests `framebuffer` otherwise. Current published runtimes may still use the
framebuffer backend until AiVectra's AiOS-only DRM/KMS host is built into the
runtime payload. `drm-trace=1` exports `AILANG_DRM_TRACE=1` for that backend.

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

## Known Follow-Ups

- `ailang debug .` and `ailang debug run .` do not yet route QEMU package
  targets correctly. Until that is fixed, use `ailang run . --target
  aios-gui ...` with `--target-option runtime-log-level=trace` for AiOS target
  testing.
- AiOS Linux bases must remain runnable under QEMU for every supported
  architecture. When adding or changing Linux base options, verify that the
  resulting base can boot with the matching `qemu-system-*` runner before
  treating the target as ready.
- Finish the AiOS-only DRM/KMS presentation backend in the AiVectra runtime
  payload. The target now exports `AILANG_AIOS_DISPLAY_BACKEND` and
  `AILANG_DRM_TRACE`, and the Buildroot fragments enable the expected virtio DRM
  kernel options. The remaining backend should open `/dev/dri/card0`, choose a
  connector/mode, allocate dumb buffers, render with the existing CPU rasterizer,
  and present through KMS/page flip. Keep the normal Linux desktop backend
  unchanged and keep framebuffer fallback.
