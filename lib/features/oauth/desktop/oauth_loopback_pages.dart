class OAuthLoopbackPages {
  OAuthLoopbackPages._();

  static const String success = '''
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <title>Авторизация выполнена</title>
  <style>
    body { font-family: -apple-system, system-ui, sans-serif; background: #1a1b1e; color: #e1e3e6; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .card { text-align: center; padding: 32px 48px; background: #2b2d31; border-radius: 12px; max-width: 440px; }
    h1 { font-size: 20px; margin: 0 0 12px; }
    p { font-size: 14px; opacity: 0.7; margin: 0; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Авторизация выполнена</h1>
    <p>Можно закрыть это окно и вернуться в Taler ID.</p>
  </div>
  <script>setTimeout(() => window.close(), 1500);</script>
</body>
</html>
''';

  static String error(String reason) => '''
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <title>Ошибка авторизации</title>
  <style>
    body { font-family: -apple-system, system-ui, sans-serif; background: #1a1b1e; color: #e1e3e6; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .card { text-align: center; padding: 32px 48px; background: #2b2d31; border-radius: 12px; max-width: 440px; }
    h1 { font-size: 20px; margin: 0 0 12px; color: #ff6b6b; }
    code { background: #1a1b1e; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Ошибка авторизации</h1>
    <p>Причина: <code>$reason</code></p>
    <p style="margin-top: 16px; opacity: 0.6">Закройте окно и попробуйте снова в приложении.</p>
  </div>
</body>
</html>
''';
}
