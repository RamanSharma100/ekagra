# Changelog

All notable changes to the **Ekagra** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-10-08

### Added
- **Dark-First Premium Design System**: Centralized design tokens for colors, typography, spacing, radius, and shadows tailored for low eye fatigue.
- **Home Productivity Overview**: Real-time circular SVG Focus Score, streak counter, state-aware Current Focus timer card, and chronological activity timeline.
- **Zen Focus Mode**: Five focus modes (Deep Work, Study, Coding, Reading, Custom), flexible duration presets, intention anchors, ambient atmosphere audio (Rain, Forest, White Noise), and post-session reflection dialog.
- **Native Android Distraction Blocker & Shield**: Platform channel integration with `AccessibilityService` and `UsageStatsManager` for real-time foreground package detection and deflection overlays.
- **Always-On Background Tracking Service**: Continuous Android foreground service tracking exact screen time and foreground application transitions without battery drain.
- **6-Hour Scheduled Attention Analysis**: Automated background `WorkManager` job running every 6 hours to analyze high-consumption apps and trigger proactive dashboard notifications.
- **Behavioral AI Insights Engine**: Dynamic cognitive pattern detection cards (Peak Cognitive Flow Window, Distraction Deflection Rate, Tuesday Momentum Peak) across Daily, Weekly, and Monthly timeframes.
- **Dynamic Profile & Cognitive Leveling**: Progression tiers (L1 to L10), lifetime productivity metrics grid (Total Focus, Deflected Apps, Completed Sprints, Daily Goal), and 5 unlockable milestone badges with interactive progress dialogs.
- **Interactive Voice & Speech Synthesis**: On-device neural voice testing in Profile settings, conversational voice commands, and real-time audio waveform animations.
- **Local Data Sovereignty**: Full JSON backup export with one-tap clipboard copy, and granular activity cache clearing.
- **First-Run Onboarding Guide & Permissions Calibration**: Interactive multi-step wizard explaining core tenets and checking live permission grants for Usage Access, Accessibility Shield, and Notifications.
- **Android Home Screen Glanceable Widget**: Custom `AppWidgetProvider` showing active focus timer, daily score, and shield status directly on the Android launcher.
- **Brand Suite**: Complete vector SVGs, high-resolution PNG icon packs (16x16 to 1024x1024), and Google Play Feature Graphic.

### Maintainer
- Created and maintained by **Raman Sharma** ([@RamanSharma100](https://github.com/RamanSharma100)).
- Project repository: [https://github.com/RamanSharma100/ekagra](https://github.com/RamanSharma100/ekagra)
