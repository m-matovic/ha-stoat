FROM caddy:builder AS builder
RUN xcaddy build --with github.com/pberkel/caddy-storage-redis
FROM caddy:alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
