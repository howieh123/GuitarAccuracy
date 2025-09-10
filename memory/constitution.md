# GuitarAccuracy macOS Application Development Constitution

## Core Principles

### I. Native-First Technology Choices
- **Language**: Swift (5.9+) is mandatory for app code; Objective-C permitted only for legacy interop.
- **UI Toolkit**: Prefer SwiftUI for new UI; bridge to AppKit using `NSViewRepresentable`/`NSViewControllerRepresentable` when needed for mature controls.
- **Minimum macOS**: Target a supported LTS-like macOS, and document the minimum deployment target. Avoid private APIs.

### II. Sound Architecture and State Management
- **Pattern**: MVVM with a Coordinator/Router for navigation and composition. Avoid Massive View Controllers.
- **Separation**: Views are declarative and side-effect free; business logic resides in testable services and view models.
- **Data Flow**: Prefer value types and unidirectional data flow. Use Swift Concurrency or Combine for reactive pipelines, not ad-hoc callbacks.

### III. Build Reliability in Xcode
- **Schemes & Configurations**: Maintain `Debug` and `Release` schemes with `.xcconfig` files committed to source control.
- **Determinism**: Builds must succeed via GUI and CLI: `xcodebuild -scheme <Scheme> -configuration <Config> -destination 'platform=macOS' build`.
- **Signing**: Use automatic signing for dev, explicit signing identities/profiles for release. Keep bundle identifiers stable per target.

### IV. Testing Strategy (Non-Negotiable)
- **Frameworks**: XCTest for unit/integration tests; XCUITest for UI flows.
- **Coverage**: Minimum 80% line coverage on critical modules; measure in CI. Tests must run headless via `xcodebuild test`.
- **Pyramids**: Favor fast unit tests; add integration tests around persistence/networking; add high-value UI tests for primary flows.

### V. Concurrency and Performance
- **Concurrency**: Use Swift Concurrency (`async/await`, `Task`, `TaskGroup`, `@MainActor`) for clarity and safety. Never block the main thread.
- **Profiling**: Use Instruments regularly (Time Profiler, Allocations, Leaks). Ship no known retain cycles or main-thread stalls >16ms for interactive UI.
- **Background Work**: Offload heavy CPU/IO to background tasks; debounce/throttle UI updates.

### VI. Persistence and Data Modeling
- **Simple Data**: Use `Codable` + `FileManager`/`URL` for small documents and preferences beyond `UserDefaults`.
- **Complex Data**: Prefer Core Data with `NSPersistentContainer`; define lightweight migrations and data model versioning policy.
- **Storage Security**: Use Keychain for secrets/tokens. Never store credentials in plaintext.

### VII. Privacy, Security, and Entitlements
- **Sandbox**: Enable App Sandbox with least-privilege entitlements only. Document each entitlement justification.
- **Hardened Runtime & Notarization**: Required for distribution. Automate notarization as part of release.
- **Privacy Strings**: Provide accurate Info.plist usage descriptions (e.g., `NSCameraUsageDescription`) for all sensitive capabilities.

### VIII. UX Quality and Accessibility
- **HIG Compliance**: Follow macOS Human Interface Guidelines. Provide standard menus, toolbar semantics, preferences window, and keyboard shortcuts.
- **Accessibility**: Add meaningful accessibility labels, roles, and actions; verify with VoiceOver. Maintain sufficient contrast and resize-friendly layouts.
- **Localization**: All user-visible strings are localizable; use `String(localized:)` and maintain a baseline `Base.lproj`.

### IX. Logging, Telemetry, and Crash Handling
- **Unified Logging**: Use `os.Logger` with appropriate subsystems/categories. No `print` in production.
- **Metrics**: Record key performance and usage metrics respectfully and with user consent.
- **Crashes**: Integrate a crash reporter (e.g., CrashReporter or third-party) with symbolication and privacy safeguards.

### X. Modularity and Reuse
- **Targets/Packages**: Extract reusable logic into Swift packages or framework targets. Keep feature modules independently testable.
- **APIs**: Design small, composable APIs; document with DocC. Avoid tight coupling to UI layers.

### XI. Configuration, Feature Flags, and Environments
- **Config**: Centralize build settings with `.xcconfig`. Keep secrets out of the repo.
- **Flags**: Use compile-time flags for risky code paths and runtime flags via `UserDefaults` for A/B or staged rollouts.

### XII. Error Handling and User Communication
- **Policy**: Fail fast in development; in production, surface actionable, friendly errors to users and log details securely.
- **Types**: Use domain-specific `Error` types; avoid swallowing errors.

### XIII. Documentation and Developer Experience
- **Docs**: Maintain `README` with Xcode/CLI build instructions, minimum macOS, signing, and test commands. Use DocC for public APIs.
- **ADR**: Capture significant decisions as Architecture Decision Records.
- **Tools**: Enforce formatting/linting via SwiftFormat/SwiftLint in CI.

## Additional Standards

### Build, Test, and Release Lifecycle
- **CI**: Required jobs execute `xcodebuild build`, `xcodebuild test`, and produce coverage. Artifact notarization occurs on release candidates.
- **Versioning**: Semantic Versioning for marketing version; increment `CFBundleVersion` each build. Automate version bumps.
- **Distribution**: Support TestFlight for beta; App Store or notarized direct distribution for release.

### Performance and Resource Use
- **Startup**: Cold start to interactive in ≤2s on reference hardware.
- **Memory**: No unbounded caches; measure peak memory in Instruments. No leaks in leak checks.

### App Lifecycle and Document Model
- **Lifecycle**: Respect app activation/background semantics; save state responsibly.
- **Documents**: For document-based apps, use `NSDocument`/`UIDocument` equivalents on macOS, adopt autosave-in-place.

## Development Workflow and Quality Gates
- **Branching**: Feature branches with PRs. Require green CI, code review, and HIG/a11y checks.
- **Reviews**: Reviewers verify architecture boundaries, test sufficiency, accessibility, and logging.
- **Checklists**: PR template includes sandbox/entitlements review, privacy strings, and localization updates.

## Governance
- **Supremacy**: This constitution supersedes ad-hoc practices. Deviations require written ADRs and time-bounded exceptions.
- **Amendments**: Changes require version bump, update of templates and checklists, and migration plans where applicable.
- **Compliance**: All PRs must attest compliance with Core Principles and pass CI gates.

**Version**: 3.0.0 | **Ratified**: 2025-09-08 | **Last Amended**: 2025-09-08