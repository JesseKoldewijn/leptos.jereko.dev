# Stage 1: Build the application
FROM rust:slim-trixie AS builder

# Build arguments with defaults
ARG PORT=8080
ARG OUTPUT_NAME=leptos-jereko
ARG LEPTOS_SITE_ADDR=0.0.0.0:${PORT}
ARG LEPTOS_RELOAD_PORT=3001

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    libssl-dev \
    perl \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy rust-toolchain.toml to respect the project's toolchain
COPY rust-toolchain.toml ./

# Add wasm target and rust-src for the toolchain specified in rust-toolchain.toml
RUN rustup target add wasm32-unknown-unknown && \
    rustup component add rust-src

# Install cargo-leptos
RUN cargo install cargo-leptos --locked

# Copy dependency files for better caching
COPY Cargo.toml Cargo.lock* ./
COPY .cargo .cargo

# Copy the rest of the project
COPY . .

# Set environment variables using build args
ENV PORT=${PORT}
ENV LEPTOS_OUTPUT_NAME=${OUTPUT_NAME}
ENV LEPTOS_SITE_ROOT="site"
ENV LEPTOS_SITE_PKG_DIR="pkg"
ENV LEPTOS_SITE_ADDR=${LEPTOS_SITE_ADDR}
ENV LEPTOS_RELOAD_PORT=${LEPTOS_RELOAD_PORT}
ENV LEPTOS_ENV="PROD"

# Build the application in release mode
RUN cargo leptos build --release

# Stage 2: Runtime image
FROM debian:trixie-slim

# Build arguments need to be redeclared in each stage
ARG PORT=8080
ARG OUTPUT_NAME=leptos-jereko
ARG LEPTOS_SITE_ADDR=0.0.0.0:${PORT}
ARG LEPTOS_RELOAD_PORT=3001

# Install runtime dependencies and create non-root user
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1001 leptos

# Set the working directory
WORKDIR /app

# Copy the server binary from the builder (using the build arg)
COPY --from=builder /app/target/release/${OUTPUT_NAME} /app/app

# Copy the site directory with all static assets
COPY --from=builder /app/target/site /app/site

# Change ownership to the leptos user
RUN chown -R leptos:leptos /app

# Switch to non-root user
USER leptos

# Set environment variables using build args
ENV PORT=${PORT}
ENV LEPTOS_OUTPUT_NAME=${OUTPUT_NAME}
ENV LEPTOS_SITE_ROOT="site"
ENV LEPTOS_SITE_PKG_DIR="pkg"
ENV LEPTOS_SITE_ADDR=${LEPTOS_SITE_ADDR}
ENV LEPTOS_RELOAD_PORT=${LEPTOS_RELOAD_PORT}
ENV LEPTOS_ENV="PROD"

# Expose the port (extract from LEPTOS_SITE_ADDR)
EXPOSE $PORT

# Run the server
CMD ["./app"]
