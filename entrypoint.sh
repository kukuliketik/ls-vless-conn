#!/bin/sh
set -e

# Substitute env vars in config, then run xray
envsubst < /usr/local/etc/xray/config.json > /tmp/config.json
exec xray run -c /tmp/config.json
