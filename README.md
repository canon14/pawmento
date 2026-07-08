<div align="center">

# 🐾 PawMento

**Your pet's health, beautifully journaled — with an AI coach that actually cares.**

PawMento is a native iOS app that helps pet parents log their pet's daily life, track a wellness score, surface meaningful health patterns, and chat with an empathetic, safety-guarded AI coach.

</div>

---

## ✨ Overview

PawMento turns scattered observations about your pet into structured, actionable insight. Tap to log meals, walks, symptoms, moods and more; PawMento computes a rolling **Wellness Score**, detects patterns (like "ear scratching tends to follow chicken meals"), and lets you talk through concerns with an AI coach that knows your pet's history — while firmly routing real emergencies to a vet.

---

## 🎯 Key Features

### 📓 Daily Logging
- **15 log categories**, each with its own emoji: Meal 🥩, Water 💧, Potty 💩, Sleep 💤, Walk 🦮, Symptom 🤒, Med 💊, Mood 😊, Grooming 🛁, Vet Visit 🏥, Training 🎯, Play 🎾, Energy ⚡️, Appetite 🥣, and Other 🐾.
- The 8 most-used categories appear in a fast horizontal quick-log scroller.
- Photo attachments, severity ratings, descriptions, and timestamps per entry.

### 💯 Wellness Score (0–100)
A rolling 14-day score computed from four weighted dimensions:

| Dimension | Max Points | Based On |
|---|---|---|
| Symptom Burden | 40 | Symptom frequency & severity |
| Routine Adherence | 25 | Meals, potty, sleep consistency |
| Activity Level | 20 | Walks & training |
| Medication Compliance | 15 | Overdue medication penalties |

### 🔍 Insights Engine
- On-device detectors run **in parallel**: Correlation, Temporal Pattern, Trend, and Milestone detection.
- Rule-based findings render instantly; nuanced patterns are scored and written up by an LLM **Insight Narrator**.
- Results are cached per pet/time-window and surfaced as pattern alert cards.
- **Breed benchmarks** let you compare your pet against breed-typical baselines.

### 🤖 AI Coach
- A streaming chat companion with a warm, empathetic, non-robotic persona.
- Automatically injects a **live pet context layer** (name, species, breed, weight, computed age) into every conversation.
- **Safety-first engineering**, with explicit emergency routing for:
  - Bloat / GDV (swollen stomach + unproductive retching)
  - Toxin ingestion (includes the ASPCA Animal Poison Control number)
  - Male-cat urinary blockages
  - Seizures
- **Anti-jailbreak guardrails** that refuse medication dosing, "pretend you're a vet" roleplay, and hypothetical-framing tricks.

### ⏰ Reminders & Medications
- Local push notifications for due tasks.
- Recurring reminders with custom recurrence rules.
- Medication tracking with streak counts and overdue detection.

### 🔐 Accounts & Sync
- Supabase Auth with secure sign-in.
- Offline-first behavior with local caching and background sync.
- Free / paid subscription tiers.

---

## 🏗️ Architecture

PawMento follows a clean **MVVM** structure built on SwiftUI.

```
PawMento/
├── App/                  # Entry point, RootView, Strings, Theme (design system)
├── Models/               # Domain models + DTOs (Pet, LogEntry, Medication,
│                         #   Reminder, ChatMessage, Insight)
├── ViewModels/           # Observable stores (PetStore, LogStore,
│                         #   CoachViewModel, InsightsViewModel, etc.)
├── Views/
│   ├── Home/             # Wellness hero, timeline, quick-log grid, pet selector
│   ├── Coach/            # AI chat UI (chat view, composer, message bubbles)
│   ├── Insights/         # Insight cards, breed benchmarks, inline charts
│   └── Components/       # Reusable views (cached images, image picker, toasts)
├── Core/
│   ├── AI/               # AICoachClient, AICoachPrompt, SafetyClassifier
│   ├── Analytics/        # TelemetryEngine
│   ├── Authentication/   # AuthManager, LoginScreen
│   ├── Database/         # SupabaseManager, OfflineSyncManager,
│   │                     #   StorageManager, schema.sql
│   ├── Insights/         # InsightEngine, Detectors, Narrator, SignalLoader
│   ├── Reminders/        # NotificationManager, ReminderStore
│   ├── Utilities/        # WellnessCalculator
│   └── Utils/            # ImageCache
├── Fonts/                # Plus Jakarta Sans family
├── Assets.xcassets/      # App icon, accent color
├── breeds.json           # Breed reference data
└── generate_breeds.py    # Breed data generator
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift |
| UI | SwiftUI |
| Architecture | MVVM |
| Backend | Supabase (PostgreSQL + Auth) |
| Security | Row Level Security (RLS) on all tables |
| AI Providers | Anthropic (`claude-haiku-4-5`, default) & OpenAI (`gpt-4o-mini`) |
| AI Transport | Server-Sent Events (SSE) streaming |
| Typography | Plus Jakarta Sans |

---

## 🗄️ Data Model

The PostgreSQL schema (`Core/Database/schema.sql`) defines 8 tables, all protected by Row Level Security so users can only ever access their own pets' data:

- **users** — public profile linked to Supabase Auth (auto-created on signup via trigger)
- **subscriptions** — free/paid plan status and billing period
- **pets** — name, species, breed, birthday, weight, photo
- **logs** — daily activity/food/medication entries
- **symptoms** — symptom type + severity (1–5) for pattern tracking
- **reminders** — due dates, recurrence rules, completion state
- **chat_messages** — AI coach conversation history
- **medications** — name, frequency, next due date, streak count

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+ deployment target
- A [Supabase](https://supabase.com) project
- An Anthropic and/or OpenAI API key

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/canon14/pawmento.git
   cd pawmento
   ```

2. **Set up the database**
   - Create a Supabase project.
   - Run [`PawMento/Core/Database/schema.sql`](PawMento/Core/Database/schema.sql) in the Supabase SQL editor to create tables, RLS policies, and triggers.
   - Apply migrations in order from [`PawMento/Core/Database/migrations/`](PawMento/Core/Database/migrations/) (at minimum **010**, **011**, **012**, and **013** for onboarding fixes).
   - Migration **013** creates the `pawmento-media` storage bucket, storage RLS policies, and the `ensure_user_bootstrap` RPC used by the app on sign-in.
   - Verify deployment with [`PawMento/Core/Database/migrations/VERIFY_DEPLOYMENT.sql`](PawMento/Core/Database/migrations/VERIFY_DEPLOYMENT.sql) in the SQL editor (checks 7–8 should return zero rows).

3. **Configure storage (if not using migration 013)**
   - In Supabase Dashboard → Storage, ensure bucket `pawmento-media` exists and is **public** (the app uses public URLs for pet photos).
   - Objects must live under `{userId}/...` so RLS policies can scope uploads to `auth.uid()`.

4. **Configure secrets**
   - Create `PawMento/Core/Secrets.swift` (git-ignored) with your keys:
     ```swift
     enum Secrets {
         static let anthropicApiKey = "YOUR_ANTHROPIC_API_KEY"
         static let openaiApiKey    = "YOUR_OPENAI_API_KEY"
         static let supabaseURL     = "YOUR_SUPABASE_URL"
         static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
     }
     ```

5. **Open and run**
   ```bash
   open PawMento.xcodeproj
   ```
   Build and run on a simulator or device.

---

## 🧪 AI Safety Testing

`StressTestRunner.py` is a QA harness that fires adversarial prompts at the AI coach to validate its safety behavior. It covers six categories: **True Emergencies**, **Jailbreak Attempts**, **Ambiguous Health**, **Tone & Personality**, **Personalization & Context**, and **Format Discipline**, writing results to a markdown report.

```bash
python3 StressTestRunner.py
```

> The script reads the Anthropic key from `Secrets.swift`. Ensure that file is configured first.

---

## ⚠️ Security Note

API keys are currently read from a bundled `Secrets.swift` file. Shipping LLM/Supabase keys inside a mobile binary is risky — for production, route AI calls through a backend proxy and keep secrets server-side.

---

## 📋 Disclaimer

PawMento is **not a substitute for professional veterinary care**. The AI coach does not diagnose conditions or prescribe medication. In an emergency, contact your veterinarian or an emergency animal hospital immediately. For suspected poisoning, call the **ASPCA Animal Poison Control Center: (888) 426-4435**.

---

<div align="center">

Made with 🐾 for pet parents everywhere.

</div>
