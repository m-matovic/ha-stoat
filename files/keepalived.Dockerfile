FROM alpine:latest
RUN apk add --no-cache keepalived curl jq ca-certificates bash iproute2
COPY notify.sh /etc/keepalived/notify.sh
RUN chmod 755 /etc/keepalived/notify.sh && chown root:root /etc/keepalived/notify.sh
CMD ["keepalived", "--dont-fork", "--log-console"]