# A self-contained playground image: builds machin from source (for the wasm
# unbuffered-stdout fix), installs zig for the wasm target, builds the playground.
FROM golang:1.25-bookworm AS build
RUN apt-get update && apt-get install -y --no-install-recommends gcc curl xz-utils ca-certificates libssl-dev && rm -rf /var/lib/apt/lists/*
# zig (for `machin build --target wasm`)
ARG ZIG=0.14.0
RUN curl -fsSL https://ziglang.org/download/${ZIG}/zig-linux-x86_64-${ZIG}.tar.xz | tar -xJ -C /opt && ln -s /opt/zig-linux-x86_64-${ZIG}/zig /usr/local/bin/zig
# machin from source (main has the wasm stdout-flush fix)
RUN git clone --depth 1 https://github.com/javimosch/machin /src/machin && cd /src/machin && make build && install -m755 bin/machin /usr/local/bin/machin
# the playground app
COPY . /src/playground
RUN cd /src/playground && machin encode framework/machweb.src ui.src app.src > app.mfl && machin build app.mfl -o /usr/local/bin/playground

FROM debian:bookworm-slim
# machin is a static Go binary and the wasm build uses `zig cc` (self-contained);
# the only runtime lib is OpenSSL — the playground binary links libcrypto (it uses
# rand_bytes for temp-file ids).
RUN apt-get update && apt-get install -y --no-install-recommends libssl3 && rm -rf /var/lib/apt/lists/*
COPY --from=build /usr/local/bin/machin /usr/local/bin/machin
COPY --from=build /usr/local/bin/playground /usr/local/bin/playground
COPY --from=build /opt /opt
RUN ln -s /opt/zig-linux-x86_64-*/zig /usr/local/bin/zig
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["playground"]
