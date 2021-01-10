# build stage based on code attributed to Raphael Lechner under the MIT license: 
# https://github.com/lraphael/deno_docker_raspberry
FROM debian:stable-slim AS build

ARG DENO_VERISON=1.6.3
ARG DEBIAN_FRONTEND=noninteractive

# obtain everything
RUN apt-get -qq update && apt-get upgrade -y --no-install-recommends && \
    apt-get -qq install -y git ca-certificates curl tar build-essential python2 --no-install-recommends && \
    curl -fsSL https://github.com/denoland/deno/releases/download/v${DENO_VERISON}/deno_src.tar.gz --output deno_src.tar.gz && \
    tar -xf deno_src.tar.gz && \
    rm deno_src.tar.gz && \
    chmod 755 deno && \
    apt-get -qq clean && rm -rf /var/lib/apt/lists/*

# add third_party prebuilts missing in release tar, as well as rust
RUN git clone https://github.com/denoland/deno_third_party.git deno/third_party
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# build deno!
RUN . /root/.cargo/env && cd deno && rustup target add wasm32-unknown-unknown && rustup target add wasm32-wasi
RUN . /root/.cargo/env && cd deno && cargo build --release -v

# The Stage Where It Happens
FROM debian:stable-slim AS run

COPY --from=build deno/target/release/deno /usr/bin/deno

ENTRYPOINT [ "deno", "run", "https://deno.land/std/examples/welcome.ts" ]