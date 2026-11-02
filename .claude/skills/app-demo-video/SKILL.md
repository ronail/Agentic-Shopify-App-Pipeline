---
name: app-demo-video
description: "Produce the two Shopify App Store video materials from a real app build: a 2-3 minute public promo video (composed, not recorded) and a separate review-only demo screencast of install, onboarding, and the primary action. Runs entirely on local, account-free tooling."
argument-hint: "[app-slug] [promo|screencast|both]"
user-invocable: true
allowed-tools: Read, Glob, Write, Edit, Bash
model: sonnet
---

> **Explicit invocation only**: run this skill when the user asks for
> `/app-demo-video`, or when `/app-page-materials` reaches the video assets.

## Purpose

The App Store needs two different videos, made by two different methods. Only the
second one is a recording:

| Profile | Material | Method | Runtime |
|---|---|---|---|
| `promo` | Public listing feature media | **Composed** — Remotion motion graphics + captions, with real UI clips as proof | 60-90 s hero cut; 2-3 min maximum |
| `screencast` | Review-only demo (requirement 4.5.3) | **Recorded** — Playwright walkthrough of install → onboarding → primary action | As long as the flow needs |

Do not render one and reuse it for the other, and do not build the promo by
recording the screencast and cutting it down — that produces an instructional
tour, which is exactly what Shopify says not to ship.

## Why the promo is composed

Shopify: the feature video is "promotional rather than instructional" and
screencasts must be at most 25% of it. A promo that is 100% captured UI cannot
meet that ratio no matter how it is edited. So the promo is a Remotion
composition — typography, benefit callouts, transitions, captions — into which
short real-UI clips are placed as proof.

## Prerequisites

- The app is deployed to a test store (`/deploy-to-test-store` completed).
- Both profiles need Playwright and ffmpeg:

  ```bash
  node -e "require('playwright')" 2>&1
  ffmpeg -version 2>&1 | head -1
  ```

- The `promo` profile additionally needs the local, account-free stack:

  ```bash
  npx remotion --version                 # composition + render
  python3 -c "import kokoro; print('ok')" # voiceover (Apache-2.0, local)
  whisper-cli --help 2>&1 | head -1       # captions (MIT, local; `main` in older builds)
  ```

- **No paid external service is required.** Do not introduce one without saying so
  and getting approval first — the whole point of this toolchain is that it runs
  locally with no accounts, API keys, or per-generation billing.
- The `promo` profile uses the `/remotion-official` skill for project scaffolding,
  the markup API, SRT captions, and the Studio preview loop. It is a pinned
  dependency, not repo content: if `bash scripts/install-vendor-skills.sh --check`
  reports it missing, install it with
  `bash scripts/install-vendor-skills.sh --install remotion-official`. Load it
  before writing composition code rather than recalling the API from memory.

## Steps

### 1. Write the beats

Read `apps/<app>/README.md` and
`production/apps/<app>/assets/screenshots/manifest.md`. Write
`production/apps/<app>/assets/video/script.md` with two sections:

- **Promo beats** — one promised outcome, then 8-12 beats. Each beat is one visual
  moment plus one short caption. Structure: hook in the first 3 seconds (the
  problem or the payoff, never a logo), problem, the app as the answer, two or
  three benefit moments, payoff, one call to action.
- **Screencast beats** — install, onboarding, primary action, result, in the order
  a reviewer will follow them.

Budget the promo explicitly: mark which beats use real UI and keep their total at
or below 25% of runtime. Everything else is type, motion, and product screenshots.

### 2. Capture the real UI (promo proof clips)

Drive the real admin with Playwright at 1920x1080 with `slowMo` so clicks read.
Capture **only** the beats marked as UI proof — one core task, not a tour. No
mockups, no synthetic footage, no stock footage of a fake product.

### 3. Compose the promo

Build a Remotion composition that plays the UI clips against typographic benefit
frames:

- Hook frame at 0 s — must read on its own, muted.
- Burned captions on every beat (the video has to work with sound off).
- 2-4 second holds; no strobing cuts.
- End frame: product name and one call to action.
- No third-party logos, no unverifiable claims, no pricing, no real merchant data.

### 4. Voiceover (optional) and music

If the promo has narration, synthesize it locally with Kokoro:

```bash
python3 - <<'PY'
from kokoro import KPipeline
import soundfile as sf
pipeline = KPipeline(lang_code='a')
for i, (gs, ps, audio) in enumerate(pipeline(open('script.txt').read(), voice='af_heart')):
    sf.write(f'vo-{i}.wav', audio, 24000)
PY
```

Music bed: a CC0 track from a free library (Pixabay, Free Music Archive,
Freesound). Do **not** use models whose weights are non-commercial.

### 5. Generate captions

Word timestamps from whisper.cpp, then convert to SRT:

```bash
whisper-cli -m models/ggml-base.en.bin -f audio.wav -osrt -ml 42 --split-on-word
```

If there is no narration, write captions from the beat sheet directly — they are
the on-screen copy, not a transcript.

### 6. Record the review screencast

A separate Playwright run that follows the install-to-value path exactly as a
reviewer would. No cuts that skip setup steps, no sped-up sections. English audio
or burned English subtitles.

### 7. Export

Ask: "May I write the script and both videos to `production/apps/<app>/assets/video/`?" Write on approval, then export to:

```
production/apps/<app>/assets/video/
  promo.mp4              (60-90 s hero, or up to 2-3 min; captioned)
  promo-poster.png       (frame 0, 1600x900-safe; used as the listing still)
  review-screencast.mp4  (install -> onboarding -> primary action, subtitles)
  script.md
  captions/promo.srt
```

Render commands:

```bash
npx remotion render src/index.ts Promo out/promo.mp4
npx remotion still  src/index.ts Promo out/promo-poster.png --frame=0
ffmpeg -i out/review-screencast-raw.mp4 -vf subtitles=captions/screencast.srt \
  -c:v libx264 -crf 18 -pix_fmt yuv420p out/review-screencast.mp4
```

### 8. Verify

```bash
ffprobe -v error -show_entries format=duration:stream=width,height \
  -of default=nw=1 production/apps/<app>/assets/video/promo.mp4
```

Check duration, 1920x1080, that the poster still exists, and that the UI share of
the promo is at or below 25%.

## Ownership

Owned by **growth-lead** (promo positioning) and **app-store-reviewer** (review
screencast completeness). `ux-lead` confirms the recorded flow matches the shipped
UI.

## Rules

- **Record the real product.** Real UI only for the app; no synthetic or
  AI-generated footage of the product.
- **Promo is composed, screencast is recorded.** If the promo is a trimmed
  screencast, it is wrong.
- **Promo is promotional, not instructional** — screencasts at most 25% of runtime.
- **2-3 minutes is the ceiling**, 60-90 seconds is the target.
- **Hook in the first 3 seconds**, never a logo animation.
- **Captions on both**; the promo must make sense muted.
- **English audio or English subtitles** on the screencast.
- **No third-party logos**, no unverifiable claims, **no pricing** in either video.
- **No PII** and no real merchant data in any recording.
- **No paid services** — Kokoro, whisper.cpp, Remotion, Playwright, and ffmpeg are
  local and free at this team size. Flag any paid dependency before using it.

## Verification

- `promo.mp4` exists, is 60 s-3 min, captioned, and its UI footage is ≤25%.
- `promo-poster.png` exists and reads on its own.
- `review-screencast.mp4` covers install, onboarding, and the primary action with
  English audio or subtitles.
- Both are separate artifacts, produced by different methods.
- Verdict: `complete` when both videos exist, the promo is composed rather than
  trimmed from the screencast, and every rule above holds; otherwise `incomplete`.

## Next Steps

- `/app-page-materials [app]` — record the video paths in the listing
- `/app-store-checklist [app]` — verify all media is present, separate, and compliant
