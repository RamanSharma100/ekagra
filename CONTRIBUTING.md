# Contributing to Ekagra

Thank you for your interest in contributing to **Ekagra**! We welcome contributions that help make focus, digital wellbeing, and calm productivity accessible to everyone.

To maintain code quality, visual elegance, and architectural clarity, please follow these guidelines.

---

## Code of Conduct

All contributors are expected to uphold the [Code of Conduct](CODE_OF_CONDUCT.md). Please report any unacceptable behavior directly to the project maintainer, **Raman Sharma** ([@RamanSharma100](https://github.com/RamanSharma100)), or via GitHub issues / discussions.

---

## How Can You Contribute?

1. **Reporting Bugs**: Check existing issues on [GitHub Issues](https://github.com/RamanSharma100/ekagra/issues). Provide device information, Android/Flutter version, and clear reproduction steps.
2. **Proposing Features**: Start a discussion in [GitHub Discussions](https://github.com/RamanSharma100/ekagra/discussions) or open a feature request issue.
3. **Submitting Pull Requests**: Implement bug fixes, performance optimizations, or agreed-upon features.
4. **Improving Documentation**: Fix typos, add doc comments, or improve user guides.

---

## Development Setup

### Prerequisites

- Flutter SDK `^3.13.2` or higher (Flutter 3.47+ recommended)
- Dart SDK `^3.13.2` or higher
- Android Studio / VS Code with Flutter and Dart extensions
- Android Emulator or physical device (Android 15 / API 35 supported)

### Getting Started

1. Fork the repository and clone your fork locally:
   ```bash
   git clone https://github.com/RamanSharma100/ekagra.git
   cd ekagra
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Verify code analysis and run test suite:
   ```bash
   flutter analyze
   flutter test
   ```

4. Run the app locally:
   ```bash
   # Run on connected Android device or emulator
   flutter run

   # Or run in debug mode on specific device
   flutter run -d emulator-5554
   ```

---

## Architectural Guidelines

Ekagra follows a **Feature-First Clean Architecture**:

- `lib/app/`: App initialization, themes, design tokens, and navigation shell.
- `lib/core/`: Reusable domain-agnostic widgets, utilities, and service contracts (`VoiceService`, `AiService`, `NotificationService`).
- `lib/data/`: Domain models, data sources, and repositories (`ProductivityRepository`, `UserRepository`).
- `lib/features/`: Feature modules (`home`, `focus`, `activity`, `insights`, `ai_companion`, `voice`, `goals`, `routines`, `profile`, `onboarding`, `shield`).
- `lib/services/`: Native Android platform channel integrations (`AppBlockerService`).

### Rules to Follow

- **Design System First**: Never hardcode colors, margins, or fonts in widgets. Use `ThemeColors`, `ThemeSpacing`, `ThemeRadius`, and `ThemeTypography`.
- **Stateless & Focused Widgets**: Keep widgets small and focused on layout. Business logic belongs in ViewModels (`ChangeNotifier`).
- **No Unnecessary Dependencies**: Prefer built-in Flutter primitives and CustomPainters over bulky third-party animation libraries.
- **Null Safety**: All code must strictly conform to sound null safety.
- **Calm Product Tone**: Follow our product principle: the AI companion must remain calm, supportive, and non-judgmental.

---

## Coding Conventions & Style

Follow the official [Effective Dart](https://dart.dev/effective-dart) style guide and Google Flutter style standards:

- Format all code with `dart format .` before committing.
- Run `flutter analyze` — pull requests with analyzer errors or warnings will not be merged.
- Add meaningful docstrings (`///`) to all public classes, methods, and repositories.
- Keep line lengths under 80–100 characters where practical.

---

## Git Workflow

1. Create a feature branch with a descriptive name:
   ```bash
   git checkout -b feat/custom-ambient-sound
   ```
2. Write clean, focused commits following Conventional Commits format:
   - `feat: add forest rain ambient sound option`
   - `fix: resolve countdown timer pause sync bug`
   - `docs: update voice command grammar examples`
3. Push your branch to your fork and open a Pull Request against `main` on [RamanSharma100/ekagra](https://github.com/RamanSharma100/ekagra/pulls).

---

## Pull Request Checklist

Before submitting your PR, ensure:

- [ ] Code compiles without warnings (`flutter analyze`).
- [ ] All existing and new tests pass (`flutter test`).
- [ ] Code is formatted with `dart format .`.
- [ ] No API keys, credentials, or personal information are committed.
- [ ] New UI features match the dark-first design system aesthetic.
- [ ] You have included screenshots or screen recordings for visual changes.

---

## Community & Support

- **Repository**: [https://github.com/RamanSharma100/ekagra](https://github.com/RamanSharma100/ekagra)
- **Discussions**: [GitHub Discussions](https://github.com/RamanSharma100/ekagra/discussions)
- **Issues**: [GitHub Issues](https://github.com/RamanSharma100/ekagra/issues)
- **Maintainer**: Raman Sharma ([@RamanSharma100](https://github.com/RamanSharma100))
