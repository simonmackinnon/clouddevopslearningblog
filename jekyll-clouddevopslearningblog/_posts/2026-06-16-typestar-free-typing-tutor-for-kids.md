---
layout: post
title: "I Built a Free Typing Tutor for Kids Because Every Other One Wanted My Credit Card"
date: 2026-06-16
categories: aws react typescript terraform claude-code devops
description: A deep dive into building TypeStar — a free, no-subscription typing tutor for primary school kids — with React, TypeScript, AWS, Terraform, and Claude Code. Architecture, real bugs, and an honest review of AI pair programming.
---

My kid is seven and ready to start learning to type. I figured finding a good website for this would take about five minutes.

It took considerably longer than that.

What I found was a graveyard of Flash-era sites that don't work anymore, a handful of polished modern products that lock 80% of their content behind a subscription, and a few free-but-awful options clearly designed for teenagers or adults. The ones that do target young kids are either visually overwhelming, plastered with ads, or hit a paywall after three exercises.

So I built one. **TypeStar** is a free, no-subscription, no-ads typing tutor designed specifically for primary school kids. It's live at [typestar.theclouddevopslearningblog.com](https://typestar.theclouddevopslearningblog.com). This post covers the architecture, the genuine challenges during development, and an honest account of what Claude Code got right — and what it didn't.

---

## What TypeStar Actually Does

![TypeStar level map showing all 20 levels across 6 colourful zones](/media/typetastic.png)

The app has **20 levels across 6 zones**, each zone targeting a different part of the keyboard or typing skill:

| Zone | Name | Content |
|---|---|---|
| 1 | Keyboard Kingdom | Home row — F/J anchors, left hand, right hand, all 8 keys |
| 2 | Top Tower | QWERTY row, left then right then combined |
| 3 | Bottom Bunker | Z X C V row and B N M , . |
| 4 | Word World | Real words, no keyboard hints |
| 5 | Sentence City | Full sentences, capitals, punctuation |
| 6 | Speed Summit | Eyes off keyboard, building to 50 WPM |

Each level has 3 exercises and requires a minimum accuracy to earn stars and unlock the next level. There's also a **quick assessment** — pass one exercise at the required accuracy threshold and you unlock the next level early without grinding through all three. Useful when a kid already knows the material.

Every level opens with a **spoken audio tutorial**, delivered by an ElevenLabs voice that explains which fingers to use and what the goal is. This matters for young kids who may not be confident readers. There are also interactive typing tutorials, posture guides, and a home row demo where you can click any key and hear which finger presses it.

Progress is tracked with stars and **badges** (first exercise, zone completion, speed milestones). Badges can be shared via the Web Share API. Everything persists to the cloud if you have an account; otherwise it lives in localStorage.

No email required to start. No credit card ever.

---

## The Architecture

![TypeStar AWS architecture diagram showing CloudFront, S3, Cognito, API Gateway, Lambda, and DynamoDB](/media/typestar-architecture.svg)

```
                    ┌─────────────────────────────────────────┐
                    │           CloudFront Distribution        │
                    │    typestar.theclouddevopslearningblog   │
                    └────────┬──────────────────┬─────────────┘
                             │                  │
                    ┌────────▼──────┐   ┌───────▼──────────┐
                    │   S3 Bucket   │   │   API Gateway     │
                    │  (SPA + MP3s) │   │   (HTTP v2)       │
                    └───────────────┘   └───────┬──────────┘
                                                │
                                       ┌────────▼──────────┐
                                       │  Lambda (Node/TS)  │
                                       │  progress handler  │
                                       └────────┬──────────┘
                                                │
                                       ┌────────▼──────────┐
                                       │     DynamoDB       │
                                       │  (progress store)  │
                                       └───────────────────┘

        ┌────────────────────────────────────────────┐
        │              AWS Cognito                   │
        │  User Pool + Google IdP + Custom Domain    │
        │  typestar-auth.auth.ap-southeast-2...      │
        └────────────────────────────────────────────┘

        ┌────────────────────────────────────────────┐
        │              GitHub Actions                │
        │  infra.yml  →  terraform apply             │
        │  deploy.yml →  generate audio + build + S3 │
        └────────────────────────────────────────────┘
```

| Layer | Service | Detail |
|---|---|---|
| Frontend | React 18 + TypeScript + Vite | SPA, React Router v6 |
| Hosting | S3 + CloudFront | Private bucket, OAI, HTTPS redirect |
| Auth | Cognito User Pool | SRP email/password + Google OAuth via hosted UI |
| API | API Gateway HTTP v2 | Custom domain, `$default` stage |
| Backend | Lambda (TypeScript) | Progress save/load |
| Database | DynamoDB | PAY_PER_REQUEST, keyed by `userId#levelId` |
| TTS audio | ElevenLabs → S3 | Pre-generated at build time, served as static MP3s |
| DNS | Route 53 | A aliases to CloudFront |
| TLS | ACM | DNS-validated; CloudFront cert in us-east-1 |
| IaC | Terraform | Remote state in S3 |
| CI/CD | GitHub Actions | Two workflows: infra and deploy |

The entire stack costs effectively nothing to run. CloudFront + S3 for a low-traffic static site is pennies per month. DynamoDB on-demand at light usage stays in the free tier. Cognito covers 50,000 MAU for free. The only real cost is the ElevenLabs API for TTS generation — and that's now a one-time cost at build time, not per-page-load.

---

## The Technical Challenges

### 1. React SPA Navigation and Stale Component State

The first real bug: clicking "Next Level" on the results screen did nothing. The URL changed (React Router navigation worked), but the game didn't reset.

The cause is a standard SPA pitfall. React Router renders the same `<GamePage>` component for `/play/01` and `/play/02`. When you navigate between them, React sees the same component type at the same position in the tree and **reuses the instance** — it doesn't unmount and remount. So all the exercise state, the typing hook, the tutorial-dismissed flag — all of it persisted from the previous level.

The fix was a one-liner wrapper:

```tsx
function KeyedGamePage() {
  const { levelId } = useParams<{ levelId: string }>();
  return <GamePage key={levelId} />;
}
```

Passing `key={levelId}` to `<GamePage>` forces React to unmount and remount the whole component tree whenever the level changes. Every hook resets, every effect re-runs. Simple, but it's not obvious until you've run into it.

---

### 2. ElevenLabs Audio and the Autoplay Policy

The browser console was showing `NotAllowedError: play() failed because the user didn't interact with the document first`.

This one is subtle. The tutorial modal auto-plays audio 400ms after opening. It fires inside a `useEffect` — which is triggered by the user clicking a level card. The intention is to treat that click as the user gesture that satisfies Chrome's autoplay policy.

But ElevenLabs TTS is asynchronous. By the time you've `await`ed the API call, constructed the `Blob`, created the `Audio` object, and called `.play()`, the browser's user-gesture window has long since closed. You can't chain a `fetch` into an `.play()` call and expect it to work.

The right fix isn't to suppress the error — it's to specifically catch `NotAllowedError` and fail silently, since in that case the user simply hasn't interacted yet:

```typescript
try {
  await audio.play();
} catch (playErr) {
  if ((playErr as DOMException).name === 'NotAllowedError') {
    setSpeaking(false);
    URL.revokeObjectURL(url);
    return; // fail silently — user can click "listen again"
  }
  throw playErr; // re-throw anything unexpected
}
```

Swallowing the error broadly would hide real problems. Catching specifically means only autoplay failures are silent; network errors and decoding failures still surface.

---

### 3. ElevenLabs Silently Drops Symbol Characters

When a level teaches `+`, `\`, `;`, `/` and similar symbols, the audio tutorial needs to say those key names aloud. ElevenLabs simply skips them. Send it `"Press ; repeatedly"` and you get `"Press repeatedly"` — the semicolon is silently dropped.

The solution was a `sanitizeForSpeech()` function that replaces symbols with their spoken equivalents before sending to the API:

```typescript
const SYMBOL_MAP: [RegExp, string][] = [
  [/\\/g,  ' backslash '],
  [/\+/g,  ' plus '],
  [/;/g,   ' semicolon '],
  [/\//g,  ' slash '],
  [/=/g,   ' equals '],
  [/\[/g,  ' left bracket '],
  [/\]/g,  ' right bracket '],
  // ...
];

function sanitizeForSpeech(text: string): string {
  let out = text;
  for (const [re, word] of SYMBOL_MAP) out = out.replace(re, word);
  return out.replace(/\s{2,}/g, ' ').trim();
}
```

This function later got extracted to `src/utils/speechUtils.ts` so it could be shared between the React hook and the build-time audio generation script.

---

### 4. Pre-Generating Audio at Build Time

The original architecture called ElevenLabs live on every tutorial play. That means latency before the audio starts, an API key exposed in the browser bundle, and a per-call cost every time a kid opens a level.

The better approach: generate all the audio once at build time and serve it as static files from S3.

There are exactly **53 phrases** the app ever speaks:
- 20 tutorial auto-play phrases (`"Level 1. Find Your Home Base!. ..."`)
- 20 tutorial listen-again phrases (same, without the `"Level N."` prefix)
- 5 tips page cards
- 8 home row demo key announcements

A build script (`scripts/generate-audio.ts`) collects all these phrases, hashes each one (`sha256(sanitizedText + voiceId).slice(0, 16)`), and only calls ElevenLabs if the corresponding MP3 doesn't already exist locally. It writes a manifest to `src/data/audioManifest.json`.

At build time, Vite bundles the manifest into the app. At runtime, `useSpeech` checks the manifest first:

```typescript
const prerecordedUrl = MANIFEST[sanitizeForSpeech(rawText)];
if (prerecordedUrl) {
  const audio = new Audio(prerecordedUrl);
  await audio.play();
  return;
}
// fall through to live ElevenLabs (dev only) or Web Speech fallback
```

GitHub Actions caches the `public/audio/` directory keyed by the hash of the four files that determine what audio gets generated. If nothing changed, the cache restores in seconds and zero ElevenLabs calls are made:

```yaml
- name: Cache pre-generated audio
  uses: actions/cache@v4
  with:
    path: public/audio
    key: audio-${{ hashFiles('scripts/generate-audio.ts', 'src/data/levels.ts',
                             'src/data/levelTutorials.ts', 'src/data/tips.ts') }}
    restore-keys: audio-
```

The first CI run generates all 53 files. Every subsequent run is instant unless the content changes.

---

### 5. Google OAuth: The redirect_uri_mismatch Nobody Warns You About

Adding Google sign-in via Cognito is well-documented, but one step is easy to miss and produces a confusing error.

The OAuth flow goes: **browser → Cognito hosted UI → Google → Cognito → browser**. The redirect from Google goes back to *Cognito*, not to your app. So the URL you need to register in the Google OAuth console is Cognito's IdP response endpoint:

```
https://typestar-auth.auth.ap-southeast-2.amazoncognito.com/oauth2/idpresponse
```

Not your app's `/callback` URL. Registering the wrong one gives you `Error 400: redirect_uri_mismatch` on the Google sign-in screen with no further explanation.

The Terraform for the Cognito side is fairly involved — you need a user pool domain, a Google identity provider, and an updated app client with OAuth flows enabled:

```hcl
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "typestar-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "Google"
  provider_type = "Google"
  provider_details = {
    client_id        = var.google_client_id
    client_secret    = var.google_client_secret
    authorize_scopes = "email profile openid"
  }
  attribute_mapping = {
    email    = "email"
    username = "sub"
  }
}

resource "aws_cognito_user_pool_client" "spa" {
  # ...existing SRP config...
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls = ["https://${local.subdomain}/callback", "http://localhost:5173/callback"]
  supported_identity_providers = ["COGNITO", "Google"]
  depends_on = [aws_cognito_identity_provider.google]
}
```

The `depends_on` on the app client is important — Cognito will reject the client config if the identity provider doesn't exist yet.

---

### 6. Playwright E2E Tests vs. a Rapidly Evolving UI

As features were added — SVG icons replacing emoji, a tutorial modal blocking the game, a mobile banner — the E2E tests broke repeatedly. The fixes were instructive:

**Emoji → SVG breaks text selectors.** A test that checked for `🔒` next to a locked level stopped working when the lock became a Lucide SVG. The fix is to add semantic attributes and test those instead:

```tsx
// Component
<div role="img" aria-label="Locked">
  <Lock aria-hidden="true" />
</div>

// Test
await expect(level2.getByRole('img', { name: 'Locked' })).toBeVisible();
```

**Tutorial modal blocks the game.** Tests that navigated to `/play/01` would time out waiting for the Start button because the tutorial modal was in the way. Rather than dismissing the modal in every test, the fix was to pre-populate `localStorage` via `addInitScript` before the page loaded:

```typescript
await page.addInitScript(() => {
  localStorage.setItem('tt_dismissed', JSON.stringify(['01']));
});
```

`addInitScript` runs before any page scripts execute, so the modal sees the dismissed state immediately and never renders.

---

## Claude Code: An Honest Review

I built this entire project with Claude Code. Here's what that actually looked like.

### What it got right

**Multi-file changes are coherent.** When a feature touched the Terraform, the React component, the GitHub Actions workflow, and a new TypeScript type all at once, Claude handled it as a single coordinated change. This is where it genuinely beats a chat-based workflow — there's no "now paste in the Terraform" step.

**Staying in scope.** I didn't get unsolicited refactoring, unnecessary abstractions, or "while I'm here I also cleaned up X". Each change was scoped to what was asked. For a project that grew incrementally over many sessions, this mattered.

**Diagnosis from real outputs.** When I pasted a console error or a TypeScript compile failure, Claude identified the root cause rather than guessing. The `NotAllowedError` autoplay fix and the Playwright `addInitScript` workaround both came from showing it the actual error, not describing the symptoms.

**The assessment system design.** When asked to add "a mini assessment per level", it proposed using a `?mode=assessment` URL parameter to reuse the existing `GamePage` infrastructure rather than building a separate page. The right call — less code, more reuse, no new route complexity.

**Security hygiene.** It never logged secrets, never put sensitive values in code, and correctly steered toward environment variables and GitHub Secrets without being prompted. When I mentioned I had the Google client secret, it explicitly said not to paste it in chat.

### What went wrong

**The mobile UX overcorrection.** When asked to add a message for mobile users, Claude built a full-screen gate that completely blocked all interactions on small viewports. That meant tutorials, badges, login — everything — was inaccessible on mobile. It had interpreted "this app needs a keyboard" as "block mobile users entirely" rather than "warn them but let them browse". Needed explicit correction.

**Broad error suppression.** The first pass at fixing the `NotAllowedError` wrapped the entire `play()` call in a generic catch block. That would have silently swallowed real errors — network failures, decoding errors — alongside the autoplay block. Needed pushing to narrow the catch to the specific `DOMException.name`.

**The Google OAuth knowledge gap.** Claude correctly scaffolded all the Terraform and frontend OAuth code, but didn't flag the Google Console setup step where the Cognito IdP response URL needs to be registered. That step only surfaced when the login failed in production. A heads-up earlier would have saved a round trip.

**Verbosity drift.** Over a long session, responses get longer. Summaries of what was just done, explanations of why code is correct, narration of the plan. Fine occasionally, noise over time. Worth being explicit about expectations — "terse, no trailing summary" — if it bothers you.

---

## Things I'd Do Differently

**Start with E2E tests that survive UI churn.** Testing by text content or emoji is fragile. `data-testid` and ARIA attributes should be the default from day one, not something you add when tests break.

**Enumerate audio phrases earlier.** The decision to call ElevenLabs live worked fine in development but was always going to be wrong in production. The build-time generation approach was obvious in hindsight — I should have planned for it from the start rather than retrofitting it later.

**Separate infra and app deployment from the beginning.** I had a single workflow for a while. Splitting into `infra.yml` (path-filtered to `infra/**`) and `deploy.yml` made both faster and clearer. Worth doing immediately.

---

## Try It

TypeStar is live and free at **[typestar.theclouddevopslearningblog.com](https://typestar.theclouddevopslearningblog.com)**.

No account needed — open it and start typing. Progress without an account saves in the browser. Create an account (email or Google) to sync across devices.

If you have a primary school kid ready to learn, I hope it helps. If you're a developer curious about the implementation, the architecture is a reasonable working example of a full-stack serverless SPA on AWS — Cognito auth, API Gateway + Lambda + DynamoDB backend, CloudFront-hosted frontend, Terraform-managed infrastructure, CI/CD with GitHub Actions — without reaching for Amplify, SAM, or any managed deployment abstraction.

Feedback welcome. Especially from the seven-year-olds.

---

*Built with React 18, TypeScript, Vite, Tailwind CSS, AWS (Cognito, CloudFront, S3, API Gateway, Lambda, DynamoDB), Terraform, ElevenLabs, and Claude Code.*
