# AGENTS.md — ossie-domain-kit

Instructions for coding agents working **on this kit**. If you are working in a
repository that this kit *generated*, read that repo's own `AGENTS.md` instead.

## What this repository is

A scaffolding tool. `bootstrap-ossie-domain.sh` stamps out a domain
semantic-model repository that consumes the [Apache Ossie][ossie] spec. The kit
itself contains no semantic models and knows nothing about any particular
industry.

```
bootstrap-ossie-domain.sh    the tool
template/                    files copied into every generated repo
skills/ossie-domain-model/   authoring skill, installed into generated repos
docs/index.html              landing page, served by GitHub Pages from /docs
```

`docs/index.html` is standalone — no build step, no dependencies beyond a Google
Fonts link. Its first section explains the problem in plain language for
non-technical readers; keep it that way. If you change the CLI flags or the
generated layout, update the page's usage table and file tree in the same commit.
Verify visually before claiming done:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new \
  --window-size=1440,10500 --virtual-time-budget=9000 \
  --screenshot=/tmp/lp.png docs/index.html
```

## Hard rules

1. **`template/` stays domain-agnostic.** No industry terms, no company names,
   no AIDT/retail/healthcare specifics. Domain content belongs in the generated
   repo. The one exception is the example model, which must stay a generic
   orders/customers starter.
2. **Never vendor upstream files into this repo.** `osi-schema.json` and
   `validate.py` are fetched at bootstrap time, on purpose — so generated repos
   pin a ref they choose, and so this repo does not redistribute ASF sources.
3. **The example model must pass validation** against the schema fetched at
   bootstrap. If you change it, run the smoke test.
4. **Test end to end before claiming done:**
   ```bash
   ./bootstrap-ossie-domain.sh smoke /tmp/smoke-ossie --no-git
   (cd /tmp/smoke-ossie && make validate)
   ```
   Re-run with `--from-clone <path-to-apache/ossie>` too if you touched the
   upstream-fetching branch.
5. **Keep the script POSIX-friendly bash.** It must run on macOS (BSD `sed`,
   older bash) and Ubuntu CI alike. `sed -i.bak … && rm -f *.bak`, not
   `sed -i`. No GNU-only flags.

## Template mechanics

Files in `template/` are copied verbatim, then renamed and stamped:

| In template | In generated repo |
| --- | --- |
| `gitignore` | `.gitignore` |
| `editorconfig` | `.editorconfig` |
| `_github/` | `.github/` |
| `models/example/example_semantic_model.yaml` | `models/<domain>/<domain>_example_model.yaml` |

The dotfile/underscore renaming is deliberate: a real `.gitignore` or
`.github/workflows/` inside `template/` would apply to *this* repo.

Placeholders substituted in `*.md`, `*.yaml`, `*.yml`, and `Makefile`:

`{{DOMAIN}}` `{{DOMAIN_TITLE}}` `{{REPO_NAME}}` `{{SPEC_VERSION}}`
`{{UPSTREAM_REF}}` `{{UPSTREAM_SHA}}` `{{UPSTREAM_ORIGIN}}` `{{DATE}}` `{{YEAR}}`

Adding a placeholder means adding it to the `stamp()` function *and* to this
list. `{{SPEC_VERSION}}` is read out of the fetched schema (the spec pins
`version` as a `const`), never hardcoded.

## Upstream facts worth remembering

- The upstream validator handles **one file per invocation** and resolves its
  schema at `../core-spec/osi-schema.json` relative to itself. Bootstrap creates
  a `core-spec -> schema` compatibility link, and the generated `Makefile` loops
  over files. Do not remove that link or "simplify" the loop.
- `version` is a schema `const`. A spec bump breaks every existing model by
  design; that is the intended signal, not a bug to work around.
- The `ossie` Go CLI's `validate` and `convert` are stubs at the time of
  writing. Do not build the kit on top of them.

## Style

Documentation in these files is read by both agents and humans under time
pressure: lead with the rule, keep tables over prose, and cut anything that does
not change what a reader does next.

[ossie]: https://github.com/apache/ossie
