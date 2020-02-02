FROM crystallang/crystal:latest
ADD . /src
WORKDIR /src

# Build App
RUN shards build --production

# Run tests
RUN crystal spec

# Extract dependencies
RUN ldd bin/app | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'

# Build a minimal docker image
FROM scratch
COPY --from=0 /src/deps /
COPY --from=0 /src/bin/app /app

# These are required if your application needs to communicate with a database
# or any other external service where DNS is used to connect.
COPY --from=0 /lib/x86_64-linux-gnu/libnss_dns.so.2 /lib/x86_64-linux-gnu/libnss_dns.so.2
COPY --from=0 /lib/x86_64-linux-gnu/libresolv.so.2 /lib/x86_64-linux-gnu/libresolv.so.2

# Run the app binding on port 8080
EXPOSE 8080
ENTRYPOINT ["/app"]
CMD ["/app", "-b", "0.0.0.0", "-p", "8080"]
