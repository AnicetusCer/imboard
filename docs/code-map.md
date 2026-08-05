# Code map

This map describes ownership and runtime flow. It is intentionally about the
current implementation rather than future plans.

## Runtime flow

1. `main.cpp` selects layer-shell before Qt creates the first window, handles
   `--toggle`, `--quit`, and single-instance startup, then exposes controllers
   to QML. The primary process holds the application D-Bus name as its liveness
   lease and accepts window commands through a private local socket.
2. `Main.qml` composes the keyboard surface and focused popup components.
3. `AlphaBoard.qml` and `DeveloperPad.qml` call `InputController` with text,
   named-key, or chord actions.
4. `InputController` converts actions to X11 keysyms and delegates press/release
   delivery to `PortalInputBackend`.
5. `PortalInputBackend` owns the XDG Remote Desktop portal session and refuses
   delivery until keyboard-only access is ready.
6. `SpeechController` captures user-initiated microphone audio in memory,
   converts it to 16 kHz mono PCM, and runs optional local Whisper transcription
   away from the UI thread. While the integrated strip is active, `InputController`
   routes keyboard actions into its local transcript editor; Apply returns to
   portal delivery and sends the completed text to the target app. Failed
   delivery keeps the transcript open and reports that the target should be
   checked before retrying.

## C++ ownership

| File | Responsibility | Directly tested by |
| --- | --- | --- |
| `main.cpp` | Process bootstrap and controller-to-QML wiring | lifecycle, QML smoke |
| `appearancestore.*` | Palette, opacity, and pad-side persistence | `appearancestore-test` |
| `compatibilitystore.*` | One-time non-KDE session warning | `compatibilitystore-test` |
| `customkeystore.*` | Validation and persistence of sixteen assignments | `customkeystore-test` |
| `inputcontroller.*` | Public action API and keysym mapping | QML smoke, manual input tests |
| `portalinputbackend.*` | Portal state machine, service-restart recovery, and safe key delivery | `portalinputbackend-test` |
| `keyboardlayoutstore.*` | Layout resource loading and normalization | `keyboardlayoutstore-test` |
| `surfacecontroller.*` | Layer-shell setup, ghost move, resize, position | lifecycle, QML smoke |
| `startupmanager.*` | Background portal or native autostart entry | `startupmanager-test` |
| `instancecontroller.*` | D-Bus liveness lease, crash recovery, single-instance lock, and local commands | lifecycle |
| `signalhandler.*` | SIGINT/SIGTERM bridge into Qt shutdown | lifecycle |
| `smoketestcontroller.*` | Non-interactive QML geometry choreography | QML smoke |
| `audioconverter.*` | Safe PCM decoding, channel mixing, and 16 kHz resampling | `audioconverter-test` |
| `speechcontroller.*` | Microphone lifecycle and offline Whisper transcription | speech lifecycle, audio conversion, QML smoke |

## QML ownership

| File | Responsibility |
| --- | --- |
| `Main.qml` | Window flags, composition, setup trigger, popup wiring |
| `KeyboardSurface.qml` | Keyboard-frame composition, board placement, and resize handle |
| `KeyboardHeader.qml` | Full-keyboard controls, movement, and transcription entry point |
| `CompactPadHeader.qml` | Compact-mode controls, movement, and custom-slot ordering |
| `TranscriptionStrip.qml` | Recording state, transcript editing, and transactional apply flow |
| `AlphaBoard.qml` | Regional alphanumeric layout rendering |
| `DeveloperPad.qml` | Swipe pages and custom-key editing coordination |
| `DeveloperPadCatalog.qml` | Declarative standard-page and custom-picker actions |
| `CustomKeyPickerPopup.qml` | Filtered custom-key catalog presentation |
| `KeyCap.qml` | Shared touch key and tooltip presentation |
| `AppearancePopup.qml` | Theme and background opacity |
| `LayoutPopup.qml` | Regional layout selection |
| `ConfigPopup.qml` | Startup state and access-management entry points |
| `CompatibilityWarningPopup.qml` | One-time note for non-KDE sessions |
| `PermissionSetupPopup.qml` | Required first-run portal explanation |
| `RemoveAccessPopup.qml` | Destructive access-removal confirmation |
| `SpeechSetupPopup.qml` | Optional small.en model add-on installation guidance |

`main.cpp` supplies the root component's required controller properties through
`QQmlApplicationEngine::setInitialProperties`. Child components receive those
dependencies through explicit required properties rather than implicit QML
context lookup.

## Persistent settings

Qt stores application settings using organization `AnicetusCer` and application
`Imboard`. Current keys are:

- `appearance/scheme`, `appearance/backdropOpacity`,
  `appearance/developerPadOnLeft`, `appearance/developerPadPageIndex`
- `compatibility/nonKdeWarningSeen`
- `customKeys/assignments`
- `keyboard/layout`
- `portal/setupComplete`, `portal/restoreToken`
- `startup/portalEnabled`
- `startup/promptSeen`
- `window/fullSize`, `window/customPadSize`, `window/layerPosition`

`window/size` is a legacy key read only when migrating an existing installation.

Changing a key without migration silently resets a user's configuration.

## Common changes

| Goal | Primary files | Required verification |
| --- | --- | --- |
| Add a regional keyboard | `layouts/*.json`, `CMakeLists.txt` | layout unit test, QML smoke |
| Add a theme | `appearancestore.cpp`, `AppearancePopup.qml` | appearance unit test, QML smoke |
| Add a named key | `inputcontroller.cpp`, `DeveloperPad.qml` | build, QML smoke, manual input |
| Change portal behavior | `portalinputbackend.*`, permission copy | portal unit test, manual permission flow |
| Change movement or resizing | `surfacecontroller.*`, `KeyboardSurface.qml` | lifecycle, QML smoke, touch test |
| Change popup structure | matching `*Popup.qml`, smoke object names | QML smoke |
| Change custom assignments | `customkeystore.*`, `DeveloperPad.qml` | custom-key unit test, QML smoke |
| Change offline dictation | `speechcontroller.*`, `audioconverter.*`, `KeyboardSurface.qml` | audio/input unit tests, QML smoke, manual microphone test |

Manual compatibility checks remain necessary for native Wayland, XWayland, and
sandboxed target applications; unit tests cannot prove compositor behavior.
