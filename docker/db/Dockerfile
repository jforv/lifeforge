# syntax=docker/dockerfile:1

# ============================================
# PocketBase - Minimal database image
# ============================================
FROM ghcr.io/muchobien/pocketbase:latest

# Add this line to install curl for the healthcheck
RUN apk add --no-cache curl

COPY docker/db/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    sed -i 's/\r$//' /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
