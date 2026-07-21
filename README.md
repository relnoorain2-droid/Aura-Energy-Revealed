# Aura Energy Revealed — native iOS app

A premium SwiftUI implementation of the approved Claude Design handoff
(*AuraVision AI · Product Design Specification v1.0*). SwiftUI · iOS 17+ ·
MVVM · SwiftData · StoreKit 2 · Vision · AVFoundation. No third-party
dependencies.

## Open & run

1. Requires a **Mac with Xcode 16 or newer**.
2. Open `AuraEnergyRevealed.xcodeproj`.
3. Select your team under *Signing & Capabilities* (any free Apple ID works
   for the simulator).
4. Run on an iPhone simulator or device (iOS 17+). The **camera needs a real
   device**; in the simulator use the photo-upload path on the scan screen.

### Fonts (recommended, 2 minutes)
The design uses Cormorant Garamond, Manrope, and IBM Plex Mono. Download
them free from fonts.google.com and drop the `.ttf` files into
`AuraEnergyRevealed/Resources/Fonts/` — see `README-FONTS.txt` there. The
app runs fine without them (system serif/sans fallbacks).

### Testing Aura+ subscriptions
1. In Xcode: *Product → Scheme → Edit Scheme… → Run → Options →
   StoreKit Configuration* → choose `AuraPlus.storekit` (project root).
2. Run — the paywall then uses local test products:
   Yearly **$39.99** (3-day free trial, anchor), Monthly **$19.99**,
   Weekly **$15.99**. Free tier includes **1 complimentary scan**.
3. For App Store release, create matching products in App Store Connect with
   the same product IDs (`com.auravision.auraplus.yearly/monthly/weekly`).

## What's implemented (matches the design spec)

- **Design system** — deep-space palette, aurora spectrum, glass cards
  (6% fill, 1px stroke, real blur, inset highlight), 4pt spacing, spec radii,
  spring motion tokens (120/280/460ms + ambient loops).
- **Living auras** — reusable `AuraOrbView` with per-colour personalities
  (spin, breathe, ripple, shimmer, pulse, drift) for all 10 aura colours.
- **Flow** — Splash → Welcome → 3-slide onboarding (with intention chips
  that personalize readings) → honest permissions priming → Home.
- **Home** — greeting, streak pill, Today's Aura hero, daily insight,
  quick actions, recent-readings rail (free sees today only).
- **Scan** — camera with framing-ring coaching + photo upload; the
  ~7-second cinematic scan (freeze → light-bar sweep + rising particles →
  resonance rings + colour bloom → white bloom reveal) with haptic ticks.
- **Result** — **the user's real photo stays the hero**: Vision person
  segmentation produces a person cutout + a tinted silhouette glow, layered
  over an animated aura field with chakra points on the meridian. Falls back
  to a photo-with-aura-rim when no person is detected.
- **Details** — colour composition bar, meaning, suggested practice;
  Body Map (14 regions, one premium template, swipe between parts);
  Chakras (7 rows with balance meters); Aura Colour Guide.
- **Practice** — meditation library + breathing player (orb paces 4-7-8),
  aura-linked daily journal (SwiftData), Aura Coach chat (on-device replies
  today; `CoachResponding` protocol is the seam for a cloud AI API).
- **You** — profile with living avatar & stats, Your Journey history with
  energy-over-time chart, milestones & forgiving streak (1 grace day/week),
  badges, settings suite with ethics statement, notifications scheduling.
- **Monetization** — soft paywall (never mid-scan): 1 free scan, then Aura+
  gates history, body map, coach, premium meditations, extra scan modes.
- **Accessibility** — Dynamic Type via relative fonts, Reduce Motion stills
  every ambient loop and swaps the scan build for a cross-fade, Reduce
  Transparency swaps glass for solid surfaces, VoiceOver labels throughout,
  never colour-only information.

## Architecture

```
AuraEnergyRevealed/
├─ App/            entry point, AppState (phase/tab/gating), RootView
├─ DesignSystem/   palette, typography (+runtime font registration), motion, haptics
├─ Components/     AuraOrbView, GlassCard, buttons, chips, FloatingTabBar,
│                  EnergyMeter, AuroraBackground
├─ Models/         AuraHue (10 auras), ScanMode (8 lenses), SwiftData models,
│                  BodyRegion (14), Chakra (7), Meditation, seeded RNG
├─ Services/       AuraEngine (interpretation, AI-API-ready seam),
│                  CameraService, PersonSegmentationService (Vision),
│                  StoreService (StoreKit 2), StreakService, NotificationService
└─ Features/       Onboarding · Home · Scan · Result · Explore · Practice · You
```

Views are declarative; state lives in `AppState`, `ScanViewModel`, and the
services. `AuraInterpreting` and `CoachResponding` protocols let you swap in
a cloud AI later without touching a single view.

## Notes & next steps

- **App Store compliance** — wording avoids medical claims; readings are
  framed as generated interpretations (ethics statement in Settings → About).
  Trial terms shown at the CTA; restore purchase available on paywall and
  in Settings.
- Meditation audio, share-card rendering, widgets/Live Activities, and
  iCloud sync are scaffolded conceptually but not yet implemented — good
  v1.1 candidates.
- If Xcode complains about the `.storekit` file version, recreate it via
  *File → New → StoreKit Configuration File* and copy the three product IDs.
