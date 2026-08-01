# Ossie core spec — working reference

This is a quick reference for the default upstream tag, `osi-0.1.1-rc1`
(spec version `0.1.1`). The vendored `schema/osi-schema.json` in a generated
repository is authoritative. If that repository was bootstrapped with another
`--ref` (especially `main`), read its schema instead of assuming this reference
still applies.

## Top level

```yaml
version: "0.1.1"       # const — must equal the version pinned by your schema
dialects: [ANSI_SQL]   # optional supported-dialect declaration
vendors: [COMMON]      # optional vendor declaration for custom extensions
semantic_model: [ ... ] # required, array of models
```

Only `version`, `dialects`, `vendors`, and `semantic_model` are valid at the
root in the default schema. `additionalProperties: false` applies at every level.

## Semantic model

Required: `name`, `datasets`.

| Key | Notes |
| --- | --- |
| `name` | Unique within the file |
| `description` | Prose; what this model covers |
| `ai_context` | String, or object with `instructions`, `synonyms`, and `examples` |
| `datasets` | Required array |
| `relationships` | Joins between datasets **in this model only** |
| `metrics` | Model-level; may reference any dataset in the model |
| `custom_extensions` | Vendor-specific extension array |

## Dataset

Required: `name`, `source`.

| Key | Notes |
| --- | --- |
| `name` | Logical name; unique within the model |
| `source` | Physical reference — `database.schema.table`, a view, or a query |
| `primary_key` | Array of column names (list every column of a composite key) |
| `unique_keys` | Array of unique-key column lists |
| `description`, `ai_context` | As above |
| `fields` | Array of Field |
| `custom_extensions` | Vendor-specific extension array |

`source` is a free string. Be consistent across the repo — either always
fully qualified or always schema relative, never mixed.

## Field

Required: `name`, `expression`.

| Key | Notes |
| --- | --- |
| `name` | Unique within the dataset |
| `expression` | Required — `{dialects: [{dialect, expression}]}` |
| `dimension` | `{is_time: true}` — mark time dimensions |
| `label` | Human-facing name when `name` mirrors a cryptic column |
| `description`, `ai_context` | As above |
| `custom_extensions` | Vendor-specific extension array |

A field expression is usually a column name, but it can be any expression over
the dataset source (`gross_amount - discount_amount`, `LOWER(email)`). The
default 0.1.1 schema does **not** allow a `datatype` key on a field.

## Metric

Required: `name`, `expression`. Optional: `description`, `ai_context`, and
`custom_extensions`.

Metrics are aggregations. Qualify columns with the dataset name
(`SUM(orders.net_amount)`) so the definition is unambiguous. The default 0.1.1
schema does **not** allow a `datatype` key on a metric.

## Relationship

Required: **all five** of `name`, `from`, `to`, `from_columns`, `to_columns`.

```yaml
- name: orders_to_customers
  from: orders                # dataset name in THIS model
  to: customers               # dataset name in THIS model
  from_columns: [customer_id] # minItems: 1
  to_columns: [customer_id]
```

Composite keys list columns in matching order in both arrays. A relationship
cannot cross model files.

## Enums and extensions

**`dialect`** — `ANSI_SQL`, `SNOWFLAKE`, `MDX`, `TABLEAU`, `DATABRICKS`, or
`MAQL`. Write `ANSI_SQL` unless engine-specific syntax is necessary; add a
second expression instead of replacing the portable one. `MDX`, `TABLEAU`, and
`MAQL` expressions are skipped by the SQL parser.

**`custom_extensions`** — an array of `{vendor_name, data}` objects. In the
default schema, `vendor_name` is one of `COMMON`, `SNOWFLAKE`, `SALESFORCE`,
`DBT`, `DATABRICKS`, or `GOODDATA`; `data` is a JSON string. Prefer this escape
hatch over an invented top-level key, and document non-portable data in
`docs/overview.md`.

## What the validator checks

`scripts/validate.py` (vendored from `validation/validate.py`) runs four passes:

1. **Schema** — structure, types, enums, required keys, and
   `additionalProperties`.
2. **Unique names** — datasets, metrics, and relationships within a model;
   fields within a dataset.
3. **References** — `from` and `to` name datasets in the same model.
4. **SQL** — each expression parses through `sqlglot`, first standalone and
   then as `SELECT <expr>`. `MDX`, `TABLEAU`, and `MAQL` are skipped.

The upstream validator handles one file per invocation and resolves its schema
at `../core-spec/osi-schema.json`. Bootstrap creates the `core-spec -> schema`
compatibility link, and `make validate` loops over model files while installing
`pyyaml`, `jsonschema`, and `sqlglot` with `uv` for the invocation.

## Error → cause

| Message | Cause |
| --- | --- |
| `[Schema] (root): '0.1.1' was expected` | `version` mismatches the vendored schema |
| `[Schema] ...: Additional properties are not allowed` | typo'd or unsupported key (for the default schema, often `datatype`) |
| `[Schema] ...: 'expression' is a required property` | field or metric has no `expression.dialects` |
| `[Schema] ...: '<x>' is not one of [...]` | unsupported `dialect` or extension vendor |
| `[Unique] Duplicate ...` | repeated name at the same level |
| `[Reference] ... references unknown dataset` | relationship crosses model files, or has a dataset typo |
| `[SQL] ...` | expression fails to parse in its dialect |
| `Error: Schema not found` | `core-spec -> schema` compatibility link is missing or broken |
| `Missing dependencies` | use `make validate`, or install `pyyaml` and `jsonschema` |
