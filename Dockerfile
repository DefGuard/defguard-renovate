FROM public.ecr.aws/docker/library/node:24@sha256:392e1e23f34da768d8d1f4e502b64f200d3be3465934d4b7930f57d7e2fc1989 AS web

WORKDIR /app
COPY web/package.json web/pnpm-lock.yaml web/pnpm-workspace.yaml web/.npmrc ./
RUN npm i -g pnpm
RUN pnpm install --ignore-scripts --frozen-lockfile
COPY web/ .
RUN pnpm run generate-translation-types
RUN pnpm build

FROM public.ecr.aws/docker/library/rust:1@sha256:1f0dbad1df66647807e6952d1db85d0b2bda7606cb2139d82517e4f009967376 AS chef

WORKDIR /build

# install & cache necessary components
RUN cargo install cargo-chef
RUN rustup component add rustfmt

FROM chef AS planner
# prepare recipe
COPY Cargo.toml Cargo.lock ./
COPY crates crates
COPY proto proto
COPY migrations migrations
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
# build deps from recipe & cache as docker layer
COPY --from=planner /build/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

# build project
COPY --from=web /app/dist ./web/dist
COPY web/src/shared/images/svg ./web/src/shared/images/svg
RUN apt-get update && apt-get -y install protobuf-compiler libprotobuf-dev
COPY Cargo.toml Cargo.lock ./
# for vergen
COPY .git .git
COPY .sqlx .sqlx
COPY crates crates
COPY proto proto
COPY migrations migrations
RUN cargo install --locked --bin defguard --path ./crates/defguard --root /build

# run
FROM public.ecr.aws/docker/library/debian:13-slim@sha256:28de0877c2189802884ccd20f15ee41c203573bd87bb6b883f5f46362d24c5c2
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install --no-install-recommends -y ca-certificates libssl-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /build/bin/defguard .
ENTRYPOINT ["./defguard"]
