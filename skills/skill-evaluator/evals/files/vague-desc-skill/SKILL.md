---
name: vague-desc-skill
description: I help you with your reports.
---

# Report Helper

Build the quarterly revenue report from the BigQuery `billing.invoices` table.
Always exclude rows where `account_type = 'test'`, group revenue by region, and
format currency in USD. The finance team needs the test-account exclusion or the
totals are wrong.
