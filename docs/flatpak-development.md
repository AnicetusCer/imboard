# Flatpak development build

Imboard's development manifest uses the KDE 6.10 runtime and builds the
current working tree together with a pinned layer-shell-qt dependency. It grants
Wayland, fallback X11, shared-memory, and GPU access. The fallback X11 socket is
included for Flatpak packaging compatibility; Imboard's supported target remains
KDE Wayland. It does not grant network or host filesystem access. Keyboard
events are sent through the user-approved XDG Remote Desktop portal.

Install the build tools and matching SDK from Flathub, then build and install:

```sh
flatpak install --user flathub org.kde.Sdk//6.10
sh ./scripts/install-user-flatpak.sh
```

Launch or toggle the installed development build:

```sh
flatpak run io.github.anicetuscer.imboard --toggle
```

Stop a running instance:

```sh
flatpak run io.github.anicetuscer.imboard --quit
```

In the Flatpak, `RUN AT LOGIN` requests autostart through the XDG Background
portal. When enabled, Imboard launches after login with the keyboard hidden and
the system-tray icon available for show/hide. Native development builds continue
to manage their own autostart desktop file.

To create a local `.flatpak` bundle suitable for attaching to a GitHub release:

```sh
sh ./scripts/build-release-bundle.sh
```

If this is run inside a nested container such as Distrobox, Flatpak Builder may
fail before compiling the app with a Bubblewrap `/etc/resolv.conf` bind-mount
error. That is a build-environment issue, not an Imboard packaging failure. Use
a normal Fedora KDE build environment where possible. On SteamOS, the installed
`org.flatpak.Builder` Flatpak can be used as a fallback; see
`docs/handover-wsl-flathub.md`.
