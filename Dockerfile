FROM caddy:builder AS builder
ARG GO_LINK
ENV GO_LINK=$GO_LINK

RUN xcaddy build --with $GO_LINK

FROM caddy:latest

COPY --from=builder /usr/bin/caddy /usr/bin/caddy