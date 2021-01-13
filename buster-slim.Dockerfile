FROM rust:1.49-slim AS build
WORKDIR /deno
COPY . .

# we gotta install python or curl for rusty_v8
# couldn't get python to work, so curl it is!
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -qq update --no-install-recommends && \
    apt-get -qq install -y curl --no-install-recommends

RUN rustup target add wasm32-unknown-unknown && rustup target add wasm32-wasi
RUN --mount=type=cache,target=/usr/local/cargo,from=rust,source=/usr/local/cargo \
	  --mount=type=cache,target=target \
    cargo build --release && \
    cp target/release/deno deno
# just for fun, let's also run Deno's tests to see what we get
# RUN cargo test --release --locked

FROM debian:buster-slim AS run
COPY --from=build /deno/deno /usr/local/deno

ENTRYPOINT ["deno"]
CMD ["run", "https://deno.land/std/examples/welcome.ts"]