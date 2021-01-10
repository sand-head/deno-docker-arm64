FROM rust:1.49-slim AS planner
WORKDIR /app
RUN cargo install cargo-chef
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM rust:1.49-slim AS cacher
WORKDIR /app
RUN cargo install cargo-chef
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

FROM rust:1.49-slim AS builder
WORKDIR /app
RUN cargo install cargo-chef
COPY --from=cacher /app/target target
COPY --from=cacher $CARGO_HOME $CARGO_HOME
RUN rustup target add wasm32-unknown-unknown && rustup target add wasm32-wasi
RUN cargo build --release 

FROM rust:1.49-slim AS run
COPY --from=builder /app/target/release/deno /usr/local/deno
ENTRYPOINT ["deno", "run", "https://deno.land/std/examples/welcome.ts"]