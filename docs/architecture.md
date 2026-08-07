# Architecture

## Surface model

Wayland intentionally prevents ordinary clients from positioning themselves or
injecting input globally. Imboard uses the standard layer-shell protocol for its
keyboard surface. The overlay layer keeps it above application windows, while
`KeyboardInteractivityNone` prevents it from taking keyboard focus from the
target application. Inside that surface, two rounded translucent regions appear
as separate boards.

Layer surfaces are positioned by anchors and margins rather than ordinary
window-manager moves. Imboard anchors to the top-left output edges and translates
touch dragging into persisted margins. Resizing updates the layer surface's
desired size. Native builds without layer-shell retain an ordinary-window
fallback for development, but that fallback must not be presented as reliable
Wayland input behavior.

The initial 1280x800 composition allocates roughly 72% of the width to letters
and 28% to the developer pad. Both proportions and overall height must remain
configurable after touch testing.

## Input backend

Imboard requests keyboard-only control through the standard XDG Remote Desktop
portal. The portal session returns a restore token for later launches. Imboard
validates that the returned device mask contains `KEYBOARD` and remains
input-inert until the session is ready.

Key symbols are delivered as signed 32-bit D-Bus values, matching the portal
interface. Press and release calls complete synchronously. A failed release is
retried; a second failure closes the session so the compositor cannot continue
repeating a stuck key. Any failed key press also closes the session instead of
leaving the UI in a false READY state. Chords are fully validated before the
first modifier is pressed and modifiers are released in reverse order.

Each portal request has a two-minute timeout. Permission state is considered
configured only when both the setup marker and a non-empty restore token were
saved successfully.

The desktop portal can be stopped and replaced while SteamOS switches between
Gaming Mode and Desktop Mode. Imboard watches the portal's session-bus owner,
abandons handles belonging to the vanished service, and retries restoration
after the replacement service has stabilized. The saved restore token is kept;
a portal restart is not treated as permission revocation. It also monitors the
portal session's `Closed` signal and treats transport-level input failures as a
lost session: the old session is closed to release virtual keys, then Imboard
reconnects using the saved grant. An explicit portal denial or cancellation
still stops automatic recovery and requires a user-initiated repair.

SteamOS starts background applications concurrently with the portal front-end
and KDE backend after leaving Gaming Mode. Automatic restoration therefore
waits for a stabilization interval after the portal appears instead of treating
its D-Bus name as proof that every backend is ready. Portal lifecycle logs record
only state and errors; restore tokens, session paths, and typed content are not
logged.

When KDE may show a permission dialog, Imboard first announces that state and
hides its layer surface. The portal `Start` request is delayed briefly so the
Wayland compositor can commit the hide before mapping its own dialog. Imboard
does not attempt to position, raise, or otherwise control the system-owned
permission window.

Portal request phases that do not involve a user decision (`CreateSession` and
`SelectDevices`) normally answer immediately. If either stalls, Imboard closes
the abandoned request and session, waits for the portal to stabilize, and
retries at most three times. The interactive `Start` phase retains its longer
timeout and is never automatically retried around a permission decision.

The UI talks only to `InputController`, which accepts three action types:

- `text`: commit Unicode text.
- `key`: press and release one named key.
- `chord`: hold modifiers while pressing one key.
Arbitrary processes and shell commands are explicitly outside the action model.

Opt-in input diagnostics instrument three boundaries without retaining input
content: `KeyCap` counts touch starts, activations, and cancellations;
`InputController` counts completed or failed logical actions; and
`PortalInputBackend` measures each synchronous press or release call and reports
whether the portal accepted it. Counts and timings are memory-only. The enabled
preference may persist, but no key name, text, portal session path, or target
application is stored or logged. A successful D-Bus method reply proves portal
acceptance, not consumption by the focused target application.

ASCII text is sent directly as keysyms. Emoji and other non-ASCII text are an
experimental opt-in because the fallback writes the text to the clipboard and
then sends `Ctrl+V`. Imboard attempts to restore the previous clipboard text
after the paste if the clipboard still contains Imboard's temporary text. The
default release behavior rejects that path rather than touching the user's
clipboard.

## Offline dictation

Dictation is an optional local pipeline integrated into the keyboard's layer
surface as a two-row strip. It records from the default microphone only after
an explicit user action, shows a persistent recording indicator and countdown,
and stops automatically after 60 seconds.

Captured audio remains in memory. Imboard requests native 16 kHz mono float
capture when the device supports it; otherwise `AudioConverter` mixes the
device's preferred channel layout to mono while resampling directly into the
final 16 kHz buffer, avoiding a full-size intermediate mono recording. The
result is passed to the optional Whisper `small.en` model Flatpak extension.
`SpeechController` runs conversion and inference outside the UI thread, uses
Vulkan compute when available with a CPU fallback, and frees the model and
audio after each transcription. Audio and
transcript contents are neither persisted nor logged, and the Flatpak retains
no network permission.

The strip shares the keyboard's surface, avoiding compositor ordering between
multiple layer windows. The keyboard layer remains non-focusable throughout,
so the target application's focus is preserved. During review,
`InputController` intercepts Imboard text and navigation actions locally for
the transcript instead of sending them through the portal. Apply disables that
local route before delegating the completed text to portal input. The transcript
is cleared only after `InputController` reports successful delivery; an
interrupted send keeps the reviewed text available for retry.

## Configuration

Built-in layouts ship as read-only JSON resources. User preferences and the
portal restore token use Qt `QSettings`, under organization `AnicetusCer` and
application `Imboard`. `CustomKeyStore` normalizes all sixteen assignments before
persisting them; invalid actions become empty slots rather than being loaded
partially. Native autostart desktop-file writes use `QSaveFile`.

Permission, custom-key, keyboard-layout, and startup persistence failures are
reported to the UI and do not masquerade as success. Appearance and window
geometry remain non-critical: their delayed writes report failures to the log
without disabling keyboard input.

## Process lifecycle

Imboard owns its application ID on the session D-Bus for the lifetime of the
primary process. This gives the single-instance guard a compositor-independent
liveness signal that is released automatically if the process crashes. A local
socket carries show, toggle, and quit commands, while a long-lived lock protects
socket creation from concurrent launches.

Flatpak processes use separate PID namespaces and can each appear as the same
PID, so a lock file alone cannot reliably identify a crashed instance. After a
control request fails, a new process may replace an abandoned lock and socket
only if it first acquires the application D-Bus name. If a live current instance
owns that name, recovery is refused.

QML resources are compiled into the release executable at build time. This
avoids reparsing the complete interface during each process start and keeps
startup independent of a writable runtime QML cache.

## Code boundaries

`main.cpp` owns process startup and object wiring. `Main.qml` is the composition
root; the keyboard frame and each settings or permission workflow live in a
focused QML component. C++ controllers own platform integration and persistence,
while QML owns presentation and transient editing state. The detailed ownership
map and persistent key inventory are in [code-map.md](code-map.md).

## Compatibility matrix

The MVP is not complete until text, arrows, F-keys, and Ctrl/Alt chords work in:

- Konsole under native Wayland
- Firefox under native Wayland
- an XWayland application
- a sandboxed Flatpak application

Secure password surfaces and the lock screen require separate validation and
must not be claimed as supported by inference.
