#!/usr/bin/env bash
# Build the playground into one native binary. Needs machin + a C compiler;
# serving /compile additionally needs `machin` and `zig` on PATH at runtime
# (it shells out to `machin build --target wasm`).
set -e
cd "$(dirname "$0")"
machin encode framework/machweb.src ui.src app.src > app.mfl
machin build app.mfl -o playground
echo "built ./playground — run: PORT=8080 ./playground  (needs machin + zig on PATH)"
