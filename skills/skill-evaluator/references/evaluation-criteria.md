# Skill Evaluation Criteria

The rubric `skill-evaluator` judges against. Three dimensions: calibration,
triggering, and value. The first two are judgement about the skill's text; the
third is measured by running the skill against a baseline.

## Contents
- Dimension A: Calibration (is the content "just right"?)
- Dimension B: Triggering (will it fire at the right time?)
- Dimension C: Value (does it beat baseline?)
- Scoring guidance

## Dimension A: Calibration

The governing question for every line of a SKILL.md: **does the model already
know this?** The context window is shared; padding the body spends a budget that
belongs to the whole session. Assume the model is already very smart and only add
what it does not already have.

Judge the body against three fates for each piece of content:

- **Keep** — local knowledge the model needs on most runs (your conventions,
  rules like "always exclude test accounts", the one chosen library, fragile
  sequences).
- **Cut** — anything the model already knows (what a PDF is, what git is) or that
  merely restates something said once.
- **Push** — real but occasional knowledge (an edge case, a rare format, deep API
  detail) belongs in a reference file, costing zero tokens until read.

Red flags: explanations of general concepts; padding that justifies nothing;
the same idea repeated; over-explaining to a capable model (which also erodes the
model's trust in the rest of the instructions).

Also assess **degrees of freedom**: is specificity matched to fragility? Loose
prose for open tasks with many valid paths; an exact, locked script for fragile,
high-stakes, must-be-consistent operations. A rigid script for a creative task is
as wrong as vague prose for a database migration.

## Dimension B: Triggering

The `description` is the only signal the model has when choosing among many
skills, and the only part always in context. Judge it on:

- **What + when.** Does it say both what the skill does and the contexts/phrasings
  that should trigger it? Capability alone does not trigger.
- **Third person.** It is injected into the system prompt. "I can help you…"
  reads inconsistently and harms discovery.
- **Key terms.** Does it contain the literal words users type (file types,
  verbs, nouns)? Those are the match surface.
- **Coverage over brevity.** The dominant failure is *under*-triggering. A good
  description is a little pushy, naming contexts even where the user never says
  the skill's name. (This is the opposite discipline to the lean body.)
- **Discrimination.** Would it wrongly fire on a near-miss task that needs a
  different tool? Would it lose to a competing skill when it should win?

Caveat: triggering is not pure keyword match. The model only consults a skill for
work it cannot already do in one step, so a skill aimed only at trivial one-liners
will not reliably fire regardless of its description.

## Dimension C: Value

The decisive dimension, and the one that cannot be judged by reading. A skill's
worth is the **gap** between the model's performance with it and without it.

- A high pass rate proves nothing alone; the model may have succeeded unaided.
- Always run each eval task in two configurations: **with the skill** and at
  **baseline** (no skill for a new skill; the previous version when improving).
- Read the **delta**. A well-written skill with a near-zero delta is dead weight.

Expectation quality gates the measurement:
- Expectations must be **objectively verifiable** and **discriminating** — if the
  baseline passes them too, they measure nothing about the skill.
- Beware **presence, not correctness** ("output includes a name" passes for a
  hallucinated name). Grade the part that is actually hard.
- Subjective skills (writing voice, design) are judged qualitatively by a human;
  do not force assertions onto them.

## Scoring guidance

Report calibration and triggering as a qualitative assessment with concrete
strengths and weaknesses, not just a number. Report value as the measured pass-rate
delta. The verdict is dominated by value: a beautifully calibrated, perfectly
triggered skill that does not move the delta is not worth shipping. Never declare a
skill effective from reading alone.
