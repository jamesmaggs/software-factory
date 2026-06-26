---
name: brand-voice
description: Runs a structured interview to establish a brand's voice and tone, then drafts several candidate voices — each rewriting the same sample copy — and has the user pick the one closest to their vision, producing a markdown brand voice guide that downstream design tools can read. Use this skill whenever the user wants to define, establish, derive, or document a "brand voice", "tone of voice", "voice and tone guidelines", or asks for a UX-style voice interview, even if they don't use the exact words "brand voice" — e.g. "help me figure out how the site should sound", "what tone should our copy use", "interview me about our brand personality". Always use this skill rather than just freehand brainstorming a tone of voice, since drafting concrete, comparable candidates produces a more defensible result than describing a voice in the abstract.
---

# Brand Voice

## Workflow

### Step 1: Discovery interview (open-ended, conversational)

Interview the user in their own words — free text, never a button/multiple-choice tool, since the value is in their phrasing. Ask one or two questions at a time and follow up on what they say; don't read out a checklist. Work broad-to-specific through the phases below and keep going until the **stopping condition** is met. The flow and exercises are drawn from cross-referenced UX/content-strategy practice (Nielsen Norman Group, Mailchimp, the Content Marketing Institute, and brand-voice workshop facilitators).

The interview exists to gather enough to do two things in the output — place the brand on the four tone dimensions, and name 3-5 distinct voice traits with do's and don'ts — so steer toward that, not toward generic chit-chat.

**Phase A — Context.** Ground the conversation before tone comes up: what the product does and for whom; who the audience is, what they already know, and the emotional state they arrive in versus how you want them to feel afterward; the change the brand wants to make.

**Phase B — Character.** Surface personality before tone:
- "If the brand were a person, how do they talk — and how would they come across at a dinner party?"
- 2-3 brands (ideally some outside the industry) whose communication they admire, and *specifically what* each does well — plus an "absolute no": a voice that would be catastrophic for them.
- 3-5 adjectives for how the brand should communicate. For each, immediately ask for the "but not" — the adjacent quality it must not tip into ("confident but not arrogant"). The negation defines more than the adjective does. If an adjective is one every competitor would also claim (professional, innovative, friendly, helpful), push for a sharper word or a differentiating "but not".

**Phase C — Dimension placement.** Position the brand on the four NN/g dimensions, framed as trade-offs (a mixing desk — more casual is bought with less formal), using concrete behavioural signals rather than aspirations:
- Funny ↔ Serious: do they ever joke in real copy? Would humour survive a 404 or an error message?
- Formal ↔ Casual: contractions? Do they address the reader as "you"? Sentence fragments for effect?
- Respectful ↔ Irreverent: any industry norm they'd publicly call wrong? (Irreverence is toward the subject/industry — never the reader.)
- Enthusiastic ↔ Matter-of-fact: do "We're absolutely thrilled!" lines sound like them or make them cringe? Roughly how many exclamation marks in their last few messages?

As a complementary check, run a quick card sort: present the 37 tone words in `assets/tone_words.md` verbatim and ask them to pick a handful that fit and a handful that definitely don't. The rejects are often the sharpest signal — they feed the "but not" constraints and the never-say list.

**Phase D — Evidence & constraints.** Ask for real copy — a few samples that sound most like them and one or two that don't. Real text reveals natural vocabulary and exposes any gap between aspiration and reality; if existing copy contradicts the stated voice, probe which is the true brand. (No existing comms is fine — proceed without it.) Then pin down the hard limits: the one tone the brand must never have, and any words or phrases that must never appear — or that feel essential.

**Stopping condition.** Keep interviewing until you can, without guessing:
1. place the brand on each of the four dimensions with a rationale grounded in something they actually said; and
2. name 3-5 distinct candidate traits, each passing the distinctiveness test (a competitor wouldn't equally claim it) and each with at least one concrete do and don't.

If a dimension is still ambiguous or a trait still reads as generic, ask another targeted question. When the same adjectives and "absolute no"s keep recurring and fresh questions stop surfacing anything new, briefly summarise what you heard and confirm it before drafting candidates. If more than one stakeholder is available, interviewing a few diverse roles (leadership, a customer-facing voice, someone outside marketing) surfaces misalignment a single view hides — reconcile it before drafting.

### Step 2: Draft 5-6 voice candidates

Based on the answers, draft 5-6 distinct candidate voices. Each candidate needs:
- A short label (e.g. "Warm Mentor", "Witty Insider", "Plain-Spoken Expert")
- A one-line description of the personality
- The SAME piece of sample copy, rewritten in that voice (pick one realistic scenario — e.g. a password-reset email, an error message, or a one-line product description — and keep it identical in length/purpose across all candidates so they're directly comparable)

Seeing the candidates side by side, in the same scenario, is what makes the choice clear — so make them genuinely distinct from one another and each a faithful, well-written take on its personality. A stray or strawman candidate just wastes the user's attention.

### Step 3: Pick the voice

Show all candidates to the user in a normal chat message (label + one-line description + sample copy for each) and ask which feels closest to their vision — e.g. "Which of these sounds most like your brand?". Invite them to refine: they may pick one outright, blend two, or tweak the wording of the one they like. Iterate on the chosen voice until they're happy with it.

If two candidates feel close and the user is torn, draft a tighter pair of variations and ask again rather than forcing a call — the point is to land on a voice they recognise as theirs, not to crown a winner mechanically.

### Step 4: Write the brand voice guide

Fill in `assets/voice_doc_template.md`, keeping its heading structure and tables exactly as-is — the fixed schema is what lets downstream tools and AI agents parse the result reliably. The template has three structured parts to complete:

- **Tone of Voice Dimensions** — score the brand on each of the four Nielsen Norman Group dimensions (Funny↔Serious, Formal↔Casual, Respectful↔Irreverent, Enthusiastic↔Matter-of-fact), reading each score against that row's own poles: 1 is the left-hand label, 5 the right-hand label. The **Position** column names the chosen pole in plain words and is the source of truth — make the number agree with it. Don't drift a dimension toward the middle to look balanced; a near-pole score is fine (many brands are, e.g., strongly respectful). Remember: irreverence is about the subject matter, never the reader.
- **Brand Voice Chart** — break the chosen voice into 3-5 distinct personality traits, one row each, with concrete, copy-level Do's and Don'ts. Fold any hard "never say" items from the interview into the Don'ts, with the reason.
- **Tone Shifts by Context** — note any contexts (error states, onboarding, high-stakes moments) where the tone moves off its default. Express each as a delta against the default scores, in the form `Dimension: default → shifted`, plus a short instruction. Omit only if genuinely none apply.

The one thing the template can't enforce: justify every position — the chosen voice, each dimension score, and the do's/don'ts — from specific interview answers and what the user told you when they picked, rather than asserting them.

Write the filled-in guide to a file with a clear name like `brand-voice-guide.md`. Save it in the current working directory unless the user has pointed you somewhere specific (e.g. a `docs/` or `brand/` folder).

Then validate it against the output contract: run `bash scripts/lint_voice_guide.sh <path>` and fix every error it reports before telling the user the guide is ready. This linter is the deterministic guarantee that the schema downstream tools and AI agents depend on is actually met — do not skip it or hand over a guide that still fails.

Once it passes, tell the user the path so they can open it. Keep that closing message short — the content lives in the file, not the chat.

## Notes for downstream design tools

This guide is designed to be consumed by other design tools and AI agents, so the output format must be predictable. Use the template's heading structure, table columns, and the 1–5 dimension scale exactly as written — do not rename headings, reorder columns, or invent a different scale. Downstream consumers locate the chosen voice, the four dimension scores, the trait-by-trait chart, and the sample copy by their fixed section headings and table shapes. Each dimension score is read against that row's own poles (1 = left label, 5 = right label); the Position text is authoritative if a number is ever ambiguous, and contextual shifts are deltas against the default scores.
