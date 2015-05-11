FROM alpine:latest

RUN apk add --update cdrkit && rm -rf /var/cache/apk/*

VOLUME ["/configdrive"]

ADD start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
