# Cross toolchain prefix (adjust if needed)
CROSS ?= i686-elf
AS    := $(CROSS)-as
CC    := $(CROSS)-gcc

QEMU  ?= qemu-system-i386

CFLAGS  := -std=gnu99 -ffreestanding -O2 -Wall -Wextra
LDFLAGS := -T linker.ld -ffreestanding -O2 -nostdlib

OBJS := boot.o kernel.o

.PHONY: all clean run iso run-iso check iso-deps docker-image docker-myos docker-all docker-clean

# Docker image tag (see Dockerfile comment)
DOCKER_IMAGE ?= gcc-cross-i686-elf:with-make

all: myos.bin

boot.o: boot.s
	$(AS) $< -o $@

kernel.o: kernel.c
	$(CC) -c $< -o $@ $(CFLAGS)

myos.bin: $(OBJS) linker.ld
	$(CC) $(LDFLAGS) -o $@ $(OBJS) -lgcc

# Optional sanity check if grub-file is available
check: myos.bin
	@command -v grub-file >/dev/null 2>&1 && \
	  grub-file --is-x86-multiboot myos.bin && echo "multiboot confirmed" || \
	  echo "(grub-file not found or not multiboot)" || true

iso-deps:
	@MISSING=0; \
	for t in grub-mkrescue xorriso mformat; do \
	  if ! command -v $$t >/dev/null 2>&1; then \
	    echo "Missing tool: $$t"; \
	    MISSING=1; \
	  fi; \
	done; \
	if [ $$MISSING -eq 1 ]; then \
	  echo "Install required tools (e.g. Debian/Ubuntu): sudo apt-get install -y grub-pc-bin xorriso mtools"; \
	  exit 1; \
	fi

iso: iso-deps myos.bin grub.cfg
	mkdir -p isodir/boot/grub
	cp myos.bin isodir/boot/myos.bin
	cp grub.cfg isodir/boot/grub/grub.cfg
	grub-mkrescue -o myos.iso isodir

run: myos.bin
	$(QEMU) -kernel myos.bin

run-iso: myos.iso
	$(QEMU) -cdrom myos.iso

clean:
	rm -rf $(OBJS) myos.bin isodir myos.iso

# --- Docker helpers ---
# Build the local Docker image defined by ./Dockerfile
docker-image:
	docker build -t $(DOCKER_IMAGE) .

# Build myos.bin inside the Docker container (no host toolchain required)
docker-myos: docker-image
	docker run --rm -v "$(PWD)":/work -w /work $(DOCKER_IMAGE) make myos.bin

# Build myos.iso inside the Docker container (no host toolchain required)
docker-iso: docker-image
	docker run --rm -v "$(PWD)":/work -w /work $(DOCKER_IMAGE) make iso

# Run a full `make all` inside the container
docker-all: docker-image
	docker run --rm -v "$(PWD)":/work -w /work $(DOCKER_IMAGE) make all

# Clean artifacts using the container
docker-clean: docker-image
	docker run --rm -v "$(PWD)":/work -w /work $(DOCKER_IMAGE) make clean

