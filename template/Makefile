# {{DOMAIN_TITLE}} semantic models — validation entry points.
#
# `make validate` checks SPEC COMPLIANCE (does the YAML satisfy the Ossie schema?).
# `make verify`   checks REALITY      (do the tables/columns actually exist?).
# Only the first one is generic; see docs/verification.md for the second.

MODELS := $(shell find models -name '*.yaml' 2>/dev/null | sort)
SCHEMA := schema/osi-schema.json
VALIDATE := uv run scripts/validate.py

.PHONY: help validate verify check

help:
	@echo "make validate                 - validate every model under models/"
	@echo "make validate FILE=<m.yaml>   - validate a single model"
	@echo "make verify                   - compare models against the source of truth"
	@echo "make check                    - validate + verify"

validate:
ifdef FILE
	@$(VALIDATE) $(FILE) --schema $(SCHEMA)
else
	@test -n "$(MODELS)" || { echo "no models found under models/"; exit 1; }
	@fail=0; for m in $(MODELS); do \
	  echo "######## $$m"; \
	  $(VALIDATE) $$m --schema $(SCHEMA) || fail=1; \
	done; \
	if [ $$fail -ne 0 ]; then echo; echo "validation FAILED"; exit 1; fi; \
	echo; echo "all models PASSED"
endif

# Replace this with a real check against your source of truth — a DDL dump,
# information_schema, a dbt manifest, a warehouse INFORMATION_SCHEMA query.
# Until then it is a loud no-op so `make check` never reports false confidence.
verify:
	@echo "no verification layer configured — see docs/verification.md"
	@echo "(skipping: models are spec-valid but NOT confirmed against real schemas)"

check: validate verify
