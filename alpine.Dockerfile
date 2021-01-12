FROM rust:1.49-alpine AS build
WORKDIR /deno
COPY . .

# we gotta install python or curl for rusty_v8
# couldn't get python to work, so curl it is!
RUN apk add --no-cache curl

RUN rustup target add wasm32-unknown-unknown && rustup target add wasm32-wasi
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
	  --mount=type=cache,target=/deno/target \
    cargo build --release --locked
# just for fun, let's also run Deno's tests to see what we get
RUN cargo test --release --locked

FROM alpine:3.12 AS run
COPY --from=build /deno/target/release/deno /usr/local/deno

ENTRYPOINT ["deno"]
CMD ["run", "https://deno.land/std/examples/welcome.ts"]