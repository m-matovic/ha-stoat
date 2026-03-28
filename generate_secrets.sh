#!/bin/sh

INVENTORY_FILE="inventory.yml"

echo "Generating secrets..."

RABBITMQ_ERLANG_COOKIE=$(openssl rand -hex 32)
RABBITMQ_USER="$(openssl rand -hex 10)"
RABBITMQ_PASSWORD=$(openssl rand -hex 24)

GARAGE_RPC_SECRET=$(openssl rand -hex 32) 

S3_ACCESS_KEY_ID=$(openssl rand -hex 20)
S3_SECRET_ACCESS_KEY=$(openssl rand -hex 40)

LIVEKIT_API_KEY=$(openssl rand -hex 24)
LIVEKIT_API_SECRET=$(openssl rand -hex 48)

FILES_ENCRYPTION_KEY=$(openssl rand -hex 32)

CADDY_REDIS_ENCRYPTION_KEY=$(openssl rand -hex 32)

echo "Secrets generated. Replacing into $INVENTORY_FILE..."

# (macOS and Linux handle 'sed -i' differently)

sed "s|<RABBITMQ_ERLANG_COOKIE>|${RABBITMQ_ERLANG_COOKIE}|g" "$INVENTORY_FILE" | \
sed "s|<RABBITMQ_USER>|${RABBITMQ_USER}|g" | \
sed "s|<RABBITMQ_PASSWORD>|${RABBITMQ_PASSWORD}|g" | \
sed "s|<GARAGE_RPC_SECRET>|${GARAGE_RPC_SECRET}|g" | \
sed "s|<S3_ACCESS_KEY_ID>|${S3_ACCESS_KEY_ID}|g" | \
sed "s|<S3_SECRET_ACCESS_KEY>|${S3_SECRET_ACCESS_KEY}|g" | \
sed "s|<LIVEKIT_API_KEY>|${LIVEKIT_API_KEY}|g" | \
sed "s|<LIVEKIT_API_SECRET>|${LIVEKIT_API_SECRET}|g" | \
sed "s|<FILES_ENCRYPTION_KEY>|${FILES_ENCRYPTION_KEY}|g" | \
sed "s|<CADDY_REDIS_ENCRYPTION_KEY>|${CADDY_REDIS_ENCRYPTION_KEY}|g" > "${INVENTORY_FILE}.tmp"

mv "${INVENTORY_FILE}.tmp" "$INVENTORY_FILE"

echo "Done"
