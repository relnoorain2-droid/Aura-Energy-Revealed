FONTS — Aura Energy Revealed
============================

The design uses three Google Fonts (all free, SIL Open Font License):

  1. Cormorant Garamond (Medium)   — display serif        → CormorantGaramond-Medium.ttf
  2. Manrope (Light/Regular/Medium/SemiBold/Bold) — UI    → Manrope-*.ttf
  3. IBM Plex Mono (Medium)        — mono accents         → IBMPlexMono-Medium.ttf

HOW TO INSTALL
--------------
1. Download from fonts.google.com (search each family → Download family).
2. Drop the .ttf files into this folder (Resources/Fonts) in Finder.
   Xcode picks them up automatically (folder is synchronized).
3. Build & run. Nothing else needed — the app registers every bundled
   .ttf/.otf at launch (see FontRegistrar in AuraTypography.swift), so no
   Info.plist changes are required.

WITHOUT THE FONTS
-----------------
The app still builds and runs: AuraFont falls back to the system serif /
sans / monospaced designs. The premium feel is better with the real fonts.
