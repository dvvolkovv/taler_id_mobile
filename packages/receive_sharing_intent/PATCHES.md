# receive_sharing_intent 1.8.1 — копия Taler ID

Взята в репозиторий 2026-10-31: системное приложение «Файлы» отдаёт фото,
видео, аудио и документы из своих разделов через `content://` URI вида
`com.android.providers.media.documents/document/<type>:<id>`, а плагин такие
URI не читает (см. ниже) — доли «Поделиться» в чат терялись либо ронялась
регистрация плагина. Правки только в `android/src/main/kotlin/…`, помечены в
коде `PATCH Pn (Taler ID)`. iOS- и Dart-часть не тронуты.

Основа: pub.dev `receive_sharing_intent` 1.8.1, sha256 архива
`ec76056e4d258ad708e76d85591d933678625318e411564dcb9059048ca3a593`.
Не скопированы: `example/`, `test/` (`*.iml` и `.gradle` в самом архиве 1.8.1
и так не было — исключали на случай, если появятся при обновлении версии).
Сверка с оригиналом (после правок должна показывать только P1–P6 плюс этот
файл — и, возможно, строку `Only in …/ios: Assets`: эта папка в оригинале
пустая, git пустые папки не хранит, а `receive_sharing_intent.podspec` на неё
не ссылается, так что после свежего чекаута её в нашей копии не будет — это
ожидаемо, не регрессия). После перехода на path-зависимость `flutter pub get`
больше не кладёт оригинал в pub cache — его нужно положить туда вручную:

    dart pub cache add receive_sharing_intent --version 1.8.1
    diff -r -x example -x test -x PATCHES.md \
      ~/.pub-cache/hosted/pub.dev/receive_sharing_intent-1.8.1 packages/receive_sharing_intent

Почему не 1.9.0: Android-часть там идентична 1.8.1 — тот же баг со всеми теми
же файлами, а iOS несёт breaking changes. Мы патчим только Android и не
трогаем iOS, так что проще взять версию без лишней миграции iOS-кода.

## Правки

- **P1** `FileDirectory.kt`, `getAbsolutePath` — весь файл переписан. Для
  любого `content://` URI путь получается только копированием через сам этот
  URI: именно на него отправитель выдал право чтения. Имя файла — через
  `OpenableColumns.DISPLAY_NAME`, обрезанное до последнего сегмента (защита от
  `../` в имени от отправителя — апстрим клал его в `File(cacheDir, fileName)`
  без всякой проверки). Было: для `document`-URI медиатеки
  (`com.android.providers.media.documents`) апстрим переписывал тип
  `image`/`video`/`audio` в запрос к коллекции
  `MediaStore…EXTERNAL_CONTENT_URI` с `_id=?`, а поток открывал на всю
  коллекцию без `selection` → `FileNotFoundException: Multiple items at
  content://media/external/images/media` на каждое фото/видео/аудио,
  расшаренное из системного приложения «Файлы»; тип `document` отдавал
  `null` → `"path": null` в JSON → Dart-сторона не может это разобрать →
  share теряется; а для `ExternalStorageDocument` отдавался голый путь
  (`Environment.getExternalStorageDirectory() + "/" + …`), недоступный
  приложению на чтение под scoped storage. Доработка в задаче 18: каждая
  копия теперь кладётся в свою папку `cache/shared/<nanoTime>/`, а имя файла
  при необходимости укорачивается до 200 байт с сохранением расширения
  (`fitName`). Было: все копии ложились прямо в `cacheDir` под одним именем —
  два элемента с одинаковым именем в одной шаре (или новая шара во время
  загрузки предыдущего файла) затирали друг друга; имя длиннее 255 байт
  (кириллица — 2 байта на букву) ломало копирование целиком, потому что файл
  с таким именем не создаётся на файловой системе.
- **P2** `ReceiveSharingIntentPlugin.kt` — старый `handleIntent` переименован
  в `handleIntentUnsafe`, новый `handleIntent` оборачивает его в `try/catch` с
  логом; вызовы в `onAttachedToActivity`/`onNewIntent` не менялись — они
  зовут `handleIntent` и теперь идут через обёртку. Было: необработанное
  исключение из разбора шаренного контента вылетало прямо из
  `onAttachedToActivity` (холодный старт — исключение ловит
  `GeneratedPluginRegistrant`, но регистрация плагина для этой activity
  срывается целиком) или из `onNewIntent` (тёплый старт — может уронить
  приложение).
- **P3** там же, `ACTION_SEND_MULTIPLE` — вызов `toJsonObject` на каждый
  элемент обёрнут в свой `try/catch`; нечитаемый элемент пропускается с
  warning-логом, остальные доходят. Было: один нечитаемый URI в
  мульти-шаринге обрывал `mapIndexedNotNull` исключением (которое без P2
  улетело бы дальше) — пропадала вся пачка файлов, а не один проблемный.
- **P4** там же, `toJsonObject` — после вычисления `path` добавлена проверка:
  если пути нет и текста нет — функция возвращает `null`, и элемент не
  попадает в JSON-массив. Было: `"path": null` без текста всё равно уходило в
  JSON, а Dart-сторона такой элемент не разбирает.
- **P5** там же, `toJsonObject` — если по MIME-типу вышло `TEXT`, но файл всё
  же пришёл как поток (`path != null`), тип подменяется на `FILE`. Было:
  файл, пришедший потоком с MIME `text/*` (`.txt`, `.csv`, `.vcf`, `.ics`,
  `.html`…), типизировался как `TEXT`, и Dart-сторона клала его кэш-путь в
  поле сообщения вместо того, чтобы прикрепить как файл.
- **P6** там же, `toJsonObject` — поля `thumbnail`/`duration` в JSON убраны,
  функция `getThumbnailAndDuration` удалена целиком вместе с шестью
  импортами, которые она одна использовала (`android.graphics.Bitmap`,
  `android.media.MediaMetadataRetriever` + `METADATA_KEY_DURATION` +
  `OPTION_CLOSEST_SYNC`, `java.io.File`, `java.io.FileOutputStream`). Было:
  миниатюра и длительность видео считались синхронно на главном потоке через
  `MediaMetadataRetriever`, хотя приложение эти поля никогда не читало — чистые
  затраты времени и риск: исключение в `getThumbnailAndDuration` роняло
  `toJsonObject` целиком, и видео терялось так же, как любой другой
  нечитаемый элемент (без P2/P3 — крашем).
