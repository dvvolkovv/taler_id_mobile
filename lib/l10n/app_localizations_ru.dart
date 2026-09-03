// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Поиск';

  @override
  String get appSubtitle => 'Единая идентификация экосистемы';

  @override
  String get login => 'Вход в аккаунт';

  @override
  String get loginButton => 'Войти';

  @override
  String get register => 'Создать аккаунт';

  @override
  String get registerButton => 'Создать аккаунт';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get confirmPassword => 'Подтвердить пароль';

  @override
  String get firstName => 'Имя';

  @override
  String get lastName => 'Фамилия';

  @override
  String get noAccount => 'Нет аккаунта?';

  @override
  String get createOne => 'Создать';

  @override
  String get haveAccount => 'Уже есть аккаунт?';

  @override
  String get signIn => 'Войти';

  @override
  String get passwordMinLength => 'Минимум 8 символов';

  @override
  String get invalidEmail => 'Введите корректный email';

  @override
  String get fieldRequired => 'Обязательное поле';

  @override
  String get twoFATitle => 'Двухфакторная аутентификация';

  @override
  String get twoFASubtitle =>
      'Введите 6-значный код из приложения-аутентификатора';

  @override
  String get twoFACode => 'Код 2FA';

  @override
  String get verify => 'Подтвердить';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Организация';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get profile => 'Профиль';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get phone => 'Телефон';

  @override
  String get country => 'Страна';

  @override
  String get dateOfBirth => 'Дата рождения';

  @override
  String get documents => 'Документы';

  @override
  String get addDocument => 'Добавить документ';

  @override
  String get noDocuments => 'Документы не загружены';

  @override
  String get save => 'Сохранить';

  @override
  String get profileUpdated => 'Профиль обновлён';

  @override
  String get personalData => 'Личные данные';

  @override
  String get passport => 'Паспорт';

  @override
  String get drivingLicense => 'Водительское удостоверение';

  @override
  String get diploma => 'Диплом';

  @override
  String get nationalId => 'Национальный ID';

  @override
  String get certificate => 'Сертификат';

  @override
  String get notSpecified => 'Не указан';

  @override
  String get notSpecifiedFemale => 'Не указана';

  @override
  String get documentType => 'Тип документа';

  @override
  String get passportId => 'Паспорт / ID';

  @override
  String get diplomaCertificate => 'Диплом / Сертификат';

  @override
  String get loadError => 'Ошибка загрузки';

  @override
  String get verification => 'Верификация';

  @override
  String get countryAustria => 'Австрия';

  @override
  String get countryGermany => 'Германия';

  @override
  String get countryRussia => 'Россия';

  @override
  String get countryUkraine => 'Украина';

  @override
  String get countryKazakhstan => 'Казахстан';

  @override
  String get countryBelarus => 'Беларусь';

  @override
  String get countryOther => 'Другая';

  @override
  String get kycTitle => 'Верификация KYC';

  @override
  String get kycVerified => 'Верифицирован';

  @override
  String get kycPending => 'На проверке';

  @override
  String get kycRejected => 'Отклонено';

  @override
  String get kycUnverified => 'Не верифицирован';

  @override
  String get kycVerifiedDesc =>
      'Ваша личность подтверждена. У вас есть полный доступ ко всем функциям экосистемы Taler.';

  @override
  String get kycPendingDesc =>
      'Ваши документы проходят верификацию. Обычно это занимает 1-2 рабочих дня.';

  @override
  String get kycRejectedDesc =>
      'Верификация не пройдена. Ознакомьтесь с причиной и отправьте документы повторно.';

  @override
  String get kycUnverifiedDesc =>
      'Пройдите верификацию для получения полного доступа к финансовым функциям экосистемы Taler.';

  @override
  String get continueVerification => 'Продолжить верификацию';

  @override
  String get kycInProgress => 'Не завершена';

  @override
  String get kycInProgressDesc =>
      'Вы начали верификацию, но не завершили её. Продолжите с того места, где остановились.';

  @override
  String get startVerification => 'Пройти верификацию';

  @override
  String get retryVerification => 'Пройти повторно';

  @override
  String verifiedAt(String date) {
    return 'Верифицирован: $date';
  }

  @override
  String get documentsSubmitted => 'Документы отправлены на проверку';

  @override
  String get documentsSubmittedDesc =>
      'Обычно проверка занимает 1-2 рабочих дня. Вы получите push-уведомление о результате.';

  @override
  String get securityAes => 'Ваши данные защищены AES-256 шифрованием';

  @override
  String get verificationTime => 'Верификация занимает 1-2 рабочих дня';

  @override
  String get pushNotification => 'Вы получите push-уведомление о результате';

  @override
  String get kycWebOnly =>
      'KYC-верификация доступна только в мобильном приложении.';

  @override
  String verificationError(String code) {
    return 'Ошибка верификации: $code';
  }

  @override
  String get organizations => 'Организации';

  @override
  String get noOrganizations => 'Нет организаций';

  @override
  String get noOrganizationsDesc =>
      'Создайте организацию или примите приглашение';

  @override
  String get createOrganization => 'Создать организацию';

  @override
  String get newOrganization => 'Новая организация';

  @override
  String get orgName => 'Название *';

  @override
  String get orgDescription => 'Описание';

  @override
  String get orgEmail => 'Контактный email';

  @override
  String get orgWebsite => 'Веб-сайт';

  @override
  String get orgLegalAddress => 'Юридический адрес';

  @override
  String get create => 'Создать';

  @override
  String get organization => 'Организация';

  @override
  String get contacts => 'Контакты';

  @override
  String members(int count) {
    return 'Участники ($count)';
  }

  @override
  String get inviteMember => 'Пригласить участника';

  @override
  String get invite => 'Пригласить';

  @override
  String get sendInvite => 'Отправить приглашение';

  @override
  String inviteSent(String email) {
    return 'Приглашение отправлено на $email';
  }

  @override
  String get role => 'Роль';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleOperator => 'Operator';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get editOrganization => 'Редактировать';

  @override
  String get editOrganizationTitle => 'Редактировать организацию';

  @override
  String get removeMember => 'Удалить участника';

  @override
  String removeMemberConfirm(String name) {
    return 'Удалить $name из организации?';
  }

  @override
  String get memberRemoved => 'Участник удалён';

  @override
  String get roleChanged => 'Роль изменена';

  @override
  String get kybVerified => 'Верифицирована';

  @override
  String get kybPending => 'На проверке';

  @override
  String get kybRejected => 'Отклонено';

  @override
  String get kybNone => 'Не верифицирована';

  @override
  String get kybVerification => 'Пройти KYB-верификацию';

  @override
  String get kybStartBusiness => 'Пройти бизнес-верификацию';

  @override
  String get kybStatusLabel => 'Статус KYB';

  @override
  String get noKyb => 'Без KYB';

  @override
  String get kybBusinessVerificationTitle => 'Бизнес-верификация (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Организация успешно верифицирована.';

  @override
  String get kybPendingOrgDesc =>
      'Документы проходят проверку. Обычно это занимает 1-3 рабочих дня.';

  @override
  String get kybRejectedOrgDesc =>
      'Верификация не пройдена. Попробуйте повторно.';

  @override
  String get kybNoneOrgDesc =>
      'Верифицируйте организацию для доступа к бизнес-функциям.';

  @override
  String get invitePlus => '+ Пригласить';

  @override
  String get kybVerificationTitle => 'KYB-верификация';

  @override
  String get kybWebOnlyBusiness =>
      'KYB-верификация доступна только в мобильном приложении.';

  @override
  String get unknownDevice => 'Неизвестное устройство';

  @override
  String get ipUnknown => 'IP неизвестен';

  @override
  String get currentSessionLabel => 'Текущая';

  @override
  String get endSessionAction => 'Завершить';

  @override
  String get deviceLoggedOut => 'Устройство будет выведено из аккаунта.';

  @override
  String get acceptInvitationTitle => 'Приглашение в организацию';

  @override
  String get acceptInvitation => 'Принять приглашение';

  @override
  String get acceptInvitationDesc =>
      'Вас пригласили присоединиться к организации в экосистеме Taler.';

  @override
  String get accept => 'Принять';

  @override
  String get reject => 'Отклонить';

  @override
  String get sessions => 'Активные сессии';

  @override
  String get currentSession => 'Текущая сессия';

  @override
  String get deleteSession => 'Завершить сессию';

  @override
  String get deleteSessionConfirm => 'Завершить эту сессию?';

  @override
  String get sessionDeleted => 'Сессия завершена';

  @override
  String get noSessions => 'Нет активных сессий';

  @override
  String minutesAgo(int count) {
    return '$count мин. назад';
  }

  @override
  String hoursAgo(int count) {
    return '$count ч. назад';
  }

  @override
  String daysAgo(int count) {
    return '$count дн. назад';
  }

  @override
  String get justNow => 'Только что';

  @override
  String get settings => 'Настройки';

  @override
  String get security => 'Безопасность';

  @override
  String get biometrics => 'Биометрия';

  @override
  String get biometricsDesc => 'Быстрый вход по Face ID или отпечатку';

  @override
  String get biometricsConfirm =>
      'Подтвердите биометрию для включения быстрого входа';

  @override
  String get biometricsError =>
      'Не удалось включить биометрию. Проверьте настройки устройства.';

  @override
  String get changePassword => 'Изменить пароль';

  @override
  String get twoFactorAuth => 'Двухфакторная аутентификация';

  @override
  String get currentPassword => 'Текущий пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get confirmNewPassword => 'Подтвердить новый пароль';

  @override
  String get passwordChanged => 'Пароль изменён';

  @override
  String get wrongCurrentPassword => 'Неверный текущий пароль';

  @override
  String get passwordTooWeak =>
      'Пароль слишком простой: минимум 8 символов, буква и цифра';

  @override
  String get passwordChangeFailed => 'Не удалось изменить пароль';

  @override
  String get notifications => 'Уведомления';

  @override
  String get permissions => 'Разрешения';

  @override
  String get permissionNotifications => 'Push-уведомления';

  @override
  String get permissionNotificationsDesc => 'Звонки, сообщения, статусы';

  @override
  String get permissionMicrophone => 'Микрофон';

  @override
  String get permissionMicrophoneDesc => 'Звонки и голосовой ассистент';

  @override
  String get permissionCamera => 'Камера';

  @override
  String get permissionCameraDesc => 'Видеозвонки и верификация';

  @override
  String get permissionLocation => 'Геолокация';

  @override
  String get permissionLocationDesc => 'Используется для верификации';

  @override
  String get permissionOpenSettings =>
      'Чтобы отозвать разрешение, откройте настройки системы';

  @override
  String get pushKycStatus => 'Push о KYC-статусе';

  @override
  String get pushKycStatusDesc => 'Результат верификации';

  @override
  String get pushLogins => 'Push о входах';

  @override
  String get pushLoginsDesc => 'При входе с нового устройства';

  @override
  String get account => 'Аккаунт';

  @override
  String get language => 'Язык';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Язык интерфейса';

  @override
  String get exportData => 'Экспорт данных (GDPR)';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirm => 'Удалить аккаунт?';

  @override
  String get deleteAccountDesc =>
      'Все ваши данные будут удалены (GDPR). Это действие необратимо.';

  @override
  String get logout => 'Выйти';

  @override
  String get logoutConfirm => 'Выйти из аккаунта?';

  @override
  String get logoutDesc => 'Вы будете выведены из Taler ID на этом устройстве.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'PIN-код';

  @override
  String get pinCodeDesc => 'Быстрый вход по 4-значному коду';

  @override
  String get setupPin => 'Установить PIN-код';

  @override
  String get enterPin => 'Введите PIN-код';

  @override
  String get confirmPin => 'Подтвердите PIN-код';

  @override
  String get pinMismatch => 'PIN-коды не совпадают';

  @override
  String get passwordMismatch => 'Пароли не совпадают';

  @override
  String get pinSet => 'PIN-код установлен';

  @override
  String get enterPinToLogin => 'Введите PIN для входа';

  @override
  String get pinIncorrect => 'Неверный PIN-код';

  @override
  String get removePin => 'Удалить PIN-код';

  @override
  String get pinRemoved => 'PIN-код удалён';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Повторить';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успешно';

  @override
  String get noData => 'Нет данных';

  @override
  String get failedToLoad => 'Не удалось загрузить данные';

  @override
  String get failedToLoadProfile => 'Не удалось загрузить профиль';

  @override
  String get failedToSave => 'Не удалось сохранить изменения';

  @override
  String get failedToLoadOrgs => 'Не удалось загрузить список организаций';

  @override
  String get failedToLoadOrg => 'Не удалось загрузить данные организации';

  @override
  String get failedToCreateOrg => 'Не удалось создать организацию';

  @override
  String get failedToInvite => 'Не удалось отправить приглашение';

  @override
  String get failedToAcceptInvite => 'Не удалось принять приглашение';

  @override
  String get failedToLoadSessions => 'Не удалось загрузить сессии';

  @override
  String get failedToDeleteSession => 'Не удалось завершить сессию';

  @override
  String get failedToLoadKyc => 'Не удалось загрузить статус верификации';

  @override
  String get failedToStartKyc => 'Не удалось запустить верификацию';

  @override
  String get verifiedPersonalInfo => 'Подтверждённые данные';

  @override
  String get middleName => 'Отчество';

  @override
  String get placeOfBirth => 'Место рождения';

  @override
  String get nationality => 'Гражданство';

  @override
  String get gender => 'Пол';

  @override
  String get genderMale => 'Мужской';

  @override
  String get genderFemale => 'Женский';

  @override
  String get docNumber => 'Номер';

  @override
  String get docIssuedDate => 'Дата выдачи';

  @override
  String get docValidUntil => 'Действителен до';

  @override
  String get docIssuedBy => 'Кем выдан';

  @override
  String get address => 'Адрес';

  @override
  String get refreshData => 'Обновить данные';

  @override
  String get failedToLoadSumsubData =>
      'Не удалось загрузить данные верификации';

  @override
  String get sumsubDataLoading => 'Загрузка данных верификации...';

  @override
  String get reviewResultGreen => 'Проверка пройдена';

  @override
  String get reviewResultRed => 'Проверка не пройдена';

  @override
  String get tabAssistant => 'Ассистент';

  @override
  String get assistantChatHint => 'Напишите ассистенту';

  @override
  String get assistantActionUnavailable => 'Элемент недоступен';

  @override
  String get assistantAttachFile => 'Прикрепить файл';

  @override
  String get assistantTyping => 'Ассистент думает…';

  @override
  String get assistantEmptyHint => 'Спросите что угодно — голосом или текстом';

  @override
  String get assistantToolLoopError => 'Ассистент не смог завершить запрос';

  @override
  String get assistantError => 'Что-то пошло не так. Попробуйте ещё раз';

  @override
  String get assistantConnecting => 'Подключение…';

  @override
  String get assistantSpeaking => 'Говорит…';

  @override
  String get assistantListening => 'Слушает…';

  @override
  String get assistantTapToStart => 'Нажмите для начала';

  @override
  String get assistantTapToTalk => 'Нажмите для разговора с AI';

  @override
  String get assistantRealtimeDesc =>
      'Ассистент отвечает голосом в реальном времени';

  @override
  String get assistantConnectingToAssistant => 'Подключение к ассистенту...';

  @override
  String get assistantAiSpeaking => 'AI говорит...';

  @override
  String get assistantAiListening => 'AI слушает';

  @override
  String get assistantSpeakerOn => 'Динамик вкл';

  @override
  String get assistantSpeaker => 'Динамик';

  @override
  String get assistantEnd => 'Завершить';

  @override
  String get assistantUnmute => 'Включить';

  @override
  String get assistantMicrophone => 'Микрофон';

  @override
  String get assistantConnectionError => 'Ошибка подключения';

  @override
  String get tabMessenger => 'Сообщения';

  @override
  String get tabCalls => 'Звонки';

  @override
  String get tabCalendar => 'Календарь';

  @override
  String get appearance => 'Оформление';

  @override
  String get appearanceSelect => 'Выбор темы';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeSystem => 'Системная';

  @override
  String get onboardingTitle1 => 'Единая идентификация';

  @override
  String get onboardingDesc1 =>
      'Taler ID — ваш цифровой паспорт в экосистеме Taler. Один аккаунт для всех сервисов.';

  @override
  String get onboardingTitle2 => 'Безопасность данных';

  @override
  String get onboardingDesc2 =>
      'KYC-верификация, AES-256 шифрование и двухфакторная аутентификация защищают вашу личность.';

  @override
  String get onboardingTitle3 => 'Будьте в курсе';

  @override
  String get onboardingDesc3 =>
      'Получайте уведомления о статусе верификации, входах с новых устройств и входящих звонках.';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingEnableNotifications => 'Включить уведомления';

  @override
  String get onboardingTitle4 => 'Голосовые звонки';

  @override
  String get onboardingDesc4 =>
      'Разрешите доступ к микрофону для звонков и AI-ассистента. Вы можете изменить это позже в настройках.';

  @override
  String get onboardingEnableMicrophone => 'Включить микрофон';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get meshLocalNetworkPromptTitle => 'Разрешите доступ к локальной сети';

  @override
  String get meshLocalNetworkPromptBody =>
      'Чтобы видеть собеседников по Wi-Fi (групповые звонки без интернета), iOS требует разрешение Local Network. Откройте Настройки → Конфиденциальность и безопасность → Локальная сеть → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'Открыть настройки';

  @override
  String get meshLocalNetworkPromptDismiss => 'Понятно';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get forgotPasswordTitle => 'Восстановление пароля';

  @override
  String get forgotPasswordSubtitle => 'Введите email для получения кода';

  @override
  String resetCodeSent(String email) {
    return 'Код отправлен на $email';
  }

  @override
  String get enterResetCode => 'Введите код';

  @override
  String get resetPasswordButton => 'Сбросить пароль';

  @override
  String get passwordResetSuccess => 'Пароль успешно изменён';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get resendCode => 'Отправить повторно';

  @override
  String get verifyEmailTitle => 'Подтверждение email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'Отправим 6-значный код на $email.';
  }

  @override
  String verifyEmailCodeSent(String email) {
    return 'Код отправлен на $email. Введите его ниже.';
  }

  @override
  String get verifyEmailSendCode => 'Отправить код';

  @override
  String get verifyEmailConfirm => 'Подтвердить';

  @override
  String get verifyEmailResend => 'Отправить код повторно';

  @override
  String get verifyEmailSuccess => 'Email подтверждён ✓';

  @override
  String get verifyEmailAlreadyVerified => 'Email уже подтверждён';

  @override
  String get verifyEmailBannerTitle => 'Подтвердите email';

  @override
  String get verifyEmailBannerSubtitle =>
      'Нажмите, чтобы получить 6-значный код и подтвердить адрес.';

  @override
  String get newGroup => 'Новая группа';

  @override
  String get newChat => 'Новый чат';

  @override
  String get groupName => 'Название группы';

  @override
  String get createGroup => 'Создать группу';

  @override
  String get groupInfo => 'О группе';

  @override
  String groupMembers(int count) {
    return 'Участники ($count)';
  }

  @override
  String get addMembers => 'Добавить участников';

  @override
  String get leaveGroup => 'Покинуть группу';

  @override
  String get leaveGroupConfirm => 'Покинуть эту группу?';

  @override
  String get deleteGroup => 'Удалить группу';

  @override
  String get deleteGroupConfirm =>
      'Удалить эту группу? Это действие необратимо.';

  @override
  String get groupRoleOwner => 'Владелец';

  @override
  String get groupRoleAdmin => 'Админ';

  @override
  String get groupRoleMember => 'Участник';

  @override
  String get selectParticipants => 'Выберите участников';

  @override
  String selectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get changeRole => 'Изменить роль';

  @override
  String get groupCreated => 'Группа создана';

  @override
  String memberJoined(String name) {
    return '$name присоединился';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name покинул группу';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name удалён';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name теперь $role';
  }

  @override
  String participantsCount(int count) {
    return '$count участников';
  }

  @override
  String get enterGroupName => 'Введите название группы';

  @override
  String get muteNotifications => 'Отключить уведомления';

  @override
  String get unmuteNotifications => 'Включить уведомления';

  @override
  String get muteFor1Hour => 'На 1 час';

  @override
  String get muteFor8Hours => 'На 8 часов';

  @override
  String get muteFor2Days => 'На 2 дня';

  @override
  String get muteForever => 'Навсегда';

  @override
  String get muted => 'Без звука';

  @override
  String get tabTranslator => 'Перевод';

  @override
  String get translatorTitle => 'Переводчик';

  @override
  String get translatorSelectLanguage => 'Выберите язык';

  @override
  String get translatorDownloading => 'Загрузка языковых моделей...';

  @override
  String get translatorDownloadingHint =>
      'Требуется интернет только при первой загрузке';

  @override
  String get translatorTypeHint => 'Введите текст или нажмите микрофон';

  @override
  String get translatorListening => 'Слушаю...';

  @override
  String get translatorTapToSpeak => 'Нажмите для записи';

  @override
  String get translatorTapToStop => 'Нажмите для остановки';

  @override
  String get translatorAutoSpeak => 'Автоозвучка';

  @override
  String get translatorCopied => 'Скопировано';

  @override
  String get translatorLangRu => 'Русский';

  @override
  String get translatorLangEn => 'Английский';

  @override
  String get translatorLangDe => 'Немецкий';

  @override
  String get translatorLangFr => 'Французский';

  @override
  String get translatorLangEs => 'Испанский';

  @override
  String get translatorLangIt => 'Итальянский';

  @override
  String get translatorLangPt => 'Португальский';

  @override
  String get translatorLangTr => 'Турецкий';

  @override
  String get translatorLangZh => 'Китайский';

  @override
  String get translatorLangJa => 'Японский';

  @override
  String get translatorLangKo => 'Корейский';

  @override
  String get translatorLangAr => 'Арабский';

  @override
  String get translatorLangPl => 'Польский';

  @override
  String get translatorLangSk => 'Словацкий';

  @override
  String get translatorLangCs => 'Чешский';

  @override
  String get translatorLangNl => 'Нидерландский';

  @override
  String get translatorLangSv => 'Шведский';

  @override
  String get translatorLangDa => 'Датский';

  @override
  String get translatorLangNo => 'Норвежский';

  @override
  String get translatorLangFi => 'Финский';

  @override
  String get translatorLangUk => 'Украинский';

  @override
  String get translatorLangEl => 'Греческий';

  @override
  String get translatorLangRo => 'Румынский';

  @override
  String get translatorLangHu => 'Венгерский';

  @override
  String get translatorLangBg => 'Болгарский';

  @override
  String get translatorLangHr => 'Хорватский';

  @override
  String get translatorLangSr => 'Сербский';

  @override
  String get translatorLangHi => 'Хинди';

  @override
  String get translatorLangTh => 'Тайский';

  @override
  String get translatorLangVi => 'Вьетнамский';

  @override
  String get translatorLangId => 'Индонезийский';

  @override
  String get translatorLangMs => 'Малайский';

  @override
  String get translatorLangHe => 'Иврит';

  @override
  String get translatorLangFa => 'Фарси';

  @override
  String get callInProgress => 'Идёт звонок';

  @override
  String get joinCall => 'Присоединиться';

  @override
  String get createCallLink => 'Ссылка на звонок';

  @override
  String get callLinkCopied => 'Ссылка скопирована';

  @override
  String get callLinkTitle => 'Ссылка на комнату';

  @override
  String get connectionUnstable =>
      'Соединение нестабильно — проверьте интернет';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get errorTimeout =>
      'Превышено время ожидания. Проверьте подключение к интернету.';

  @override
  String get errorNoConnection => 'Нет подключения к интернету.';

  @override
  String get errorGeneral => 'Произошла ошибка. Попробуйте ещё раз.';

  @override
  String errorWithMessage(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get notifChannelMessages => 'Сообщения';

  @override
  String get notifChannelMessagesDesc => 'Уведомления о новых сообщениях';

  @override
  String get notifChannelMissedCalls => 'Пропущенные звонки';

  @override
  String get notifChannelMissedCallsDesc => 'Уведомления о пропущенных звонках';

  @override
  String get notifMissedCall => 'Пропущенный звонок';

  @override
  String get notifAccept => 'Принять';

  @override
  String get notifDecline => 'Отклонить';

  @override
  String get notifIncomingCall => 'Входящий звонок';

  @override
  String get notifIncomingCallChannel => 'Входящий звонок';

  @override
  String get notifMissedCallChannel => 'Пропущенный звонок';

  @override
  String get notifUnknown => 'Неизвестный';

  @override
  String get effectNone => 'Без фона';

  @override
  String get effectBlur => 'Размытие';

  @override
  String get effectOffice => 'Офис';

  @override
  String get effectNature => 'Природа';

  @override
  String get effectGradient => 'Градиент';

  @override
  String get effectLibrary => 'Библиотека';

  @override
  String get effectCity => 'Город';

  @override
  String get effectMinimalism => 'Минимализм';

  @override
  String get voiceParticipant => 'Участник';

  @override
  String get voiceInvitesToRoom => 'приглашает вас в комнату';

  @override
  String get voiceRoom => 'Комната';

  @override
  String get voicePasswordProtected => 'Защищена паролем';

  @override
  String get voicePasswordHint => 'Пароль';

  @override
  String get voiceEnter => 'Войти';

  @override
  String get voiceJoinRoom => 'Войти в комнату';

  @override
  String get voiceYourName => 'Ваше имя';

  @override
  String voiceInvitationSent(String name) {
    return 'Приглашение отправлено $name';
  }

  @override
  String get voiceNoActiveRoom => 'Нет активной комнаты';

  @override
  String get voiceCameraPermission =>
      'Разрешите доступ к камере в Настройках → Конфиденциальность → Камера → TalerID';

  @override
  String get voiceOpenSettings => 'Открыть';

  @override
  String voiceCameraError(String error) {
    return 'Не удалось включить камеру: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'Все согласились. Запись начата.';

  @override
  String get voiceNewParticipantAgreed =>
      'Новый участник согласился на запись.';

  @override
  String get voiceDeclinedRecording => 'Вы отклонили запись. Покидаете звонок.';

  @override
  String get voiceRecordingEnded => 'Запись завершена';

  @override
  String get voiceRecordingInProgress => 'Запись идёт';

  @override
  String get voiceTranscriptionRequest => 'Запрос на протоколирование';

  @override
  String get voiceRecordingRequest => 'Запрос на запись';

  @override
  String get voiceAgree => 'Согласен';

  @override
  String get voiceDeclineAndLeave => 'Отклонить и выйти';

  @override
  String get voiceAudioOutput => 'Аудиовыход';

  @override
  String get voiceAudioPhone => 'Телефон';

  @override
  String get voiceAudioSpeaker => 'Динамик';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Наушники';

  @override
  String get voiceLinkCopied => 'Ссылка скопирована';

  @override
  String get voiceTranslateTo => 'Переводить на';

  @override
  String get voiceSearchLanguage => 'Поиск языка...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Комната $name';
  }

  @override
  String get voiceVoiceCall => 'Голосовой звонок';

  @override
  String get voiceOnHold => 'На удержании';

  @override
  String get voiceActiveCall => 'Активный';

  @override
  String get voiceEndAllCalls => 'Завершить все';

  @override
  String get voiceEndThisCall => 'Завершить этот звонок';

  @override
  String get voiceCopyLink => 'Скопировать ссылку';

  @override
  String get voiceAddParticipant => 'Добавить участника';

  @override
  String get voiceReconnecting => 'Переподключение...';

  @override
  String get voiceConnectionError => 'Ошибка подключения';

  @override
  String get voiceClose => 'Закрыть';

  @override
  String get voiceCalling => 'Вызов...';

  @override
  String get voiceCallActive => 'Звонок активен';

  @override
  String get voiceWaiting => 'Ожидание';

  @override
  String get voiceWaitingUpper => 'ОЖИДАНИЕ';

  @override
  String get voiceRec => 'REC';

  @override
  String get voiceStop => 'Стоп';

  @override
  String get voiceRecord => 'Запись';

  @override
  String get voiceTranslation => 'Перевод';

  @override
  String get voiceAudio => 'Аудио';

  @override
  String get voiceFlipCamera => 'Повернуть';

  @override
  String get voiceBackground => 'Фон';

  @override
  String get voiceAssistantSpeakingStatus => 'Ассистент говорит...';

  @override
  String get voiceAssistantListeningStatus => 'Ассистент слушает...';

  @override
  String get voiceUnmute => 'Включить';

  @override
  String get voiceMic => 'Микрофон';

  @override
  String get voiceAssistantLabel => 'Ассистент';

  @override
  String get voiceCameraOn => 'Камера вкл.';

  @override
  String get voiceCameraLabel => 'Камера';

  @override
  String get voiceEndCall => 'Завершить';

  @override
  String get voiceWaitingParticipants => 'Ожидание участников...';

  @override
  String get voiceYou => 'Вы';

  @override
  String get voiceChat => 'Чат';

  @override
  String get voiceChatHint => 'Сообщение...';

  @override
  String get voiceChatEmpty => 'Пока никто ничего не написал';

  @override
  String get voiceChatSend => 'Отправить';

  @override
  String get voiceAiAssistant => 'AI Ассистент';

  @override
  String get voiceVideoUnavailable => 'Видео недоступно';

  @override
  String get voiceSearchNickname => 'Поиск по никнейму...';

  @override
  String get voiceTranscriptionWord => 'протоколирование';

  @override
  String get voiceRecordingWord => 'запись';

  @override
  String get voiceConnecting => 'Подключение...';

  @override
  String get voiceVideoBackground => 'Фон видео';

  @override
  String get voiceCallSettings => 'Параметры звонка';

  @override
  String get voiceEnableAI => 'Подключить AI ассистента';

  @override
  String get voiceAIParticipating => 'AI будет участвовать в разговоре';

  @override
  String get voiceNormalCall => 'Обычный звонок без AI';

  @override
  String get voiceCallConfirm => 'Позвонить?';

  @override
  String get chatAlreadyInCall => 'Уже идёт звонок';

  @override
  String chatCallError(String error) {
    return 'Ошибка звонка: $error';
  }

  @override
  String get chatPhotoVideo => 'Фото / Видео';

  @override
  String get chatCamera => 'Камера';

  @override
  String get chatFile => 'Файл';

  @override
  String get chatContact => 'Контакт';

  @override
  String get chatSelectContact => 'Выберите контакт';

  @override
  String get chatNoContacts => 'Нет контактов';

  @override
  String get chatUser => 'Пользователь';

  @override
  String get chatFileAttachment => '📎 Файл';

  @override
  String chatFileUploadError(String error) {
    return 'Ошибка загрузки файла: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Голосовое сообщение';

  @override
  String get chatGroup => 'Группа';

  @override
  String get chatDialog => 'Диалог';

  @override
  String get chatCall => 'Позвонить';

  @override
  String get chatStartConversation => 'Начните переписку';

  @override
  String get chatYou => 'Вы';

  @override
  String get chatIsTyping => 'печатает...';

  @override
  String chatUserIsTyping(String name) {
    return '$name печатает...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names печатают...';
  }

  @override
  String get chatPreparingFile => 'Подготовка файла…';

  @override
  String chatUploading(int progress) {
    return 'Загрузка… $progress%';
  }

  @override
  String get chatEdited => 'Отредактировано';

  @override
  String get chatViaMesh => 'через mesh';

  @override
  String get chatReply => 'Ответить';

  @override
  String get chatEdit => 'Редактировать';

  @override
  String get chatCopy => 'Копировать';

  @override
  String get chatCopied => 'Скопировано';

  @override
  String get chatSaveMedia => 'Сохранить';

  @override
  String get chatForward => 'Переслать';

  @override
  String get chatSaving => 'Сохранение...';

  @override
  String get chatSavedToGallery => 'Сохранено в галерею';

  @override
  String get chatNoSavePermission =>
      'Нет разрешения на сохранение. Проверьте настройки.';

  @override
  String get chatFileSaved => 'Файл сохранён';

  @override
  String get chatFileSaveError => 'Ошибка сохранения файла';

  @override
  String get chatDeleteMessage => 'Удалить сообщение';

  @override
  String get chatDeleteForMe => 'Удалить у меня';

  @override
  String get chatDeleteForEveryone => 'Удалить у всех';

  @override
  String get chatMessageForwarded => 'Сообщение переслано';

  @override
  String get chatContactTapToOpen => 'Контакт · нажмите чтобы открыть';

  @override
  String get chatForwardTo => 'Переслать в...';

  @override
  String get chatSearchHint => 'Поиск...';

  @override
  String get chatRecording => 'Запись...';

  @override
  String get chatMessageHint => 'Сообщение...';

  @override
  String get chatHideKeyboard => 'Скрыть клавиатуру';

  @override
  String get chatEditing => 'Редактирование';

  @override
  String get chatFileDownloadError => 'Ошибка загрузки файла';

  @override
  String get chatVoiceMessageShort => 'Голосовое сообщение';

  @override
  String get chatVideoSavedToGallery => 'Видео сохранено в галерею';

  @override
  String get chatSavingError => 'Ошибка сохранения';

  @override
  String get convSetNickname => 'Задайте никнейм';

  @override
  String get convNicknameRequired =>
      'Никнейм обязателен для использования мессенджера. Другие пользователи смогут найти вас по нему.';

  @override
  String get convNicknameRules => '3–30 символов: буквы, цифры, _';

  @override
  String get convNicknameTaken => 'Никнейм уже занят';

  @override
  String get convSaveError => 'Ошибка сохранения';

  @override
  String get convContactsLabel => 'Контакты';

  @override
  String get convDefaultUser => 'Пользователь';

  @override
  String get convNoDialogs => 'Нет диалогов';

  @override
  String get convFindUserToChat =>
      'Найдите пользователя чтобы начать переписку';

  @override
  String get convDefaultContact => 'Контакт';

  @override
  String get dashboardUser => 'Пользователь';

  @override
  String get dashboardIncomingCall => 'Входящий звонок';

  @override
  String get dashboardDecline => 'Отклонить';

  @override
  String get dashboardAccept => 'Принять';

  @override
  String get dashboardActiveCall =>
      'Активный звонок — нажмите, чтобы вернуться';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Доступно обновление $version';
  }

  @override
  String get dashboardUpdate => 'Обновить';

  @override
  String get dashboardWhatsNew => 'Что нового';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'Что нового в $version';
  }

  @override
  String get dashboardInstalling => 'Устанавливается...';

  @override
  String get updateInstallConflictTitle => 'Не удалось обновить поверх';

  @override
  String updateInstallConflictBody(String filename) {
    return 'Установленная версия подписана другим сертификатом, поэтому Android отказывается её обновить. Удали приложение через Настройки → Приложения → Taler ID, затем открой папку «Загрузки» в файловом менеджере и тапни по $filename чтобы установить заново. Этот шаг нужен один раз.';
  }

  @override
  String get updateInstallFailedTitle => 'Установка не удалась';

  @override
  String updateInstallFailedBody(String reason, String filename) {
    return '$reason\n\nAPK сохранён в папку «Загрузки» как $filename — можно попробовать установить вручную из файлового менеджера.';
  }

  @override
  String get updateInstallOk => 'Понятно';

  @override
  String get contactRequestsTitle => 'Контакты';

  @override
  String get messengerContactRequestsSection => 'Заявки в контакты';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count новых заявок',
      many: '$count новых заявок',
      few: '$count новые заявки',
      one: '1 новая заявка',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Поиск';

  @override
  String get contactRequestsIncoming => 'Входящие';

  @override
  String get contactRequestsSent => 'Отправленные';

  @override
  String get contactRequestsSearchHint => 'Никнейм или email';

  @override
  String get contactRequestSent => 'Запрос отправлен';

  @override
  String get contactRequestsNoUsers => 'Пользователи не найдены';

  @override
  String get contactRequestsSearchHelp =>
      'Введите точный никнейм или email\nи нажмите поиск';

  @override
  String get contactRequestsSendTooltip => 'Отправить запрос';

  @override
  String get contactRequestTitle => 'Запрос на общение';

  @override
  String contactRequestConfirm(String name) {
    return 'Отправить запрос на общение пользователю $name?';
  }

  @override
  String get contactRequestSend => 'Отправить';

  @override
  String get contactRequestsNoIncoming => 'Нет входящих запросов';

  @override
  String get contactRequestsNoSent => 'Нет отправленных запросов';

  @override
  String get contactRequestStatusPending => 'Ожидает ответа';

  @override
  String get contactRequestStatusAccepted => 'Принят';

  @override
  String get contactRequestStatusRejected => 'Отклонён';

  @override
  String get userSearchTitle => 'Найти пользователя';

  @override
  String get userSearchHint => 'Никнейм, телефон или email';

  @override
  String get userSearchHelper => 'Введите @никнейм, email или имя для поиска';

  @override
  String get userSearchNoUsers => 'Пользователи не найдены';

  @override
  String get userProfileShareContact => 'Поделиться контактом';

  @override
  String get userProfileShareContactDesc => 'Отправить ссылку на контакт';

  @override
  String get userProfileCopyLink => 'Скопировать ссылку';

  @override
  String get userProfileCopied => 'Скопировано';

  @override
  String get userProfileTitle => 'Профиль';

  @override
  String get userProfileLoadError => 'Ошибка загрузки профиля';

  @override
  String get userProfileMessage => 'Написать';

  @override
  String get userProfileCall => 'Позвонить';

  @override
  String get userProfileRequestSent => 'Запрос отправлен';

  @override
  String get userProfileAccept => 'Принять';

  @override
  String get userProfileDecline => 'Отклонить';

  @override
  String get userProfileAddToContacts => 'Добавить в контакты';

  @override
  String get userProfileMediaTab => 'Медиа';

  @override
  String get userProfileFilesTab => 'Файлы';

  @override
  String get userProfileLinksTab => 'Ссылки';

  @override
  String get userProfileRecordingsTab => 'Записи';

  @override
  String get userProfileSummariesTab => 'Резюме';

  @override
  String get userProfileNoMedia => 'Нет медиафайлов';

  @override
  String get userProfileNoFiles => 'Нет файлов';

  @override
  String get userProfileNoLinks => 'Нет ссылок';

  @override
  String get userProfileNoRecordings => 'Нет записей';

  @override
  String get userProfileNoSummaries => 'Нет резюме';

  @override
  String get userProfileMeetingSummary => 'Резюме встречи';

  @override
  String get userProfileFailedOpenChat => 'Не удалось открыть чат';

  @override
  String get sharedMediaTitle => 'Медиа и файлы';

  @override
  String get sharedMediaTab => 'Медиа';

  @override
  String get sharedFilesTab => 'Файлы';

  @override
  String get sharedLinksTab => 'Ссылки';

  @override
  String get sharedNoMedia => 'Нет медиафайлов';

  @override
  String get sharedNoFiles => 'Нет файлов';

  @override
  String get sharedNoLinks => 'Нет ссылок';

  @override
  String get shareToChat => 'Переслать в чат';

  @override
  String get shareSelectChat => 'Выберите чат';

  @override
  String get shareNoChats => 'Нет чатов';

  @override
  String shareFilesCount(int count) {
    return '$count файлов';
  }

  @override
  String get contactsTitle => 'Контакты';

  @override
  String get contactsAddTooltip => 'Добавить контакт';

  @override
  String get contactsSearchHint => 'Поиск контактов...';

  @override
  String get contactsNotFound => 'Ничего не найдено';

  @override
  String get contactsEmpty => 'Нет контактов';

  @override
  String get contactsAdd => 'Добавить контакт';

  @override
  String get contactsPendingConfirmation => 'Ожидает подтверждения';

  @override
  String get contactsMessage => 'Написать';

  @override
  String get contactsCall => 'Позвонить';

  @override
  String get contactsResend => 'Отправить повторно';

  @override
  String get contactsResendTimeout => 'Повтор через 24ч';

  @override
  String get contactsResent => 'Запрос отправлен повторно';

  @override
  String get contactsWantsToConnect => 'Хочет добавить вас в контакты';

  @override
  String get contactsSearchPeople => 'Найти людей';

  @override
  String get notesTitle => 'Заметки';

  @override
  String get notesAssistantSpeaking => 'Ассистент говорит...';

  @override
  String get notesListening => 'Слушаю...';

  @override
  String get notesEmpty => 'Нет заметок';

  @override
  String get notesEmptyHint =>
      'Нажмите микрофон для диктовки\nили + для ручного ввода';

  @override
  String get notesDeleteConfirm => 'Удалить заметку?';

  @override
  String get notesNew => 'Новая заметка';

  @override
  String get notesEdit => 'Редактировать';

  @override
  String get notesTitleHint => 'Заголовок';

  @override
  String get notesContentHint => 'Запишите свои мысли...';

  @override
  String get calendarTitle => 'Календарь';

  @override
  String get calendarStop => 'Остановить';

  @override
  String get calendarVoiceInput => 'Голосовой ввод';

  @override
  String get calendarNewEvent => 'Новое событие';

  @override
  String get calendarAssistantSpeaking => 'Ассистент говорит...';

  @override
  String get calendarListening => 'Слушаю...';

  @override
  String calendarInvitations(int count) {
    return 'Приглашения ($count)';
  }

  @override
  String get calendarNoEvents => 'Нет событий';

  @override
  String get calendarDayMon => 'Пн';

  @override
  String get calendarDayTue => 'Вт';

  @override
  String get calendarDayWed => 'Ср';

  @override
  String get calendarDayThu => 'Чт';

  @override
  String get calendarDayFri => 'Пт';

  @override
  String get calendarDaySat => 'Сб';

  @override
  String get calendarDaySun => 'Вс';

  @override
  String get calendarEnterRoom => 'Войти в комнату';

  @override
  String get calendarMeeting => 'Встреча';

  @override
  String calendarLocationPrefix(String location) {
    return 'Место: $location';
  }

  @override
  String get calendarEditEvent => 'Редактировать';

  @override
  String get calendarTitleHint => 'Название';

  @override
  String get calendarDescriptionHint => 'Описание';

  @override
  String get calendarTypeEvent => 'Событие';

  @override
  String get calendarTypeMeeting => 'Встреча';

  @override
  String get calendarTypeReminder => 'Напоминание';

  @override
  String get calendarKindEvent => 'Событие';

  @override
  String get calendarKindTask => 'Задача';

  @override
  String get calendarTaskMarkDone => 'Отметить выполненной';

  @override
  String get calendarTaskDelete => 'Удалить';

  @override
  String get calendarTaskDoneMsg => 'Задача выполнена';

  @override
  String get calendarTaskDeletedMsg => 'Задача удалена';

  @override
  String get calendarTypeLabel => 'Тип';

  @override
  String get calendarMeetingLink => 'Ссылка на встречу';

  @override
  String get calendarLocationHint => 'Место';

  @override
  String get calendarDateLabel => 'Дата';

  @override
  String get calendarTimeLabel => 'Время';

  @override
  String get calendarReminderLabel => 'Напоминание';

  @override
  String get calendarReminderNone => 'Нет';

  @override
  String get calendarReminder15min => 'За 15 мин';

  @override
  String get calendarReminder30min => 'За 30 мин';

  @override
  String get calendarReminder1hour => 'За 1 час';

  @override
  String get calendarRepeatLabel => 'Повторение';

  @override
  String get calendarRepeatNone => 'Не повторять';

  @override
  String get calendarRepeatDaily => 'Каждый день';

  @override
  String get calendarRepeatWeekly => 'Каждую неделю';

  @override
  String get calendarRepeatMonthly => 'Каждый месяц';

  @override
  String get calendarRepeatYearly => 'Каждый год';

  @override
  String get calendarParticipants => 'Участники';

  @override
  String get calendarAddParticipant => 'Добавить';

  @override
  String get calendarSearchContacts => 'Поиск контактов...';

  @override
  String get calendarNoContacts => 'Нет контактов';

  @override
  String get calendarStatusAccepted => 'Подтвердил';

  @override
  String get calendarStatusDeclined => 'Отказался';

  @override
  String get calendarStatusMaybe => 'Под вопросом';

  @override
  String get calendarStatusPending => 'Ожидает';

  @override
  String get calendarEndTime => 'Окончание';

  @override
  String get calendarYourAnswer => 'Ваш ответ:';

  @override
  String get calendarOrganizer => 'Организатор';

  @override
  String calendarDeleteError(String error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get calendarRsvpAccept => 'Принять';

  @override
  String get calendarRsvpMaybe => 'Возможно';

  @override
  String get calendarRsvpDecline => 'Отказ';

  @override
  String get callHistoryTitle => 'Звонки';

  @override
  String get callHistoryTab => 'История звонков';

  @override
  String get callHistoryTempMeeting => 'Временная встреча';

  @override
  String get callHistoryCopy => 'Скопировать';

  @override
  String get callHistoryLinkCopied => 'Ссылка скопирована';

  @override
  String get callHistoryShare => 'Поделиться';

  @override
  String get callHistoryEnter => 'Войти';

  @override
  String get callHistoryAlreadyInCall => 'Уже идёт звонок';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'Не удалось определить собеседника';

  @override
  String get callHistoryContacts => 'Контакты';

  @override
  String get callHistoryFailedLoadRoom => 'Не удалось загрузить вашу комнату';

  @override
  String get callHistoryYourRoom => 'Ваша комната';

  @override
  String get callHistoryCreateMeeting => 'Создать встречу';

  @override
  String get callHistoryMeetingSummaries => 'Резюме встреч';

  @override
  String get callHistoryMeetingRecordings => 'Записи встреч';

  @override
  String get callHistoryNoCalls => 'Нет звонков';

  @override
  String get callHistoryMissed => 'Пропущенный';

  @override
  String get callHistoryRecording => 'Запись';

  @override
  String get callHistorySummary => 'Резюме';

  @override
  String get callHistoryCallAgain => 'Позвонить снова';

  @override
  String callHistoryTodayTime(String time) {
    return 'Сегодня, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Вчера, $time';
  }

  @override
  String get callHistoryUnknown => 'Неизвестный';

  @override
  String get callHistoryDetails => 'Детали звонка';

  @override
  String get callHistoryOutgoing => 'Исходящий звонок';

  @override
  String get callHistoryIncoming => 'Входящий звонок';

  @override
  String callHistoryDuration(String duration) {
    return 'Длительность: $duration';
  }

  @override
  String get callHistoryWithAI => 'С AI-ассистентом';

  @override
  String get callHistoryParticipants => 'Участники';

  @override
  String get callDetailYouSuffix => '(Вы)';

  @override
  String get callHistoryMeetingSummary => 'Резюме встречи';

  @override
  String get callHistoryMoreDetails => 'Подробнее';

  @override
  String get callHistorySummaryProcessing => 'Резюме обрабатывается...';

  @override
  String get callHistoryMeetingRecording => 'Запись встречи';

  @override
  String get callHistoryProcessing => 'Обработка...';

  @override
  String get callHistoryCreateTranscript => 'Создать протокол';

  @override
  String get callHistoryNoSummaries => 'Нет резюме';

  @override
  String get callHistoryRecordDuringCall =>
      'Нажмите \"Запись\" во время звонка';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Встреча $time';
  }

  @override
  String get callHistoryTranscribing => 'Транскрибация и суммаризация...';

  @override
  String get callHistoryTranscriptCreated => 'Протокол создан';

  @override
  String get callHistoryNoRecordings => 'Нет записей';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Запись $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Запись недоступна';

  @override
  String get callHistoryTranscriptReady => 'Протокол готов';

  @override
  String get callHistoryTranscript => 'Протокол';

  @override
  String get callHistoryKeyPoints => 'Ключевые моменты';

  @override
  String get callHistoryTasks => 'Задачи';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'Ответственный: $assignee';
  }

  @override
  String get callHistoryDecisions => 'Принятые решения';

  @override
  String get callHistoryShowTranscript => 'Показать полный транскрипт';

  @override
  String get profileScanQr => 'Сканировать QR';

  @override
  String get profileMyQrCode => 'Мой QR код';

  @override
  String profileAddMeShare(String userId) {
    return 'Добавь меня в Taler ID!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Покажи этот код, чтобы добавить тебя';

  @override
  String get profileEditDesc => 'Имя, фамилия, отчество, дата рождения';

  @override
  String get profileAboutMe => 'О себе';

  @override
  String get profileAboutMeDesc => 'Ценности, навыки, интересы и другое';

  @override
  String get profileNotes => 'Заметки';

  @override
  String get profileNotesDesc => 'Мысли, идеи и записи';

  @override
  String get profileAvatarUpdated => 'Аватар обновлён';

  @override
  String get profileNickname => 'Никнейм';

  @override
  String get profileNotSet => 'Не задан';

  @override
  String get profileChangeNickname => 'Изменить никнейм';

  @override
  String get profileNicknameUpdated => 'Никнейм обновлён';

  @override
  String get profileShareLabel => 'Поделиться';

  @override
  String get profileScanQrCode => 'Сканировать QR код';

  @override
  String get profilePointCamera => 'Наведите камеру на QR код';

  @override
  String get profilePhotoCamera => 'Сделать фото';

  @override
  String get profilePhotoGallery => 'Выбрать из галереи';

  @override
  String get editProfilePatronymic => 'Отчество (опционально)';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => 'О себе';

  @override
  String get aboutMeClickToFill => 'Нажмите, чтобы заполнить';

  @override
  String get aboutMeCoreValues => 'Ценности';

  @override
  String get aboutMeWorldview => 'Видение мира';

  @override
  String get aboutMeSkills => 'Навыки';

  @override
  String get aboutMeInterests => 'Интересы';

  @override
  String get aboutMeDesires => 'Желания';

  @override
  String get aboutMeBackground => 'Профиль';

  @override
  String get aboutMeLikes => 'Нравится';

  @override
  String get aboutMeDislikes => 'Не нравится';

  @override
  String get aboutMeDeleteSection => 'Удалить раздел?';

  @override
  String get aboutMeDeleteConfirm => 'Все данные этого раздела будут удалены.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Ошибка подключения: $error';
  }

  @override
  String get aboutMeVisibility => 'Видимость';

  @override
  String get aboutMeTags => 'Теги';

  @override
  String get aboutMeAddTag => 'Добавить тег...';

  @override
  String get aboutMeDescription => 'Описание';

  @override
  String get aboutMeDescribeLong => 'Расскажите подробнее...';

  @override
  String get aboutMeVisibilityEveryone => 'Все';

  @override
  String get aboutMeVisibilityContacts => 'Контакты';

  @override
  String get aboutMeVisibilityOnlyMe => 'Только я';

  @override
  String get settingsProfileSubtitle => 'Профиль';

  @override
  String get settingsWallpaper => 'Обои';

  @override
  String get settingsWallpaperDesc =>
      'Фоновое изображение для всего приложения';

  @override
  String get settingsWallpaperNone => 'Без обоев';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get settingsKycVerification => 'Верификация личности (KYC)';

  @override
  String get settingsOrganizations => 'Организации';

  @override
  String get incomingCallLabel => 'Входящий звонок';

  @override
  String get incomingCallDecline => 'Отклонить';

  @override
  String get incomingCallAccept => 'Принять';

  @override
  String callGlareTitle(String name) {
    return '$name тоже звонит вам';
  }

  @override
  String get callGlareBody =>
      'Вы набрали друг друга одновременно. Принять его звонок или остаться на своём?';

  @override
  String get callGlareSwitch => 'Принять его';

  @override
  String get callGlareKeepOwn => 'Остаться на своём';

  @override
  String get meshIncomingCallLabel => '📡 Входящий mesh-звонок';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'Mesh-устройство $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'Завершите текущий звонок';

  @override
  String get callPopupTransportTitle => 'Способ звонка';

  @override
  String get callPopupTransportMesh => '📡 По сети (mesh)';

  @override
  String get callPopupTransportLk => '📞 Через сервер';

  @override
  String get callPopupTransportMeshUnavailable =>
      'Контакт не доступен через mesh';

  @override
  String get meshOnboardingTitle =>
      '📡 Mesh-звонки требуют активного приложения';

  @override
  String get meshOnboardingBody =>
      'Когда телефон заблокирован, mesh-звонки могут прерываться через ~30 секунд (iOS ограничение).';

  @override
  String get meshOnboardingAck => 'Понятно';

  @override
  String get meshHistoryBadge => '📡 Mesh';

  @override
  String get meshHistoryNoChatAvailable => 'Контакт не в списке';

  @override
  String get meshCallStatusInviting => 'Вызов…';

  @override
  String get meshCallStatusConnecting => 'Соединение…';

  @override
  String get meshCallEndedUserHangup => 'Звонок завершён';

  @override
  String get meshCallEndedRemoteHangup => 'Завершён собеседником';

  @override
  String get meshCallEndedRejected => 'Отклонён';

  @override
  String get meshCallEndedNoAnswer => 'Не отвечает';

  @override
  String get meshCallEndedConnectionLost => 'Соединение потеряно';

  @override
  String get meshCallEndedError => 'Ошибка соединения';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 Mesh · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 Mesh';

  @override
  String get batteryExemptionTitle => '📡 Бесперебойные mesh-звонки';

  @override
  String get batteryExemptionBody =>
      'Чтобы Android не убивал mesh-сеть в фоне, разреши приложению работать без ограничений батареи.';

  @override
  String get batteryExemptionAccept => 'Открыть настройки';

  @override
  String get batteryExemptionDismiss => 'Не сейчас';

  @override
  String get groupCamera => 'Камера';

  @override
  String get groupGallery => 'Галерея';

  @override
  String get groupAvatarUpdated => 'Аватар группы обновлён';

  @override
  String get groupNameTitle => 'Название группы';

  @override
  String get groupEnterName => 'Введите название';

  @override
  String get groupDescriptionTitle => 'Описание группы';

  @override
  String get groupEnterDescription => 'Введите описание группы';

  @override
  String get groupChangeRoleTitle => 'Изменить роль';

  @override
  String get groupRemoveMemberTitle => 'Удалить участника';

  @override
  String get groupDescription => 'Описание';

  @override
  String get groupAddDescription => 'Добавить описание группы';

  @override
  String get groupNoDescription => 'Нет описания';

  @override
  String get groupMediaAndFiles => 'Медиа и файлы';

  @override
  String get groupMuteNotifications => 'Отключить уведомления';

  @override
  String get groupMuted => 'Отключено';

  @override
  String get groupNoResults => 'Нет результатов';

  @override
  String get authInvalidCode => 'Неверный код. Попробуйте ещё раз.';

  @override
  String get loginSubtitle => 'Используйте email и пароль';

  @override
  String get emailRequired => 'Введите email';

  @override
  String get emailInvalid => 'Некорректный email';

  @override
  String get passwordRequired => 'Введите пароль';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get registerSubtitle => 'Один аккаунт для всей экосистемы Taler';

  @override
  String get usernameOptional => 'Никнейм (необязательно)';

  @override
  String get usernameMinLength => 'Минимум 3 символа';

  @override
  String get usernameMaxLength => 'Максимум 30 символов';

  @override
  String get usernameInvalid => 'Только буквы, цифры и _';

  @override
  String get biometricLoginReason => 'Войдите в Taler ID';

  @override
  String get docTypePassport => 'Паспорт';

  @override
  String get docTypeIdCard => 'ID-карта';

  @override
  String get docTypeDriverLicense => 'Водительское удостоверение';

  @override
  String get docTypeResidencePermit => 'Вид на жительство';

  @override
  String addressApartment(String number) {
    return 'кв. $number';
  }

  @override
  String get failedToUpdateProfile => 'Не удалось обновить профиль';

  @override
  String get failedToStartKyb => 'Не удалось запустить KYB-верификацию';

  @override
  String get orgUpdated => 'Организация обновлена';

  @override
  String get failedToUpdateOrg => 'Не удалось обновить организацию';

  @override
  String get failedToChangeRole => 'Не удалось изменить роль';

  @override
  String get failedToRemoveMember => 'Не удалось удалить участника';

  @override
  String get capabilityMessagesTitle => 'Сообщения';

  @override
  String get capabilityMessagesDesc =>
      'Проверь сообщения или напиши кому-нибудь. Например: \"Напиши Виктору: буду через час\"';

  @override
  String get capabilityCallsTitle => 'Звонки';

  @override
  String get capabilityCallsDesc =>
      'Позвони любому контакту голосом. Например: \"Позвони Виктору Викторову\"';

  @override
  String get capabilityChatTitle => 'Переписка';

  @override
  String get capabilityChatDesc =>
      'Проанализирую историю чата. Например: \"Что мы обсуждали с Виктором?\"';

  @override
  String get capabilityProfileTitle => 'Профиль';

  @override
  String get capabilityProfileDesc =>
      'Покажу или обновлю твой профиль. Например: \"Покажи мой профиль\"';

  @override
  String get capabilityCoachingTitle => 'Коучинг';

  @override
  String get capabilityCoachingDesc =>
      'Режимы: коучинг ICF, психолог, HR-консультация. Скажи: \"Давай коучинг\"';

  @override
  String get capabilityCalendarTitle => 'Календарь';

  @override
  String get capabilityCalendarDesc =>
      'Запланируй встречу или поставь напоминание. Например: \"Поставь встречу с Виктором на завтра в 15:00\"';

  @override
  String get capabilityNotesTitle => 'Заметки';

  @override
  String get capabilityNotesDesc =>
      'Сохрани мысль или прочитай последние заметки. Например: \"Запиши идею...\" или \"Прочитай последние заметки\"';

  @override
  String get assistantCallConfirm => 'Позвонить?';

  @override
  String get callNoAnswer => 'Нет ответа';

  @override
  String get contactDelete => 'Удалить контакт';

  @override
  String get contactDeleteTitle => 'Удалить контакт';

  @override
  String get contactDeleteConfirm => 'Вы уверены? Контакт будет удалён.';

  @override
  String get contactBlock => 'Заблокировать';

  @override
  String get contactBlockTitle => 'Заблокировать пользователя';

  @override
  String get contactBlockConfirm =>
      'Пользователь не сможет писать вам и звонить.';

  @override
  String get contactUnblock => 'Разблокировать';

  @override
  String get contactBlocked => 'Заблокирован';

  @override
  String get contactYouAreBlocked => 'Этот пользователь вас заблокировал';

  @override
  String get chatBlockedByYou => 'Вы заблокировали этого пользователя';

  @override
  String get chatYouAreBlocked => 'Вы заблокированы этим пользователем';

  @override
  String get chatNotContacts =>
      'Добавьте пользователя в контакты, чтобы писать';

  @override
  String get contactRevokeRequest => 'Отозвать запрос';

  @override
  String get messengerPoll => 'Опрос';

  @override
  String get messengerCreatePoll => 'Создать опрос';

  @override
  String get messengerPollQuestion => 'Вопрос';

  @override
  String messengerPollOption(int number) {
    return 'Вариант $number';
  }

  @override
  String get messengerPollAddOption => 'Добавить вариант';

  @override
  String get messengerPollAnonymous => 'Анонимное голосование';

  @override
  String get messengerPollMultiple => 'Несколько вариантов';

  @override
  String get messengerPollCreateError => 'Ошибка создания опроса';

  @override
  String get messengerPollUnavailable => 'Опрос недоступен';

  @override
  String get messengerPollMultipleNote => 'Можно выбрать несколько';

  @override
  String messengerPollVotes(int count) {
    return '$count голосов';
  }

  @override
  String get messengerVideoMessage => 'Видеосообщение';

  @override
  String get messengerVideoRecordError => 'Ошибка записи видео';

  @override
  String get messengerVideoPlaybackError => 'Не удалось воспроизвести видео';

  @override
  String get messengerGalleryAccessError => 'Нет доступа к галерее';

  @override
  String get messengerSearchInChat => 'Поиск в чате...';

  @override
  String get messengerSaveToFavorites => 'В избранное';

  @override
  String get messengerSavedToFavorites => 'Сохранено в избранное';

  @override
  String get messengerSearchInMessages => 'Поиск в сообщениях...';

  @override
  String messengerFoundInMessages(int count) {
    return 'Найдено в сообщениях ($count)';
  }

  @override
  String get messengerGroupDefault => 'Группа';

  @override
  String get messengerUserDefault => 'Пользователь';

  @override
  String get messengerPin => 'Закрепить';

  @override
  String get messengerUnpin => 'Открепить';

  @override
  String get messengerArchive => 'Архивировать';

  @override
  String get messengerUnarchive => 'Разархивировать';

  @override
  String get messengerDeleteChat => 'Удалить чат';

  @override
  String get messengerDeleteChatTitle => 'Удалить чат?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'Удалить чат с $name? Это действие нельзя отменить.';
  }

  @override
  String get messengerCreateChannel => 'Создать канал';

  @override
  String get messengerChannelName => 'Название';

  @override
  String get messengerChannelDescription => 'Описание (необязательно)';

  @override
  String get messengerChannelCreateError => 'Ошибка создания канала';

  @override
  String get messengerFilterAll => 'Все';

  @override
  String get messengerFilterUnread => 'Непрочитанные';

  @override
  String get messengerFilterPersonal => 'Личные';

  @override
  String get messengerFilterGroups => 'Группы';

  @override
  String get messengerFilterChannels => 'Каналы';

  @override
  String get messengerArchivedSection => 'Архивировано';

  @override
  String get messengerSavedSection => 'Избранное';

  @override
  String get messengerSavedSubtitle => 'Сохранить в память';

  @override
  String messengerArchiveTitle(int count) {
    return 'Архив ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'Архив пуст';

  @override
  String messengerYouPrefix(String message) {
    return 'Вы: $message';
  }

  @override
  String get messengerMissedCall => 'Пропущенный звонок';

  @override
  String get messengerSavedTitle => 'Избранное';

  @override
  String get messengerNoSavedMessages => 'Нет сохранённых сообщений';

  @override
  String get messengerSavedHint => 'Зажмите сообщение → \"В избранное\"';

  @override
  String get messengerDefaultFile => 'Файл';

  @override
  String get messengerTopicDefault => 'Общая';

  @override
  String get messengerTopicNew => 'Новая тема';

  @override
  String get messengerTopicNameHint => 'Название темы';

  @override
  String get messengerTopicIcon => 'Иконка';

  @override
  String messengerTopicCount(int count) {
    return '$count тем';
  }

  @override
  String get messengerNoTopics => 'Нет тем';

  @override
  String get messengerNoMessages => 'Нет сообщений';

  @override
  String get you => 'Вы';

  @override
  String get messengerThread => 'Тред';

  @override
  String get messengerThreadReply => 'ответ';

  @override
  String get messengerThreadReplies => 'ответов';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'Нет ответов';

  @override
  String get messengerReplyHint => 'Ответить в тред...';

  @override
  String get messengerContactName => 'Имя контакта';

  @override
  String messengerOriginalName(String name) {
    return 'Оригинальное имя: $name';
  }

  @override
  String get messengerDisplayName => 'Отображаемое имя';

  @override
  String messengerShareContact(String name) {
    return 'Контакт в Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'Авто-удаление сообщений';

  @override
  String get messengerAutoDeleteOff => 'Выключено';

  @override
  String get messengerAutoDelete7d => '7 дней';

  @override
  String get messengerAutoDelete30d => '30 дней';

  @override
  String get messengerAutoDelete90d => '90 дней';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count дней';
  }

  @override
  String get messengerSettingsHeader => 'Настройки';

  @override
  String get messengerAdminOnly => 'Только админы пишут';

  @override
  String get messengerAdminOnlyDesc => 'Участники могут только читать';

  @override
  String get messengerTopics => 'Темы';

  @override
  String get messengerTopicsDesc => 'Разделить чат на темы';

  @override
  String get aiTwinSection => 'Голосовой двойник';

  @override
  String get aiTwinEnabled => 'Включить AI-двойника';

  @override
  String get aiTwinEnabledDesc =>
      'Если вы не ответите на звонок, AI-двойник примет его вашим голосом';

  @override
  String get aiTwinTimeout => 'Время ожидания';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds сек';
  }

  @override
  String get aiTwinPrompt => 'Инструкция для AI';

  @override
  String get aiTwinPromptSubtitle =>
      'Как AI-двойник должен представляться и о чём говорить';

  @override
  String aiTwinPromptHint(String name) {
    return 'Привет, это голосовой двойник $name. $name сейчас не смог ответить. Расскажите, кто звонит и по какому вопросу — я обязательно передам.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Ваш персональный голос появится позже. Сейчас AI говорит голосом $name.';
  }

  @override
  String get aiTwinDefaultName => 'владельца';

  @override
  String get aiTwinPromptReset => 'Сбросить';

  @override
  String get callHistoryAiTwinAnswered => 'AI-ДВОЙНИК ОТВЕТИЛ';

  @override
  String get callHistoryAiTwinSummary => 'СУТЬ РАЗГОВОРА';

  @override
  String get callHistoryAiTwinTranscript => 'РАСШИФРОВКА';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'От $name';
  }

  @override
  String get aiTwinOfferTitle => 'Не отвечает';

  @override
  String aiTwinOfferBody(String name) {
    return '$name не успевает ответить. Оставить сообщение голосовому двойнику?';
  }

  @override
  String get aiTwinOfferBodyUser => 'Пользователь';

  @override
  String get aiTwinOfferAccept => 'Да, оставить';

  @override
  String get aiTwinOfferKeepWaiting => 'Ждать ответа';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'Ваш ИИ-заместитель';

  @override
  String get aiTwinHeroSubtitle =>
      'Он ответит на звонок вашим голосом, если вы заняты.';

  @override
  String get aiTwinProfileTitle => 'ИИ-заместитель';

  @override
  String get aiTwinProfileDesc => 'Отвечает на звонки вашим голосом';

  @override
  String get aiTwinBadgeOn => 'ВКЛ';

  @override
  String get aiAnalystTitle => 'AI Аналитик';

  @override
  String get aiAnalystSubtitle => 'Файлы, задачи, анализ — Claude';

  @override
  String get channelsDiscover => 'Найти канал';

  @override
  String get channelsSearchHint => 'Поиск каналов';

  @override
  String get channelsSubscribers => 'подписчиков';

  @override
  String get channelsSubscribe => 'Подписаться';

  @override
  String get channelsUnsubscribe => 'Отписаться';

  @override
  String get channelsSubscribedLabel => 'Вы подписаны на канал';

  @override
  String get channelsSettings => 'Настройки канала';

  @override
  String get channelsDelete => 'Удалить канал';

  @override
  String get channelsDeleteConfirm =>
      'Удалить канал без возможности восстановления?';

  @override
  String get channelsEmpty => 'Каналов пока нет';

  @override
  String get channelsOpen => 'Открыть';

  @override
  String get channelsNameLabel => 'Название';

  @override
  String get channelsDescriptionLabel => 'Описание';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'Владелец не может отписаться. Удалите канал.';

  @override
  String get channelsNotFoundRedirect => 'Канал больше не существует';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count поиска',
      many: '$count поисков',
      few: '$count поиска',
      one: '$count поиск',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
      one: '$count файл',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count команды',
      many: '$count команд',
      few: '$count команды',
      one: '$count команда',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count картинки',
      many: '$count картинок',
      few: '$count картинки',
      one: '$count картинка',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count шага',
      many: '$count шагов',
      few: '$count шага',
      one: '$count шаг',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '$seconds с';
  }

  @override
  String get savedTitle => 'Избранное';

  @override
  String get savedSubtitle => 'Ваше личное облако';

  @override
  String get savedOpenError => 'Не удалось открыть Избранное';

  @override
  String get billingWalletTitle => 'Кошелёк';

  @override
  String get billingBuyPackage => 'Купить пакет';

  @override
  String get billingCurrentBalance => 'Текущий баланс';

  @override
  String get billingPackagesTitle => 'Пакеты';

  @override
  String get billingPackagesUnavailable => 'Пакеты недоступны';

  @override
  String get billingRecentOperations => 'Последние операции';

  @override
  String get billingAllOperations => 'Все операции';

  @override
  String get billingNoOperations => 'Операций нет';

  @override
  String get billingOperationsTitle => 'Операции';

  @override
  String get billingOperationsEmptyTitle => 'Операций пока нет';

  @override
  String get billingOperationsEmptySubtitle =>
      'Здесь будут пополнения и списания за AI-функции';

  @override
  String get billingPricebookTitle => 'Цены на функции';

  @override
  String get billingPricebookUnavailable => 'Прайс-лист недоступен';

  @override
  String get billingAiFeaturesTitle => 'AI-функции';

  @override
  String get billingInsufficientFundsTitle => 'Недостаточно средств';

  @override
  String get billingInsufficientFundsSubtitle =>
      'Для использования этой функции нужно пополнить баланс.';

  @override
  String billingRequiredLine(String required) {
    return 'Нужно: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'Есть: $available μTAL';
  }

  @override
  String get billingTopUp => 'Пополнить';

  @override
  String get billingCancel => 'Отмена';

  @override
  String get billingRetry => 'Повторить';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'Баланс на исходе: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'Кошелёк и баланс';

  @override
  String get billingSectionHeader => 'Платежи и AI';

  @override
  String get billingFeatureVoiceAssistant => 'Голосовой ассистент';

  @override
  String get billingFeatureWebSearch => 'Веб-поиск ассистента';

  @override
  String get billingFeatureAiTwin => 'Голосовой двойник';

  @override
  String get billingFeatureAiTwinLong => 'Голосовой двойник (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'Outbound-бот';

  @override
  String get billingFeatureOutboundCallLong => 'Outbound-бот обзвона';

  @override
  String get billingFeatureWhisperTranscribe => 'Транскрипция звонков';

  @override
  String get billingFeatureMeetingSummary => 'AI-резюме звонков';

  @override
  String get billingConfigureAiTwin => 'Настроить двойника';

  @override
  String get billingWebSearchSubtitle => '(при использовании ассистента)';

  @override
  String billingPackagePurchased(String balance) {
    return 'Пакет куплен: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'Рекомендуем';

  @override
  String get billingSessionTerminatedNoFunds =>
      'Баланс закончился — сессия завершена';

  @override
  String get billingSessionTerminatedGeneric => 'Сессия ассистента завершена';

  @override
  String billingBuyForPrice(String price) {
    return 'Купить за €$price';
  }

  @override
  String get billingTxTypeTopup => 'Пополнение';

  @override
  String get billingTxTypeRefund => 'Возврат';

  @override
  String get billingTxTypeSpend => 'Оплата';

  @override
  String get billingUnitMinute => 'минуту';

  @override
  String get billingUnitRequest => 'запрос';

  @override
  String get billingUnitToken => 'токен';

  @override
  String get billingUnitTokens1k => '1К токенов';

  @override
  String get billingUnitCall => 'звонок';

  @override
  String get groupCallSelectParticipants => 'Выбрать участников';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'Поиск';

  @override
  String get groupCallMaxReached => 'Максимум 7 участников';

  @override
  String get groupCallLobbyTitle => 'Группа • Lobby';

  @override
  String groupCallHostLabel(String name) {
    return 'Хост: $name';
  }

  @override
  String get groupCallMicHint => 'Микрофон активируется при подключении';

  @override
  String get groupCallCancel => 'Отменить';

  @override
  String get groupCallNoAnswer => 'Никто не ответил';

  @override
  String get groupCallEndedByHost => 'Звонок завершён хостом';

  @override
  String get groupCallAllLeft => 'Все вышли из звонка';

  @override
  String get groupCallEnded => 'Звонок завершён';

  @override
  String groupCallActiveTitle(int count) {
    return 'Группа • $count';
  }

  @override
  String get groupCallConnectionLost => 'Соединение потеряно';

  @override
  String get groupCallMuteRequested => 'Хост попросил всех замьютиться';

  @override
  String get groupCallUnmute => 'Включить микрофон';

  @override
  String get groupCallMute => 'Заглушить';

  @override
  String get groupCallMuteAll => 'Заглушить всех';

  @override
  String get groupCallLeave => 'Уйти';

  @override
  String get groupCallStatusCalling => 'звоним…';

  @override
  String get groupCallStatusDeclined => 'отклонил';

  @override
  String get groupCallStatusTimeout => 'не ответил';

  @override
  String get groupCallStatusLeft => 'покинул';

  @override
  String groupCallKickConfirm(String name) {
    return 'Удалить $name из звонка';
  }

  @override
  String get groupCallCancelAction => 'Отмена';

  @override
  String get groupCallActiveBanner => 'Активный звонок';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'Группа: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'Группа: $host';
  }

  @override
  String get groupCallCreateError => 'Не удалось создать звонок';

  @override
  String get groupCallJoinError => 'Не удалось присоединиться';

  @override
  String get groupCallLivekitError => 'Ошибка LiveKit';

  @override
  String get groupCallDone => 'Готово';

  @override
  String get groupCallNoResults => 'Ничего не найдено';

  @override
  String get groupCallNoContacts => 'Нет контактов';

  @override
  String get meshGcContactOffline => 'Не в этой Wi-Fi сети';

  @override
  String get meshGcOnlineViaMesh => 'В сети через mesh';

  @override
  String get meshGcMaxInvitees =>
      'В групповом звонке до 4 приглашённых (5 всего).';

  @override
  String get meshGcStart => 'Начать групповой звонок';

  @override
  String get meshGcCancel => 'Отмена';

  @override
  String get meshGcStatusCalling => 'Вызов…';

  @override
  String get meshGcStatusJoined => 'Подключён';

  @override
  String get meshGcStatusDeclined => 'Отклонил';

  @override
  String get meshGcStatusNoAnswer => 'Нет ответа';

  @override
  String get meshGcStatusConnectionFailed => 'Соединение не удалось';

  @override
  String get meshGcStatusLeft => 'Вышел';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne => 'Сначала завершите текущий звонок.';

  @override
  String get presenceOnline => 'в сети';

  @override
  String get presenceLastSeenJustNow => 'был(а) в сети только что';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'был(а) в сети $minutes мин назад';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'был(а) в сети сегодня в $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'был(а) в сети вчера в $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'был(а) в сети $date';
  }

  @override
  String get presenceLastSeenRecently => 'был(а) в сети недавно';

  @override
  String get privacySectionTitle => 'Конфиденциальность';

  @override
  String get privacyLastSeenLabel => 'Кто видит время последнего входа';

  @override
  String get privacyEveryone => 'Все';

  @override
  String get privacyContacts => 'Только контакты';

  @override
  String get privacyNobody => 'Никто';

  @override
  String get voiceTurnOffTranslation => 'Выключить переводчик';

  @override
  String get informerBotTitle => 'Informer';

  @override
  String get informerBotSubtitle => 'Мониторинг кошельков и балансов';

  @override
  String seenByCount(int count) {
    return 'Прочитали: $count';
  }

  @override
  String get messageInfo => 'Информация о сообщении';

  @override
  String get readBy => 'Прочитали';

  @override
  String get notReadYet => 'Ещё не прочитано';

  @override
  String get reactionsLabel => 'Реакции';

  @override
  String get noReactions => 'Нет реакций';

  @override
  String get mailTitle => 'Почта';

  @override
  String get mailSectionHeader => 'Почта';

  @override
  String get mailInboxEmpty => 'Писем пока нет';

  @override
  String get mailNoAccountTitle => 'Выберите ваш адрес @talerid.io';

  @override
  String get mailNoAccountBody =>
      'Создайте личный email-адрес для отправки и получения почты.';

  @override
  String get mailChooseAddress => 'Выбрать адрес';

  @override
  String get mailAddressHint => 'имя';

  @override
  String get mailAddressTaken => 'Адрес уже занят';

  @override
  String get mailAddressInvalid =>
      'Только латиница, цифры, точка, дефис, подчёркивание (3–64)';

  @override
  String get mailAddressReserved => 'Это имя зарезервировано';

  @override
  String get mailAddressAvailable => 'Адрес свободен';

  @override
  String get mailCreateAddress => 'Создать адрес';

  @override
  String get mailSetupLater => 'Позже';

  @override
  String get mailCompose => 'Новое письмо';

  @override
  String get mailTo => 'Кому';

  @override
  String get mailSubject => 'Тема';

  @override
  String get mailBody => 'Сообщение';

  @override
  String get mailSend => 'Отправить';

  @override
  String get mailSent => 'Письмо отправлено';

  @override
  String get mailReply => 'Ответить';

  @override
  String get mailDelete => 'Удалить';

  @override
  String get mailMarkUnread => 'Отметить непрочитанным';

  @override
  String get mailAttachments => 'Вложения';

  @override
  String get mailAttachFile => 'Прикрепить файл';

  @override
  String get mailAppPasswords => 'Пароли приложений';

  @override
  String get mailAppPasswordsHint =>
      'Используйте пароли приложений для подключения Apple Mail, Gmail и других IMAP-клиентов.';

  @override
  String get mailAppPasswordLabel => 'Название (напр. iPhone Apple Mail)';

  @override
  String get mailAppPasswordCreate => 'Создать пароль';

  @override
  String get mailAppPasswordShownOnce =>
      'Сохраните пароль сейчас — он показывается только один раз.';

  @override
  String get mailAppPasswordCopied => 'Пароль скопирован';

  @override
  String get mailAppPasswordRevoke => 'Отозвать';

  @override
  String get mailClientSettingsTitle => 'Настройки клиента';

  @override
  String get mailSendLimitReached => 'Дневной лимит отправки исчерпан';

  @override
  String get mailSendFailed => 'Не удалось отправить письмо';

  @override
  String get mailAttachmentsTooLarge => 'Вложения — не более 10 МБ суммарно';

  @override
  String get mailQuotaTitle => 'Почтовый ящик';

  @override
  String get mailFolders => 'Папки';

  @override
  String get mailFolderInbox => 'Входящие';

  @override
  String get mailFolderSent => 'Отправленные';

  @override
  String get mailFolderDrafts => 'Черновики';

  @override
  String get mailFolderJunk => 'Спам';

  @override
  String get mailFolderTrash => 'Корзина';

  @override
  String get mailNewFolder => 'Новая папка';

  @override
  String get mailDeleteFolder => 'Удалить папку?';

  @override
  String get mailMoveTo => 'Переместить в';

  @override
  String get mailMoved => 'Перемещено';

  @override
  String get mailSaveDraft => 'Сохранить черновик?';

  @override
  String get mailDraftSaved => 'Черновик сохранён';

  @override
  String get deviceApprovalTitle => 'Подтвердите вход';

  @override
  String get deviceApprovalWaiting =>
      'Мы отправили запрос на ваши доверенные устройства. Откройте уведомление и подтвердите вход.';

  @override
  String get deviceApprovalNoApprovers =>
      'Не нашлось устройства, на которое можно отправить запрос. Получите код на почту.';

  @override
  String deviceApprovalExpiresIn(String time) {
    return 'Осталось $time';
  }

  @override
  String get deviceApprovalRejected => 'Вход отклонён с другого устройства.';

  @override
  String get deviceApprovalExpired => 'Время подтверждения истекло.';

  @override
  String get deviceApprovalBackToLogin => 'Вернуться ко входу';

  @override
  String get deviceApprovalSendEmail => 'Отправить код на почту';

  @override
  String get deviceApprovalEmailSent => 'Код отправлен на вашу почту';

  @override
  String get deviceApprovalEnterCode => 'Введите код из письма';

  @override
  String get deviceApprovalSheetTitle => 'Вход в аккаунт';

  @override
  String get deviceApprovalSheetBody =>
      'Кто-то входит в ваш аккаунт с этого устройства. Это вы?';

  @override
  String get deviceApprovalAllow => 'Это я, разрешить';

  @override
  String get deviceApprovalDeny => 'Это не я';

  @override
  String get deviceApprovalApproved => 'Вход разрешён';

  @override
  String get deviceApprovalDenied => 'Вход отклонён';

  @override
  String get trustedDevicesTitle => 'Устройства';

  @override
  String get trustedDevicesToggle => 'Подтверждать вход с новых устройств';

  @override
  String get trustedDevicesToggleHint =>
      'Вход с незнакомого устройства потребует подтверждения с этого или кода на почту';

  @override
  String get trustedDevicesEmpty => 'Пока нет доверенных устройств';

  @override
  String get trustedDevicesThisDevice => 'Это устройство';

  @override
  String trustedDevicesLastSeen(String when) {
    return 'Последний вход: $when';
  }

  @override
  String get trustedDevicesRevoke => 'Отозвать';

  @override
  String get trustedDevicesRevokeConfirm =>
      'Отозвать доверие к этому устройству? Оно будет разлогинено.';

  @override
  String get pinnedMessage => 'Закреплённое сообщение';

  @override
  String get pinnedMessagesTitle => 'Закреплённые';

  @override
  String get pinAction => 'Закрепить';

  @override
  String get unpinAction => 'Открепить';

  @override
  String get unpinAllAction => 'Открепить всё';

  @override
  String get noPinnedMessages => 'Нет закреплённых сообщений';

  @override
  String pinnedCounter(int current, int total) {
    return '$current из $total';
  }

  @override
  String messagePinnedBy(String actor) {
    return '$actor закрепил сообщение';
  }

  @override
  String get unpinAllConfirm => 'Открепить все сообщения в этом чате?';

  @override
  String get pinnedMessageNotLoaded =>
      'Сообщение не загружено — прокрутите вверх, чтобы найти его';

  @override
  String get chatReplyOriginalNotLoaded =>
      'Оригинал не загружен — прокрутите вверх, чтобы найти его';

  @override
  String get chatOriginalDeleted => 'Сообщение удалено';

  @override
  String chatForwardedFrom(String name) {
    return 'Переслано от $name';
  }

  @override
  String get chatUnreadDivider => 'Непрочитанные сообщения';

  @override
  String chatSelectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String chatSelectionLimit(int limit) {
    return 'Можно выбрать не больше $limit сообщений';
  }

  @override
  String get chatSelect => 'Выделить';

  @override
  String get convDraftLabel => 'Черновик';

  @override
  String get chatMentionNotFound => 'Пользователь не найден';

  @override
  String get chatTranscribeVoice => 'Расшифровать';

  @override
  String get chatTranscribing => 'Расшифровываю…';

  @override
  String get chatTranscribeEmpty => 'В записи ничего не разобрать';

  @override
  String get chatTranscribeFailed => 'Не удалось расшифровать';

  @override
  String get inviteJoinTitle => 'Приглашение';

  @override
  String get inviteJoinAction => 'Вступить';

  @override
  String get inviteOpenChat => 'Открыть';

  @override
  String get inviteAlreadyMember => 'Вы уже участник';

  @override
  String get inviteRevoked => 'Ссылка отозвана';

  @override
  String get inviteExpired => 'Срок действия ссылки истёк';

  @override
  String get inviteExhausted => 'По этой ссылке больше нельзя вступить';

  @override
  String get inviteNotFound => 'Ссылка недействительна';

  @override
  String inviteMembers(int count) {
    return 'участников: $count';
  }

  @override
  String get inviteLinkTitle => 'Ссылка-приглашение';

  @override
  String get inviteLinkCreate => 'Создать ссылку';

  @override
  String get inviteLinkCopied => 'Ссылка скопирована';

  @override
  String get inviteLinkRevoke => 'Отозвать';

  @override
  String get invitePublicName => 'Публичное имя';

  @override
  String get invitePublicNameHint => 'например talerid_news';

  @override
  String get invitePublicNameSaved => 'Публичное имя сохранено';

  @override
  String get invitePublicNameTaken => 'Имя уже занято';

  @override
  String get invitePublicNameBad =>
      'От 5 до 32 символов, начиная с буквы: a-z, 0-9 и _';

  @override
  String chatViews(int count) {
    return '$count просмотров';
  }

  @override
  String get chatReadBy => 'Прочитали';

  @override
  String chatReadByMore(int count) {
    return 'и ещё $count';
  }

  @override
  String get chatReadByNobody => 'Пока никто';

  @override
  String get chatSendSilently => 'Отправить без звука';

  @override
  String get chatSendLater => 'Отправить позже';

  @override
  String chatScheduledFor(String when) {
    return 'Отправится $when';
  }

  @override
  String get chatSendScheduled => 'Запланировано';

  @override
  String get chatFormatBold => 'Жирный';

  @override
  String get chatFormatItalic => 'Курсив';

  @override
  String get chatFormatStrike => 'Зачёркнутый';

  @override
  String get chatFormatCode => 'Код';

  @override
  String get chatFormatSpoiler => 'Спойлер';
}
