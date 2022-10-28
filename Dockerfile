FROM 84codes/crystal:latest-alpine as build
WORKDIR /app

# Create a non-privileged user, defaults are appuser:10001
ARG IMAGE_UID="10001"
ENV UID=$IMAGE_UID
ENV USER=appuser

# See https://stackoverflow.com/a/55757473/12429735
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

# Add dependencies commonly required for building crystal applications
# hadolint ignore=DL3018
RUN apk add \
  --update \
  --no-cache \
    gcc \
    make \
    autoconf \
    automake \
    libtool \
    patch \
    ca-certificates \
    yaml-dev \
    yaml-static \
    git \
    bash \
    iputils \
    libelf \
    gmp-dev \
    libxml2-dev \
    musl-dev \
    pcre-dev \
    zlib-dev \
    zlib-static \
    libunwind-dev \
    libunwind-static \
    libevent-dev \
    libevent-static \
    libssh2-static \
    lz4-dev \
    lz4-static \
    tzdata \
    curl

# Already included in the image
# openssl-dev
# openssl-libs-static

RUN update-ca-certificates

# Install any additional dependencies
# RUN apk add libssh2 libssh2-dev

# Install shards for caching
COPY shard.yml shard.yml
COPY shard.override.yml shard.override.yml
COPY shard.lock shard.lock

RUN shards install --production --ignore-crystal-version --skip-postinstall --skip-executables

# Add src
COPY ./src /app/src

# Build application
RUN shards build --production --release --error-trace
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Extract binary dependencies (uncomment if not compiling a static build)
RUN for binary in /app/bin/*; do \
        ldd "$binary" | \
        tr -s '[:blank:]' '\n' | \
        grep '^/' | \
        xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'; \
    done

# Generate OpenAPI docs while we still have source code access
RUN ./bin/app --docs --file=openapi.yml

# Build a minimal docker image
FROM scratch
WORKDIR /
ENV PATH=$PATH:/

# Copy the user information over
COPY --from=build etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group

# These are required for communicating with external services
COPY --from=build /etc/hosts /etc/hosts

# These provide certificate chain validation where communicating with external services over TLS
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# This is required for Timezone support
COPY --from=build /usr/share/zoneinfo/ /usr/share/zoneinfo/

# This is your application
COPY --from=build /app/deps /
COPY --from=build /app/bin /

# Copy the docs into the container, you can serve this file in your app
COPY --from=build /app/openapi.yml /openapi.yml

# Use an unprivileged user.
USER appuser:appuser

# Spider-gazelle has a built in helper for health checks (change this as desired for your applications)
HEALTHCHECK CMD ["/app", "-c", "http://127.0.0.1:3000/"]

# Run the app binding on port 3000
EXPOSE 3000
ENTRYPOINT ["/app"]
CMD ["/app", "-b", "0.0.0.0", "-p", "3000"]
