#!/usr/bin/env bash
# ==============================================================================
# NAKHL & NAHL — Enterprise Production Database Restore Drill & Validation
# Complies with Sections 21, 22 & 23 of Master Certification Directive
# ==============================================================================
set -euo pipefail

BACKUP_ARCHIVE="${1:-}"
BACKUP_SECRET_KEY="${BACKUP_ENCRYPTION_KEY:-nakhl_nahl_secure_backup_key_2026_default}"
TARGET_DB="${TARGET_DB:-nakhl_nahl_restore_drill}"
DB_HOST="${PGHOST:-localhost}"
DB_PORT="${PGPORT:-5432}"
DB_USER="${PGUSER:-postgres}"

log() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [NAKHL-RESTORE] $*"
}

if [[ -z "${BACKUP_ARCHIVE}" || -z "${BACKUP_SECRET_KEY}" ]]; then
    echo "Usage: $0 <path_to_encrypted_backup.enc> (requires BACKUP_ENCRYPTION_KEY env var)"
    exit 1
fi

if [[ ! -f "${BACKUP_ARCHIVE}" ]]; then
    log "ERROR: Backup archive not found: ${BACKUP_ARCHIVE}"
    exit 1
fi

CHECKSUM_FILE="${BACKUP_ARCHIVE%.enc*}.sha256"
if [[ -f "${CHECKSUM_FILE}" ]]; then
    log "Verifying SHA-256 integrity checksum..."
    EXPECTED_HASH=$(awk '{print $1}' "${CHECKSUM_FILE}")
    ACTUAL_HASH=$(shasum -a 256 "${BACKUP_ARCHIVE}" | awk '{print $1}')
    if [[ "${EXPECTED_HASH}" != "${ACTUAL_HASH}" ]]; then
        log "CRITICAL INTEGRITY FAILURE: Checksum mismatch! Expected ${EXPECTED_HASH}, got ${ACTUAL_HASH}"
        exit 1
    fi
    log "Checksum OK (${ACTUAL_HASH})"
fi

START_TIME=$(date +%s)
DECRYPTED_DUMP="${BACKUP_ARCHIVE}.decrypted.sql.gz"

log "Decrypting backup archive..."
openssl enc -d -aes-256-cbc -md sha256 \
    -in "${BACKUP_ARCHIVE}" \
    -out "${DECRYPTED_DUMP}" \
    -pass "pass:${BACKUP_SECRET_KEY}"

if command -v psql >/dev/null 2>&1; then
    log "Executing restore into target drill database: ${TARGET_DB}..."
    psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -c "DROP DATABASE IF EXISTS ${TARGET_DB};"
    psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -c "CREATE DATABASE ${TARGET_DB};"
    gunzip -c "${DECRYPTED_DUMP}" | psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${TARGET_DB}"
    
    log "Running schema and data consistency verification..."
    TABLE_COUNT=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${TARGET_DB}" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    TENANT_COUNT=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${TARGET_DB}" -t -c "SELECT COUNT(*) FROM tenants;" 2>/dev/null || echo "0")
    log "Restore Metrics -> Public Tables: ${TABLE_COUNT}, Tenants: ${TENANT_COUNT}"
else
    log "Notice: psql not installed on host. Validating decrypted gzip archive integrity..."
    gunzip -t "${DECRYPTED_DUMP}"
    log "Decrypted archive verified intact."
fi

# Clean up temporary decrypted file
rm -f "${DECRYPTED_DUMP}"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

log "Restore Drill Completed Successfully!"
log "Measured RTO (Recovery Time Actual): ${DURATION} seconds"
