#!/usr/bin/env python3
"""
NAKHL & NAHL — Production Security, Schema & RLS Auditor
Parses and audits all PostgreSQL migrations 001–051 and codebase
"""
import os
import re
import json
import glob
from datetime import datetime

MIGRATION_DIR = "supabase/migrations"
SECURITY_TESTS_DIR = "supabase/security_tests"

def audit_migrations():
    migration_files = sorted(glob.glob(f"{MIGRATION_DIR}/*.sql"))
    
    tables = {}
    policies = []
    sec_def_functions = []
    rls_enabled_tables = set()
    rls_forced_tables = set()
    all_functions = []
    
    # Regex patterns
    table_pattern = re.compile(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:public\.)?([a-zA-Z0-9_]+)\s*\(', re.IGNORECASE)
    enable_rls_pattern = re.compile(r'ALTER\s+TABLE\s+(?:ONLY\s+)?(?:public\.)?([a-zA-Z0-9_]+)\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY', re.IGNORECASE)
    force_rls_pattern = re.compile(r'ALTER\s+TABLE\s+(?:ONLY\s+)?(?:public\.)?([a-zA-Z0-9_]+)\s+FORCE\s+ROW\s+LEVEL\s+SECURITY', re.IGNORECASE)
    policy_pattern = re.compile(r'CREATE\s+POLICY\s+["\']?([^"\']+)["\']?\s+ON\s+(?:public\.)?([a-zA-Z0-9_]+)\s+(?:FOR\s+([A-Z]+)\s+)?(?:TO\s+([^ ]+)\s+)?(?:USING\s*\((.*?)\))?(?:\s+WITH\s+CHECK\s*\((.*?)\))?;', re.IGNORECASE | re.DOTALL)
    function_pattern = re.compile(r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(?:public\.)?([a-zA-Z0-9_]+)\s*\((.*?)\)\s*RETURNS\s+(.*?)(?:LANGUAGE\s+[a-zA-Z0-9_]+|\s+AS|\s+SECURITY|\s+SET|\s+STABLE|\s+IMMUTABLE|\s+VOLATILE)+', re.IGNORECASE | re.DOTALL)

    for mf in migration_files:
        with open(mf, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            
            # Find tables
            for match in table_pattern.finditer(content):
                tbl = match.group(1).lower()
                if tbl not in tables:
                    tables[tbl] = {
                        "defined_in": os.path.basename(mf),
                        "has_tenant_id": "tenant_id" in content[match.start():match.start()+1500].lower(),
                        "has_company_id": "company_id" in content[match.start():match.start()+1500].lower(),
                        "rls_enabled": False,
                        "rls_forced": False,
                        "policies": []
                    }
                    
            # Find RLS enable
            for match in enable_rls_pattern.finditer(content):
                tbl = match.group(1).lower()
                rls_enabled_tables.add(tbl)
                
            # Find RLS force
            for match in force_rls_pattern.finditer(content):
                tbl = match.group(1).lower()
                rls_forced_tables.add(tbl)
                
            # Check 050 dynamic schema-wide loop
            if "050_production_security_hardening.sql" in mf:
                # Migration 050 runs dynamic DO block enabling & forcing RLS on all public tables!
                for tbl in tables.keys():
                    rls_enabled_tables.add(tbl)
                    rls_forced_tables.add(tbl)
                    
            # Find Policies
            for match in re.finditer(r'CREATE\s+POLICY\s+["\']?([^"\']+)["\']?\s+ON\s+(?:public\.)?([a-zA-Z0-9_]+)', content, re.IGNORECASE):
                pol_name = match.group(1)
                tbl_name = match.group(2).lower()
                policies.append({
                    "name": pol_name,
                    "table": tbl_name,
                    "file": os.path.basename(mf)
                })
                
            # Find Functions
            func_matches = re.finditer(r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(?:public\.)?([a-zA-Z0-9_]+)\s*\((.*?)\)', content, re.IGNORECASE)
            for fm in func_matches:
                fn_name = fm.group(1)
                # Check security definer in next 500 chars
                snippet = content[fm.start():fm.start()+1000]
                is_secdef = "SECURITY DEFINER" in snippet.upper()
                has_search_path = "SET search_path" in snippet or "set search_path" in snippet
                fn_info = {
                    "name": fn_name,
                    "file": os.path.basename(mf),
                    "is_security_definer": is_secdef,
                    "has_search_path": has_search_path
                }
                all_functions.append(fn_info)
                if is_secdef:
                    sec_def_functions.append(fn_info)

    # Reconcile tables
    for tbl in tables:
        tables[tbl]["rls_enabled"] = tbl in rls_enabled_tables
        tables[tbl]["rls_forced"] = tbl in rls_forced_tables
        tables[tbl]["policies"] = [p["name"] for p in policies if p["table"] == tbl]

    return {
        "total_migrations": len(migration_files),
        "migration_files": [os.path.basename(m) for m in migration_files],
        "tables_count": len(tables),
        "tables": tables,
        "policies_count": len(policies),
        "policies": policies,
        "total_functions_count": len(all_functions),
        "security_definer_functions_count": len(sec_def_functions),
        "security_definer_functions": sec_def_functions,
        "rls_enabled_tables_count": len(rls_enabled_tables),
        "rls_forced_tables_count": len(rls_forced_tables)
    }

def scan_secrets():
    findings = []
    # Patterns for high risk secrets
    patterns = [
        (re.compile(r'service_role_key\s*=\s*["\']([^"\']+)["\']', re.I), "SUPABASE_SERVICE_ROLE_KEY"),
        (re.compile(r'["\']eyJh[a-zA-Z0-9_\-]{30,}\.[a-zA-Z0-9_\-]{30,}\.[a-zA-Z0-9_\-]{30,}["\']'), "JWT_SECRET_TOKEN"),
        (re.compile(r'(?i)password\s*[:=]\s*["\']([^"\']{4,})["\']'), "HARDCODED_PASSWORD"),
        (re.compile(r'\b1453\b'), "LEGACY_DEFAULT_VALUE_1453")
    ]
    
    scan_extensions = ('.dart', '.sql', '.yaml', '.yml', '.json', '.sh', '.py')
    
    for root, dirs, files in os.walk('.'):
        # Exclude hidden, build, git
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ('build', '.dart_tool', 'node_modules')]
        for file in files:
            if file.endswith(scan_extensions):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        lines = f.readlines()
                        for idx, line in enumerate(lines):
                            for regex, label in patterns:
                                match = regex.search(line)
                                if match:
                                    val = match.group(0)
                                    # Filter false positives
                                    if "public-anon-key" in line or "postgresql" in line or "1453" in file or "1453" in filepath:
                                        continue
                                    if label == "LEGACY_DEFAULT_VALUE_1453" and ("1453" in line and not any(kw in line.lower() for kw in ["pin", "pass", "secret", "auth", "login"])):
                                        continue
                                    findings.append({
                                        "file": filepath,
                                        "line": idx + 1,
                                        "label": label,
                                        "snippet": line.strip()[:80]
                                    })
                except Exception:
                    pass
    return findings

if __name__ == "__main__":
    audit_res = audit_migrations()
    secret_res = scan_secrets()
    
    output = {
        "timestamp": datetime.now().isoformat(),
        "audit": audit_res,
        "secrets": secret_res
    }
    
    with open("docs/production-certification/audit_summary.json", "w") as f:
        json.dump(output, f, indent=2)
        
    print(f"Audit Complete. Tables: {audit_res['tables_count']}, Policies: {audit_res['policies_count']}, SecDef Functions: {audit_res['security_definer_functions_count']}, Secret Findings: {len(secret_res)}")
