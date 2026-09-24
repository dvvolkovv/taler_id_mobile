# flutter_callkit_incoming 2.5.8 — копия Taler ID

Взята в репозиторий 2026-09-24: на iOS разговор теперь живёт в CallKit до конца
(см. docs/superpowers/specs/2026-09-24-ios-calls-through-callkit-design.md), а
плагин рассчитан на один звонок за раз. Правки только в `ios/Classes`,
помечены в коде `PATCH Pn (Taler ID)`. Android-часть не тронута.

Основа: pub.dev `flutter_callkit_incoming` 2.5.8, sha256 архива
`993fb0f0cd990961072f0d13ff815a91773f92bfa1895be17d3366b2225ec9cd`.
Не скопированы: `example/`, `images/`, `test/`, `*.iml`, `android/.gradle/`.
Сверка с оригиналом (после правок должна показывать только P1–P7):

    diff -r -x example -x images -x test -x '*.iml' -x .gradle -x PATCHES.md \
      ~/.pub-cache/hosted/pub.dev/flutter_callkit_incoming-2.5.8 packages/flutter_callkit_incoming

При обновлении плагина: взять новую версию, перенести правки по этому списку,
прогнать матрицу из задачи 20 плана 2026-09-24-ios-calls-through-callkit.

(список правок — ниже, дополняется в задаче 2)
