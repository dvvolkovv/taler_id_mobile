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

## ✅ Phase 5 — Реакции, Reply, Forward, Edit/Delete (ALREADY IMPLEMENTED)
- **Реакции**: long-press → emoji picker (👍❤️😂😮😢🙏), `_ReactionsRow` под пузырём
- **Reply**: swipe-to-reply (drag threshold 56px + HapticFeedback), reply preview над input
- **Forward**: long-press → "Переслать" → `_ForwardPickerSheet`
- **Edit**: `_startEditing` → заполняет input + `EditMessage` event
- **Delete**: "Удалить для меня" / "Удалить для всех"

## ✅ Phase 6 — Медиа и файлы (PARTIAL — URL preview added)
- ✅ **Прогресс загрузки**: LinearProgressIndicator при upload
- ✅ **URL preview**: OG-метаданные (title, description, image) в карточке под текстом
- 🔲 **Галерея чата**: кнопка в шапке → все фото/видео чата в сетке

## ✅ Phase 7 — Статусы и присутствие (ALREADY IMPLEMENTED)
- ✅ **"Печатает..."**: `typingUsers` из BLoC → subtitle в AppBar чата
- ✅ **Двойные галочки**: ✓ → ✓✓ серые (delivered) → ✓✓ белые (read)
- 🔲 **"Онлайн / был(а) N мин назад"**: нужна поддержка на бэкенде

---

## 🔲 Phase 8 — Полировка UX (оставшиеся задачи)
- **Галерея чата**: кнопка в шапке → grid всех фото/видео чата
- **Анимация новых сообщений**: slide-up + fade при получении
- **Контекстное меню**: popup над пузырём вместо BottomSheet (как Telegram)
- **"Онлайн / был(а)"**: добавить на бэкенд `lastSeen` + Socket.io `online_status`
