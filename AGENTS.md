# Working on Fluidtime

Fluidtime is a native SwiftUI client for Solidtime. Target macOS 14 or later, Xcode 27 or later, and Swift 6.4. The bundle identifier is `cz.matee.fluidtime`. The main window opens on launch and the window-style `MenuBarExtra` is always available, with separate native Settings and entry editor windows. Do not restore a selector for choosing between them. Show the Dock icon while any app window is open and return to accessory mode when the last window closes, including after reopening the same window.

## Current verification restrictions

- Tests are paused until the user explicitly authorizes running them. Do not execute unit tests, UI tests, preview capture tests, or manual app checks while that restriction remains active. Compiling the app and test sources, formatting, and linting are allowed.
- Use `solidtime-api.json` as the official API contract. `.env.local` may be used only for read-only verification. Never perform live API writes during testing, embed its values in the app, or print its credentials.
- Do not alter real time entries, login-item registration, or user keyboard shortcuts as part of verification without explicit authorization. Test write behavior with injected mocks or the in-memory `URLProtocol` transport.
- Preview rendering must stay offscreen and must not activate the app, change focus, or open windows on the user's display. Both preview helpers default to bitmap rendering in hidden hosts. Use `FLUIDTIME_VISIBLE_PREVIEWS=1` only when the user explicitly requests visible desktop checks; ordinary preview authorization does not permit it.
- Preserve existing tracked and untracked changes, including Xcode user data. Avoid modifying generated build artifacts or dependency checkouts.
- The initial release is v1.0.0 and is currently unreleased. Local commits are allowed; do not push, publish releases, upload update feeds, or replace the installed app without new authorization.

## Code organization

```text
Fluidtime/
  App/              SwiftUI scenes, application delegate, and native lifecycle wiring
  Features/         TCA reducers and native views, grouped by feature
  Domain/           Models, validation, preferences, and time calculations
  Clients/          TCA dependency contracts and test defaults
  Infrastructure/   HTTP, Keychain, UserDefaults, and macOS live implementations
  Services/         Session synchronization using client contracts
  Shared/           Errors and reusable native views
  Resources/        Localizable.xcstrings and asset catalog
Tests/              Feature, domain, infrastructure, service, and UI tests
```

- Use only native macOS views. Keep related code together and extract focused helpers instead of collecting unrelated responsibilities into a large file.
- Use The Composable Architecture and its dependency system for state, effects, composition, and injection. Do not add Factory or another DI framework. TCA is pinned to 1.26.2 in both SwiftPM and Xcode; keep the manifests and lockfiles consistent when changing dependencies.
- Keep dependency contracts in `Clients`, with unimplemented `TestDependencyKey.testValue` defaults. Put `DependencyKey.liveValue` implementations in `Infrastructure`. Missing test overrides must fail rather than call real services.
- Construct the root store in `FluidtimeAppDelegate`. Use `@Dependency` in reducers, including clocks, dates, and UUIDs. Override endpoints with `TestStore` or store dependency overrides.
- Use `@ViewAction` for feature views. Send `.view` actions for view interactions and `.interface` actions for native lifecycle callbacks. Keep HTTP, persistence, and system registration calls in injected clients.
- `AppFeature` owns the shared account, synchronization, menu bar presentation, and timer state. Keep its state, actions, destinations, and operation helpers in the existing separate files under `Features/App`.
- Compose `EntryEditorFeature` through the existing `@Presents` destination. Compose `GeneralSettingsFeature` for login-item state and changes. Avoid duplicating shared preferences in multiple stores or adding shared-state wrappers for views of the same root store.
- `WorkspaceFeature` owns filters and analysis options. `EarningsFeature` owns the single private preview rate, Touch ID access, and Keychain operations; scope the same feature into Settings and the preview. Pass shared session data from `AppFeature`; do not create a second account or timer store. Keep interval calculations, lunch estimates, and CSV construction in focused domain types.
- Keep Sparkle pinned to 2.10.0 in SwiftPM and Xcode. `UpdatesClient` is the injected boundary; Sparkle performs update checks and installation. Do not add a hand-written GitHub version checker.

## Behavior to preserve

### Menu bar and settings

- Use a root `NavigationSplitView` for the main window, with a native sidebar `List` and value-based navigation links. Keep sidebar selection and visibility in `WorkspaceFeature`. Place timer controls and status banners inside the detail pane; do not put a navigation container below a separate window-wide header. Use native navigation titles and toolbar actions.
- Settings tabs are ordered General, Tracking, Workspace, Earnings, Menu bar, and Account. Keep organization selection in Tracking settings. Opening Settings from the panel must close the panel.
- Support running-timer duration, today's total, this week's total, an active indicator, and clock-only menu bar modes. Honor the Show seconds preference for every duration mode.
- Advance displayed durations and totals every second. Use the existing timer publisher in `MenuBarLabelView`; a `TimelineView` there previously caused repeated menu bar host invalidation and a launch hang.
- Keep the active clock and dot in one composite `NSImage`. Additional images in a menu bar label may be dropped by macOS.
- Display the active dot in every menu bar mode, including clock-only, today's total, and this week's total.
- The global shortcut toggles the menu open and closed. Its default is **Control–Option–Shift–Command–F** (`⌃⌥⇧⌘F`). KeyboardShortcuts 3.1.0 stores the assignment, and MenuBarExtraAccess 1.3.1 synchronizes native presentation with TCA state.
- Preserve customized or cleared shortcuts. Keep the persisted shortcut name `openFluidtime` stable. Changing the initial shortcut affects new installations and Restore default; existing installations select the new default with Settings > Menu bar > Restore default.
- The timer shortcut (`toggleFluidtimeTimer`, default `⌃⌥⇧⌘T`) stops the current server timer or starts a new entry from the latest completed entry. Open the main window if account configuration or synchronization is needed. The open shortcut always toggles the menu.
- Show timer confirmations in a nonactivating native panel, not Notification Center. Idle and long timer reminders are optional, disabled by default, and never modify entries automatically.
- Keep native recorder validation. Block known macOS shortcut conflicts. No chosen combination can be guaranteed unused by every other application or user customization; do not claim universal conflict freedom.
- General settings offers Launch at login through `LoginItemClient` and `SMAppService.mainApp`. Read registration from macOS rather than copying it into UserDefaults. Show approval guidance and a Login Items settings button when required, and refresh status when the app becomes active again.

### Time entries

- Show only the five most recent distinct completed entries. Each recent row has only a start button; do not restore its editing or options menu.
- Starting a recent entry stops the current server-side timer first, then creates a new entry in the selected organization. Copy its description and available project, use the project's current billability default, and do not copy its task or tags.
- A running timer in another organization can be stopped using that organization's member ID. Keep controls busy throughout the stop-and-create sequence. If stopping fails, do not create a new entry. If creation fails after a confirmed stop, retain the stopped state.
- Editing a running entry remains available. Changing its project clears the task and adopts the new project's default billability; preserve other metadata.
- Present entry editing in its own native window scoped to the existing destination. Do not attach its sheet to the transient menu bar host. Keep the editor open while saving and pause synchronization for the whole editing session.
- Tracking settings controls visible projects for start/edit pickers only. All available projects are visible by default, and hidden IDs are persisted per instance, user, and organization. Keep full project data for history filters, analytics, labels, recent/pinned starts, validation, and saving an entry's existing project. Never clear an existing assignment because its project is hidden.
- Every time entry represents tracked work. Do not add a break-entry model, type filter, special editing rules, or recorded-break CSV columns. Keep the fixed `type: "work"` value at the creation transport boundary only for API compatibility. Lunch is a statistic inferred from gaps between entries, never an entry or timer mode.
- Pinned tasks are scoped to the instance, user, and organization. History uses a continuously scrolling native `List` of all matching entries, with date/description/project/billability filters and editing. The shared session already loads the full history for analysis; do not add presentation page state, previous/next buttons, or a separate history fetch lifecycle. Preserve five start-only rows in the menu's recent list.
- Read the current active timer before writes. Check cancellation after network suspensions and before subsequent writes. Do not automatically retry failed writes.
- Show progress only after two seconds; preserve existing data during refresh and surface errors promptly.

### Accounts, security, and synchronization

- Allow a custom instance address and API key. Store the instance and organization selection in UserDefaults and credentials in Keychain. The app must never load `.env.local`.
- Require HTTPS for remote instances; allow HTTP only for loopback development. Use ephemeral URL sessions and never follow redirects with the API key.
- Use organization member IDs, not user IDs, in time-entry requests. Keep pagination and account/organization scoping consistent with the local API contract.
- Calculate work totals in the Solidtime user's time zone and configured week. Sum tracked intervals, clip entries to day/week boundaries, exclude gaps between entries, and include the running entry exactly once.
- Preserve the existing synchronization strategy: current-week and active-timer polling every 30 seconds, full reads at startup, every five minutes, on manual refresh, at week rollover, and when the active timer changes.
- Pause refresh while an editor or disconnect confirmation is open. Stage snapshot reads before applying them, preserve the prior session on connection failure, and reject late responses using lifecycle and operation identifiers.
- Keep background effects alive while the panel is closed, cancel them on shutdown, and refresh after waking. Disconnecting removes credentials but does not stop a server-side timer.

### Analytics and private earnings

- Calculate work using merged tracked intervals. Never subtract the inferred lunch gap from tracked work. Never count overlapping work or a running entry twice. Split at day boundaries in the account time zone, including daylight saving changes.
- Time at work is the daily span from the first work start to the last work end, or now for running work. It includes lunch and other gaps. Do not present that span as paid work.
- Estimate lunch as the full longest gap between merged work entries whose midpoint lies in the configured local lunch window, initially 11:00–15:00. Include the start boundary and exclude the end boundary. Use the account time zone, choose the first gap on equal duration, and count only fully bounded same-day gaps. Other gaps stay separate. Changing the window must never change work totals or earnings.
- Daily averages use the selected basis: days with entries, weekdays, or all calendar days. Weekly/monthly averages include touched calendar periods, including partial periods. Explain the basis in the UI.
- Store one fixed hourly rate and currency in Keychain, scoped to instance/user/organization, and edit it only in Earnings settings. There is no date-effective rate history. Never store the rate in UserDefaults.
- Require fresh Touch ID verification through injected `BiometricsClient` before reading or displaying the rate or preview. Use biometric-only LocalAuthentication policy with no password/Apple Watch fallback or reuse period. Clear private state on conceal, view/window closure, session lock, sleep, and account changes. Cancel pending authentication and reject late responses. Do not prompt for actual Touch ID during automated or manual verification while tests are paused.
- The preview applies the single current rate to all tracked work in the selected period, with no payroll or historical-rate semantics. Gaps including lunch are already absent from work: never deduct inferred lunch again. Non-billable client work is included by default; client billability is not employee pay eligibility.
- CSV exports contain entries or daily time summaries, never hourly rates or earnings. Escape spreadsheet formulas as well as CSV quotes/newlines. Daily dates use the account calendar; entry timestamps identify UTC explicitly.

### Automatic updates

- Sparkle reads the feed URL and public Ed25519 key from `Configuration/Info.plist`. Never put GitHub credentials or private update signing keys in the app or repository.
- The update signing key is in the release Mac's Keychain. `scripts/create-update-feed.sh` uses the official Sparkle tools, verifies the public key, and generates a signed feed locally; it does not upload it.
- The repository is currently private. The configured unauthenticated GitHub release feed will not work for users until accessible feed/archive hosting is arranged. Do not change repository visibility or publish assets as a workaround without authorization.
- Increase the build number for every update. Use Developer ID signing and notarization for distribution; Sparkle archive signatures do not replace those requirements.

## Localization and writing

- Keep all app-authored visible strings in `Fluidtime/Resources/Localizable.xcstrings`, including errors, help, accessibility labels, and parameterized messages.
- Use Xcode-generated `LocalizedStringResource` symbols directly in SwiftUI and `TextState`. Use `String(localized:)` where an API requires a `String`. Do not restore an `L10n` wrapper or hand-maintained symbol definitions.
- Let generated resources select the app or SwiftPM resource bundle. Preserve user-provided descriptions, project names, and account names verbatim.
- Follow Material 3 writing guidance: clear consequences, concise wording, sentence case, and useful translator comments. Weekday names come from localized calendar symbols; time boundaries come from Solidtime account preferences.

## Formatting and refactoring

- Run SwiftFormat and SwiftLint on owned project sources. Use their default rule sets with no disabled rules, inline suppressions, per-file exceptions, or increased limits.
- Fix violations by improving code structure. Do not change wrapping options to conceal type or function length problems. `.swiftformat` contains only the Swift version, indentation, line width, and trailing-comma style needed to agree with default SwiftLint.
- Keep generated localization source and dependency code outside formatting scope.

```sh
swiftformat Fluidtime Tests Package.swift
swiftformat Fluidtime Tests Package.swift --lint --cache ignore
swiftlint lint --no-cache
git diff --check
```

## Compilation and tests

Open `Fluidtime.xcodeproj`, choose the Fluidtime scheme and My Mac to build the application. The Swift package contains the reducers, clients, models, native views, resources, and isolated tests; it does not launch the app. Keep build products and scratch directories outside the repository and reuse existing caches when practical.

These commands compile without executing tests:

```sh
xcodebuild -project Fluidtime.xcodeproj -scheme Fluidtime \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath /tmp/fluidtime-build CODE_SIGNING_ALLOWED=NO build
swift build --target FluidtimeCoreTests --scratch-path /tmp/fluidtime-tests
```

An unsigned build is for compilation checks. Use a correctly signed application bundle for installation and native Service Management behavior.

Only after the user explicitly authorizes test execution:

```sh
swift test --scratch-path /tmp/fluidtime-tests
```

Keep reducer tests exhaustive. Inject mock clients for mutations and use the in-memory `URLProtocol` for HTTP tests. Tests must never read `.env.local` or contact a real Solidtime instance.

The optional native preview test uses fictional state, renders offscreen, and writes captures to `/private/tmp/fluidtime-tca-*.png`. It is also paused under the current testing restriction. Once authorized:

```sh
FLUIDTIME_CAPTURE_PREVIEWS=1 swift test --scratch-path /tmp/fluidtime-tests \
  --filter 'capture native views'
```

Report compilation, formatting, test execution, and live UI verification separately. A successful build does not verify menu bar interaction, shortcut delivery, login behavior, or live API writes.

After test execution is authorized, verify the gap-based lunch/attendance and fixed-rate preview calculations, continuous history scrolling/filtering/CSV privacy, account-switch privacy, global timer shortcut, confirmations/reminders, standalone running-entry editor, main/menu availability and Dock transitions, Touch ID denial/cancellation/late-response privacy, and Sparkle settings. Native checks must use fictional data or injected clients and must not change real entries, shortcut assignments, or login-item registration.
