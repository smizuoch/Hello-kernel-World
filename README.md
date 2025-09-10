# Hello-kernel-World

A tiny i386 Multiboot-compatible “Hello, kernel World!” written in C with a minimal assembly boot stub. It prints a few lines to the VGA text buffer, supports newline and simple scrolling, and can be run directly in QEMU or packaged as a bootable ISO via GRUB.

## Features
- Multiboot header (compatible with GRUB and similar bootloaders)
- Minimal 16 KiB stack and C `kernel_main`
- Direct VGA text mode output with newline + scroll support
- Simple `Makefile` with local and Docker-based builds
- QEMU run targets and GRUB ISO creation

## Requirements (local toolchain)
To build natively on Linux without Docker, you need an i686-elf cross toolchain:
- `i686-elf-gcc`, `i686-elf-as`
- `qemu-system-i386` to run
- Optional: `grub-mkrescue`, `xorriso` for ISO creation; `grub-file` for multiboot checks

If you don’t have a cross toolchain, use the included Docker workflow instead.

## Build and Run (Local)
```sh
# Build kernel binary
make

# Sanity check the multiboot header (optional)
make check

# Run directly with QEMU (loads kernel as a Multiboot kernel)
make run

# Create a bootable ISO via GRUB, then run it
make iso
make run-iso
```

Outputs produced:
- `myos.bin`: the linked kernel binary (Multiboot-compliant)
- `myos.iso`: bootable ISO (after `make iso`)

## Build and Run (Docker)
You don’t need to install a cross toolchain locally. The provided `Dockerfile` builds an image with `i686-elf` GCC and `make`.

```sh
# Build the Docker image
make docker-image

# Build inside the container (produces myos.bin)
make docker-myos

# Or run a full build inside the container (equivalent to `make all`)
make docker-all

# Clean artifacts via container
make docker-clean
```

The Docker image tag defaults to `gcc-cross-i686-elf:with-make` and can be overridden via `DOCKER_IMAGE=...`.

## Project Layout
- `boot.s`: Multiboot header + tiny entry stub; sets up stack and calls `kernel_main`.
- `kernel.c`: Minimal kernel that writes to VGA text buffer, with scrolling.
- `linker.ld`: Places sections and sets entry to `_start`; loads at 2 MiB.
- `grub.cfg`: GRUB menu used when creating an ISO.
- `Makefile`: Targets for building, running, ISO creation, and Docker helpers.
- `Dockerfile`: Builds a container with `i686-elf` cross-compiler and make.

## How It Works (Brief)
- The Multiboot header in `boot.s` lets GRUB/QEMU recognize and load the kernel.
- `_start` sets up a 16 KiB stack and calls `kernel_main`.
- `kernel.c` writes characters into VGA memory at `0xB8000` (80x25 text mode).
- Simple newline handling and buffer shift implement one-line scrolling.

## Troubleshooting
- QEMU not found: install `qemu-system-i386` or use Docker ISO flow.
- `grub-mkrescue` missing: install `grub-pc-bin` and `xorriso` (package names vary by distro), or skip ISO and run with `make run`.
- Compiler errors about not using cross-compiler: ensure `i686-elf-gcc` is used. The `Makefile` uses `i686-elf` by default; override with `CROSS=...` if needed.
- Permission issues with Docker: ensure your user can run Docker or use `sudo`.

## Customization Tips
- Change text output in `kernel.c` inside `kernel_main`.
- Adjust load address or sections in `linker.ld` if you integrate more components.
- Add more drivers or higher-level features incrementally; keep freestanding flags (`-ffreestanding`, `-nostdlib`).

## Acknowledgements
Inspired by the OSDev Wiki “Bare Bones” tutorials and the broader hobby OS community.
