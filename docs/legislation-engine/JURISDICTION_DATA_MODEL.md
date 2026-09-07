# Jurisdiction‑Specific Legislation Data Model

## Overview
The legislation engine must store **machine‑readable rules** per jurisdiction while keeping the core ledger untouched.  The model is deliberately **extensible**: new jurisdictions can be added as a lightweight shell without loading any rules.

## Core Tables (PostgreSQL)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `jurisdictions` | Master list of legal domains (e.g., SA, TR, EU, DE, shell) | `id`, `code` (ISO‑2), `name`, `description`, `is_active` |
| `rule_categories` | High‑level groups (VAT, Excise, Zakat, Customs, etc.) | `id`, `jurisdiction_id`, `code`, `name` |
| `rules` | Individual machine‑readable rules (JSON) | `id`, `category_id`, `code`, `title`, `definition_json`, `effective_from`, `effective_to`, `status` (ACTIVE/INACTIVE/UNKNOWN) |
| `rule_versions` | Historical versioning for audit & temporal queries | `id`, `rule_id`, `definition_json`, `valid_from`, `valid_to`, `created_at` |
| `rule_mappings` | Optional mapping of external source identifiers (e.g., ZATCA rule IDs) to internal `rules.code` | `id`, `external_source`, `external_id`, `rule_id` |

## JSON Schema (example for a VAT rule)
```json
{
  "type": "object",
  "properties": {
    "rate": {"type": "number"},
    "threshold": {"type": "number"},
    "applicable_goods": {"type": "array", "items": {"type": "string"}},
    "exemptions": {"type": "array", "items": {"type": "string"}}
  },
  "required": ["rate"]
}
```

## Relationships
- Each **tenant** (customer) is linked to a set of enabled jurisdictions via `tenant_jurisdictions` (existing many‑to‑many table can be reused).
- The **rule engine** queries `rules` filtered by the tenant’s active jurisdictions and the transaction date.
- RLS policies ensure a tenant can only read rules for its jurisdictions.

## Extensibility / Shell Jurisdictions
- For a *shell* jurisdiction we create a row in `jurisdictions` with `is_active = false` and **no** entries in `rule_categories`/`rules`. The UI will automatically show an empty rule set, ready for future population.

## Migration Sketch
Create a new migration `054_jurisdiction_data_model.sql` that adds the tables above and appropriate indexes/FK constraints. The migration will be **backward compatible** – existing modules continue to work because no existing queries reference these tables.

## API Endpoints (planned, not implemented yet)
- `GET /api/jurisdictions` – list active jurisdictions.
- `GET /api/jurisdictions/{code}/rules` – fetch applicable rules (JSON) for a date range.
- `POST /api/jurisdictions/{code}/rules` – admin endpoint to add/modify rules.

## UI Sketch (future)
- Admin screen **Jurisdiction Catalog** to create shells and import official sources (ZATCA, GIB, EU).  Each rule can be edited in a JSON editor with validation against the schema.

---

*This document defines the core data model for jurisdiction‑specific legislation. Implementation of API and UI will follow in subsequent phases.*
