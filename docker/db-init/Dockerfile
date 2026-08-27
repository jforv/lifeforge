# syntax=docker/dockerfile:1

# ============================================
# Get PocketBase binary from official image
# ============================================
FROM ghcr.io/muchobien/pocketbase:latest AS pocketbase

# ============================================
# Builder stage - build forge CLI
# ============================================
# FROM oven/node:alpine AS builder
# To this:
FROM oven/bun:alpine AS builder

# Enable bun
# RUN corepack enable bun

WORKDIR /app

# Copy source
COPY . .

# Install dependencies
RUN --mount=type=cache,target=/root/.bun/install/cache \
    bun install

# Build @lifeforge/log (required by tools)
RUN cd /app/packages/log && bun run build

# Build @lifeforge/server-utils (required by schema files)
RUN cd /app/packages/server-utils && bun run build

# Build forge CLI
RUN cd /app/tools && bun run build

# Collect only schema files to staging directory
RUN mkdir -p /schemas && \
    find /app/apps/api/src/lib -name "schema.ts" -exec sh -c 'mkdir -p /schemas/$(dirname ${1#/app/}) && cp "$1" /schemas/$(dirname ${1#/app/})/' _ {} \;
# Collect only schema files to staging directory
# RUN mkdir -p /schemas && \
    # find /app/server/src/lib -name "schema.ts" -exec sh -c 'mkdir -p /schemas/$(dirname ${1#/app/}) && cp "$1" /schemas/$(dirname ${1#/app/})/' _ {} \;

# ============================================
# Production stage - minimal runtime
# ============================================
FROM oven/bun:alpine

# Copy PocketBase binary from official image
COPY --from=pocketbase /usr/local/bin/pocketbase /usr/local/bin/pocketbase

WORKDIR /app

# Copy ONLY bundled forge CLI (no node_modules!)
COPY --from=builder /app/tools/dist/forge.js ./forge.js

# Copy server schema files needed for migration generation
# COPY --from=builder /schemas/server/src/lib ./server/src/lib
COPY --from=builder /schemas/apps/api/src/lib ./apps/api/src/lib


# Copy shared package (built) for schema imports
# COPY --from=builder /app/shared/dist ./shared/dist
# COPY --from=builder /app/shared/package.json ./shared/package.json

# Copy @lifeforge/server-utils (required by schema files)
COPY --from=builder /app/packages/server-utils/dist ./packages/server-utils/dist
COPY --from=builder /app/packages/server-utils/package.json ./packages/server-utils/package.json

# Create node_modules symlinks for package resolution
RUN mkdir -p node_modules/@lifeforge && \
    # ln -sf /app/shared node_modules/shared && \
    ln -sf /app/packages/server-utils node_modules/@lifeforge/server-utils

# Install minimal dependencies for schema evaluation
# Install dependencies for schema evaluation and CLI execution
RUN <<'EOF'
cat > package.json <<'JSON'
{
    "dependencies": {
        "zod": "4.3.5",
        "dotenv": "17.4.2",
        "chalk": "5.6.2",
        "pocketbase": "0.27.3",
        "lodash": "4.17.21",
        "dayjs": "1.11.19",
        "argon2": "0.44.0",
        "commander": "14.0.2",
        "prompts": "2.4.2",
        "prettier": "3.8.0",
        "concurrently": "10.0.3",
        "semver": "7.7.3",
        "crypto-js": "4.2.0",
        "handlebars": "4.7.8",
        "openai": "6.7.0",
        "tar": "7.5.2",
        "undici": "8.10.0",
        "express": "4.21.2",
        "form-data": "4.0.0",
        "groq-sdk": "0.20.0",
        "ical.js": "2.1.0",
        "pdf2pic": "3.1.4",
        "socket.io": "4.8.3",
        "tesseract.js": "6.0.1",
        "uuid": "13.0.2"
    },
    "devDependencies": {
        "@eslint/js": "10.0.1",
        "@module-federation/vite": "1.18.2",
        "@rolldown/plugin-babel": "0.2.3",
        "@trivago/prettier-plugin-sort-imports": "6.0.2",
        "@types/cookie-parser": "1.4.10",
        "@types/eslint-plugin-jsx-a11y": "6.10.1",
        "@types/jsonwebtoken": "9.0.10",
        "@types/lodash": "4.17.21",
        "@types/opentype.js": "1.3.10",
        "@types/react": "19.2.7",
        "@types/react-dom": "19.2.3",
        "@types/tinycolor2": "1.4.6",
        "@typescript-eslint/eslint-plugin": "8.64.0",
        "@typescript-eslint/parser": "8.64.0",
        "@typescript-eslint/utils": "8.61.0",
        "@typescript/typescript6": "6.0.2",
        "@vitejs/plugin-react": "6.0.3",
        "bcryptjs": "3.0.3",
        "cross-env": "7.0.3",
        "eslint": "10.7.0",
        "eslint-import-resolver-alias": "1.1.2",
        "eslint-plugin-import": "2.32.0",
        "eslint-plugin-jsx-a11y": "6.10.2",
        "eslint-plugin-perfectionist": "5.9.0",
        "eslint-plugin-react": "7.37.5",
        "eslint-plugin-react-compiler": "19.1.0-rc.2",
        "eslint-plugin-sonarjs": "4.2.0",
        "eslint-plugin-unused-imports": "4.2.0",
        "globals": "17.7.0",
        "jiti": "2.7.0",
        "rimraf": "5.0.10",
        "turbo": "2.0.4",
        "typescript": "6.0.3",
        "vite": "8.1.5",
        "vite-plugin-dts": "5.0.3",
        "vitest": "4.1.10"
    }
}
JSON
bun install
EOF

# Set environment for Docker mode
ENV DOCKER_MODE=true
ENV PB_DIR=/pb_data
ENV PB_BINARY_PATH=/usr/local/bin/pocketbase

# Copy entrypoint
COPY docker/db-init/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    sed -i 's/\r$//' /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
