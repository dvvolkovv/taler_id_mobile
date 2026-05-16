#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <string>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Register talerid:// URI scheme on first launch (HKEY_CURRENT_USER — no admin)
  {
    HKEY hKey;
    LPCWSTR keyPath = L"Software\\Classes\\talerid";
    if (RegCreateKeyExW(HKEY_CURRENT_USER, keyPath, 0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS) {
      const wchar_t* protoName = L"URL:Taler ID Protocol";
      RegSetValueExW(hKey, L"", 0, REG_SZ, (BYTE*)protoName, (DWORD)((wcslen(protoName) + 1) * sizeof(wchar_t)));
      const wchar_t* empty = L"";
      RegSetValueExW(hKey, L"URL Protocol", 0, REG_SZ, (BYTE*)empty, (DWORD)sizeof(wchar_t));
      RegCloseKey(hKey);

      HKEY hCmdKey;
      LPCWSTR cmdPath = L"Software\\Classes\\talerid\\shell\\open\\command";
      if (RegCreateKeyExW(HKEY_CURRENT_USER, cmdPath, 0, NULL, 0, KEY_WRITE, NULL, &hCmdKey, NULL) == ERROR_SUCCESS) {
        wchar_t exePath[MAX_PATH];
        GetModuleFileNameW(NULL, exePath, MAX_PATH);
        std::wstring cmdValue = L"\"";
        cmdValue += exePath;
        cmdValue += L"\" \"%1\"";
        RegSetValueExW(hCmdKey, L"", 0, REG_SZ, (BYTE*)cmdValue.c_str(),
                       (DWORD)((cmdValue.length() + 1) * sizeof(wchar_t)));
        RegCloseKey(hCmdKey);
      }
    }
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"taler_id_mobile", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
