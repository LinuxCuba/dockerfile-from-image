FROM alpine:3.11
MAINTAINER Arian Molina <linuxcuba@teknik.io>

RUN apk update && \
    apk --no-cache add ruby-dev ruby make gcc libc-dev ca-certificates && \
    gem install --no-document excon docker-api && \
    apk del ruby-dev make gcc libc-dev && \
    apk add --no-cache ruby-json && \
    rm /var/cache/apk/*

ADD dockerfile-from-image.rb /usr/src/app/dockerfile-from-image.rb

ENTRYPOINT ["/usr/src/app/dockerfile-from-image.rb"]
CMD ["--help"]
