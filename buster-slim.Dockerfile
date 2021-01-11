FROM rust:1.49-slim AS planner
WORKDIR /app
RUN cargo install cargo-chef
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM rust:1.49-slim AS cacher
WORKDIR /app
RUN cargo install cargo-chef
COPY --from=planner /app/recipe.json recipe.json

# we gotta install python or curl for rusty_v8
# couldn't get python to work, so curl it is!
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update --no-install-recommends && \
  apt-get -qq install -y curl --no-install-recommends

RUN rustup target add wasm32-unknown-unknown && rustup target add wasm32-wasi
RUN cargo chef cook --release --recipe-path recipe.json

FROM rust:1.49-slim AS builder
WORKDIR /app
RUN cargo install cargo-chef
COPY . .
COPY --from=cacher /app/target target
COPY --from=cacher $CARGO_HOME $CARGO_HOME

RUN rustup target add wasm32-unknown-unknown && rustup target add wasm32-wasi
RUN cargo build --release --locked --all-targets
# just for fun, let's also run Deno's tests to see what we get
RUN cargo test --release --locked --all-targets

FROM debian:buster-slim AS run
COPY --from=builder /app/target/release/deno /usr/local/deno

ENTRYPOINT ["deno"]
CMD ["run", "https://deno.land/std/examples/welcome.ts"]