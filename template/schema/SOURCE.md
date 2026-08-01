# Vendored upstream files

Two files in this repository are copies of [Apache Ossie (incubating)][ossie]
sources, vendored so that validation works standalone:

| Local path            | Upstream path                 |
| --------------------- | ----------------------------- |
| `schema/osi-schema.json` | `core-spec/osi-schema.json` |
| `scripts/validate.py`    | `validation/validate.py`    |

`core-spec -> schema` is a local compatibility link, not a third vendored
upstream file. The upstream validator resolves its schema through that path, so
keep the link in place when updating either vendored file.

- Origin: {{UPSTREAM_ORIGIN}}
- Ref: `{{UPSTREAM_REF}}`
- Commit: `{{UPSTREAM_SHA}}`
- Vendored on: {{DATE}}
- Licence: Apache License 2.0 (see `LICENSE`, `NOTICE`)

The spec version pinned by this schema is **`{{SPEC_VERSION}}`** — the schema
declares `version` as a `const`, so every model in `models/` must carry exactly
that string. Bumping the schema means bumping every model.

## Updating

```bash
# from a local apache/ossie clone
cp ../ossie/core-spec/osi-schema.json schema/osi-schema.json
cp ../ossie/validation/validate.py    scripts/validate.py

# or straight from GitHub (pin a ref you can name in the commit message)
REF=osi-0.1.1-rc1
curl -fsSL "https://raw.githubusercontent.com/apache/ossie/$REF/core-spec/osi-schema.json" -o schema/osi-schema.json
curl -fsSL "https://raw.githubusercontent.com/apache/ossie/$REF/validation/validate.py"    -o scripts/validate.py

# Recreate this only if it was removed; it lets the validator find the schema.
test -e core-spec || ln -s schema core-spec
```

Then, in the same commit:

1. Update the ref/commit/date above.
2. Re-run `make validate` — a spec bump usually breaks the `version` const first.
3. Note the upstream commit hash in the commit message.

Ossie is an incubating project; the schema still changes. This kit defaults to
the `osi-0.1.1-rc1` tag (the 0.1.1 release candidate). If this repository was
bootstrapped with another `--ref`, its vendored schema is authoritative.

[ossie]: https://github.com/apache/ossie
