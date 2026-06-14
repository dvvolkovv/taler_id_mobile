# Vendored Windows nuget packages (offline feed)

The Windows build box has no route to nuget.org. Several Windows plugins
(audioplayers_windows, flutter_ble_peripheral, flutter_tts, local_auth_windows,
permission_handler_windows) need Microsoft.Windows.CppWinRT + .ImplementationLibrary (WIL).
These .nupkg are vendored so the build stages them OFFLINE by extracting the zip into
build/windows/x64/packages/<Id>.<Version>/ (see infra/do/provision/windows-build.ps1).
To update: drop a newer .nupkg here and bump the version in windows-build.ps1.
