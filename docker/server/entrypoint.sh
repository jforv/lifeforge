#!/bin/sh
set -e

echo "Waiting for PocketBase to be ready..."
until wget -q --spider http://db:8090/api/health 2>/dev/null; do
    echo "PocketBase not ready, waiting..."
    sleep 2
done
echo "PocketBase is ready!"

# Create symlinks for externalized dependencies
mkdir -p /lifeforge/node_modules/@lifeforge

# Symlink @lifeforge/log (required by server-utils)
ln -sf /lifeforge/packages/log /lifeforge/node_modules/@lifeforge/log

# Symlink @lifeforge/server-utils (required by module bundles)
ln -sf /lifeforge/packages/server-utils /lifeforge/node_modules/@lifeforge/server-utils

# Symlink @lifeforge/pocketbase (required by the server bundle)
ln -sf /lifeforge/packages/pocketbase /lifeforge/node_modules/@lifeforge/pocketbase

# Symlink @lifeforge/configs (required by module routes)
ln -sf /lifeforge/packages/configs /lifeforge/node_modules/@lifeforge/configs

# Check if modules are mounted
if [ -d "/lifeforge/modules" ] && [ "$(ls -A /lifeforge/modules 2>/dev/null)" ]; then
    module_count=$(ls -d /lifeforge/modules/*/ 2>/dev/null | wc -l | tr -d ' ')
    echo "Found $module_count module(s) mounted at /lifeforge/modules"
else
    echo "No modules mounted. Mount modules to /lifeforge/modules to enable them."
fi

echo "Starting server..."
cd /lifeforge/apps/api
exec bun dist/server.js
