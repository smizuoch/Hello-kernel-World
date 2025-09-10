# Dockerfile
FROM techiekeith/gcc-cross-i686-elf:latest
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends make libmpc3 libmpfr6 libgmp10 \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /work

# docker build -t gcc-cross-i686-elf:with-make .
# docker run --rm -v "$PWD":/work -w /work gcc-cross-i686-elf:with-make make