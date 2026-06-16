---
name: clean-skill
description: Normalizes phone numbers to E.164 format from messy free-text input. Use when the user needs to clean, standardize, or validate phone numbers, or mentions E.164, dialing codes, or contact-list cleanup.
---

# Normalizing Phone Numbers

Parse each input string, infer the country from any leading + or dialing code,
and emit E.164. When the country is ambiguous, ask rather than guess.
