FROM crystallang/crystal:latest
ADD . /src
WORKDIR /src

# Install any additional dependencies
# RUN apt-get update
# RUN apt-get install --no-install-recommends -y iputils-ping curl
# RUN rm -rf /var/lib/apt/lists/*

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

# These are required if your application needs to communicate with a database
# or any other external service where DNS is used to connect.
COPY --from=0 /lib/x86_64-linux-gnu/libnss_dns.so.2 /lib/x86_64-linux-gnu/libnss_dns.so.2
COPY --from=0 /lib/x86_64-linux-gnu/libresolv.so.2 /lib/x86_64-linux-gnu/libresolv.so.2
COPY --from=0 /etc/hosts /etc/hosts

# This is required for Timezone support
COPY --from=0 /usr/share/zoneinfo/ /usr/share/zoneinfo/
# COPY --from=0 /usr/share/lib/zoneinfo/ /usr/share/lib/zoneinfo/
# COPY --from=0 /usr/lib/locale/TZ/ /usr/lib/locale/TZ/

# Run the app binding on port 8080
EXPOSE 8080
ENTRYPOINT ["/app"]
HEALTHCHECK CMD ["/app", "-c", "http://127.0.0.1:8080/"]
CMD ["/app", "-b", "0.0.0.0", "-p", "8080"]
