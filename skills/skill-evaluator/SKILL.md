---
name: skill-evaluator
description: Judges whether a skill is actually good, in two parts: a qualitative review of its calibration and description/triggering quality, plus a behavioural evaluation that runs the skill's tasks with and without the skill loaded and scores the pass-rate delta against baseline. Use when the user wants to evaluate, judge, grade, score, or assess a skill, decide whether a skill is effective or worth shipping, or prove a skill beats baseline. For purely mechanical spec compliance (frontmatter limits, paths, reference nesting), use skill-linter; this skill judges substance and measures value, not syntax.
---

# Skill Evaluator

Answer two questions about a skill: **is it well-made?** (judgement about its text)
and **does it work?** (measured against a baseline). The second question is the one
that matters most, and the one nobody can answer by reading alone.

Judge against the rubric in [references/evaluation-criteria.md](references/evaluation-criteria.md).
Read it before evaluating; it defines the three dimensions used below.

## Step 0 — Form first (optional but recommended)

If `skill-linter` is available, run it first to clear mechanical issues
(frontmatter limits, path style, reference nesting). There is no point judging the
substance of a skill whose frontmatter is invalid. Note its verdict and move on;
this skill does not repeat those deterministic checks.

## Step 1 — Judge the contents

Read the target SKILL.md and its bundled files, then assess two dimensions from the
rubric:

- **Calibration (Dimension A):** walk the body and classify content as keep / cut /
  push. Flag anything the model already knows, padding, repetition, and any
  mismatch between specificity and the fragility of the task. Label each finding
  explicitly as keep, cut, or push in your written output — the labels are the
  deliverable, not just your private reasoning; they are what makes the review
  actionable. Name all three categories even when one is empty (e.g. "Push:
  nothing here"), so it is clear the full keep/cut/push framework was applied
  rather than only keep and cut.
- **Triggering (Dimension B):** assess the description for what + when, third
  person, key terms, coverage against under-triggering, and whether it would
  misfire on near-misses or lose to a competing skill.

Produce concrete strengths and weaknesses with line-level examples, not a bare
score. **This step measures form, not effectiveness — a skill can read beautifully,
pass every mechanical check, and still do nothing.** Say so plainly when form is
clean but the content is thin or padded; naming that gap is one of the most useful
things this review produces. This holds even when you could not run skill-linter —
note whether the skill would *likely* pass mechanical checks, and that passing them
is not the same as being good.

## Step 2 — Measure value against baseline

This is the decisive step (Dimension C). A skill's worth is the gap between the
model's performance with it and without it.

1. **Get evaluations.** Use the skill's `evals/evals.json` if present. If there are
   none, create a small set of 3 realistic task prompts with verifiable,
   *discriminating* expectations (ones a no-skill run would tend to fail). Note that
   a dedicated evals-first workflow produces better sets than improvising here.
2. **Run both configurations, in the same turn.** For each task, run it once **with
   the skill loaded** and once at **baseline** (no skill for a new skill; the
   previous version when improving an existing one). In Claude Code, spawn one
   subagent per configuration so they run together; on platforms without subagents,
   run them yourself one at a time with fresh context each.
3. **Grade each run** against the expectations. Record each as `text` / `passed` /
   `evidence`. Compute the pass rate per configuration.
4. **Report the delta.** `value = with_skill_pass_rate − baseline_pass_rate`.
   Always produce a measured delta, even when you had to reason through the two
   configurations inline rather than run them — a verdict with no delta is the exact
   failure mode this skill exists to prevent.

Watch for non-discriminating expectations (the baseline passes them too) and
presence-not-correctness traps; both make the delta lie. Flag them rather than
trusting the number.

## Step 3 — Verdict

Combine the two halves, but let value dominate:

- Lead with the **delta** and what it means. A near-zero delta means the skill is
  dead weight however well it reads.
- Then give the calibration and triggering assessment as the explanation for *why*
  the skill performs as it does, and what to change.
- End with a clear recommendation: ship, revise (with the specific changes), or
  rethink.

**Never declare a skill effective from reading alone.** If you could not run the
baseline (no environment for it), say so plainly and present only the contents
judgement, clearly labelled as form, not proof.

## Before you finish — checklist

Copy this and confirm each item. These are the behaviours that make the evaluation
worth more than an unaided read, and the ones easiest to skip under time pressure:

- [ ] Ran skill-linter, or noted it was unavailable
- [ ] Labelled calibration findings as keep / cut / push, naming all three categories even if one is empty
- [ ] Stated whether the skill would pass mechanical/lint checks and that passing them is not the same as being good (form ≠ value), even if the linter could not be run
- [ ] Produced a measured with-vs-baseline delta, even if reasoned inline
- [ ] Led the verdict with that delta, not with writing quality
- [ ] Did not declare the skill effective from reading alone

Grounded in Anthropic's Agent Skills best-practices and the skill-creator eval loop
(`platform.claude.com/docs/en/agents-and-tools/agent-skills`).
