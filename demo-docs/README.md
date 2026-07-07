# Demo Dataset

A self-contained, synthetic dataset for running and evaluating the assistant end-to-end. Everything here describes a **fictional company, "Northbridge Manufacturing"** — no real company data is used.

The dataset deliberately spans all four categories (**HR, Finance, Operations, IT**) and all three ingestion source types the pipeline supports (**markdown/text, PDF, and web**), so a single test exercises the whole system.

## Contents

| File | Source type | Category | Ingestion branch | Covers |
|------|-------------|----------|-----------------|--------|
| `employee_handbook_excerpt.pdf` | PDF | HR | native PDF | PTO, sick leave, remote work, holidays |
| `benefits_enrollment_guide.pdf` | PDF | HR | native PDF | health/dental plans, 401k match, open enrollment |
| `expense_policy_annotated.png` | image | Finance | image → Gemini vision | travel & expense policy with handwritten annotations |
| `procurement_policy.pdf` | PDF | Finance | native PDF | requisitions, approval thresholds, vendors |
| `ops_runbook_shift_handover_scanned.pdf` | scanned PDF | Operations | scanned PDF → Mistral OCR | shift handover procedure, escalation matrix |
| `it_security_policy.pdf` | PDF | IT | native PDF | MFA, device policy, AI tools, incident reporting |
| `it_help_software_hardware.html` | web | IT | web → Firecrawl | requesting software, hardware, and access |
| `sample_metadata.json` | — | — | — | expected category + summary per source (verify the classifier) |
| `sample_queries.json` | — | — | — | golden questions, source docs, expected answer facts, `needs_human` |

## How to use it

1. **Ingest:** drop all files into your configured Google Drive ingest folder (or point the web crawler at the HTML file). The pipeline will route each file through the correct ingestion branch automatically — native PDFs via the regular PDF path, the scanned PDF through Mistral OCR, the PNG through Gemini vision, and the HTML through Firecrawl.
2. **Verify classification:** compare the `category` metadata the classifier assigns against `sample_metadata.json`.
3. **Ask the questions** in `sample_queries.json` through the chat and check each answer against `expected_answer_contains`.
4. **Check the guardrail:** query **Q8** ("parental leave") is intentionally *not* covered by any document. A correct system sets `needs_human: true`, returns the handoff message, and triggers the email escalation branch — it does **not** fabricate an answer.

## As an evaluation set

`sample_queries.json` doubles as a starting **golden set**. Because every expected fact is verified to exist in its source document, you can use it to measure retrieval quality (does the right chunk get retrieved?) and answer quality (does the grounded answer contain the key facts?) — for example, comparing vector-only vs. hybrid vs. hybrid+rerank retrieval. Q8 measures the refusal/escalation path.

> All names, policies, figures, and the company itself are fabricated for demonstration.
