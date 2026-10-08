# Security Policy

The Ekagra project takes user privacy, attention data protection, and application security seriously. Because Ekagra monitors personal focus sessions, application usage, and speech audio locally, we adhere to strict privacy-first and on-device processing guidelines.

---

## Supported Versions

We actively provide security patches and dependency updates for the following releases:

| Version | Supported          | Release Date |
| ------- | ------------------ | ------------ |
| 1.0.x   | :white_check_mark: | 2026-10      |
| < 1.0   | :x:                | N/A          |

---

## Privacy & Data Handling Architecture

Ekagra is designed around zero-unnecessary-cloud principles:

1. **On-Device Storage**: User focus scores, timeline events, routines, and app usage logs are stored locally using sandboxed storage abstractions (SQLite and SharedPreferences).
2. **Speech Recognition**: Voice transcription uses platform speech recognition interfaces and on-device neural speech recognizers whenever available.
3. **No Hidden Telemetry**: Ekagra does not collect keystrokes, passwords, clipboard items, or background screen recordings.
4. **Data Portability**: Users can export their entire database in open JSON format or permanently erase all data at any time via the Profile settings.

---

## Reporting a Vulnerability

If you discover a security vulnerability in Ekagra, please **do not** open a public issue on GitHub. Instead, report it responsibly via:

* **GitHub Security Advisory**: Open a private disclosure at [https://github.com/RamanSharma100/ekagra/security/advisories](https://github.com/RamanSharma100/ekagra/security/advisories)
* **Direct Contact**: Reach maintainer **Raman Sharma** ([@RamanSharma100](https://github.com/RamanSharma100)) via GitHub private messaging.

### Information to Include in Your Report

To help us triage and resolve the issue quickly, please provide:

1. A clear description of the vulnerability.
2. The affected components, services, or versions.
3. Step-by-step reproduction instructions or a minimal Proof of Concept (PoC).
4. Potential impact or threat vectors.
5. Any potential remediations or workarounds you have identified.

### Response Timelines

- **Initial Acknowledgment**: Within 48 hours of receipt.
- **Triage & Assessment**: Within 5 business days.
- **Fix & Public Advisory**: Coordinated disclosure typically within 30 days of confirmation.

We ask that you refrain from disclosing the vulnerability to the public until we have published a patch and advisory.

---

## Security Best Practices for Contributors

When writing code for Ekagra:

- **Never hardcode secrets or API keys**: Use environment configurations or runtime injection.
- **Enforce input sanitization**: Validate all voice transcript strings and form fields.
- **Respect platform permissions**: Request microphone or notification permissions only on-demand with clear user explanations.
- **Zero dynamic code execution**: Never use `eval` or execute arbitrary strings as code.
- **Run security audits**: Regularly run `flutter pub outdated` and `flutter analyze` to ensure dependencies have no known CVEs.
