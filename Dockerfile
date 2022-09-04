FROM alpine:3.16

ARG FUEGO_VERSION
ARG FUEGO_CHECKSUM

RUN apk add --no-cache \
        jq \
        wget \
    && mkdir /tmp/fuego \
    && cd /tmp/fuego \
    && wget -q -O fuego.tar.gz https://github.com/sgarciac/fuego/releases/download/${FUEGO_VERSION}/fuego_${FUEGO_VERSION}_Linux_64-bit.tar.gz \
    && if [ "${FUEGO_CHECKSUM}" != "$(sha256sum fuego.tar.gz | awk '{print $1}')" ]; then echo "Wrong sha256sum of downloaded file!"; exit 1; fi \
    && tar zxvf fuego.tar.gz \
    && mv fuego /usr/local/bin \
    && rm -rf /tmp/fuego

ENTRYPOINT ["fuego"]
