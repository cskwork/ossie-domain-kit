# {{DOMAIN_TITLE}} semantic model catalogue

One row per model file. Keep this table honest — it is what downstream
consumers read before trusting a definition.

| Model | Scope | Source of truth | Status |
| ----- | ----- | --------------- | ------ |
| `models/{{DOMAIN}}/{{DOMAIN}}_example_model.yaml` | Example orders/customers starter | none | proposed (example — replace) |

Status values: **verified** (checked by `make verify` against a real schema),
**inferred** (reconstructed from application code), **proposed** (designed
before the tables exist). See [verification.md](verification.md).

## Naming conventions

Pick them once, write them down here, and let the validator's uniqueness checks
enforce the rest.

- Datasets: singular physical concept, snake_case (`order`, `customer_account`).
- Fields: match the physical column name unless the physical name is cryptic;
  when they differ, the `label` carries the human name.
- Metrics: `<noun>_<aggregation>` or a business term everyone already says
  (`net_revenue`, not `sum_of_net_amount_v2`).
- One model file per bounded subdomain. Split when a file stops fitting in one
  reviewer's head, not when it hits a line count.

## Cross-model joins

Ossie `relationships` only connect datasets **within** one model. Joins that
cross model files have to be documented by hand — do it here, or in a
`docs/joins.md` if there are many.

| From | To | Key | Note |
| ---- | -- | --- | ---- |
| _(none yet)_ | | | |

## Decisions

Record the non-obvious calls — why a metric excludes cancelled orders, why two
near-identical tables became one dataset. The YAML says *what*; this says *why*.

- {{DATE}} — repository bootstrapped from
  [ossie-domain-kit](https://github.com/cskwork/ossie-domain-kit).
