# PawMento — Activation & Retention Implementation Spec

> **Purpose:** A day-0 → day-7 activation plan turned into concrete, hand-off-ready prompts for an AI coding assistant.
> **Strategy in one line:** Deliver honest instant wins immediately, show a visible ladder to the earned (statistical) wins, and never fake the Poisson/insight payoff.
>
> **How to use this file:** Prepend the **Preamble** to *every* Priority prompt before handing it to your AI coding assistant. Run the priorities in order (P1 → P5); each builds on signals introduced earlier. Verify each ships green before moving on.

---

## Strategy summary

New users hit an empty Home screen, and the best feature (the Poisson-based insight engine) is structurally incapable of delivering value on day 1 because it needs consecutive days of data. **Effort precedes reward**, so users churn before converting.

The fix splits value into two tracks:

- **Track A — Honest instant wins** (Coach answers, first-log celebration, profile summary): zero history needed, delivered day 0.
- **Track B — Earned statistical wins** (wellness score, insights): gated by data, but shown as a *visible, near* goal via a progress ladder instead of a blank neutral state.

**Non-negotiable discipline:** manufacture day-1 dopamine only where it can be truthful. Never fake the wellness score or a statistical insight — that trustworthiness is the product's moat.

### Priority overview

| # | Priority | Primary files |
|---|----------|---------------|
| P1 | AI Coach welcome card (day-0 front door) | `HomeScreen.swift`, `WelcomeCoachCard.swift` (new), `CoachViewModel`, `AICoachClient.swift`, `AICoachPrompt.swift` |
| P2 | Wellness ring setup-ladder + empty-state rewrites | `WellnessRingView.swift`, `HomeViewModel.swift`, section/teaser views |
| P3 | First-log celebration + streak + "today's one thing" | `HomeViewModel.swift`, log-save path, `CelebrationOverlay.swift` + `StreakChip.swift` (new) |
| P4 | Early-insight prioritization + first-insight celebration | `InsightEngine.swift`, `Detectors.swift` (MilestoneDetector), `InsightNarrator.swift`, `InsightStore` |
| P5 | Event-triggered paywall on earned value | paywall/subscription flow, `InsightNarrator.swift`, `CoachViewModel`, `verify-premium` (read-only) |

---

## 📋 PREAMBLE — Read before every task

> Prepend this section to every Priority prompt below.

**Project context**

You are working on **PawMento**, a native iOS (SwiftUI) app for pet parents. The architecture is **MVVM + Core-services layering**: `App/`, `Models/`, `ViewModels/`, `Views/`, `Core/`, plus a Supabase backend under `supabase/functions/`. The app combines pet logging, an AI Coach, a statistical Insights engine, reminders, and a freemium subscription model.

**Your operating rules — follow these on every task**

1. **Ground yourself in the real code first. Do not hallucinate.**
   - Before writing any code, open and read the actual files named in the task. If a file, type, property, or function I reference does not exist exactly as described, **stop and report it** — do not invent it or guess a substitute.
   - Match the existing code's naming conventions, formatting, access-control patterns, and concurrency model (`actor` / `@MainActor` / `@StateObject` / environment objects) already in use. Do not introduce new patterns unless asked.

2. **Make the smallest change that satisfies the task.**
   - Touch only the files listed in the task. Do not refactor unrelated code, rename existing symbols, or reformat files.
   - Additive over destructive: prefer adding new render modes, flags, views, or prompt templates over rewriting existing logic.

3. **Protect these non-negotiables (the product's trust moat):**
   - **Never fabricate the wellness score or any statistical insight.** The `WellnessCalculator` data-confidence gate (`hasSufficientData`) and the Insight engine's statistical rigor (Poisson, multiple-comparisons correction, trend regression) must remain **untouched** unless a task explicitly says otherwise.
   - Any setup/progress UI must be clearly labeled as **setup progress**, never presented as a health score.
   - **All AI calls route through the existing `ai-proxy` Supabase edge function** using the user's session token. Never add API keys on the device. Never bypass server-side quota enforcement.
   - Coach/welcome content generated from profile facts must **never imply statistical insight** — that is the earned Insights engine's territory.

4. **Preserve safety and tone guarantees.**
   - Any new AI prompt must inherit the existing safety/non-diagnostic/emergency-routing and jailbreak-defense guardrails already defined in `AICoachPrompt.swift`. Do not weaken them.

5. **⚠️ MANDATORY — Test and verify after every change.**
   - After implementing, ensure the project **compiles cleanly** (no build errors, no new warnings you introduced).
   - **Run the existing test suite and confirm it passes.** If there are no relevant tests for the changed area, add at least one lightweight test (or a SwiftUI `#Preview`) that exercises the new behavior and its empty/edge state.
   - If any test fails or the build breaks, **fix it before considering the task done** — do not leave the project in a broken state.
   - Manually confirm the specific first-run / empty-state scenario described in the task renders correctly (e.g., via Preview or simulator).

6. **Report back in this format when done:**
   - **Files changed** (with a one-line summary each)
   - **New symbols added** (types, functions, properties)
   - **Build status** (clean / warnings)
   - **Test status** (passed / added — name them)
   - **Anything I referenced that didn't match the codebase** (flag it, don't silently work around it)
   - **Manual verification performed** (which state/screen you checked)

7. **If anything is ambiguous or the code doesn't match this brief, ask before proceeding.** A stop-and-clarify is always better than a plausible-but-wrong implementation.

---

## 🔥 PRIORITY 1 — AI Coach welcome card (day-0 front door)

**Goal:** Turn the AI Coach into the hero of the first-run Home screen. When a brand-new user finishes onboarding and lands on Home, they should see a **pre-generated, personalized Coach answer** (using only their pet's profile facts), tappable follow-up suggestions, and a positive framing of the free quota — all above the empty ring/timeline.

**Read these files first (ground yourself, do not assume their contents):**
- `PawMento/Views/.../HomeScreen.swift` (the Home view + its section composition)
- `PawMento/ViewModels/HomeViewModel.swift`
- `PawMento/.../CoachViewModel.swift`
- `PawMento/Core/AI/AICoachClient.swift`
- `PawMento/Core/AI/AICoachPrompt.swift`
- The `PetStore` / active-pet model that exposes `species`, `breed`, `age`/birthdate, and `name`

If any referenced type or property (e.g., pet `breed`, `age`, the quota state on `CoachViewModel`, the streaming entry point) does **not** exist with the exact name/shape assumed below, **stop and report it** rather than inventing it.

**Task 1 — Add a `profilePrimer` prompt template in `AICoachPrompt.swift`**
- Add a new prompt builder (e.g. `static func profilePrimer(for pet:) -> String` or a new case matching the file's existing pattern) that produces a **profile-only** welcome answer.
- Content intent: *"A few things to know about {name}, a {age} {breed} {species}, right now"* — 2–3 short, practical, life-stage-appropriate points.
- **Must inherit all existing guardrails** from this file: non-diagnostic, safety/emergency routing, jailbreak defenses, and the established persona/tone.
- **Must NOT** imply any statistical insight, pattern, or health score — this is an honest profile-based primer only, not the earned Insights engine's territory.
- Match the exact construction style (persona header, context injection, output constraints) already used by the existing Coach prompt in this file.

**Task 2 — Add a one-shot primer call in `CoachViewModel`**
- Add a method (e.g. `func generateWelcomePrimer(for pet:) async`) that:
  - Fires **exactly one** Coach request using the `profilePrimer` prompt, routed through the **existing `ai-proxy`** path used by `AICoachClient` (session token; no new keys, no direct Anthropic call).
  - **Does NOT count against the user's free question quota** (it's a gift). If quota decrement happens server-side, coordinate a flag/param so this call is exempt — if that's not possible without backend changes, **stop and report** rather than silently consuming quota.
  - **Caches** the result (per pet) so re-opening Home does not regenerate or re-charge. Expose it as a published property (e.g. `@Published var welcomePrimer: WelcomePrimerState`) with states: `idle / loading / loaded(text) / failed`.
  - Is safe to call repeatedly (no duplicate in-flight calls; reuse the cached value if present).
- Add a small list of **life-stage-appropriate follow-up suggestions** (2–3 strings) derived from the pet's species/age (e.g. puppy → vaccines/feeding; senior → symptom-watch). A simple deterministic helper is fine — no extra AI call.

**Task 3 — Build `WelcomeCoachCard.swift` (new view)**
- New SwiftUI view in the Views layer, styled consistently with existing Home cards.
- Renders based on `CoachViewModel.welcomePrimer` state:
  - `loading` → tasteful placeholder/shimmer (not a blank box).
  - `loaded` → the primer text, a header like *"Ask PawMento about {name}"*, the 2–3 **tappable follow-up chips**, and a subtle quota line: *"You have {N} free questions to get started."* (positive/gift framing).
  - `failed` → graceful fallback: a friendly prompt + working "Ask a question" button (never a broken/empty card).
- Tapping a follow-up chip (or the card's primary CTA) enters the **existing streaming Coach flow** with that question **pre-filled/seeded**, so the user watches the answer stream in. Reuse the existing streaming entry point — do not build a new Coach screen.
- Include a `#Preview` for all three states (`loading`, `loaded`, `failed`).

**Task 4 — Wire it into `HomeScreen` as the first-run hero**
- Add an `isFirstRun` (or equivalent) condition in `HomeViewModel` — true when the active pet has **zero logs / insufficient data** (reuse existing signals like the `hasSufficientData` gate or a log-count; do not add a redundant source of truth). Report which existing signal you used.
- On first-run Home only, render `WelcomeCoachCard` **at the top**, directly under the greeting header and **above** the wellness ring. After the user has data, the card is hidden and the normal layout is restored.
- Trigger `generateWelcomePrimer(for:)` during the existing Home load path (`HomeViewModel.load(for:)` / `.task`) — ideally pre-warmed so the card is populated on first paint. Do not fire it on every load; respect the cache.

**Guardrails specific to this task**
- One primer call only — no speculative or repeated generation; latency- and quota-conscious.
- Profile facts only; never fabricate patterns, scores, or statistical claims.
- Route through `ai-proxy`; no on-device keys; quota enforcement preserved (with the welcome call exempted, or reported if not feasible).
- Do not modify the Insights engine, `WellnessCalculator`, or the streaming Coach internals — only *call* the existing streaming entry point.

**Definition of done (in addition to the preamble's test requirements)**
- Project compiles clean; existing tests pass.
- `#Preview` renders all three card states correctly.
- Manually verify: fresh pet with no logs → Coach welcome card appears as hero above the ring; tapping a chip enters the streaming Coach with the question seeded; re-opening Home reuses the cached primer (no regeneration).
- Report which existing pet properties and quota/streaming APIs you used, and flag any that didn't match.

---

## 🔥 PRIORITY 2 — Wellness ring "setup ladder" mode + empty-state rewrites

**Goal:** On a data-less first-run account, the wellness ring should stop showing a neutral "not enough data" dead state and instead render a **setup-progress ladder** that visibly fills as the user completes onboarding milestones — giving the dopamine of a filling ring **without faking a health score**. When real data qualifies, it animates into the true scored ring. Empty states elsewhere become "coming soon + ladder" teasers.

**Read these files first (ground yourself, do not assume their contents):**
- `PawMento/Views/.../WellnessRingView.swift` (current ring rendering + how it consumes its snapshot)
- `PawMento/ViewModels/HomeViewModel.swift` (how `wellnessSnapshot` / `hasSufficientData` is computed and passed to the ring)
- `PawMento/Core/Utilities/WellnessCalculator.swift` (**read only — do NOT modify** the scoring logic or the `hasSufficientData` gate)
- The empty-state / section views for the timeline, insights teaser, and reminders on Home

If the ring's current data source, the `hasSufficientData` flag, or the snapshot type do **not** match what's assumed below, **stop and report it** rather than inventing a substitute.

**Task 1 — Add a `.setupProgress` render mode to `WellnessRingView`**
- Introduce a mode/enum (e.g. `enum WellnessRingMode { case setupProgress(SetupProgress); case score(WellnessSnapshot) }`) or an equivalent that fits the file's existing style. Additive only — do not remove or rewrite the existing scored rendering.
- **`setupProgress` rendering:**
  - The ring fills proportionally to completed setup steps (e.g. 4 discrete segments/steps).
  - Center shows a **clearly-labeled setup indicator** — e.g. *"Setup 2/4"* or *"Getting started"* — **never a number that could be mistaken for a 0–100 health score.** Do not render a score-styled integer in this mode.
  - Below/around the ring, show the current step's next action label (e.g. *"Log your first entry"*).
  - Use a visually distinct treatment (color/label) from the real scored ring so the two modes are never confused.
- **`score` rendering:** unchanged existing behavior (real animated scored ring, color band, component breakdown on tap).

**Task 2 — Define the setup ladder in `HomeViewModel`**
- Add a `SetupProgress` model describing the ordered steps. Suggested steps (adjust to real available signals — report what you used):
  1. **Add pet** (always complete once on Home)
  2. **First log** (any log entry exists)
  3. **3 days logged** (reuse the distinct-day counting concept already present in `WellnessCalculator` — do **not** duplicate a second source of truth; read the existing count if exposed, otherwise report how you derived it)
  4. **First pattern unlocked** (first real insight exists)
- Compute the ring mode: when `hasSufficientData == false`, drive `WellnessRingView` with `.setupProgress(...)`; when `hasSufficientData == true`, drive it with `.score(snapshot)` exactly as today.
- **Do not alter `WellnessCalculator` or the gate.** The real score still only appears when the calculator says data qualifies.

**Task 3 — Animate the setup → score transition**
- When `hasSufficientData` flips from false → true (e.g., the day-3 threshold clears), animate the transition from the setup-ladder ring into the real scored ring (a satisfying fill/morph or crossfade). This is the earned Track-B reward moment — make it feel like an unlock, not a silent swap.
- Ensure the transition is driven by the published state change on `HomeViewModel`, on `@MainActor`, consistent with the existing reactive flow.

**Task 4 — Rewrite empty states as "coming soon + ladder" teasers**
- **Timeline (today's activity):** replace any bare empty state with an encouraging line + inline CTA pointing back at the quick-log row (e.g. *"Nothing logged yet today — tap below to add {pet}'s first entry."*).
- **Insights teaser:** replace with a proximity message tied to the ladder (e.g. *"Your first pattern unlocks after ~3 days of logging — you're on day {X}."*). Pull the day count from the same setup-ladder source (no new source of truth). **Do not fabricate or preview a fake insight.**
- **Reminders:** replace the empty state with a friendly CTA to set the first reminder.
- Keep copy consistent in tone with the app's existing voice; each empty state must teach its value **and** point to a next action — no blank gaps.

**Guardrails specific to this task**
- `WellnessCalculator` and `hasSufficientData` are **read-only**. No fabricated score, ever.
- The setup ring must be visually and textually **unmistakably "setup progress,"** not a health score.
- Reuse existing signals (log counts, distinct-day count, insight existence) as the single source of truth — do not introduce duplicate/competing counters.
- Purely presentational/state-mapping changes on the Home + ring layer; no changes to insight statistics or scoring math.

**Definition of done (in addition to the preamble's test requirements)**
- Project compiles clean; existing tests pass.
- `#Preview` (or previews) for `WellnessRingView` covering: `setupProgress` at multiple step counts (e.g. 1/4 and 3/4) **and** the existing `score` mode.
- Manually verify the sequence: fresh pet → ring shows labeled setup ladder (no score number); add a log → ladder advances; once `hasSufficientData` flips true → ring animates into the real scored ring.
- Manually verify each rewritten empty state (timeline, insights teaser, reminders) shows the new copy + CTA and the insights teaser day count matches the ladder.
- Report which existing signals you used for each ladder step and the `hasSufficientData` source, and flag anything that didn't match.

---

## ⚡ PRIORITY 3 — First-log celebration + streak + "today's one thing" (habit loop)

**Goal:** Reward the very first log with a moment of delight, then give the user a reason to return every day *before* the statistical engine can. This is the Track-A competence/delight win and the daily habit hook.

**Read these files first (ground yourself, do not assume their contents):**
- `PawMento/ViewModels/HomeViewModel.swift`
- `PawMento/.../PetStore.swift` and the **log-save path** (whichever store/method persists a new log entry — symptom/meal/activity/med/weight/note)
- `PawMento/Core/Utilities/WellnessCalculator.swift` (**read only** — it already counts distinct logged days; reuse that concept, do not duplicate it)
- `PawMento/Views/.../HomeScreen.swift` (where the streak chip and celebration will surface)
- The Priority 2 `SetupProgress` model in `HomeViewModel` (the celebration must advance the setup ladder)

If the log-save entry point, the log-count/distinct-day signal, or the `SetupProgress` model do **not** exist as assumed, **stop and report it** rather than inventing a substitute.

**Task 1 — Detect the first-ever log**
- Add a way to know when a save is the user's **first log for the active pet** (e.g. `isFirstLog` derived from an existing total-log count — do **not** add a competing counter; read the count the app already maintains). Report which signal you used.
- The detection must be evaluated **at save time** (compare count before/after, or check "was zero, now one"), not on a timer or view appear.

**Task 2 — First-log celebration**
- Create `CelebrationOverlay.swift` (new view): a lightweight, dismissible overlay — confetti/animation + message (*"First log! 🎉 You're on your way."*). Auto-dismisses after a short interval or on tap. Styled consistently with the app.
- Trigger it exactly **once** on the first-ever log save, coordinated through `HomeViewModel` published state (e.g. `@Published var celebration: CelebrationState`), on `@MainActor`.
- Fire a haptic (success feedback generator) alongside the visual.
- On the same event, **advance the Priority 2 setup ladder** (First log → complete) so the ring visibly progresses in the same moment. Reuse the existing `SetupProgress` source of truth — do not recompute independently.
- Guard against re-triggering: after the first log, this celebration must never fire again for that pet.

**Task 3 — Streak counter (`StreakChip.swift`)**
- Add a streak computation in `HomeViewModel` derived from **distinct logged days** (reuse the distinct-day counting concept already in `WellnessCalculator` — read the existing value if exposed; if not, derive it from the same log data and report how). Do not introduce a second, divergent definition of a "day."
- Streak semantics: consecutive calendar days with ≥1 log. Define the calendar/timezone handling **consistently with how the app already buckets days** (check `WellnessCalculator`/insight detectors for the existing convention — e.g. fixed UTC vs. local — and match it; report which you followed).
- Create `StreakChip.swift` (new view): compact chip showing the current streak (e.g. *"🔥 3-day streak"*). When streak is 0/1, show an encouraging start state rather than a bare "0".
- Surface the chip in `HomeScreen` (e.g. in or near the greeting header). Include a `#Preview` for streak = 0, 1, and 3.

**Task 4 — "Today's one thing" nudge**
- Add a single, deterministic suggested action for today when the user hasn't logged yet today (e.g. *"Log breakfast to keep {pet}'s record complete."*). No AI call — a simple rule based on time-of-day and/or what's missing today is sufficient.
- Compute it in `HomeViewModel`; surface it as a small prompt on Home (near the quick-log row or timeline empty state). Once the user has logged today, hide it or switch to a "done for today ✓" state.
- Keep it to **one** suggestion at a time — do not stack multiple nudges.

**Guardrails specific to this task**
- Reuse existing log-count and distinct-day signals as the **single source of truth**; do not create parallel counters or a second definition of "a day."
- Match the app's existing day-bucketing/timezone convention exactly (report which one).
- Celebration fires **once** for the first log only — idempotent and non-repeating.
- Purely presentational + state-derivation changes; do **not** modify `WellnessCalculator` math, the Insights engine, or scoring.
- No new AI calls in this priority.

**Definition of done (in addition to the preamble's test requirements)**
- Project compiles clean; existing tests pass. Add a lightweight unit test for the **streak computation** (e.g. consecutive days, a gap breaking the streak, same-day multiple logs counting once).
- `#Preview`s: `CelebrationOverlay`, and `StreakChip` at 0/1/3-day states.
- Manually verify the sequence: fresh pet → save first log → celebration + haptic fires once, setup ladder advances, streak shows 1; second log same day → streak still 1, no re-celebration; log on a new day → streak 2; "today's one thing" appears before today's first log and disappears/checks off after.
- Report which log-count, distinct-day, and day-bucketing signals you used, and flag anything that didn't match.

---

## ⚡ PRIORITY 4 — Early-insight prioritization + first-insight celebration

**Goal:** Deliver a *genuine* earned insight as early as possible so the user experiences the "aha" the product is built on — without weakening the statistical rigor of the Poisson/correlation engine. Achieve this by surfacing the **low-N, rule-based and temporal detectors first**, and celebrate the user's very first real insight as a milestone conversion moment.

**Read these files first (ground yourself, do not assume their contents):**
- `PawMento/Core/Insights/InsightEngine.swift` (the orchestration/fan-out, rule-vs-LLM split, ordering of results)
- `PawMento/Core/Insights/Detectors/Detectors.swift` (the `InsightCandidate` contract + `CorrelationDetector`, `TemporalPatternDetector`, `TrendDetector`, `MilestoneDetector`)
- `PawMento/Core/Insights/InsightNarrator.swift` (evidence anchor, confidence tiers, `ConfidenceTier`)
- `PawMento/.../InsightStore.swift` (or wherever generated insights are held/observed by the UI)
- The insights teaser/detail view on Home (the "coming soon" teaser from Priority 2 becomes a real insight here)

If the detector set, the `InsightCandidate` fields (e.g. `isRuleBased`, `evidenceCount`), the `ConfidenceTier` cases, or the engine's result ordering do **not** match what's assumed below, **stop and report it** rather than inventing a substitute.

**Task 1 — Prioritize early-firing detectors in `InsightEngine`**
- **Do NOT change any detector's statistical thresholds, math, or firing conditions.** The Poisson process, multiple-comparisons correction, trend regression, and temporal windowing must remain untouched. This task is about **ordering and surfacing**, not loosening rigor.
- In the engine's result assembly, introduce an explicit **priority/ordering** so that, when multiple candidates exist, **rule-based `MilestoneDetector` and `TemporalPatternDetector` candidates surface first** for early-stage users, ahead of the higher-N `CorrelationDetector`/`TrendDetector` outputs.
- Ordering should be deterministic and defensible — e.g. sort by a tuple of (detector class priority, then existing confidence/evidence). Report the exact sort key you implemented.
- This must be additive: existing consumers that read all candidates keep working; you're changing **order**, not filtering anything out.

**Task 2 — Ensure a low-N positive milestone exists**
- Confirm `MilestoneDetector` already emits early positive milestones that can fire with only a few days of data (e.g. "3-day logging streak," "first full day of meals logged"). **Read it first.**
- If such a low-N positive milestone does **not** exist, add **one** modest, clearly rule-based milestone that can honestly fire early — following the detector's existing `InsightCandidate` construction pattern exactly (rule-based flag set, no implication of statistical/causal insight). Keep the tone positive-reinforcement, consistent with the file.
- **If it already exists, change nothing here** — just report that it's present and which milestone(s) qualify.

**Task 3 — Expose a "first insight" event**
- Add a way to detect when the user's **first-ever real insight** for the active pet is generated (e.g. transition from zero stored insights → one). Reuse the existing insight store/count — do **not** add a competing counter. Report the signal used.
- This event must be raised through the existing reactive flow (published state on the store/view model, `@MainActor`), so the UI can react once.

**Task 4 — Wire the insights teaser → real insight + celebration**
- When the first real insight exists, the Home insights section transitions from the Priority 2 "coming soon + ladder" teaser to the **actual first insight card**.
- Present the first insight with a **milestone treatment**: e.g. a "Your first pattern! 🐾" header and a **"Save for vet" / share CTA** (reuse any existing insight detail/share affordance — do not build a new sharing subsystem; if none exists, add a simple share sheet and report it).
- Also advance the Priority 2 setup ladder ("First pattern unlocked" → complete) on this same event, reusing the existing `SetupProgress` source of truth.
- Celebration fires **once** for the first insight only — idempotent, never repeats.

**Guardrails specific to this task**
- **No statistical change of any kind.** Thresholds, Poisson math, correction, regression, and windowing are read-only. You are re-ordering and surfacing, not fabricating or loosening.
- Never present a rule-based milestone as a statistical/causal finding — preserve the existing `isRuleBased` distinction and non-causal language enforced by `InsightNarrator`.
- All LLM narration continues to route through `ai-proxy`; the evidence-anchor + ±0.10 confidence-clamp logic in `InsightNarrator` stays intact.
- Reuse existing insight-count and `SetupProgress` signals as single sources of truth; no parallel counters.

**Definition of done (in addition to the preamble's test requirements)**
- Project compiles clean; existing tests pass. Add a lightweight unit test for the **new ordering** (given a mixed set of candidates, rule-based/temporal surface ahead of correlation/trend) and, if you added a milestone, a test that it fires under its low-N condition and does **not** fire below it.
- Manually verify the sequence: log for a few days → first rule-based/temporal insight appears **before** any correlation insight; the Home insights teaser becomes the real first-insight card with the milestone treatment + Save-for-vet CTA; the setup ladder's final step completes; celebration fires once and never repeats.
- Report the exact sort key, whether a new milestone was needed (or existing one used), the first-insight signal, and flag anything that didn't match the codebase.

---

## 💰 PRIORITY 5 — Event-triggered paywall on earned value

**Goal:** Stop showing the paywall on a blind timer or at a cold moment. Instead, trigger the premium moment **right after the user has *felt* value** — either when their first **strong-tier insight** appears, or when they exhaust their **free Coach quota** (i.e., they're hooked and want more). Both are warm conversion moments.

**Read these files first (ground yourself, do not assume their contents):**
- The **paywall / subscription flow** view + its presenter/view model (however the app currently triggers and shows the paywall)
- `PawMento/.../CoachViewModel.swift` (the free-question **quota state** and how exhaustion is detected)
- `PawMento/Core/Insights/InsightNarrator.swift` (`ConfidenceTier` — specifically the **strong** tier — and where `finalConfidence`/tier is assigned)
- `PawMento/.../InsightStore.swift` (where insights + their tiers are held/observed)
- `supabase/functions/verify-premium/...` (**read only** — server-side premium validation; must NOT change)
- The StoreKit purchase entry point already wired to the paywall

If the current paywall trigger mechanism, the `ConfidenceTier` cases, the quota-exhaustion signal, or the StoreKit entry point do **not** match what's assumed below, **stop and report it** rather than inventing a substitute.

**Task 1 — Define the two paywall trigger events**
- Introduce a single, explicit paywall-trigger concept (e.g. `enum PaywallTrigger { case firstStrongInsight; case coachQuotaExhausted }`) that the paywall presenter consumes. Additive — do not remove existing manual/entry-point ways of opening the paywall (e.g. a settings "Upgrade" button must still work).
- The paywall presentation should be able to carry its trigger context so the copy/headline can adapt (see Task 4).

**Task 2 — Trigger A: first strong-tier insight**
- Detect when an insight reaches the **strong** `ConfidenceTier` for the active user for the **first time** (reuse the existing insight store + tier assignment from `InsightNarrator`; do **not** recompute confidence or add a competing counter). Report the exact signal used.
- On that event, present the paywall with `.firstStrongInsight`.
- Fire **once** — idempotent; a persisted flag so it never re-triggers on subsequent strong insights. Use whatever local persistence the app already uses (report which).
- **Do not gate the insight itself behind the paywall here** — the user still sees their first strong insight; the paywall is presented *around/after* it as an upsell ("unlock full pattern history"), preserving the honest value delivery.

**Task 3 — Trigger B: free Coach quota exhausted**
- Detect the moment the user's free Coach quota hits zero (reuse the **existing server-enforced quota state** on `CoachViewModel` — do not reimplement quota logic client-side; the server via `ai-proxy` remains the source of truth).
- When the user attempts a Coach question with no free quota remaining (and isn't premium), present the paywall with `.coachQuotaExhausted` instead of a bare "out of questions" error.
- This must respect the existing server-side enforcement — the client trigger is purely *presentational*; it must never grant access or bypass the quota. Report how you detect exhaustion (returned quota state vs. an error from `ai-proxy`).

**Task 4 — Context-aware paywall copy**
- Adapt the paywall headline/subcopy to the trigger:
  - `.firstStrongInsight` → e.g. *"You just unlocked your first strong pattern — go premium for full history & unlimited insights."*
  - `.coachQuotaExhausted` → e.g. *"You've used your free questions — go unlimited with {pet}'s Coach."*
- Reuse the existing paywall UI/StoreKit purchase button; only the framing copy varies by trigger. Do not build a new purchase pipeline.

**Task 5 — Frequency & respect**
- Ensure the paywall is not annoying: each event-trigger fires at most once (Trigger A once ever; Trigger B on genuine exhaustion, with a sensible cooldown so it doesn't reappear on every tap after dismissal). Report the cooldown/dismissal handling you implemented.
- A dismissed paywall must never block the user from continuing to use free features they already have.

**Guardrails specific to this task**
- **`verify-premium` and server-side quota enforcement are read-only.** All money/entitlement decisions stay server-authoritative; the client only *presents* the paywall.
- Never bypass, grant, or fake premium access on the client. The quota trigger is presentational only.
- Do not gate the first strong insight itself behind the wall — value is delivered, *then* upsold.
- Reuse existing tier assignment (`InsightNarrator`), quota state (`CoachViewModel`), StoreKit entry point, and local persistence — no parallel systems.

**Definition of done (in addition to the preamble's test requirements)**
- Project compiles clean; existing tests pass. Add a lightweight test for the trigger logic: first strong-tier insight fires the paywall once (and not again), and quota-exhaustion maps to the paywall rather than a bare error.
- Manually verify: reach a strong-tier insight → paywall appears once with insight-context copy, and dismissing it still shows the insight; exhaust free Coach questions → next question attempt shows the quota-context paywall (no server bypass), dismiss → still no premium access granted; existing manual "Upgrade" entry point still works.
- Confirm `verify-premium` and server quota logic were not modified.
- Report the strong-tier signal, quota-exhaustion detection method, persistence used for the once-only flag, and the cooldown handling — and flag anything that didn't match the codebase.

---

## Suggested build order

1. **P1** — AI Coach welcome card (biggest bang, isolated change). Ship green.
2. **P2** — Ring setup-ladder + empty-state rewrites (visual momentum).
3. **P3** — First-log celebration + streak (habit loop; depends on P2's `SetupProgress`).
4. **P4** — Early-insight prioritization + first-insight celebration (depends on P2/P3 signals).
5. **P5** — Event-triggered paywall (harvests the value created by P1–P4).