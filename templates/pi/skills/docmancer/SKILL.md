---
name: docmancer
description: Query indexed local, vendored, or external documentation with Docmancer. Use this before reading large documentation trees or docs websites into context.
---

# Docmancer

Use Docmancer for documentation questions, especially library docs, API
references, internal docs, Markdown/PDF/DOCX/HTML trees, and docs websites.

## Query indexed docs

```bash
mise run docmancer-query -- "question here"
```

## Add a documentation site

```bash
DOCS_URL="https://example.com/docs" mise run docmancer-add
```

## Ingest local docs

```bash
DOCS_PATH="./docs" mise run docmancer-ingest
```

Prefer `--explain` output when provenance matters.

Do not dump raw docs into Pi context unless Docmancer cannot answer.
