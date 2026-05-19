# AppSubsystem

A foundational framework for building iOS apps with structured state management, dependency injection, and reactive observation.

AppSubsystem provides the core architecture that apps build on. It manages the build lifecycle, theming, logging, localization, and developer tools so that app code can focus on features rather than infrastructure.

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Bootstrap Script](#bootstrap-script)
  - [Manual Setup](#manual-setup)
- [Module Reference](#module-reference)
- [Architecture](#architecture)
  - [Reducers and View Models](#reducers-and-view-models)
  - [Effects](#effects)
  - [Dependency Injection](#dependency-injection)
  - [Reactive Observation](#reactive-observation)
  - [Theming](#theming)
  - [Localization](#localization)
  - [Navigation](#navigation)
  - [Persistence](#persistence)
  - [Developer Tools](#developer-tools)
- [Delegate Customization](#delegate-customization)
- [Conventions](#conventions)
- [Dependencies](#dependencies)

---

## Overview

AppSubsystem is organized around several key concepts:

- **Reducers and view models.** Each screen defines a [`Reducer`](Sources/Modules/Reducer/Protocols/Reducer.swift) that describes how state changes in response to actions. A [`ViewModel`](Sources/Modules/Reducer/Models/ViewModel.swift) connects that reducer to SwiftUI, publishing state and accepting actions through bindings. Data flows in one direction: from actions, through the reducer, into state, and out to the view.

- **Dependency injection.** Services and configuration are provided through the [`@Dependency`](Sources/Modules/Dependency%20Injection/Models/Dependency.swift) property wrapper rather than singletons or initializer parameters. Dependencies are resolved at the call site and can be overridden for testing or previews.

- **Reactive observation.** Shared values that cross feature boundaries are expressed as [`Observable`](Sources/Modules/Observable/Models/Observable.swift) instances. Views subscribe through the [`Observer`](Sources/Modules/Observable/Protocols/ObserverProtocol.swift) protocol, which dispatches changes to the appropriate reducer on the main actor.

- **Theming.** Appearance is driven by a [`UITheme`](Sources/Modules/Theming/Models/UITheme.swift) value that can be swapped at runtime. Views that adopt the theming system update automatically when the active theme changes.

- **Localization.** Multi-language support is built in through property-list-based string tables and an integrated translation pipeline powered by [Translator](https://github.com/grantbrooksgoodman/translator).

- **Navigation.** A coordinator-based navigation system manages stack, sheet, and modal presentation through a single published state value. SwiftUI views bind directly to the coordinator and respond to navigation changes automatically.

- **Developer tools.** Pre-release builds include a build expiry timebomb, a build-info overlay, breadcrumb capture, logging, and a Developer Mode action menu – all of which are disabled or hidden in general-release builds automatically.

---

## Requirements

| Platform | Minimum Version |
| --- | --- |
| iOS | 17.0 |

---

## Installation

### Bootstrap Script

A setup script creates the required files in an existing Xcode project:

```bash
./bootstrap.sh --target /path/to/MyApp.xcodeproj
```

| Flag | Purpose |
|---|---|
| `--target` | Path to the `.xcodeproj` bundle. When omitted, the script searches the current working directory for a `.xcodeproj` and infers the target name from its filename. |

The script creates `AppDelegate.swift`, `ContentView.swift`, `SceneDelegate.swift`, `Info.plist`, and `LocalizedStrings.plist`. It also removes any existing `@main` entry point, adds the AppSubsystem package dependency, configures build settings (`ENABLE_USER_SCRIPT_SANDBOXING`, `GENERATE_INFOPLIST_FILE`, `INFOPLIST_FILE`), adds the Run Script build phase, removes `Info.plist` from Copy Bundle Resources, and sets `OS_ACTIVITY_MODE = disable` in the scheme's environment variables automatically.

See [`bootstrap.sh`](Resources/bootstrap.sh) for details. To set things up manually instead, follow the steps below.

### Manual Setup

#### 0. Add the AppSubsystem Package Dependency

AppSubsystem is distributed as a Swift package. Add it to your project using [Swift Package Manager](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/).

#### 1. Remove the Existing `@main` Entry Point

If the project was created from Xcode's default SwiftUI template, it contains a file (typically `MyApp.swift` or `<ProjectName>App.swift`) annotated with `@main`. AppSubsystem uses a UIKit-based `AppDelegate` as the entry point instead, so the existing `@main` struct must be removed – only one `@main` type can exist per target.

Delete the file entirely, or remove the `@main` attribute and the `App` conformance to retain other code in the same file.

#### 2. Create `AppDelegate.swift`

Call `AppSubsystem.initialize()` as early as possible, ideally in `application(_:didFinishLaunchingWithOptions:)`:

```swift
import AppSubsystem
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AppSubsystem.initialize(
            appStoreBuildNumber: 0,
            buildMilestone: .preAlpha,
            codeName: "Alpine",
            finalName: "My App",
            languageCode: Locale.systemLanguageCode,
            loggingEnabled: true
        )

        return true
    }
}
```

#### 3. Create `SceneDelegate.swift`

Use `RootWindowScene.instantiate(_:rootView:)` to create the window. Pass the root SwiftUI view and forward trait collection changes to the subsystem:

```swift
import AppSubsystem
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        window = RootWindowScene.instantiate(
            scene,
            rootView: ContentView() // Replace with your root view.
        )
    }
    
    func windowScene(
        _ windowScene: UIWindowScene,
        didUpdate previousCoordinateSpace: UICoordinateSpace,
        interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
        traitCollection previousTraitCollection: UITraitCollection
    ) {
        RootWindowScene.traitCollectionChanged()
    }
}
```

#### 4. Create `Info.plist`

The `Info.plist` must include all the keys shown below. Scene configuration values can be customized as long as they match the delegate class names:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBuildDate</key>
    <string>1183100400</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.0.0</string>
    <key>CFBundleVersion</key>
    <string>0</string>
    <key>CFFirstCompileDate</key>
    <string>1183100400</string>
    <key>CFTargetName</key>
    <string>$(TARGET_NAME)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Photo library access is requested to save images for Breadcrumbs capture.</string>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array>
                <dict>
                    <key>UISceneConfigurationName</key>
                    <string>Default Configuration</string>
                    <key>UISceneDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                </dict>
            </array>
        </dict>
    </dict>
    <key>UIDesignRequiresCompatibility</key>
    <false/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
    </array>
</dict>
</plist>
```

> `CFBuildDate` and `CFFirstCompileDate` use a placeholder value (`1183100400`) that is replaced on first build by the run-script phase below.

> **Important:** Verify that `Info.plist` does **not** appear in the target's **Copy Bundle Resources** build phase. Xcode sometimes adds it automatically. If it does appear there, remove it – the property list is read by the build system directly and should not be copied into the app bundle as a resource. The bootstrap script handles this removal automatically.

#### 5. Add a Run Script Build Phase

In the target's **Build Phases**, add a **Run Script** phase. Uncheck *Based on dependency analysis*:

```bash
#!/bin/bash

set -e
PLIST="$INFOPLIST_FILE"

# Increment build number
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST")
BUILD_NUMBER=$((BUILD_NUMBER + 1))

# Current build timestamp
BUILD_DATE=$(date +%s)

# Update CFBuildDate and CFBundleVersion
/usr/libexec/PlistBuddy -c "Set :CFBuildDate $BUILD_DATE" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$PLIST"

# Conditionally set CFFirstCompileDate
PLACEHOLDER_FIRST_COMPILE_DATE="1183100400"
CURRENT_FIRST_COMPILE_DATE=$(/usr/libexec/PlistBuddy -c "Print :CFFirstCompileDate" "$PLIST" 2>/dev/null || echo "")

if [[ "$CURRENT_FIRST_COMPILE_DATE" == "$PLACEHOLDER_FIRST_COMPILE_DATE" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFFirstCompileDate $BUILD_DATE" "$PLIST"
fi
```

This script automatically increments the build number and records the build date during each build. On the first build, it also records the initial compile date.

#### 6. Adjust Build Settings

Set the following in the target's **Build Settings**:

| Setting | Value | Purpose |
|---|---|---|
| `ENABLE_USER_SCRIPT_SANDBOXING` | `NO` | Allows the run-script phase to modify the property list. |
| `GENERATE_INFOPLIST_FILE` | `NO` | Tells Xcode to use the custom `Info.plist` rather than generating one. |
| `INFOPLIST_FILE` | `$(TARGET_NAME)/Info.plist` | Specifies the property list path for the build system – adjust the value if `Info.plist` is in a different location. |

#### 7. (Optional) Suppress System Log Output

Open the scheme editor (**Product → Scheme → Edit Scheme…**), select the **Run** action, and navigate to the **Arguments** tab. Under **Environment Variables**, add:

| Variable | Value |
|---|---|
| `OS_ACTIVITY_MODE` | `disable` |

This suppresses the default system logging that appears in the Xcode console at launch, keeping the console output focused on app-level messages from the AppSubsystem logger.

#### 8. Run

Build and run. After completing these steps, AppSubsystem is fully active – theming, logging, localization, developer tools, and all supporting infrastructure.

---

## Module Reference

AppSubsystem is composed of nine internal modules, each with a focused responsibility:

| Module | Purpose |
|---|---|
| **Foundation** | Core infrastructure: build lifecycle ([`Build`](Sources/Modules/Foundation/Services/Public/Build.swift)), logging ([`Logger`](Sources/Modules/Foundation/Services/Public/Logger.swift)), caching (`CacheService`, [`CacheDomain`](Sources/Modules/Foundation/Models/Public/Key%20Domains/CacheDomain.swift)), persistence ([`@Persistent`](Sources/Modules/Foundation/Models/Public/Persistent.swift), [`PersistentStorageKey`](Sources/Modules/Foundation/Models/Public/Key%20Domains/PersistentStorageKey.swift)), various property wrappers, [`AppConstants`](Sources/Modules/Foundation/Constants/AppConstants.swift), [`CoreKit`](Sources/Modules/Foundation/Services/Public/CoreKit/CoreKit.swift), UI components, view modifiers, and extensions. |
| **Reducer** | The [`Reducer`](Sources/Modules/Reducer/Protocols/Reducer.swift) protocol, [`ViewModel`](Sources/Modules/Reducer/Models/ViewModel.swift), [`Reduce`](Sources/Modules/Reducer/Models/Reduce.swift), and [`ReducerBuilder`](Sources/Modules/Reducer/Models/ReducerBuilder.swift) for unidirectional state management. |
| **Effect** | The [`Effect`](Sources/Modules/Effect/Public/Effect.swift) type and [`Send`](Sources/Modules/Effect/Public/Send.swift) callback for describing asynchronous work, including cancellation and merge support. |
| **Dependency Injection** | The [`@Dependency`](Sources/Modules/Dependency%20Injection/Models/Dependency.swift) and [`@ObservedDependency`](Sources/Modules/Dependency%20Injection/Models/ObservedDependency.swift) property wrappers, [`DependencyKey`](Sources/Modules/Dependency%20Injection/Protocols/DependencyKey.swift) protocol, [`DependencyValues`](Sources/Modules/Dependency%20Injection/Services/DependencyValues.swift) container, and scope propagation. |
| **Observable** | The [`Observable`](Sources/Modules/Observable/Models/Observable.swift) value type, [`Observer`](Sources/Modules/Observable/Protocols/ObserverProtocol.swift) protocol, [`ViewObserver`](Sources/Modules/Observable/Models/ViewObserver.swift) lifecycle wrapper, and the [`Observers`](Sources/Modules/Observable/Services/Observers.swift) registry for reactive cross-feature communication. |
| **Theming** | [`UITheme`](Sources/Modules/Theming/Models/UITheme.swift) definitions, [`ThemeService`](Sources/Modules/Theming/Services/ThemeService.swift), [`ThemedView`](Sources/Modules/Theming/Views/Public/ThemedView.swift), and convenience color extensions for runtime appearance swapping. |
| **Localization** | Source-based string resolution through [`LocalizationSource`](Sources/Modules/Localization/Models/Public/LocalizationSource.swift), the [`@Localized`](Sources/Modules/Localization/Models/Public/Localized.swift) property wrapper, the [`LocalizedStringKeyRepresentable`](Sources/Modules/Localization/Protocols/LocalizedStringKeyRepresentable.swift) protocol, and the [`Localization`](Sources/Modules/Localization/Services/Public/Localization.swift) property list generation service. |
| **Navigation** | The [`Navigating`](Sources/Modules/Navigation/Protocols/NavigatingProtocol.swift) and [`NavigatorState`](Sources/Modules/Navigation/Protocols/NavigatorStateProtocol.swift) protocols, [`NavigationCoordinator`](Sources/Modules/Navigation/Services/NavigationCoordinator.swift), and the [`@Navigator`](Sources/Modules/Navigation/Models/Navigator.swift) / [`@ObservedNavigator`](Sources/Modules/Navigation/Models/ObservedNavigator.swift) property wrappers for coordinated presentation. |
| **Developer Mode** | [`DevModeService`](Sources/Modules/Developer%20Mode/Services/DevModeService.swift), [`DevModeAction`](Sources/Modules/Developer%20Mode/Models/Public/DevModeAction.swift), and the [`DevModeAppActionDelegate`](Sources/Modules/Developer%20Mode/Protocols/DevModeAppActionDelegate.swift) for pre-release debugging tools. |

All modules are compiled into a single `AppSubsystem` library. There are no separate import targets.

---

## Architecture

### Reducers and View Models

State management follows a unidirectional data flow. Each feature defines a type that conforms to the [`Reducer`](Sources/Modules/Reducer/Protocols/Reducer.swift) protocol. A reducer declares a `State` type, an `Action` type, and a `reduce(into:action:)` method that applies actions to state and returns an [`Effect`](Sources/Modules/Effect/Public/Effect.swift) describing any asynchronous follow-up work.

```swift
struct CounterReducer: Reducer {
    enum Action {
        case increment
        case decrement
    }

    struct State: Equatable {
        var count = 0
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .increment: state.count += 1
        case .decrement: state.count -= 1
        }

        return .none
    }
}
```

A [`ViewModel`](Sources/Modules/Reducer/Models/ViewModel.swift) pairs a reducer with its initial state and exposes that state to SwiftUI as a published property. The class adopts `@dynamicMemberLookup`, so state properties are accessible directly on the view model instance. Call `send(_:)` to dispatch an action:

```swift
struct CounterView: View {
    @StateObject var viewModel = ViewModel<CounterReducer>(
        initialState: .init(),
        reducer: CounterReducer()
    )

    var body: some View {
        Text("\(viewModel.count)")
        Button("Increment") { viewModel.send(.increment) }
    }
}
```

Create two-way SwiftUI bindings through `binding(for:sendAction:)`. The binding reads from the current state and dispatches an action whenever the value changes:

```swift
Toggle(
    "Enabled",
    isOn: viewModel.binding(
        for: \.isEnabled,
        sendAction: { .setEnabled($0) }
    )
)
```

For loading flows or other asynchronous sequences, `send(_:while:)` dispatches an action and suspends until a state predicate evaluates to `false`:

```swift
await viewModel.send(.refresh, while: \.isLoading)
```

> **Note:** [`ViewModel`](Sources/Modules/Reducer/Models/ViewModel.swift) is confined to the main actor. State mutations happen synchronously when `send(_:)` is called. The `Task` returned by `send(_:)` represents the lifetime of the resulting effect, not the state change itself.

### Effects

When an action requires asynchronous work, the reducer returns an [`Effect`](Sources/Modules/Effect/Public/Effect.swift) instead of `.none`. The runtime executes the effect after the state change and dispatches any resulting actions back to the reducer.

```swift
case .refresh:
    return .run { send in
        let items = await service.fetchItems()
        await send(.itemsLoaded(items))
    }
```

The effect system provides several type methods:

| Method | Purpose |
|---|---|
| `.none` | No follow-up work. |
| `.run { send in ... }` | General-purpose async work that may send zero or more actions. |
| `.fireAndForget { ... }` | Async work that does not produce actions, such as analytics or logging. |
| `.task { ... }` | Async work that returns a single optional action. Supports an optional `delay` parameter. |
| `.merge(...)` | Runs multiple effects in parallel. |

#### Cancellation

Mark long-running effects with `.cancellable(id:)` and cancel them later with `.cancel(id:)`. This is useful for work that should stop when conditions change, such as polling or observation:

```swift
case .startPolling:
    return .run { send in
        for await _ in clock.timer(interval: .seconds(5)) {
            await send(.poll)
        }
    }
    .cancellable(id: CancelIDs.polling)

case .stopPolling:
    return .cancel(id: CancelIDs.polling)
```

Pass `cancelInFlight: true` to automatically cancel any previously running effect with the same identifier before starting a new one.

#### Combining Effects

Use `merge` to run multiple effects concurrently:

```swift
return .merge(
    .fireAndForget { await analytics.track(.refreshed) },
    .task { await .itemsLoaded(service.fetchItems()) }
)
```

#### Dependency Scope

Effects created with `.run(priority:operation:)` and its variants automatically capture the current dependency scope. Dependencies resolved inside the effect closure see the same values that were active when the effect was created.

### Dependency Injection

Services and configuration are accessed through the [`@Dependency`](Sources/Modules/Dependency%20Injection/Models/Dependency.swift) property wrapper rather than singletons or initializer parameters:

```swift
@Dependency(\.urlSession) var urlSession: URLSession
```

#### Declaring a Dependency

Each dependency is defined in two steps. First, conform a type to the [`DependencyKey`](Sources/Modules/Dependency%20Injection/Protocols/DependencyKey.swift) protocol and implement the `resolve(_:)` method to provide the default value:

```swift
enum UserDefaultsDependency: DependencyKey {
    static func resolve(_ dependencies: DependencyValues) -> UserDefaults {
        .standard
    }
}
```

Then expose the dependency on [`DependencyValues`](Sources/Modules/Dependency%20Injection/Services/DependencyValues.swift) through a computed property. This enables key-path-based access at the call site:

```swift
extension DependencyValues {
    var userDefaults: UserDefaults {
        get { self[UserDefaultsDependency.self] }
        set { self[UserDefaultsDependency.self] = newValue }
    }
}
```

#### Using Dependencies

Use [`@Dependency`](Sources/Modules/Dependency%20Injection/Models/Dependency.swift) in reducers, services, or other non-view code:

```swift
@Dependency(\.userDefaults) var userDefaults: UserDefaults
```

For SwiftUI views that need to observe an `ObservableObject` dependency and update when it changes, use [`@ObservedDependency`](Sources/Modules/Dependency%20Injection/Models/ObservedDependency.swift) instead:

```swift
@ObservedDependency(\.sessionManager) var sessionManager: SessionManager
```

#### Scope Propagation

Each access to a [`@Dependency`](Sources/Modules/Dependency%20Injection/Models/Dependency.swift) property resolves the value from ``DependencyValues.current``, which is propagated through Swift's structured concurrency via `@TaskLocal`. Scopes set with ``DependencyScopes.withDependencies`` are visible to any `@Dependency` access within that task. Effects automatically capture and restore the active scope, so dependencies resolved inside an effect closure see the same values that were active when the effect was created.

### Reactive Observation

Values that need to be shared across feature boundaries – such as authentication state, toast messages, or refresh signals – are expressed as [`Observable`](Sources/Modules/Observable/Models/Observable.swift) instances.

#### Declaring Observables

Declare observables as static properties on a shared namespace. Each observable stores a typed value and notifies registered observers when that value changes:

```swift
public enum Observables {
    static let isLoggedIn = Observable<Bool>(false)
    static let sessionDidExpire = Observable<Nil>()
}
```

Use [`Observable<Nil>`](Sources/Modules/Observable/Models/Observable.swift) for event-style signals that carry no payload. Call `trigger()` instead of assigning a value:

```swift
Observables.sessionDidExpire.trigger()
```

#### Responding to Changes

Conform to the [`Observer`](Sources/Modules/Observable/Protocols/ObserverProtocol.swift) protocol to define which observables a view watches and how each change maps to a reducer action:

```swift
struct MyObserver: Observer {
    typealias R = MyReducer

    let observedValues: [any ObservableProtocol] = [Observables.isLoggedIn]
    let viewModel: ViewModel<MyReducer>

    init(_ viewModel: ViewModel<MyReducer>) {
        self.viewModel = viewModel
    }

    func onChange(of observable: Observable<Any>) {
        switch observable {
        case Observables.isLoggedIn:
            send(.refreshUI)
        default: ()
        }
    }
}
```

The pattern-matching operator (`~=`) compares the identity of the observable that changed against the candidate passed to the observer, so each `case` uniquely identifies a single source of truth.

#### Lifecycle Management

Wrap an observer in a [`ViewObserver`](Sources/Modules/Observable/Models/ViewObserver.swift) to tie its registration to the lifetime of a SwiftUI view. When the view appears, the observer is registered; when the view is deallocated, the observer is removed:

```swift
@StateObject private var observer: ViewObserver<MyObserver>
```

> **Note:** [`Observable`](Sources/Modules/Observable/Models/Observable.swift) is thread-safe. The `value` property can be read and written from any isolation context. Observer callbacks are always dispatched to the main actor.

### Theming

Appearance is driven by [`UITheme`](Sources/Modules/Theming/Models/UITheme.swift) values. Each theme defines a set of [`ColoredItem`](Sources/Modules/Theming/Models/UITheme+DataModels.swift) entries that map [`ColoredItemType`](Sources/Modules/Theming/Models/ColoredItemType.swift) cases to colors, along with a `UIUserInterfaceStyle` preference.

#### Defining a Theme

Create a [`UITheme`](Sources/Modules/Theming/Models/UITheme.swift) by providing a name, a set of colored items, and an optional interface style:

```swift
let oceanTheme = UITheme(
    name: "Ocean",
    items: [
        .init(.background, color: .systemBlue),
        .init(.titleText, color: .white),
    ],
    style: .dark
)
```

Register available themes by providing a [`UIThemeListDelegate`](Sources/Modules/Foundation/Protocols/Public/Delegates/UIThemeListDelegate.swift) to `AppSubsystem.delegates`. The default delegate provides a single theme.

#### Applying Themes

Set the active theme at runtime through [`ThemeService`](Sources/Modules/Theming/Services/ThemeService.swift):

```swift
ThemeService.setTheme(oceanTheme)
```

The current theme is persisted across launches. During initialization, the subsystem restores the last-active theme automatically.

#### Themed Views

Wrap view content in a [`ThemedView`](Sources/Modules/Theming/Views/Public/ThemedView.swift) so that it responds to theme changes:

```swift
var body: some View {
    ThemedView {
        Text("Hello")
            .foregroundStyle(.titleText)
    }
}
```

By default, themed views update colors in place without rebuilding the view hierarchy. Set `redrawsOnAppearanceChange` to `true` when the view tree itself depends on values resolved at construction time.

### Localization

Multi-language support is provided through property-list-based string tables and an integrated translation pipeline.

#### Localization Sources

AppSubsystem maintains its own localized strings property list for framework-provided UI strings such as alert titles and button labels. Apps may provide a separate property list for app-specific strings. The two never need to share keys.

The [`LocalizationSource`](Sources/Modules/Localization/Models/Public/LocalizationSource.swift) enum identifies which property list to read from:

| Source | Property List | Bundle |
|---|---|---|
| `.app()` | `LocalizedStrings` (configurable) | Main bundle. |
| `.custom(plistName:bundle:)` | Configurable | Configurable. |
| `.subsystem` | `LocalizedStrings` | AppSubsystem module bundle. |

#### Defining String Keys

Define string keys by conforming an enum to [`LocalizedStringKeyRepresentable`](Sources/Modules/Localization/Protocols/LocalizedStringKeyRepresentable.swift):

```swift
enum StringKey: String, LocalizedStringKeyRepresentable {
    case helloWorld

    var referent: String { rawValue.snakeCased }
}
```

#### Resolving Strings

Use [`@Localized`](Sources/Modules/Localization/Models/Public/Localized.swift) to declare a string property whose value is resolved from a given source by key and language code:

```swift
@Localized(key: .helloWorld, source: .app())
var greeting: String
```

Define a constrained extension on `Localized` to provide a default source for your key type:

```swift
extension Localized where T == StringKey {
    init(
        _ key: StringKey,
        languageCode: String = RuntimeStorage.languageCode,
        source: LocalizationSource = .app()
    ) {
        self.init(
            key: key,
            languageCode: languageCode,
            source: source
        )
    }
}
```

With this extension in place:

```swift
@Localized(.helloWorld) var greeting: String
```

The lookup is backed by an internal cache, so repeated accesses do not re-read the property list from disk.

#### Accessing Subsystem Strings

AppSubsystem's property list includes localized strings for framework-provided UI elements such as "Cancel" and "Done." Apps can resolve these strings by declaring an available subsystem key in their own [`LocalizedStringKeyRepresentable`](Sources/Modules/Localization/Protocols/LocalizedStringKeyRepresentable.swift)-conforming enum and passing `.subsystem` as the source. For the full list of available keys, see [`SubsystemStringKey.swift`](Sources/Modules/Localization/Models/Internal/SubsystemStringKey.swift).

The following example resolves the `cancel` key from the subsystem's property list and defaults all other keys to the app's:

```swift
extension Localized where T == StringKey {
    init(
        _ key: StringKey,
        languageCode: String = RuntimeStorage.languageCode,
        source: LocalizationSource = .app()
    ) {
        var source = source
        if key == .cancel {
            source = .subsystem
        }

        self.init(
            key: key,
            languageCode: languageCode,
            source: source
        )
    }
}
```

> **Note:** Most apps do not need to reference the subsystem's strings.

#### Generating the Property List

Use [`Localization`](Sources/Modules/Localization/Services/Public/Localization.swift) to translate a string into every supported language and write the results to a property list in the app's temporary directory. If a property list with the specified name exists in the configured bundle, its entries are preserved in the output.

```swift
let result = await Localization.createPLIST(
    translating: "Hello, world!"
)
```

On success, the returned `Callback` contains the file path of the generated property list. Pass a [`PropertyListConfiguration`](Sources/Modules/Localization/Services/Public/Localization.swift) to control the output file name, the bundle searched for existing entries, and the overwrite behavior.

Each set of translations is stored under a top-level dictionary key in the property list. When no key is provided, the method derives one automatically from the first four words of the input, stripped of non-letter characters, lowercased, and joined with underscores. To specify the key explicitly, pass the `withKey` parameter:

```swift
let result = await Localization.createPLIST(
    translating: "Hello, world!",
    withKey: "greeting"
)
```

> **Note:** Non-letter characters are stripped before derivation. For example, `"Hello, world!"` produces the key `hello_world`.

To apply processing to translated strings before they are written – such as capitalization rules, character stripping, or sentinel replacements – pass a [`ProcessingConfiguration`](Sources/Modules/Localization/Services/Public/Localization.swift). When a configuration is provided, operations are applied in order: capitalization, sentinel replacement, then character stripping. All translations are sanitized and trimmed of leading and trailing whitespace regardless of whether a processing configuration is provided.

> **Note:** [`ProcessingConfiguration`](Sources/Modules/Localization/Services/Public/Localization.swift) requires at least one non-`nil` parameter. Passing `nil` for all three triggers a runtime assertion failure.

For additional transformation after processing is complete, pass a closure to the `postProcessingTransformation` parameter. The closure receives the fully processed string and returns the transformed result. To provide a custom translation implementation, pass a closure to the `translate` parameter.

#### Dynamic Translation

For runtime translation of content not present in the property list, the `TranslationService` provides asynchronous methods with activity indicator and timeout support. Toast and alert content can be translated at runtime before presentation.

### Navigation

Navigation is coordinated through three protocols and a coordinator class that together manage stack, sheet, and modal presentation from a single published state value.

#### Defining Navigation State

Conform to [`NavigatorState`](Sources/Modules/Navigation/Protocols/NavigatorStateProtocol.swift) to declare the three presentation channels available in the app. Each channel uses a [`Paths`](Sources/Modules/Navigation/Protocols/NavigatorStateProtocol.swift)-conforming type to enumerate its destinations:

```swift
struct AppNavigationState: NavigatorState {
    var modal: ModalPath? = nil
    var sheet: SheetPath? = nil
    var stack: [SeguePath] = []
}
```

#### Defining Routes

Conform to [`Navigating`](Sources/Modules/Navigation/Protocols/NavigatingProtocol.swift) to describe how each route modifies the navigation state:

```swift
struct AppNavigator: Navigating {
    enum Route {
        case dismiss
        case home
        case profile(userID: String)
        case settings
    }

    func navigate(to route: Route, on state: inout AppNavigationState) {
        switch route {
        case .dismiss:
            state.sheet = nil
        case .home:
            state.stack.removeAll()
        case .profile(let userID):
            state.stack.append(.profile(userID: userID))
        case .settings:
            state.sheet = .settings
        }
    }
}
```

#### The Navigation Coordinator

[`NavigationCoordinator`](Sources/Modules/Navigation/Services/NavigationCoordinator.swift) owns the navigation state and publishes changes for SwiftUI. Create a coordinator with an initial state and a [`Navigating`](Sources/Modules/Navigation/Protocols/NavigatingProtocol.swift) instance, then store it in the [`NavigationCoordinatorResolver`](Sources/Modules/Navigation/Services/NavigationCoordinatorResolver.swift) so that property wrappers can find it:

```swift
let navigation = NavigationCoordinator(
    AppNavigationState(),
    navigating: AppNavigator()
)

NavigationCoordinatorResolver.shared.store(navigation)
```

Trigger navigation by calling `navigate(to:)`:

```swift
navigation.navigate(to: .profile(userID: "42"))
```

Use `navigable(_:route:)` to create a two-way binding suitable for SwiftUI presentation modifiers:

```swift
.sheet(item: navigation.navigable(\.sheet, route: { _ in .dismiss })) { path in
    // Destination view for path.
}
```

#### Property Wrappers

Use [`@Navigator`](Sources/Modules/Navigation/Models/Navigator.swift) to access the coordinator in non-view code, and [`@ObservedNavigator`](Sources/Modules/Navigation/Models/ObservedNavigator.swift) to access it in SwiftUI views with automatic observation:

```swift
@ObservedNavigator var navigation: NavigationCoordinator<AppNavigator>
```

### Persistence

The [`@Persistent`](Sources/Modules/Foundation/Models/Public/Persistent.swift) property wrapper persists a `Codable` value across launches through a strongly typed [`PersistentStorageKey`](Sources/Modules/Foundation/Models/Public/Key%20Domains/PersistentStorageKey.swift). Values are encoded as binary property lists automatically, falling back to JSON when property list coding is not supported. Types that are natively supported by `UserDefaults` (such as `Bool`, `Int`, and `String`) are stored directly.

#### Defining Keys

Declare keys as static properties on [`PersistentStorageKey`](Sources/Modules/Foundation/Models/Public/Key%20Domains/PersistentStorageKey.swift):

```swift
extension PersistentStorageKey {
    static let hasCompletedOnboarding = PersistentStorageKey("hasCompletedOnboarding")
    static let lastSyncDate = PersistentStorageKey("lastSyncDate")
}
```

Using a dedicated key type prevents raw-string typos and makes it straightforward to audit every persisted value in the app.

#### Reading and Writing Values

Use [`@Persistent`](Sources/Modules/Foundation/Models/Public/Persistent.swift) to declare a property that reads from and writes to persistent storage:

```swift
@Persistent(.hasCompletedOnboarding) var hasCompletedOnboarding: Bool?
@Persistent(.lastSyncDate) var lastSyncDate: Date?
```

The wrapped value is always optional. Reading returns `nil` when no value has been stored for the key. Assigning `nil` removes the entry entirely.

Custom `Codable` types work the same way:

```swift
@Persistent(.userPreferences) var preferences: UserPreferences?
```

#### Storage Strategy

Small values are stored in `UserDefaults`. When the encoded representation of a value reaches 16 KB, the wrapper compresses the data using LZ4 and writes it to a file in the app's Application Support directory instead. This transition is automatic and transparent – reading and writing through the property wrapper behaves the same regardless of where the value is stored.

#### In-Memory Cache

`@Persistent` maintains a process-wide, write-through in-memory cache. Every write updates the cache, and every read checks it before falling back to disk. Values decoded from the persistent store are cached automatically so that subsequent reads within the same process do not repeat the decoding work.

The persistence cache is registered as a [`CacheDomain`](Sources/Modules/Foundation/Models/Public/Key%20Domains/CacheDomain.swift), so clearing all cache domains also clears the persistence cache.

> **Note:** Keys registered through the [`PermanentPersistentStorageKeyDelegate`](Sources/Modules/Foundation/Protocols/Public/Delegates/PermanentPersistentStorageKeyDelegate.swift) are protected from cache clearing, ensuring that critical values survive a full reset. Calling `reset(preserving:)` removes values from both `UserDefaults` and the Application Support directory, so filesystem-backed entries are cleaned up automatically.

### Developer Tools

Pre-release builds (any milestone before `generalRelease`) automatically include several diagnostic tools. All of them are disabled or hidden in general-release builds.

#### Build-Info Overlay

A persistent banner displays the build number, version, and milestone. It can be toggled through Developer Mode and is managed automatically by the subsystem.

#### Build Expiry

Pre-release builds enforce a 30-day evaluation period. The expiry date is calculated as the build date (recorded in `CFBuildDate`) plus 30 days. Once the period elapses, the app presents a full-screen gate on launch that requires a six-digit expiration override code to continue. If the correct code is not entered within 30 seconds, the app exits. General-release builds are exempt – the timebomb is never active when the milestone is `generalRelease`. The timebomb can also be toggled at runtime through the Developer Mode action menu.

> **Important:** Keep pre-release builds up to date. After 30 days a build becomes restricted and cannot be used without the expiration override code.

#### Breadcrumb Capture

Automated screenshot capture records the user's path through the app during debugging sessions. Enable or disable capture at runtime, with optional save-to-Photos support. Capture state is persisted between launches for pre-release builds and cleared automatically in general-release builds.

#### Logger

A domain-scoped logging system with session recording and subscriber-based filtering. Subscribe to specific domains through the [`LoggerDomainSubscriptionDelegate`](Sources/Modules/Foundation/Protocols/Public/Delegates/LoggerDomainSubscriptionDelegate.swift), and exclude domains from session records as needed:

```swift
Logger.log(
    .init("User tapped refresh.", metadata: .init(sender: self)),
    domain: .general
)
```

Any log call can optionally surface a runtime issue in Xcode by passing `showRuntimeWarning: true`. Runtime issues appear in the issue navigator alongside compiler warnings and errors, making them useful for flagging conditions that merit attention during development.

> **Note:** Runtime issues are not visible when the `OS_ACTIVITY_MODE` environment variable is set to `disable`.

#### Developer Mode Menu

A customizable action sheet provides app-specific debugging tasks at runtime. Register actions through [`DevModeService`](Sources/Modules/Developer%20Mode/Services/DevModeService.swift):

```swift
DevModeService.addAction(
    DevModeAction(title: "Clear Cache") {
        CacheService.clearAllDomains()
    }
)
```

Additional actions can be provided by registering a [`DevModeAppActionDelegate`](Sources/Modules/Developer%20Mode/Protocols/DevModeAppActionDelegate.swift) on `AppSubsystem.delegates`. Present the menu by calling `DevModeService.presentActionSheet()`.

---

## Delegate Customization

Default behavior can be replaced or extended by registering delegates on `AppSubsystem.delegates`. Delegates with sensible defaults are provided automatically. Optional delegates start as `nil` and can be registered at any time before or after initialization.

### Delegates with Defaults

| Delegate | Purpose | Default |
|---|---|---|
| `breadcrumbsCapture` | Screenshot capture for debugging. | Built-in [`Breadcrumbs`](Sources/Modules/Foundation/Services/Internal/Breadcrumbs.swift) implementation. |
| `cacheDomainList` | Application-specific cache domains. | Empty domain list. |
| `loggerDomainSubscription` | Logger domain filtering and session-record exclusions. | Subscribes to all domains. |
| `uiThemeList` | Available themes for the theme picker. | Single default theme. |

### Optional Delegates

| Delegate | Purpose |
|---|---|
| `buildInfoOverlayDotIndicatorColor` | Custom color for the build-info overlay indicator dot. |
| `devModeAppActions` | Additional actions in the Developer Mode menu. |
| `exceptionMetadata` | Controls which errors are reportable and provides user-facing descriptions. |
| `forcedUpdateModal` | Drives a forced-update flow with a redirect URL and publisher. |
| `permanentPersistentStorageKeys` | Keys that are protected from cache clearing. |

Register delegates individually or in a single call:

```swift
AppSubsystem.delegates.register(
    exceptionMetadataDelegate: MyExceptionDelegate(),
    uiThemeListDelegate: MyThemeListDelegate()
)

AppSubsystem.delegates.registerExceptionMetadataDelegate(MyExceptionDelegate())
```

---

## Conventions

AppSubsystem is an opinionated framework. Adopting it means adopting its conventions:

- **Main-actor isolation.** Reducers, view models, and most UI-facing services are confined to the main actor. The framework asserts at runtime if this invariant is violated. Asynchronous work runs in effects, which execute off the main actor and send results back through a [`Send`](Sources/Modules/Effect/Public/Send.swift) callback.

- **State is always equatable.** Reducer state must conform to `Equatable`. The view model compares the state before and after each action and publishes a change only when the values differ. If a reducer modifies state back to its original value, no view update occurs.

- **Actions over callbacks.** Rather than passing closures between components, the framework favors dispatching actions. This keeps data flow visible, testable, and easy to follow.

- **Constants by extension.** [`AppConstants`](Sources/Modules/Foundation/Constants/AppConstants.swift) provides empty inner enums (`CGFloats`, `Colors`, `Strings`, and others) that apps extend with domain-scoped values. This keeps constants discoverable through autocompletion and prevents naming collisions.

- **Scene-based window management.** [`RootWindowScene`](Sources/Modules/Foundation/Views/Internal/Root/RootWindowScene.swift) owns the window hierarchy. It creates the main content window, an overlay window for toasts and the build-info overlay, and a status-bar window. Apps should not create their own `UIWindow` instances.

- **Delegate-driven customization.** The framework does not use subclassing for customization. Behavior is adjusted by registering delegate conformances on `AppSubsystem.delegates`. Defaults are provided where possible; override only what is needed.

- **Swift 6 strict concurrency.** The package compiles with full sendability checking enabled. All public types are designed for safe use across isolation boundaries.

---

## Dependencies

AppSubsystem builds on three companion packages:

| Package | Purpose |
|---|---|
| [AlertKit](https://github.com/grantbrooksgoodman/alert-kit) | Structured alert and HUD presentation with integrated translation support. |
| [ComponentKit](https://github.com/grantbrooksgoodman/component-kit) | Reusable SwiftUI component primitives. |
| [Translator](https://github.com/grantbrooksgoodman/translator) | Asynchronous translation pipeline with local archiving and language recognition services. |

---

&copy; NEOTechnica Corporation. All rights reserved.
