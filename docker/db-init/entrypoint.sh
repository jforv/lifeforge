#!/bin/sh
set -eu

progress_bar() {
	progress=0
	while [ ! -f "$1" ]; do
		progress=$(( (progress + 1) % 21 ))
		filled=$(printf '%*s' "$progress" '' | tr ' ' '#')
		empty=$(printf '%*s' "$((20 - progress))" '' | tr ' ' '-')
		printf '\rApplying migrations [%s%s]' "$filled" "$empty"
		sleep 0.2
	done
}

echo "=== LifeForge DB Init ==="
echo "Generating database migrations..."

# Ensure the migrations directory exists
mkdir -p /pb_data/pb_migrations

# Generate and apply migrations using bundled forge CLI
cd /app
migration_status_file="/tmp/lifeforge-migration-status.$$"
migration_log_file="/tmp/lifeforge-migration.log.$$"
trap 'rm -f "$migration_status_file" "${migration_status_file}.tmp" "$migration_log_file"' EXIT

(
    if bun forge --log-level debug db push >"$migration_log_file" 2>&1; then
		migration_status=0
	else
		migration_status=$?
	fi
	printf '%s' "$migration_status" > "${migration_status_file}.tmp"
	mv "${migration_status_file}.tmp" "$migration_status_file"
) &
migration_pid=$!
progress_bar "$migration_status_file"
wait "$migration_pid" || true

migration_status=$(cat "$migration_status_file")
if [ "$migration_status" -ne 0 ]; then
	printf '\rApplying migrations [failed]\n'
	echo "Migration command failed with exit code $migration_status:"
	cat "$migration_log_file"
	exit "$migration_status"
fi
printf '\rApplying migrations [####################]\n'

echo "Migrations applied successfully!"
echo "=== DB Init Complete ==="
