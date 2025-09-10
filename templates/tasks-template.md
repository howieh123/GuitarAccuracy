# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **macOS app**: `.xcodeproj/`, `Sources/`, `Tests/`, `Packages/`
- **Targets**: App target, framework targets, test targets
- **Schemes**: Debug/Release; ensure scheme is shared for CI
- Adjust paths and target names based on plan.md structure

## Phase 3.1: Setup
- [ ] T001 Create/verify Xcode project structure and shared scheme in `macos/[AppName].xcodeproj`
- [ ] T002 Configure `.xcconfig` for Debug/Release and set minimum macOS version
- [ ] T003 [P] Add SwiftPM dependencies in `Packages/` and resolve versions
- [ ] T004 [P] Configure SwiftFormat/SwiftLint and add CI step

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T005 [P] Unit tests for ViewModels in `Tests/Unit/<Feature>ViewModelTests.swift`
- [ ] T006 [P] Unit tests for Services in `Tests/Unit/<Service>Tests.swift`
- [ ] T007 Integration tests for persistence/networking in `Tests/Integration/<Feature>IntegrationTests.swift`
- [ ] T008 UI tests for primary flows in `Tests/UITests/<Feature>UITests.swift`

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T009 [P] Implement `<Feature>ViewModel.swift` in `Sources/Features/<Feature>/`
- [ ] T010 [P] Implement services in `Sources/Services/<Service>.swift`
- [ ] T011 Implement SwiftUI/AppKit views in `Sources/UI/<Feature>View.swift`
- [ ] T012 Wire navigation via Coordinator in `Sources/App/Coordinator.swift`
- [ ] T013 Implement input validation and user feedback
- [ ] T014 Add unified logging via `os.Logger` (remove print statements)

## Phase 3.4: Integration
- [ ] T015 Configure persistence (Codable files/Core Data) with migrations if applicable
- [ ] T016 Secure secrets with Keychain access group
- [ ] T017 Configure entitlements and App Sandbox; document justification
- [ ] T018 Implement background tasks and ensure no main-thread blocking

## Phase 3.5: Polish
- [ ] T019 [P] Add missing unit tests; raise coverage to target
- [ ] T020 Profile with Instruments (Time Profiler, Allocations, Leaks); fix hotspots
- [ ] T021 [P] Update user docs and `README` build/run instructions
- [ ] T022 Remove duplication and tighten access control (internal/public)
- [ ] T023 Verify accessibility labels, shortcuts, and localization

## Dependencies
- Tests (T005-T008) before implementation (T009-T014)
- T009 blocks T010, T015
- T016 blocks T017
- Implementation before polish (T019-T023)

## Parallel Example
```
# Launch T005-T008 together:
Task: "Unit tests for ViewModels in Tests/Unit/<Feature>ViewModelTests.swift"
Task: "Unit tests for Services in Tests/Unit/<Service>Tests.swift"
Task: "Integration tests for persistence in Tests/Integration/<Feature>IntegrationTests.swift"
Task: "UI tests for primary flows in Tests/UITests/<Feature>UITests.swift"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → Tests → Models → Services → Endpoints → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] Tests precede implementation; failing states recorded
- [ ] Each task specifies exact file path and target/scheme if relevant
- [ ] Parallel tasks truly independent (different files/modules)
- [ ] Build/test commands defined for CI (`xcodebuild build/test`)
- [ ] Accessibility and privacy-related tasks included where UI/data present