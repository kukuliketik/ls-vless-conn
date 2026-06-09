FROM alpine:latest

RUN apk add --no-cache tzdata ca-certificates gettext && \
    wget -q -O /tmp/xray.zip \
      https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -q /tmp/xray.zip -d /tmp/xray && \
    mv /tmp/xray/xray /usr/local/bin/xray && \
    mv /tmp/xray/geoip.dat /usr/local/bin/geoip.dat && \
    mv /tmp/xray/geosite.dat /usr/local/bin/geosite.dat && \
    mkdir -p /usr/local/etc/xray && \
    rm -rf /tmp/xray.zip /tmp/xray && \
    chmod +x /usr/local/bin/xray

COPY config.json /usr/local/etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
