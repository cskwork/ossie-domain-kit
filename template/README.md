# {{DOMAIN_TITLE}} Semantic Models

Vendor-agnostic semantic models for the **{{DOMAIN_TITLE}}** domain, written
against the [Apache Ossie (incubating)][ossie] specification (formerly OSI,
Open Semantic Interchange).

The point: agents, BI tools, and dashboards should all answer *"what is net
revenue?"* the same way. This repository is the single place that definition
lives.

## Layout

```
{{REPO_NAME}}/
├── models/{{DOMAIN}}/          # the semantic models (the actual output)
├── schema/
│   ├── osi-schema.json         # vendored Ossie Core schema
│   └── SOURCE.md               # upstream ref/commit + how to update
├── core-spec -> schema/         # validator compatibility link
├── scripts/validate.py         # vendored Ossie validator
├── docs/
│   ├── overview.md             # model catalogue, conventions, decisions
│   └── verification.md         # how to prove models match real schemas
├── AGENTS.md                   # instructions for coding agents
└── Makefile
```

This repository **consumes** the spec; it does not modify it. Spec changes go
upstream to [apache/ossie][ossie].

## Validate

Requires [uv](https://docs.astral.sh/uv/). The generated `Makefile` installs
`pyyaml`, `jsonschema`, and `sqlglot` on demand for the vendored validator.

```bash
make validate                                 # every model under models/
make validate FILE=models/{{DOMAIN}}/{{DOMAIN}}_example_model.yaml
make check                                    # validate + verify
```

`make validate` checks four things:

1. **Structure** — the Ossie JSON Schema (types, enums, required fields).
2. **Uniqueness** — no duplicate dataset, field, metric, or relationship names.
3. **References** — relationships point at datasets that exist.
4. **SQL** — expressions parse under their declared dialect (best-effort,
   via `sqlglot`).

It does **not** check that the underlying tables and columns exist. That is
`make verify`, which starts as a no-op — see
[docs/verification.md](docs/verification.md) to wire it to your source of truth.

CI runs `make validate` on every push and pull request.

## Adding a model

1. Copy an existing file into `models/{{DOMAIN}}/` (or a new subdomain folder).
2. Fill in `datasets` → `fields` → `relationships` → `metrics`.
3. Put the evidence in the file header: where the table definitions came from,
   which commit/snapshot, and whether you verified or inferred them.
4. `make validate`.
5. Add a row to [docs/overview.md](docs/overview.md).

Working with a coding agent? [AGENTS.md](AGENTS.md) holds the rules it should
follow, and `.claude/skills/ossie-domain-model/` is a ready-made authoring
skill.

## Licence

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).
`schema/osi-schema.json` and `scripts/validate.py` are vendored from
[apache/ossie][ossie]; provenance is recorded in
[schema/SOURCE.md](schema/SOURCE.md).

[ossie]: https://github.com/apache/ossie
