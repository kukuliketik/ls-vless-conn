#!/bin/bash
# Generate UUID, x25519 key pair, and short ID for xray VLESS+Reality

echo "=== Generating Keys ==="
echo ""

UUID=$(xray uuid)
echo "UUID: $UUID"

KEY_OUT=$(xray x25519)
PRIVATE_KEY=$(echo "$KEY_OUT" | grep "PrivateKey" | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEY_OUT" | grep "Password" | awk '{print $2}')
echo "PrivateKey: $PRIVATE_KEY"
echo "PublicKey:  $PUBLIC_KEY"

SHORT_ID=$(openssl rand -hex 8)
echo "ShortId:    $SHORT_ID"

echo ""
echo "=== Add these to config.json ==="
echo ""
echo "Replace __YOUR_UUID__        with: $UUID"
echo "Replace __YOUR_PRIVATE_KEY__ with: $PRIVATE_KEY"
echo "Replace __YOUR_SHORT_ID__    with: $SHORT_ID"
echo ""
echo "=== Client share link (for V2rayN / Nekobox / v2rayNG) ==="
echo ""

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

cat <<EOF
vless://$UUID@$SERVER_IP:443?security=reality&encryption=none&pbk=$PUBLIC_KEY&headerType=none&type=tcp&flow=xtls-rprx-vision&sni=www.microsoft.com&fp=chrome&sid=$SHORT_ID#VLESS-Reality-VPN
EOF
