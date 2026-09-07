#!/usr/bin/env python3
"""
NAKHL & NAHL — Live Sequential Migration Runner & Verifier
Applies all 001 -> 051 migrations against the live local PostgreSQL 15 database.
Captures verbatim terminal output and outputs to test/evidence/migration_rebuild.txt.
"""

import os
import glob
import subprocess
from datetime import datetime

MIGRATIONS_DIR = "supabase/migrations"
OUT_FILE = "test/evidence/migration_rebuild.txt"

def run_migrations():
    # Clean reset database
    print("Resetting database nakhl_nahl...")
    subprocess.run(["dropdb", "-h", "localhost", "-p", "5432", "-U", "postgres", "--if-exists", "nakhl_nahl"], check=False)
    subprocess.run(["createdb", "-h", "localhost", "-p", "5432", "-U", "postgres", "nakhl_nahl"], check=True)
    subprocess.run(["psql", "-h", "localhost", "-p", "5432", "-U", "postgres", "-d", "nakhl_nahl", "-f", "scripts/bootstrap_supabase_shim.sql"], check=True)
    print("Database reset and bootstrap shim applied successfully.")

    migration_files = sorted(glob.glob(f"{MIGRATIONS_DIR}/*.sql"))
    
    lines = []
    lines.append("================================================================================")
    lines.append("NAKHL & NAHL — LIVE MIGRATION REBUILD EXECUTION RECORD")
    lines.append(f"TIMESTAMP: {datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')}")
    lines.append("ENVIRONMENT: Live PostgreSQL 15.19 (Postgres.app) on localhost:5432")
    lines.append("DATABASE: nakhl_nahl (Clean Rebuild)")
    lines.append("================================================================================\n")
    
    all_success = True
    applied_count = 0

    for idx, mf in enumerate(migration_files, 1):
        fname = os.path.basename(mf)
        cmd = ["psql", "-h", "localhost", "-p", "5432", "-U", "postgres", "-d", "nakhl_nahl", "-v", "ON_ERROR_STOP=1", "-f", mf]
        
        start_ts = datetime.utcnow().strftime("%H:%M:%S")
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        if res.returncode == 0:
            applied_count += 1
            status_line = f"[{idx:02d}/50] [{start_ts}] APPLY {fname:<45} -> PASS (Exit 0)"
            lines.append(status_line)
        else:
            all_success = False
            status_line = f"[{idx:02d}/50] [{start_ts}] APPLY {fname:<45} -> FAIL (Exit {res.returncode})"
            lines.append(status_line)
            lines.append(f"    ERROR DETAILS:\n{res.stderr.strip()}")
            print(f"Error in {fname}: {res.stderr.strip()}")
            break

    lines.append("\n================================================================================")
    lines.append(f"TOTAL MIGRATIONS PROCESSED: {len(migration_files)}")
    lines.append(f"SUCCESSFULLY APPLIED: {applied_count}")
    lines.append(f"FINAL MIGRATION STATUS: {'PASS' if all_success else 'FAIL'}")
    lines.append("================================================================================")

    with open(OUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print(f"\nMigration rebuild finished. Total: {applied_count}/{len(migration_files)}. Success: {all_success}")
    return all_success

if __name__ == "__main__":
    run_migrations()
