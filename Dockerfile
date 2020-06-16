FROM crystallang/crystal:0.35.0-alpine
ADD . /src
WORKDIR /src

# Add trusted CAs for communicating with external services
RUN apk update && apk add --no-cache ca-certificates tzdata && update-ca-certificates

# Install any additional dependencies
# RUN apk add libssh2 libssh2-dev

# Create a non-privileged user
# defaults are appuser:10001
ARG IMAGE_UID="10001"
ENV UID=$IMAGE_UID
ENV USER=appuser

# See https://stackoverflow.com/a/55757473/12429735RUN
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

# Build App
RUN shards build --error-trace --production

# Extract dependencies
RUN ldd bin/app | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'

# Build a minimal docker image
FROM scratch
WORKDIR /
ENV PATH=$PATH:/
COPY --from=0 /src/deps /
COPY --from=0 /src/bin/app /app
COPY --from=0 /etc/hosts /etc/hosts

# These provide certificate chain validation where communicating with external services over TLS
COPY --from=0 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# This is required for Timezone support
COPY --from=0 /usr/share/zoneinfo/ /usr/share/zoneinfo/

# Copy the user information over
COPY --from=0 /etc/passwd /etc/passwd
COPY --from=0 /etc/group /etc/group

# Use an unprivileged user.
USER appuser:appuser

# Run the app binding on port 8080
EXPOSE 8080
ENTRYPOINT ["/app"]
HEALTHCHECK CMD ["/app", "-c", "http://127.0.0.1:8080/"]
CMD ["/app", "-b", "0.0.0.0", "-p", "8080"]
