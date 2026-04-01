# Telegram-style Messenger Improvements

Ветка: `telegram` (создана от `main`)

---

## ✅ Phase 1 — Дизайн пузырей (DONE, commit `db3584a`)
- Цвет: исходящие = primary, входящие = card
- Хвостик: `Radius.circular(4)` на нужном углу последнего в группе
- Группировка: `isFirstInGroup` / `isLastInGroup` — отступ 2px/8px
- Имя отправителя только на `isFirstInGroup`
- "Вы: " перед своим последним сообщением в списке чатов

## ✅ Phase 2 — Поиск в чате + кнопка вниз (DONE, commit `7fd7f70`)
- Строка поиска в AppBar чата (режим переключается)
- Подсветка найденных пузырей (amber border)
- `Scrollable.ensureVisible` + `GlobalKey` для прокрутки к совпадению
- FAB "↓" с бейджем непрочитанных

## ✅ Phase 3 — Waveform аудио + Hero галерея (DONE, commit `c14a6f6`)
- Замена AudioPlayer на waveform-визуализацию (28 баров, `CustomPainter`)
- Прогресс воспроизведения, скорость 1×/2×
- Hero-анимация при открытии изображений
- `PageRouteBuilder` + FadeTransition для галереи
- Share кнопка в полноэкранной галерее

## ✅ Phase 4 — Фильтры, пин, архив (DONE, commit `d56fae1`)
- Фильтр-чипы "Все / Непрочитанные" под поиском
- Long-press на чат → pin/unpin, archive/unarchive
- Закреплённые чаты вверху списка + иконка 📌
- Строка "Архивировано N" внизу (сворачивается/разворачивается)
- Хранение в Hive (`messenger_prefs`)

---

## 🔲 Phase 5 — Реакции, Reply, Forward, Edit/Delete
- **Реакции**: long-press на сообщение → emoji picker (👍❤️😂😮😢🔥)
  - Показывать счётчики реакций под пузырём
  - Socket.io: `add_reaction` / `remove_reaction` events
- **Reply (цитата)**: свайп вправо на пузыре → цитата в поле ввода
  - Показывать превью цитируемого сообщения над input bar
  - `replyToId` в теле сообщения
- **Forward**: long-press → "Переслать" → выбор диалога из списка
- **Edit/Delete**: long-press → "Редактировать" / "Удалить"
  - Редактирование: заполнить поле ввода + индикатор режима
  - Удаление: для всех / только у себя

## 🔲 Phase 6 — Медиа и файлы
- **Галерея чата**: кнопка в шапке → все фото/видео чата в сетке
- **Прогресс загрузки**: LinearProgressIndicator внутри пузыря при upload
- **URL preview**: парсить ссылки → карточка с заголовком/превью
- **Видео**: автовоспроизведение превью при тапе в чате

## 🔲 Phase 7 — Статусы и присутствие
- **"Печатает..."**: Socket.io `typing` event → показывать в заголовке чата
  - Уже приходит с бэкенда, нужно только отобразить
- **"Онлайн / был(а) N минут назад"**: через Socket.io `online_status` или API
- **Двойные галочки ✓✓**: в trailing пузыря
  - ✓ — отправлено (`isDelivered=false`)
  - ✓✓ серые — доставлено (`isDelivered=true`)
  - ✓✓ синие — прочитано (`isRead=true`)

## 🔲 Phase 8 — Полировка UX
- **Swipe-to-reply** прямо в списке сообщений (GestureDetector + анимация)
- **Анимация новых сообщений**: slide-up + fade при получении
- **Haptic feedback**: `HapticFeedback.mediumImpact()` на long-press, реакции
- **Smooth scroll при отправке**: `animateTo(0)` с curve
- **Контекстное меню**: replace BottomSheet на кастомный popup над пузырём (как Telegram)
