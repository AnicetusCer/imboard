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

## QML ownership

| File | Responsibility |
| --- | --- |
| `Main.qml` | Window flags, composition, setup trigger, popup wiring |
| `KeyboardSurface.qml` | Neon frame, move/resize controls, board placement |
| `AlphaBoard.qml` | Regional alphanumeric layout rendering |
| `DeveloperPad.qml` | Swipe pages and transactional custom-key editing |
| `KeyCap.qml` | Shared touch key and tooltip presentation |
| `AppearancePopup.qml` | Theme and background opacity |
| `LayoutPopup.qml` | Regional layout selection |
| `ConfigPopup.qml` | Startup state and access-management entry points |
| `CompatibilityWarningPopup.qml` | One-time note for non-KDE sessions |
| `PermissionSetupPopup.qml` | Required first-run portal explanation |
| `RemoveAccessPopup.qml` | Destructive access-removal confirmation |

`main.cpp` supplies the root component's required controller properties through
`QQmlApplicationEngine::setInitialProperties`. Child components receive those
dependencies through explicit required properties rather than implicit QML
context lookup.

## Persistent settings

Qt stores application settings using organization `AnicetusCer` and application
`Imboard`. Current keys are:

- `appearance/scheme`, `appearance/backdropOpacity`,
  `appearance/developerPadOnLeft`
- `compatibility/nonKdeWarningSeen`
- `customKeys/assignments`
- `keyboard/layout`
- `portal/setupComplete`, `portal/restoreToken`
- `startup/portalEnabled`
- `startup/promptSeen`
- `window/size`, `window/layerPosition`

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

Manual compatibility checks remain necessary for native Wayland, XWayland, and
sandboxed target applications; unit tests cannot prove compositor behavior.
