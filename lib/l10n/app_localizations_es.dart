// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Buscar';

  @override
  String get appSubtitle => 'Identidad del ecosistema unificado';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get register => 'Crear cuenta';

  @override
  String get registerButton => 'Crear cuenta';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get firstName => 'Nombre';

  @override
  String get lastName => 'Apellido';

  @override
  String get noAccount => '¿No tienes una cuenta?';

  @override
  String get createOne => 'Crea una';

  @override
  String get haveAccount => '¿Ya tienes una cuenta?';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get passwordMinLength => 'Mínimo 8 caracteres';

  @override
  String get invalidEmail => 'Introduce un correo electrónico válido';

  @override
  String get fieldRequired => 'Campo obligatorio';

  @override
  String get twoFATitle => 'Autenticación de dos factores';

  @override
  String get twoFASubtitle =>
      'Introduce el código de 6 dígitos de tu aplicación de autenticación';

  @override
  String get twoFACode => 'Código 2FA';

  @override
  String get verify => 'Verificar';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Organización';

  @override
  String get tabSettings => 'Configuración';

  @override
  String get profile => 'Perfil';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get phone => 'Teléfono';

  @override
  String get country => 'País';

  @override
  String get dateOfBirth => 'Fecha de nacimiento';

  @override
  String get documents => 'Documentos';

  @override
  String get addDocument => 'Añadir documento';

  @override
  String get noDocuments => 'No se han subido documentos';

  @override
  String get save => 'Guardar';

  @override
  String get profileUpdated => 'Perfil actualizado';

  @override
  String get personalData => 'Datos personales';

  @override
  String get passport => 'Pasaporte';

  @override
  String get drivingLicense => 'Permiso de conducir';

  @override
  String get diploma => 'Diploma';

  @override
  String get nationalId => 'DNI';

  @override
  String get certificate => 'Certificado';

  @override
  String get notSpecified => 'No especificado';

  @override
  String get notSpecifiedFemale => 'No especificado';

  @override
  String get documentType => 'Tipo de documento';

  @override
  String get passportId => 'Pasaporte / DNI';

  @override
  String get diplomaCertificate => 'Diploma / Certificado';

  @override
  String get loadError => 'Error de carga';

  @override
  String get verification => 'Verificación';

  @override
  String get countryAustria => 'Austria';

  @override
  String get countryGermany => 'Alemania';

  @override
  String get countryRussia => 'Rusia';

  @override
  String get countryUkraine => 'Ucrania';

  @override
  String get countryKazakhstan => 'Kazajistán';

  @override
  String get countryBelarus => 'Bielorrusia';

  @override
  String get countryOther => 'Otro';

  @override
  String get kycTitle => 'Verificación KYC';

  @override
  String get kycVerified => 'Verificado';

  @override
  String get kycPending => 'Pendiente';

  @override
  String get kycRejected => 'Rechazado';

  @override
  String get kycUnverified => 'No verificado';

  @override
  String get kycVerifiedDesc =>
      'Tu identidad ha sido verificada. Tienes acceso completo a todas las funciones del ecosistema Taler.';

  @override
  String get kycPendingDesc =>
      'Tus documentos están siendo revisados. Esto suele tardar 1-2 días laborables.';

  @override
  String get kycRejectedDesc =>
      'La verificación falló. Por favor, revisa el motivo y vuelve a enviar tus documentos.';

  @override
  String get kycUnverifiedDesc =>
      'Completa la verificación para desbloquear el acceso completo a las funciones financieras del ecosistema Taler.';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get kycInProgress => 'In progress';

  @override
  String get kycInProgressDesc =>
      'You started verification but didn\'t finish it. Pick up right where you left off.';

  @override
  String get startVerification => 'Iniciar verificación';

  @override
  String get retryVerification => 'Reintentar verificación';

  @override
  String verifiedAt(String date) {
    return 'Verificado: $date';
  }

  @override
  String get documentsSubmitted => 'Documentos enviados para revisión';

  @override
  String get documentsSubmittedDesc =>
      'La revisión suele tardar 1-2 días laborables. Recibirás una notificación push con el resultado.';

  @override
  String get securityAes => 'Tus datos están protegidos con cifrado AES-256';

  @override
  String get verificationTime => 'La verificación tarda 1-2 días laborables';

  @override
  String get pushNotification =>
      'Recibirás una notificación push con el resultado';

  @override
  String get kycWebOnly =>
      'La verificación KYC solo está disponible en la aplicación móvil.';

  @override
  String verificationError(String code) {
    return 'Error de verificación: $code';
  }

  @override
  String get organizations => 'Organizaciones';

  @override
  String get noOrganizations => 'No hay organizaciones';

  @override
  String get noOrganizationsDesc =>
      'Crea una organización o acepta una invitación';

  @override
  String get createOrganization => 'Crear organización';

  @override
  String get newOrganization => 'Nueva Organización';

  @override
  String get orgName => 'Nombre *';

  @override
  String get orgDescription => 'Descripción';

  @override
  String get orgEmail => 'Correo de Contacto';

  @override
  String get orgWebsite => 'Sitio Web';

  @override
  String get orgLegalAddress => 'Dirección Legal';

  @override
  String get create => 'Crear';

  @override
  String get organization => 'Organización';

  @override
  String get contacts => 'Contactos';

  @override
  String members(int count) {
    return 'Miembros ($count)';
  }

  @override
  String get inviteMember => 'Invitar Miembro';

  @override
  String get invite => 'Invitar';

  @override
  String get sendInvite => 'Enviar Invitación';

  @override
  String inviteSent(String email) {
    return 'Invitación enviada a $email';
  }

  @override
  String get role => 'Rol';

  @override
  String get roleOwner => 'Propietario';

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleOperator => 'Operador';

  @override
  String get roleViewer => 'Visualizador';

  @override
  String get editOrganization => 'Editar';

  @override
  String get editOrganizationTitle => 'Editar Organización';

  @override
  String get removeMember => 'Eliminar Miembro';

  @override
  String removeMemberConfirm(String name) {
    return '¿Eliminar a $name de la organización?';
  }

  @override
  String get memberRemoved => 'Miembro eliminado';

  @override
  String get roleChanged => 'Rol cambiado';

  @override
  String get kybVerified => 'Verificado';

  @override
  String get kybPending => 'Pendiente';

  @override
  String get kybRejected => 'Rechazado';

  @override
  String get kybNone => 'No verificado';

  @override
  String get kybVerification => 'Iniciar Verificación KYB';

  @override
  String get kybStartBusiness => 'Iniciar Verificación de Negocio';

  @override
  String get kybStatusLabel => 'Estado KYB';

  @override
  String get noKyb => 'Sin KYB';

  @override
  String get kybBusinessVerificationTitle => 'Verificación de Negocio (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Organización verificada con éxito.';

  @override
  String get kybPendingOrgDesc =>
      'Los documentos están siendo revisados. Esto suele tardar de 1 a 3 días laborables.';

  @override
  String get kybRejectedOrgDesc =>
      'La verificación falló. Por favor, inténtelo de nuevo.';

  @override
  String get kybNoneOrgDesc =>
      'Verifique su organización para acceder a funciones de negocio.';

  @override
  String get invitePlus => '+ Invitar';

  @override
  String get kybVerificationTitle => 'Verificación KYB';

  @override
  String get kybWebOnlyBusiness =>
      'La verificación KYB solo está disponible en la aplicación móvil.';

  @override
  String get unknownDevice => 'Dispositivo desconocido';

  @override
  String get ipUnknown => 'IP desconocida';

  @override
  String get currentSessionLabel => 'Actual';

  @override
  String get endSessionAction => 'Finalizar';

  @override
  String get deviceLoggedOut => 'El dispositivo se cerrará la sesión.';

  @override
  String get acceptInvitationTitle => 'Invitación a la Organización';

  @override
  String get acceptInvitation => 'Aceptar invitación';

  @override
  String get acceptInvitationDesc =>
      'Has sido invitado a unirte a una organización en el ecosistema de Taler.';

  @override
  String get accept => 'Aceptar';

  @override
  String get reject => 'Rechazar';

  @override
  String get sessions => 'Sesiones activas';

  @override
  String get currentSession => 'Sesión actual';

  @override
  String get deleteSession => 'Finalizar sesión';

  @override
  String get deleteSessionConfirm => '¿Finalizar esta sesión?';

  @override
  String get sessionDeleted => 'Sesión finalizada';

  @override
  String get noSessions => 'No hay sesiones activas';

  @override
  String minutesAgo(int count) {
    return 'Hace $count min';
  }

  @override
  String hoursAgo(int count) {
    return 'Hace $count hr';
  }

  @override
  String daysAgo(int count) {
    return 'Hace $count días';
  }

  @override
  String get justNow => 'Justo ahora';

  @override
  String get settings => 'Configuración';

  @override
  String get security => 'Seguridad';

  @override
  String get biometrics => 'Biometría';

  @override
  String get biometricsDesc => 'Inicio rápido con Face ID o huella digital';

  @override
  String get biometricsConfirm =>
      'Confirma la biometría para habilitar el inicio rápido';

  @override
  String get biometricsError =>
      'No se pudo habilitar la biometría. Verifica la configuración del dispositivo.';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get twoFactorAuth => 'Autenticación de dos factores';

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get confirmNewPassword => 'Confirmar nueva contraseña';

  @override
  String get passwordChanged => 'Contraseña cambiada';

  @override
  String get wrongCurrentPassword => 'Contraseña actual incorrecta';

  @override
  String get passwordTooWeak =>
      'Contraseña demasiado débil: se requieren al menos 8 caracteres, letra y dígito';

  @override
  String get passwordChangeFailed => 'No se pudo cambiar la contraseña';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get permissions => 'Permisos';

  @override
  String get permissionNotifications => 'Notificaciones push';

  @override
  String get permissionNotificationsDesc => 'Llamadas, mensajes, estados';

  @override
  String get permissionMicrophone => 'Micrófono';

  @override
  String get permissionMicrophoneDesc => 'Llamadas y asistente de voz';

  @override
  String get permissionCamera => 'Cámara';

  @override
  String get permissionCameraDesc => 'Videollamadas y verificación';

  @override
  String get permissionLocation => 'Ubicación';

  @override
  String get permissionLocationDesc => 'Usado para verificación';

  @override
  String get permissionOpenSettings =>
      'Para revocar un permiso, abre la configuración del sistema';

  @override
  String get pushKycStatus => 'Notificación de estado KYC';

  @override
  String get pushKycStatusDesc => 'Resultado de la verificación';

  @override
  String get pushLogins => 'Notificación de inicio de sesión';

  @override
  String get pushLoginsDesc => 'Al iniciar sesión desde un nuevo dispositivo';

  @override
  String get account => 'Cuenta';

  @override
  String get language => 'Idioma';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Idioma de la interfaz';

  @override
  String get exportData => 'Exportar datos (GDPR)';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountConfirm => '¿Eliminar cuenta?';

  @override
  String get deleteAccountDesc =>
      'Todos tus datos serán eliminados (GDPR). Esta acción es irreversible.';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get logoutConfirm => '¿Cerrar sesión?';

  @override
  String get logoutDesc =>
      'Se cerrará la sesión de Taler ID en este dispositivo.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'Código PIN';

  @override
  String get pinCodeDesc => 'Inicio rápido con código de 4 dígitos';

  @override
  String get setupPin => 'Configurar PIN';

  @override
  String get enterPin => 'Introduce el PIN';

  @override
  String get confirmPin => 'Confirma el PIN';

  @override
  String get pinMismatch => 'Los PIN no coinciden';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden';

  @override
  String get pinSet => 'PIN configurado con éxito';

  @override
  String get enterPinToLogin => 'Introduce el PIN para iniciar sesión';

  @override
  String get pinIncorrect => 'PIN incorrecto';

  @override
  String get removePin => 'Eliminar PIN';

  @override
  String get pinRemoved => 'PIN eliminado';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Reintentar';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get noData => 'Sin datos';

  @override
  String get failedToLoad => 'Error al cargar datos';

  @override
  String get failedToLoadProfile => 'Error al cargar el perfil';

  @override
  String get failedToSave => 'Error al guardar cambios';

  @override
  String get failedToLoadOrgs => 'Error al cargar organizaciones';

  @override
  String get failedToLoadOrg => 'Error al cargar datos de la organización';

  @override
  String get failedToCreateOrg => 'Error al crear la organización';

  @override
  String get failedToInvite => 'Error al enviar invitación';

  @override
  String get failedToAcceptInvite => 'Error al aceptar la invitación';

  @override
  String get failedToLoadSessions => 'Error al cargar sesiones';

  @override
  String get failedToDeleteSession => 'Error al finalizar la sesión';

  @override
  String get failedToLoadKyc => 'Error al cargar el estado de verificación';

  @override
  String get failedToStartKyc => 'Error al iniciar la verificación';

  @override
  String get verifiedPersonalInfo => 'Datos verificados';

  @override
  String get middleName => 'Segundo nombre';

  @override
  String get placeOfBirth => 'Lugar de nacimiento';

  @override
  String get nationality => 'Nacionalidad';

  @override
  String get gender => 'Género';

  @override
  String get genderMale => 'Masculino';

  @override
  String get genderFemale => 'Femenino';

  @override
  String get docNumber => 'Número';

  @override
  String get docIssuedDate => 'Emitido';

  @override
  String get docValidUntil => 'Válido hasta';

  @override
  String get docIssuedBy => 'Emitido por';

  @override
  String get address => 'Dirección';

  @override
  String get refreshData => 'Actualizar datos';

  @override
  String get failedToLoadSumsubData => 'Error al cargar datos de verificación';

  @override
  String get sumsubDataLoading => 'Cargando datos de verificación...';

  @override
  String get reviewResultGreen => 'Verificación aprobada';

  @override
  String get reviewResultRed => 'Verificación fallida';

  @override
  String get tabAssistant => 'Asistente';

  @override
  String get assistantChatHint => 'Message the assistant';

  @override
  String get assistantActionUnavailable => 'Item is no longer available';

  @override
  String get assistantAttachFile => 'Attach file';

  @override
  String get assistantTyping => 'Assistant is thinking…';

  @override
  String get assistantEmptyHint => 'Ask anything — by voice or text';

  @override
  String get assistantToolLoopError =>
      'The assistant couldn\'t complete the request';

  @override
  String get assistantError => 'Something went wrong. Try again';

  @override
  String get assistantConnecting => 'Conectando…';

  @override
  String get assistantSpeaking => 'Hablando…';

  @override
  String get assistantListening => 'Escuchando…';

  @override
  String get assistantTapToStart => 'Toca para comenzar';

  @override
  String get assistantTapToTalk => 'Toca para hablar con AI';

  @override
  String get assistantRealtimeDesc =>
      'El asistente responde con voz en tiempo real';

  @override
  String get assistantConnectingToAssistant => 'Conectando con el asistente...';

  @override
  String get assistantAiSpeaking => 'AI hablando...';

  @override
  String get assistantAiListening => 'AI escuchando';

  @override
  String get assistantSpeakerOn => 'Altavoz activado';

  @override
  String get assistantSpeaker => 'Altavoz';

  @override
  String get assistantEnd => 'Finalizar';

  @override
  String get assistantUnmute => 'Activar sonido';

  @override
  String get assistantMicrophone => 'Micrófono';

  @override
  String get assistantConnectionError => 'Error de conexión';

  @override
  String get tabMessenger => 'Mensajes';

  @override
  String get tabCalls => 'Llamadas';

  @override
  String get tabCalendar => 'Calendario';

  @override
  String get appearance => 'Apariencia';

  @override
  String get appearanceSelect => 'Elegir tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get onboardingTitle1 => 'Identidad Unificada';

  @override
  String get onboardingDesc1 =>
      'Taler ID es tu pasaporte digital en el ecosistema Taler. Una cuenta para todos los servicios.';

  @override
  String get onboardingTitle2 => 'Seguridad de Datos';

  @override
  String get onboardingDesc2 =>
      'La verificación KYC, el cifrado AES-256 y la autenticación de dos factores protegen tu identidad.';

  @override
  String get onboardingTitle3 => 'Mantente Informado';

  @override
  String get onboardingDesc3 =>
      'Recibe notificaciones sobre el estado de verificación, inicios de sesión desde nuevos dispositivos y llamadas entrantes.';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingEnableNotifications => 'Activar notificaciones';

  @override
  String get onboardingTitle4 => 'Llamadas de Voz';

  @override
  String get onboardingDesc4 =>
      'Concede acceso al micrófono para llamadas de voz y asistente AI. Puedes cambiar esto más tarde en la configuración.';

  @override
  String get onboardingEnableMicrophone => 'Activar micrófono';

  @override
  String get onboardingStart => 'Comenzar';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get meshLocalNetworkPromptTitle => 'Permitir acceso a la red local';

  @override
  String get meshLocalNetworkPromptBody =>
      'Para encontrar pares en Wi-Fi (llamadas grupales sin conexión), iOS requiere el permiso de Red Local. Abre Configuración → Privacidad y Seguridad → Red Local → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'Abrir configuración';

  @override
  String get meshLocalNetworkPromptDismiss => 'Entendido';

  @override
  String get forgotPassword => '¿Olvidaste la contraseña?';

  @override
  String get forgotPasswordTitle => 'Restablecer contraseña';

  @override
  String get forgotPasswordSubtitle =>
      'Introduce tu correo electrónico para recibir un código de restablecimiento';

  @override
  String resetCodeSent(String email) {
    return 'Código enviado a $email';
  }

  @override
  String get enterResetCode => 'Introduce el código';

  @override
  String get resetPasswordButton => 'Restablecer contraseña';

  @override
  String get passwordResetSuccess => 'Contraseña restablecida con éxito';

  @override
  String get sendCode => 'Enviar código';

  @override
  String get resendCode => 'Reenviar código';

  @override
  String get verifyEmailTitle => 'Verify Email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'We\'ll send a 6-digit code to $email.';
  }

  @override
  String verifyEmailCodeSent(String email) {
    return 'Code sent to $email. Enter it below.';
  }

  @override
  String get verifyEmailSendCode => 'Send Code';

  @override
  String get verifyEmailConfirm => 'Verify';

  @override
  String get verifyEmailResend => 'Resend code';

  @override
  String get verifyEmailSuccess => 'Email verified ✓';

  @override
  String get verifyEmailAlreadyVerified => 'Email is already verified';

  @override
  String get verifyEmailBannerTitle => 'Verify your email';

  @override
  String get verifyEmailBannerSubtitle =>
      'Tap to receive a 6-digit code and confirm your address.';

  @override
  String get newGroup => 'Nuevo grupo';

  @override
  String get newChat => 'Nuevo chat';

  @override
  String get groupName => 'Nombre del grupo';

  @override
  String get createGroup => 'Crear grupo';

  @override
  String get groupInfo => 'Información del grupo';

  @override
  String groupMembers(int count) {
    return 'Miembros ($count)';
  }

  @override
  String get addMembers => 'Añadir miembros';

  @override
  String get leaveGroup => 'Salir del grupo';

  @override
  String get leaveGroupConfirm => '¿Salir de este grupo?';

  @override
  String get deleteGroup => 'Eliminar grupo';

  @override
  String get deleteGroupConfirm =>
      '¿Eliminar este grupo? Esto no se puede deshacer.';

  @override
  String get groupRoleOwner => 'Propietario';

  @override
  String get groupRoleAdmin => 'Administrador';

  @override
  String get groupRoleMember => 'Miembro';

  @override
  String get selectParticipants => 'Seleccionar participantes';

  @override
  String selectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get changeRole => 'Cambiar rol';

  @override
  String get groupCreated => 'Grupo creado';

  @override
  String memberJoined(String name) {
    return '$name se unió';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name salió';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name fue eliminado';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name ahora es $role';
  }

  @override
  String participantsCount(int count) {
    return '$count participantes';
  }

  @override
  String get enterGroupName => 'Introduce el nombre del grupo';

  @override
  String get muteNotifications => 'Silenciar notificaciones';

  @override
  String get unmuteNotifications => 'Activar notificaciones';

  @override
  String get muteFor1Hour => 'Por 1 hora';

  @override
  String get muteFor8Hours => 'Por 8 horas';

  @override
  String get muteFor2Days => 'Por 2 días';

  @override
  String get muteForever => 'Para siempre';

  @override
  String get muted => 'Silenciado';

  @override
  String get tabTranslator => 'Traducir';

  @override
  String get translatorTitle => 'Traductor';

  @override
  String get translatorSelectLanguage => 'Seleccionar idioma';

  @override
  String get translatorDownloading => 'Descargando modelos de idioma...';

  @override
  String get translatorDownloadingHint =>
      'Se necesita internet solo para la primera descarga';

  @override
  String get translatorTypeHint => 'Escribe texto o toca el micrófono';

  @override
  String get translatorListening => 'Escuchando...';

  @override
  String get translatorTapToSpeak => 'Toca para hablar';

  @override
  String get translatorTapToStop => 'Toca para detener';

  @override
  String get translatorAutoSpeak => 'Habla automáticamente';

  @override
  String get translatorCopied => 'Copiado';

  @override
  String get translatorLangRu => 'Ruso';

  @override
  String get translatorLangEn => 'Inglés';

  @override
  String get translatorLangDe => 'Alemán';

  @override
  String get translatorLangFr => 'Francés';

  @override
  String get translatorLangEs => 'Español';

  @override
  String get translatorLangIt => 'Italiano';

  @override
  String get translatorLangPt => 'Portugués';

  @override
  String get translatorLangTr => 'Turco';

  @override
  String get translatorLangZh => 'Chino';

  @override
  String get translatorLangJa => 'Japonés';

  @override
  String get translatorLangKo => 'Coreano';

  @override
  String get translatorLangAr => 'Árabe';

  @override
  String get translatorLangPl => 'Polaco';

  @override
  String get translatorLangSk => 'Eslovaco';

  @override
  String get translatorLangCs => 'Checo';

  @override
  String get translatorLangNl => 'Holandés';

  @override
  String get translatorLangSv => 'Sueco';

  @override
  String get translatorLangDa => 'Danés';

  @override
  String get translatorLangNo => 'Noruego';

  @override
  String get translatorLangFi => 'Finlandés';

  @override
  String get translatorLangUk => 'Ucraniano';

  @override
  String get translatorLangEl => 'Griego';

  @override
  String get translatorLangRo => 'Rumano';

  @override
  String get translatorLangHu => 'Húngaro';

  @override
  String get translatorLangBg => 'Búlgaro';

  @override
  String get translatorLangHr => 'Croata';

  @override
  String get translatorLangSr => 'Serbio';

  @override
  String get translatorLangHi => 'Hindi';

  @override
  String get translatorLangTh => 'Tailandés';

  @override
  String get translatorLangVi => 'Vietnamita';

  @override
  String get translatorLangId => 'Indonesio';

  @override
  String get translatorLangMs => 'Malayo';

  @override
  String get translatorLangHe => 'Hebreo';

  @override
  String get translatorLangFa => 'Persa';

  @override
  String get callInProgress => 'Llamada en curso';

  @override
  String get joinCall => 'Unirse';

  @override
  String get createCallLink => 'Enlace de llamada';

  @override
  String get callLinkCopied => 'Enlace copiado';

  @override
  String get callLinkTitle => 'Enlace de sala';

  @override
  String get connectionUnstable => 'Conexión inestable — verifica tu internet';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get errorTimeout =>
      'Tiempo de conexión agotado. Verifica tu conexión a internet.';

  @override
  String get errorNoConnection => 'Sin conexión a internet.';

  @override
  String get errorGeneral => 'Ocurrió un error. Por favor, inténtalo de nuevo.';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get notifChannelMessages => 'Mensajes';

  @override
  String get notifChannelMessagesDesc => 'Notificaciones de nuevos mensajes';

  @override
  String get notifChannelMissedCalls => 'Llamadas perdidas';

  @override
  String get notifChannelMissedCallsDesc =>
      'Notificaciones de llamadas perdidas';

  @override
  String get notifMissedCall => 'Llamada perdida';

  @override
  String get notifAccept => 'Aceptar';

  @override
  String get notifDecline => 'Rechazar';

  @override
  String get notifIncomingCall => 'Llamada entrante';

  @override
  String get notifIncomingCallChannel => 'Llamada entrante';

  @override
  String get notifMissedCallChannel => 'Llamada perdida';

  @override
  String get notifUnknown => 'Desconocido';

  @override
  String get effectNone => 'Sin fondo';

  @override
  String get effectBlur => 'Desenfoque';

  @override
  String get effectOffice => 'Oficina';

  @override
  String get effectNature => 'Naturaleza';

  @override
  String get effectGradient => 'Degradado';

  @override
  String get effectLibrary => 'Biblioteca';

  @override
  String get effectCity => 'Ciudad';

  @override
  String get effectMinimalism => 'Minimalismo';

  @override
  String get voiceParticipant => 'Participante';

  @override
  String get voiceInvitesToRoom => 'te invita a la sala';

  @override
  String get voiceRoom => 'Sala';

  @override
  String get voicePasswordProtected => 'Protegido por contraseña';

  @override
  String get voicePasswordHint => 'Contraseña';

  @override
  String get voiceEnter => 'Entrar';

  @override
  String get voiceJoinRoom => 'Unirse a la sala';

  @override
  String get voiceYourName => 'Tu nombre';

  @override
  String voiceInvitationSent(String name) {
    return 'Invitación enviada a $name';
  }

  @override
  String get voiceNoActiveRoom => 'No hay sala activa';

  @override
  String get voiceCameraPermission =>
      'Permitir acceso a la cámara en Configuración → Privacidad → Cámara → TalerID';

  @override
  String get voiceOpenSettings => 'Abrir';

  @override
  String voiceCameraError(String error) {
    return 'Error al activar la cámara: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'Todos de acuerdo. Grabación iniciada.';

  @override
  String get voiceNewParticipantAgreed =>
      'Nuevo participante aceptó la grabación.';

  @override
  String get voiceDeclinedRecording =>
      'Rechazaste la grabación. Saliendo de la llamada.';

  @override
  String get voiceRecordingEnded => 'Grabación finalizada';

  @override
  String get voiceRecordingInProgress => 'Grabación en curso';

  @override
  String get voiceTranscriptionRequest => 'Solicitud de transcripción';

  @override
  String get voiceRecordingRequest => 'Solicitud de grabación';

  @override
  String get voiceAgree => 'Aceptar';

  @override
  String get voiceDeclineAndLeave => 'Rechazar y salir';

  @override
  String get voiceAudioOutput => 'Salida de audio';

  @override
  String get voiceAudioPhone => 'Teléfono';

  @override
  String get voiceAudioSpeaker => 'Altavoz';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Auriculares';

  @override
  String get voiceLinkCopied => 'Enlace copiado';

  @override
  String get voiceTranslateTo => 'Traducir a';

  @override
  String get voiceSearchLanguage => 'Buscar idioma...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Sala $name';
  }

  @override
  String get voiceVoiceCall => 'Llamada de voz';

  @override
  String get voiceOnHold => 'En espera';

  @override
  String get voiceActiveCall => 'Activa';

  @override
  String get voiceEndAllCalls => 'Finalizar todas las llamadas';

  @override
  String get voiceEndThisCall => 'Finalizar esta llamada';

  @override
  String get voiceCopyLink => 'Copiar enlace';

  @override
  String get voiceAddParticipant => 'Añadir participante';

  @override
  String get voiceReconnecting => 'Reconectando...';

  @override
  String get voiceConnectionError => 'Error de conexión';

  @override
  String get voiceClose => 'Cerrar';

  @override
  String get voiceCalling => 'Llamando...';

  @override
  String get voiceCallActive => 'Llamada activa';

  @override
  String get voiceWaiting => 'Esperando';

  @override
  String get voiceWaitingUpper => 'ESPERANDO';

  @override
  String get voiceRec => 'REC';

  @override
  String get voiceStop => 'Detener';

  @override
  String get voiceRecord => 'Grabación';

  @override
  String get voiceTranslation => 'Traducción';

  @override
  String get voiceAudio => 'Audio';

  @override
  String get voiceFlipCamera => 'Girar';

  @override
  String get voiceBackground => 'Fondo';

  @override
  String get voiceAssistantSpeakingStatus => 'Asistente hablando...';

  @override
  String get voiceAssistantListeningStatus => 'Asistente escuchando...';

  @override
  String get voiceUnmute => 'Activar sonido';

  @override
  String get voiceMic => 'Micrófono';

  @override
  String get voiceAssistantLabel => 'Asistente';

  @override
  String get voiceCameraOn => 'Cámara encendida';

  @override
  String get voiceCameraLabel => 'Cámara';

  @override
  String get voiceEndCall => 'Finalizar llamada';

  @override
  String get voiceWaitingParticipants => 'Esperando a los participantes...';

  @override
  String get voiceYou => 'Tú';

  @override
  String get voiceAiAssistant => 'Asistente AI';

  @override
  String get voiceVideoUnavailable => 'Vídeo no disponible';

  @override
  String get voiceSearchNickname => 'Buscar por apodo...';

  @override
  String get voiceTranscriptionWord => 'transcripción';

  @override
  String get voiceRecordingWord => 'grabación';

  @override
  String get voiceConnecting => 'Conectando...';

  @override
  String get voiceVideoBackground => 'Fondo de vídeo';

  @override
  String get voiceCallSettings => 'Configuración de llamada';

  @override
  String get voiceEnableAI => 'Activar asistente AI';

  @override
  String get voiceAIParticipating => 'AI participará en la conversación';

  @override
  String get voiceNormalCall => 'Llamada normal sin AI';

  @override
  String get voiceCallConfirm => '¿Hacer una llamada?';

  @override
  String get chatAlreadyInCall => 'Ya en una llamada';

  @override
  String chatCallError(String error) {
    return 'Error de llamada: $error';
  }

  @override
  String get chatPhotoVideo => 'Foto / Vídeo';

  @override
  String get chatCamera => 'Cámara';

  @override
  String get chatFile => 'Archivo';

  @override
  String get chatContact => 'Contacto';

  @override
  String get chatSelectContact => 'Seleccionar un contacto';

  @override
  String get chatNoContacts => 'Sin contactos';

  @override
  String get chatUser => 'Usuario';

  @override
  String get chatFileAttachment => '📎 Archivo';

  @override
  String chatFileUploadError(String error) {
    return 'Error de carga de archivo: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Mensaje de voz';

  @override
  String get chatGroup => 'Grupo';

  @override
  String get chatDialog => 'Diálogo';

  @override
  String get chatCall => 'Llamada';

  @override
  String get chatStartConversation => 'Iniciar una conversación';

  @override
  String get chatYou => 'Tú';

  @override
  String get chatIsTyping => 'está escribiendo...';

  @override
  String chatUserIsTyping(String name) {
    return '$name está escribiendo...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names están escribiendo...';
  }

  @override
  String get chatPreparingFile => 'Preparando archivo…';

  @override
  String chatUploading(int progress) {
    return 'Subiendo… $progress%';
  }

  @override
  String get chatEdited => 'Editado';

  @override
  String get chatViaMesh => 'vía mesh';

  @override
  String get chatReply => 'Responder';

  @override
  String get chatEdit => 'Editar';

  @override
  String get chatCopy => 'Copiar';

  @override
  String get chatCopied => 'Copiado';

  @override
  String get chatSaveMedia => 'Guardar';

  @override
  String get chatForward => 'Reenviar';

  @override
  String get chatSaving => 'Guardando...';

  @override
  String get chatSavedToGallery => 'Guardado en la galería';

  @override
  String get chatNoSavePermission =>
      'Sin permiso para guardar. Verifica la configuración.';

  @override
  String get chatFileSaved => 'File saved';

  @override
  String get chatFileSaveError => 'Error al guardar el archivo';

  @override
  String get chatDeleteMessage => 'Eliminar mensaje';

  @override
  String get chatDeleteForMe => 'Eliminar para mí';

  @override
  String get chatDeleteForEveryone => 'Eliminar para todos';

  @override
  String get chatMessageForwarded => 'Mensaje reenviado';

  @override
  String get chatContactTapToOpen => 'Contacto · toca para abrir';

  @override
  String get chatForwardTo => 'Reenviar a...';

  @override
  String get chatSearchHint => 'Buscar...';

  @override
  String get chatRecording => 'Grabando...';

  @override
  String get chatMessageHint => 'Mensaje...';

  @override
  String get chatHideKeyboard => 'Ocultar teclado';

  @override
  String get chatEditing => 'Editando';

  @override
  String get chatFileDownloadError => 'Error al descargar el archivo';

  @override
  String get chatVoiceMessageShort => 'Mensaje de voz';

  @override
  String get chatVideoSavedToGallery => 'Video guardado en la galería';

  @override
  String get chatSavingError => 'Error al guardar';

  @override
  String get convSetNickname => 'Establecer un apodo';

  @override
  String get convNicknameRequired =>
      'Se requiere un apodo para usar el mensajero. Otros usuarios pueden encontrarte por él.';

  @override
  String get convNicknameRules => '3–30 caracteres: letras, dígitos, _';

  @override
  String get convNicknameTaken => 'Apodo ya tomado';

  @override
  String get convSaveError => 'Error al guardar';

  @override
  String get convContactsLabel => 'Contactos';

  @override
  String get convDefaultUser => 'Usuario';

  @override
  String get convNoDialogs => 'No hay conversaciones';

  @override
  String get convFindUserToChat => 'Buscar un usuario para empezar a chatear';

  @override
  String get convDefaultContact => 'Contacto';

  @override
  String get dashboardUser => 'Usuario';

  @override
  String get dashboardIncomingCall => 'Llamada entrante';

  @override
  String get dashboardDecline => 'Rechazar';

  @override
  String get dashboardAccept => 'Aceptar';

  @override
  String get dashboardActiveCall => 'Llamada activa — toca para volver';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Actualización disponible $version';
  }

  @override
  String get dashboardUpdate => 'Actualizar';

  @override
  String get dashboardWhatsNew => 'Novedades';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'Novedades en $version';
  }

  @override
  String get dashboardInstalling => 'Instalando...';

  @override
  String get updateInstallConflictTitle => 'Couldn\'t update in place';

  @override
  String updateInstallConflictBody(String filename) {
    return 'The installed version is signed with a different certificate, so Android refuses to update it. Uninstall the app via Settings → Apps → Taler ID, then open the Downloads folder in your file manager and tap $filename to install fresh. This step is only needed once.';
  }

  @override
  String get updateInstallFailedTitle => 'Install failed';

  @override
  String updateInstallFailedBody(String reason, String filename) {
    return '$reason\n\nThe APK was saved to your Downloads folder as $filename — you can try installing it manually from a file manager.';
  }

  @override
  String get updateInstallOk => 'OK';

  @override
  String get contactRequestsTitle => 'Contactos';

  @override
  String get messengerContactRequestsSection => 'Solicitudes de contacto';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuevas solicitudes',
      one: '1 nueva solicitud',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Buscar';

  @override
  String get contactRequestsIncoming => 'Entrantes';

  @override
  String get contactRequestsSent => 'Enviadas';

  @override
  String get contactRequestsSearchHint => 'Apodo o correo electrónico';

  @override
  String get contactRequestSent => 'Solicitud enviada';

  @override
  String get contactRequestsNoUsers => 'No se encontraron usuarios';

  @override
  String get contactRequestsSearchHelp =>
      'Introduce el apodo exacto o correo electrónico\ny presiona buscar';

  @override
  String get contactRequestsSendTooltip => 'Enviar solicitud';

  @override
  String get contactRequestTitle => 'Solicitud de contacto';

  @override
  String contactRequestConfirm(String name) {
    return '¿Enviar solicitud de contacto a $name?';
  }

  @override
  String get contactRequestSend => 'Enviar';

  @override
  String get contactRequestsNoIncoming => 'No hay solicitudes entrantes';

  @override
  String get contactRequestsNoSent => 'No hay solicitudes enviadas';

  @override
  String get contactRequestStatusPending => 'Esperando respuesta';

  @override
  String get contactRequestStatusAccepted => 'Aceptada';

  @override
  String get contactRequestStatusRejected => 'Rechazada';

  @override
  String get userSearchTitle => 'Buscar usuario';

  @override
  String get userSearchHint => 'Apodo, teléfono o correo electrónico';

  @override
  String get userSearchHelper =>
      'Introduce @apodo, correo electrónico o nombre para buscar';

  @override
  String get userSearchNoUsers => 'No se encontraron usuarios';

  @override
  String get userProfileShareContact => 'Compartir contacto';

  @override
  String get userProfileShareContactDesc => 'Enviar enlace de contacto';

  @override
  String get userProfileCopyLink => 'Copiar enlace';

  @override
  String get userProfileCopied => 'Copiado';

  @override
  String get userProfileTitle => 'Perfil';

  @override
  String get userProfileLoadError => 'Error al cargar el perfil';

  @override
  String get userProfileMessage => 'Mensaje';

  @override
  String get userProfileCall => 'Llamar';

  @override
  String get userProfileRequestSent => 'Solicitud enviada';

  @override
  String get userProfileAccept => 'Aceptar';

  @override
  String get userProfileDecline => 'Rechazar';

  @override
  String get userProfileAddToContacts => 'Añadir a contactos';

  @override
  String get userProfileMediaTab => 'Medios';

  @override
  String get userProfileFilesTab => 'Archivos';

  @override
  String get userProfileLinksTab => 'Enlaces';

  @override
  String get userProfileRecordingsTab => 'Grabaciones';

  @override
  String get userProfileSummariesTab => 'Resúmenes';

  @override
  String get userProfileNoMedia => 'No hay archivos multimedia';

  @override
  String get userProfileNoFiles => 'No hay archivos';

  @override
  String get userProfileNoLinks => 'No hay enlaces';

  @override
  String get userProfileNoRecordings => 'No hay grabaciones';

  @override
  String get userProfileNoSummaries => 'No hay resúmenes';

  @override
  String get userProfileMeetingSummary => 'Resumen de la reunión';

  @override
  String get userProfileFailedOpenChat => 'Error al abrir el chat';

  @override
  String get sharedMediaTitle => 'Medios y archivos';

  @override
  String get sharedMediaTab => 'Medios';

  @override
  String get sharedFilesTab => 'Archivos';

  @override
  String get sharedLinksTab => 'Enlaces';

  @override
  String get sharedNoMedia => 'No hay archivos multimedia';

  @override
  String get sharedNoFiles => 'No hay archivos';

  @override
  String get sharedNoLinks => 'No hay enlaces';

  @override
  String get shareToChat => 'Reenviar al chat';

  @override
  String get shareSelectChat => 'Seleccionar chat';

  @override
  String get shareNoChats => 'No hay chats';

  @override
  String shareFilesCount(int count) {
    return '$count archivos';
  }

  @override
  String get contactsTitle => 'Contactos';

  @override
  String get contactsAddTooltip => 'Añadir contacto';

  @override
  String get contactsSearchHint => 'Buscar contactos...';

  @override
  String get contactsNotFound => 'No se encontró nada';

  @override
  String get contactsEmpty => 'No hay contactos';

  @override
  String get contactsAdd => 'Añadir contacto';

  @override
  String get contactsPendingConfirmation => 'Esperando confirmación';

  @override
  String get contactsMessage => 'Mensaje';

  @override
  String get contactsCall => 'Llamar';

  @override
  String get contactsResend => 'Reenviar solicitud';

  @override
  String get contactsResendTimeout => 'Reintentar en 24h';

  @override
  String get contactsResent => 'Solicitud reenviada';

  @override
  String get contactsWantsToConnect => 'Quiere conectarse contigo';

  @override
  String get contactsSearchPeople => 'Buscar personas';

  @override
  String get notesTitle => 'Notas';

  @override
  String get notesAssistantSpeaking => 'Asistente hablando...';

  @override
  String get notesListening => 'Escuchando...';

  @override
  String get notesEmpty => 'Sin notas';

  @override
  String get notesEmptyHint =>
      'Presiona el micrófono para dictar\no + para entrada manual';

  @override
  String get notesDeleteConfirm => '¿Eliminar nota?';

  @override
  String get notesNew => 'Nueva nota';

  @override
  String get notesEdit => 'Editar';

  @override
  String get notesTitleHint => 'Título';

  @override
  String get notesContentHint => 'Escribe tus pensamientos...';

  @override
  String get calendarTitle => 'Calendario';

  @override
  String get calendarStop => 'Detener';

  @override
  String get calendarVoiceInput => 'Entrada de voz';

  @override
  String get calendarNewEvent => 'Nuevo evento';

  @override
  String get calendarAssistantSpeaking => 'Asistente hablando...';

  @override
  String get calendarListening => 'Escuchando...';

  @override
  String calendarInvitations(int count) {
    return 'Invitaciones ($count)';
  }

  @override
  String get calendarNoEvents => 'Sin eventos';

  @override
  String get calendarDayMon => 'Lun';

  @override
  String get calendarDayTue => 'Mar';

  @override
  String get calendarDayWed => 'Mié';

  @override
  String get calendarDayThu => 'Jue';

  @override
  String get calendarDayFri => 'Vie';

  @override
  String get calendarDaySat => 'Sáb';

  @override
  String get calendarDaySun => 'Dom';

  @override
  String get calendarEnterRoom => 'Entrar a la sala';

  @override
  String get calendarMeeting => 'Reunión';

  @override
  String calendarLocationPrefix(String location) {
    return 'Ubicación: $location';
  }

  @override
  String get calendarEditEvent => 'Editar';

  @override
  String get calendarTitleHint => 'Título';

  @override
  String get calendarDescriptionHint => 'Descripción';

  @override
  String get calendarTypeEvent => 'Evento';

  @override
  String get calendarTypeMeeting => 'Reunión';

  @override
  String get calendarTypeReminder => 'Recordatorio';

  @override
  String get calendarKindEvent => 'Event';

  @override
  String get calendarKindTask => 'Task';

  @override
  String get calendarTaskMarkDone => 'Mark done';

  @override
  String get calendarTaskDelete => 'Delete';

  @override
  String get calendarTaskDoneMsg => 'Task completed';

  @override
  String get calendarTaskDeletedMsg => 'Task deleted';

  @override
  String get calendarTypeLabel => 'Tipo';

  @override
  String get calendarMeetingLink => 'Enlace de reunión';

  @override
  String get calendarLocationHint => 'Ubicación';

  @override
  String get calendarDateLabel => 'Fecha';

  @override
  String get calendarTimeLabel => 'Hora';

  @override
  String get calendarReminderLabel => 'Recordatorio';

  @override
  String get calendarReminderNone => 'Ninguno';

  @override
  String get calendarReminder15min => '15 min antes';

  @override
  String get calendarReminder30min => '30 min antes';

  @override
  String get calendarReminder1hour => '1 hora antes';

  @override
  String get calendarRepeatLabel => 'Repetir';

  @override
  String get calendarRepeatNone => 'No repetir';

  @override
  String get calendarRepeatDaily => 'Cada día';

  @override
  String get calendarRepeatWeekly => 'Cada semana';

  @override
  String get calendarRepeatMonthly => 'Cada mes';

  @override
  String get calendarRepeatYearly => 'Cada año';

  @override
  String get calendarParticipants => 'Participantes';

  @override
  String get calendarAddParticipant => 'Añadir';

  @override
  String get calendarSearchContacts => 'Buscar contactos...';

  @override
  String get calendarNoContacts => 'Sin contactos';

  @override
  String get calendarStatusAccepted => 'Aceptado';

  @override
  String get calendarStatusDeclined => 'Rechazado';

  @override
  String get calendarStatusMaybe => 'Quizás';

  @override
  String get calendarStatusPending => 'Pendiente';

  @override
  String get calendarEndTime => 'Hora de finalización';

  @override
  String get calendarYourAnswer => 'Tu respuesta:';

  @override
  String get calendarOrganizer => 'Organizador';

  @override
  String calendarDeleteError(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get calendarRsvpAccept => 'Aceptar';

  @override
  String get calendarRsvpMaybe => 'Quizás';

  @override
  String get calendarRsvpDecline => 'Rechazar';

  @override
  String get callHistoryTitle => 'Llamadas';

  @override
  String get callHistoryTab => 'Historial de llamadas';

  @override
  String get callHistoryTempMeeting => 'Reunión temporal';

  @override
  String get callHistoryCopy => 'Copiar';

  @override
  String get callHistoryLinkCopied => 'Enlace copiado';

  @override
  String get callHistoryShare => 'Compartir';

  @override
  String get callHistoryEnter => 'Entrar';

  @override
  String get callHistoryAlreadyInCall => 'Ya en una llamada';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'No se pudo determinar la otra parte';

  @override
  String get callHistoryContacts => 'Contactos';

  @override
  String get callHistoryFailedLoadRoom => 'Error al cargar tu sala';

  @override
  String get callHistoryYourRoom => 'Tu sala';

  @override
  String get callHistoryCreateMeeting => 'Crear reunión';

  @override
  String get callHistoryMeetingSummaries => 'Resúmenes de reuniones';

  @override
  String get callHistoryMeetingRecordings => 'Grabaciones de reuniones';

  @override
  String get callHistoryNoCalls => 'Sin llamadas';

  @override
  String get callHistoryMissed => 'Perdida';

  @override
  String get callHistoryRecording => 'Grabación';

  @override
  String get callHistorySummary => 'Resumen';

  @override
  String get callHistoryCallAgain => 'Llamar de nuevo';

  @override
  String callHistoryTodayTime(String time) {
    return 'Hoy, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Ayer, $time';
  }

  @override
  String get callHistoryUnknown => 'Desconocido';

  @override
  String get callHistoryDetails => 'Detalles de la llamada';

  @override
  String get callHistoryOutgoing => 'Llamada saliente';

  @override
  String get callHistoryIncoming => 'Llamada entrante';

  @override
  String callHistoryDuration(String duration) {
    return 'Duración: $duration';
  }

  @override
  String get callHistoryWithAI => 'Con asistente AI';

  @override
  String get callHistoryParticipants => 'Participantes';

  @override
  String get callDetailYouSuffix => '(Tú)';

  @override
  String get callHistoryMeetingSummary => 'Resumen de la reunión';

  @override
  String get callHistoryMoreDetails => 'Más detalles';

  @override
  String get callHistorySummaryProcessing => 'Procesando resumen...';

  @override
  String get callHistoryMeetingRecording => 'Grabación de la reunión';

  @override
  String get callHistoryProcessing => 'Procesando...';

  @override
  String get callHistoryCreateTranscript => 'Crear transcripción';

  @override
  String get callHistoryNoSummaries => 'Sin resúmenes';

  @override
  String get callHistoryRecordDuringCall =>
      'Presiona \"Grabar\" durante una llamada';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Reunión $time';
  }

  @override
  String get callHistoryTranscribing => 'Transcribiendo y resumiendo...';

  @override
  String get callHistoryTranscriptCreated => 'Transcripción creada';

  @override
  String get callHistoryNoRecordings => 'Sin grabaciones';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Grabación $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Grabación no disponible';

  @override
  String get callHistoryTranscriptReady => 'Transcripción lista';

  @override
  String get callHistoryTranscript => 'Transcripción';

  @override
  String get callHistoryKeyPoints => 'Puntos clave';

  @override
  String get callHistoryTasks => 'Tareas';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'Asignado a: $assignee';
  }

  @override
  String get callHistoryDecisions => 'Decisiones';

  @override
  String get callHistoryShowTranscript => 'Mostrar transcripción completa';

  @override
  String get profileScanQr => 'Escanear QR';

  @override
  String get profileMyQrCode => 'Mi código QR';

  @override
  String profileAddMeShare(String userId) {
    return '¡Añádeme en Taler ID!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Muestra este código para añadirte';

  @override
  String get profileEditDesc =>
      'Nombre, apellido, segundo nombre, fecha de nacimiento';

  @override
  String get profileAboutMe => 'Sobre mí';

  @override
  String get profileAboutMeDesc => 'Valores, habilidades, intereses y más';

  @override
  String get profileNotes => 'Notas';

  @override
  String get profileNotesDesc => 'Pensamientos, ideas y notas';

  @override
  String get profileAvatarUpdated => 'Avatar actualizado';

  @override
  String get profileNickname => 'Apodo';

  @override
  String get profileNotSet => 'No establecido';

  @override
  String get profileChangeNickname => 'Cambiar apodo';

  @override
  String get profileNicknameUpdated => 'Apodo actualizado';

  @override
  String get profileShareLabel => 'Compartir';

  @override
  String get profileScanQrCode => 'Escanear código QR';

  @override
  String get profilePointCamera => 'Apunta la cámara al código QR';

  @override
  String get profilePhotoCamera => 'Tomar foto';

  @override
  String get profilePhotoGallery => 'Elegir de la galería';

  @override
  String get editProfilePatronymic => 'Segundo nombre (opcional)';

  @override
  String get editProfileDateFormat => 'DD.MM.AAAA';

  @override
  String get aboutMeTitle => 'Sobre mí';

  @override
  String get aboutMeClickToFill => 'Haz clic para completar';

  @override
  String get aboutMeCoreValues => 'Valores';

  @override
  String get aboutMeWorldview => 'Cosmovisión';

  @override
  String get aboutMeSkills => 'Habilidades';

  @override
  String get aboutMeInterests => 'Intereses';

  @override
  String get aboutMeDesires => 'Deseos';

  @override
  String get aboutMeBackground => 'Perfil';

  @override
  String get aboutMeLikes => 'Gustos';

  @override
  String get aboutMeDislikes => 'Disgustos';

  @override
  String get aboutMeDeleteSection => '¿Eliminar sección?';

  @override
  String get aboutMeDeleteConfirm =>
      'Todos los datos en esta sección serán eliminados.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Error de conexión: $error';
  }

  @override
  String get aboutMeVisibility => 'Visibilidad';

  @override
  String get aboutMeTags => 'Etiquetas';

  @override
  String get aboutMeAddTag => 'Añadir etiqueta...';

  @override
  String get aboutMeDescription => 'Descripción';

  @override
  String get aboutMeDescribeLong => 'Cuéntanos más...';

  @override
  String get aboutMeVisibilityEveryone => 'Todos';

  @override
  String get aboutMeVisibilityContacts => 'Contactos';

  @override
  String get aboutMeVisibilityOnlyMe => 'Solo yo';

  @override
  String get settingsProfileSubtitle => 'Perfil';

  @override
  String get settingsWallpaper => 'Fondo de pantalla';

  @override
  String get settingsWallpaperDesc => 'Imagen de fondo para toda la app';

  @override
  String get settingsWallpaperNone => 'Ninguno';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsKycVerification => 'Verificación de identidad (KYC)';

  @override
  String get settingsOrganizations => 'Organizaciones';

  @override
  String get incomingCallLabel => 'Llamada entrante';

  @override
  String get incomingCallDecline => 'Rechazar';

  @override
  String get incomingCallAccept => 'Aceptar';

  @override
  String callGlareTitle(String name) {
    return '$name is also calling you';
  }

  @override
  String get callGlareBody =>
      'You both dialled each other at the same moment. Pick up theirs or stay on yours?';

  @override
  String get callGlareSwitch => 'Pick up theirs';

  @override
  String get callGlareKeepOwn => 'Stay on mine';

  @override
  String get meshIncomingCallLabel => '📡 Llamada de malla entrante';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'Dispositivo de malla $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'Termina la llamada actual primero';

  @override
  String get callPopupTransportTitle => 'Llamar vía';

  @override
  String get callPopupTransportMesh => '📡 Malla (peer-to-peer)';

  @override
  String get callPopupTransportLk => '📞 Servidor';

  @override
  String get callPopupTransportMeshUnavailable =>
      'Contacto no accesible vía malla';

  @override
  String get meshOnboardingTitle =>
      '📡 Las llamadas de malla necesitan la app abierta';

  @override
  String get meshOnboardingBody =>
      'Cuando el teléfono está bloqueado, las llamadas de malla pueden cortarse después de ~30 segundos (limitación de iOS).';

  @override
  String get meshOnboardingAck => 'Entendido';

  @override
  String get meshHistoryBadge => '📡 Malla';

  @override
  String get meshHistoryNoChatAvailable => 'El contacto no está en tu lista';

  @override
  String get meshCallStatusInviting => 'Llamando…';

  @override
  String get meshCallStatusConnecting => 'Conectando…';

  @override
  String get meshCallEndedUserHangup => 'Llamada finalizada';

  @override
  String get meshCallEndedRemoteHangup => 'Finalizada por el par';

  @override
  String get meshCallEndedRejected => 'Rechazada';

  @override
  String get meshCallEndedNoAnswer => 'Sin respuesta';

  @override
  String get meshCallEndedConnectionLost => 'Conexión perdida';

  @override
  String get meshCallEndedError => 'Error de conexión';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 Malla · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 Malla';

  @override
  String get batteryExemptionTitle => '📡 Llamadas de malla fiables';

  @override
  String get batteryExemptionBody =>
      'Permite que la app funcione sin restricciones de batería para que Android no cierre la malla en segundo plano.';

  @override
  String get batteryExemptionAccept => 'Abrir configuración';

  @override
  String get batteryExemptionDismiss => 'Ahora no';

  @override
  String get groupCamera => 'Cámara';

  @override
  String get groupGallery => 'Galería';

  @override
  String get groupAvatarUpdated => 'Avatar del grupo actualizado';

  @override
  String get groupNameTitle => 'Nombre del grupo';

  @override
  String get groupEnterName => 'Introduce el nombre';

  @override
  String get groupDescriptionTitle => 'Descripción del grupo';

  @override
  String get groupEnterDescription => 'Introduce la descripción del grupo';

  @override
  String get groupChangeRoleTitle => 'Cambiar rol';

  @override
  String get groupRemoveMemberTitle => 'Eliminar miembro';

  @override
  String get groupDescription => 'Descripción';

  @override
  String get groupAddDescription => 'Añadir descripción del grupo';

  @override
  String get groupNoDescription => 'Sin descripción';

  @override
  String get groupMediaAndFiles => 'Medios y archivos';

  @override
  String get groupMuteNotifications => 'Silenciar notificaciones';

  @override
  String get groupMuted => 'Silenciado';

  @override
  String get groupNoResults => 'Sin resultados';

  @override
  String get authInvalidCode => 'Código inválido. Inténtalo de nuevo.';

  @override
  String get loginSubtitle => 'Usa correo electrónico y contraseña';

  @override
  String get emailRequired => 'Introduce el correo electrónico';

  @override
  String get emailInvalid => 'Correo electrónico inválido';

  @override
  String get passwordRequired => 'Introduce la contraseña';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'Una cuenta para todo el ecosistema Taler';

  @override
  String get usernameOptional => 'Nombre de usuario (opcional)';

  @override
  String get usernameMinLength => 'Mínimo 3 caracteres';

  @override
  String get usernameMaxLength => 'Máximo 30 caracteres';

  @override
  String get usernameInvalid => 'Solo letras, dígitos y _';

  @override
  String get biometricLoginReason => 'Inicia sesión en Taler ID';

  @override
  String get docTypePassport => 'Pasaporte';

  @override
  String get docTypeIdCard => 'DNI';

  @override
  String get docTypeDriverLicense => 'Carnet de conducir';

  @override
  String get docTypeResidencePermit => 'Permiso de residencia';

  @override
  String addressApartment(String number) {
    return 'apt. $number';
  }

  @override
  String get failedToUpdateProfile => 'Error al actualizar el perfil';

  @override
  String get failedToStartKyb => 'Error al iniciar la verificación KYB';

  @override
  String get orgUpdated => 'Organización actualizada';

  @override
  String get failedToUpdateOrg => 'Error al actualizar la organización';

  @override
  String get failedToChangeRole => 'Error al cambiar el rol';

  @override
  String get failedToRemoveMember => 'Error al eliminar el miembro';

  @override
  String get capabilityMessagesTitle => 'Mensajes';

  @override
  String get capabilityMessagesDesc =>
      'Revisa mensajes o escribe a alguien. Por ejemplo: \"Escribe a Viktor: llegaré en una hora\"';

  @override
  String get capabilityCallsTitle => 'Llamadas';

  @override
  String get capabilityCallsDesc =>
      'Llama a cualquier contacto por voz. Por ejemplo: \"Llama a Viktor Viktorov\"';

  @override
  String get capabilityChatTitle => 'Historial de chat';

  @override
  String get capabilityChatDesc =>
      'Analizaré el historial de chat. Por ejemplo: \"¿De qué hablamos con Viktor?\"';

  @override
  String get capabilityProfileTitle => 'Perfil';

  @override
  String get capabilityProfileDesc =>
      'Mostraré o actualizaré tu perfil. Por ejemplo: \"Muestra mi perfil\"';

  @override
  String get capabilityCoachingTitle => 'Coaching';

  @override
  String get capabilityCoachingDesc =>
      'Modos: coaching ICF, psicólogo, consulta de RRHH. Di: \"Hagamos coaching\"';

  @override
  String get capabilityCalendarTitle => 'Calendario';

  @override
  String get capabilityCalendarDesc =>
      'Programa una reunión o establece un recordatorio. Por ejemplo: \"Programa una reunión con Viktor para mañana a las 15:00\"';

  @override
  String get capabilityNotesTitle => 'Notas';

  @override
  String get capabilityNotesDesc =>
      'Guarda una idea o lee notas recientes. Por ejemplo: \"Anota una idea...\" o \"Lee notas recientes\"';

  @override
  String get assistantCallConfirm => '¿Hacer una llamada?';

  @override
  String get callNoAnswer => 'Sin respuesta';

  @override
  String get contactDelete => 'Eliminar contacto';

  @override
  String get contactDeleteTitle => 'Eliminar contacto';

  @override
  String get contactDeleteConfirm =>
      '¿Estás seguro? Este contacto será eliminado.';

  @override
  String get contactBlock => 'Bloquear';

  @override
  String get contactBlockTitle => 'Bloquear usuario';

  @override
  String get contactBlockConfirm =>
      'Este usuario no podrá enviarte mensajes ni llamarte.';

  @override
  String get contactUnblock => 'Desbloquear';

  @override
  String get contactBlocked => 'Bloqueado';

  @override
  String get contactYouAreBlocked => 'Este usuario te ha bloqueado';

  @override
  String get chatBlockedByYou => 'Has bloqueado a este usuario';

  @override
  String get chatYouAreBlocked => 'Has sido bloqueado por este usuario';

  @override
  String get chatNotContacts =>
      'Añade este usuario a contactos para enviarle mensajes';

  @override
  String get contactRevokeRequest => 'Revocar solicitud';

  @override
  String get messengerPoll => 'Encuesta';

  @override
  String get messengerCreatePoll => 'Crear encuesta';

  @override
  String get messengerPollQuestion => 'Pregunta';

  @override
  String messengerPollOption(int number) {
    return 'Opción $number';
  }

  @override
  String get messengerPollAddOption => 'Añadir opción';

  @override
  String get messengerPollAnonymous => 'Votación anónima';

  @override
  String get messengerPollMultiple => 'Elección múltiple';

  @override
  String get messengerPollCreateError => 'Error al crear la encuesta';

  @override
  String get messengerPollUnavailable => 'Encuesta no disponible';

  @override
  String get messengerPollMultipleNote => 'Puedes seleccionar varias';

  @override
  String messengerPollVotes(int count) {
    return '$count votos';
  }

  @override
  String get messengerVideoMessage => 'Mensaje de video';

  @override
  String get messengerVideoRecordError => 'Error de grabación de video';

  @override
  String get messengerVideoPlaybackError => 'No se pudo reproducir el video';

  @override
  String get messengerGalleryAccessError => 'Sin acceso a la galería';

  @override
  String get messengerSearchInChat => 'Buscar en el chat...';

  @override
  String get messengerSaveToFavorites => 'Guardar en favoritos';

  @override
  String get messengerSavedToFavorites => 'Guardado en favoritos';

  @override
  String get messengerSearchInMessages => 'Buscar en mensajes...';

  @override
  String messengerFoundInMessages(int count) {
    return 'Encontrado en mensajes ($count)';
  }

  @override
  String get messengerGroupDefault => 'Grupo';

  @override
  String get messengerUserDefault => 'Usuario';

  @override
  String get messengerPin => 'Fijar';

  @override
  String get messengerUnpin => 'Desfijar';

  @override
  String get messengerArchive => 'Archivar';

  @override
  String get messengerUnarchive => 'Desarchivar';

  @override
  String get messengerDeleteChat => 'Eliminar chat';

  @override
  String get messengerDeleteChatTitle => '¿Eliminar chat?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return '¿Eliminar chat con $name? Esto no se puede deshacer.';
  }

  @override
  String get messengerCreateChannel => 'Crear canal';

  @override
  String get messengerChannelName => 'Nombre';

  @override
  String get messengerChannelDescription => 'Descripción (opcional)';

  @override
  String get messengerChannelCreateError => 'Error al crear el canal';

  @override
  String get messengerFilterAll => 'Todos';

  @override
  String get messengerFilterUnread => 'No leídos';

  @override
  String get messengerFilterPersonal => 'Personal';

  @override
  String get messengerFilterGroups => 'Grupos';

  @override
  String get messengerFilterChannels => 'Canales';

  @override
  String get messengerArchivedSection => 'Archivados';

  @override
  String get messengerSavedSection => 'Favoritos';

  @override
  String get messengerSavedSubtitle => 'Guardar en memoria';

  @override
  String messengerArchiveTitle(int count) {
    return 'Archivados ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'El archivo está vacío';

  @override
  String messengerYouPrefix(String message) {
    return 'Tú: $message';
  }

  @override
  String get messengerMissedCall => 'Llamada perdida';

  @override
  String get messengerSavedTitle => 'Favoritos';

  @override
  String get messengerNoSavedMessages => 'No hay mensajes guardados';

  @override
  String get messengerSavedHint =>
      'Mantén presionado un mensaje → \"Guardar en favoritos\"';

  @override
  String get messengerDefaultFile => 'Archivo';

  @override
  String get messengerTopicDefault => 'General';

  @override
  String get messengerTopicNew => 'Nuevo tema';

  @override
  String get messengerTopicNameHint => 'Nombre del tema';

  @override
  String get messengerTopicIcon => 'Icono';

  @override
  String messengerTopicCount(int count) {
    return '$count temas';
  }

  @override
  String get messengerNoTopics => 'No hay temas';

  @override
  String get messengerNoMessages => 'No hay mensajes';

  @override
  String get you => 'Tú';

  @override
  String get messengerThread => 'Hilo';

  @override
  String get messengerThreadReply => 'respuesta';

  @override
  String get messengerThreadReplies => 'respuestas';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'No hay respuestas';

  @override
  String get messengerReplyHint => 'Responder al hilo...';

  @override
  String get messengerContactName => 'Nombre del contacto';

  @override
  String messengerOriginalName(String name) {
    return 'Nombre original: $name';
  }

  @override
  String get messengerDisplayName => 'Nombre para mostrar';

  @override
  String messengerShareContact(String name) {
    return 'Contacto en Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'Borrar mensajes automáticamente';

  @override
  String get messengerAutoDeleteOff => 'Desactivado';

  @override
  String get messengerAutoDelete7d => '7 días';

  @override
  String get messengerAutoDelete30d => '30 días';

  @override
  String get messengerAutoDelete90d => '90 días';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count días';
  }

  @override
  String get messengerSettingsHeader => 'Configuración';

  @override
  String get messengerAdminOnly => 'Solo admin puede publicar';

  @override
  String get messengerAdminOnlyDesc => 'Los miembros solo pueden leer';

  @override
  String get messengerTopics => 'Temas';

  @override
  String get messengerTopicsDesc => 'Dividir chat en temas';

  @override
  String get aiTwinSection => 'Gemelo de Voz AI';

  @override
  String get aiTwinEnabled => 'Activar Gemelo AI';

  @override
  String get aiTwinEnabledDesc =>
      'Si no respondes, tu gemelo AI toma la llamada con tu voz';

  @override
  String get aiTwinTimeout => 'Tiempo de espera de respuesta';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds seg';
  }

  @override
  String get aiTwinPrompt => 'Instrucciones AI';

  @override
  String get aiTwinPromptSubtitle =>
      'Cómo debe presentarse el gemelo AI y de qué hablar';

  @override
  String aiTwinPromptHint(String name) {
    return 'Hola, soy el gemelo de voz AI de $name. $name no puede atender ahora. Dime quién llama y de qué se trata — se lo pasaré.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Clonación de voz personalizada próximamente. Por ahora, la AI habla con la voz de $name.';
  }

  @override
  String get aiTwinDefaultName => 'el propietario';

  @override
  String get aiTwinPromptReset => 'Restablecer';

  @override
  String get callHistoryAiTwinAnswered => 'RESPONDIDO POR GEMELO AI';

  @override
  String get callHistoryAiTwinSummary => 'RESUMEN DE LLAMADA';

  @override
  String get callHistoryAiTwinTranscript => 'TRANSCRIPCIÓN';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'De $name';
  }

  @override
  String get aiTwinOfferTitle => 'No responde';

  @override
  String aiTwinOfferBody(String name) {
    return '$name no responde. ¿Dejar un mensaje con su gemelo de voz AI?';
  }

  @override
  String get aiTwinOfferBodyUser => 'Usuario';

  @override
  String get aiTwinOfferAccept => 'Sí, dejar mensaje';

  @override
  String get aiTwinOfferKeepWaiting => 'Seguir esperando';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'Tu sustituto AI';

  @override
  String get aiTwinHeroSubtitle =>
      'Responde llamadas con tu voz cuando no puedes.';

  @override
  String get aiTwinProfileTitle => 'Sustituto AI';

  @override
  String get aiTwinProfileDesc => 'Responde llamadas con tu voz';

  @override
  String get aiTwinBadgeOn => 'ACTIVO';

  @override
  String get aiAnalystTitle => 'Analista AI';

  @override
  String get aiAnalystSubtitle => 'Archivos, tareas, análisis — Claude';

  @override
  String get channelsDiscover => 'Buscar canal';

  @override
  String get channelsSearchHint => 'Buscar canales';

  @override
  String get channelsSubscribers => 'suscriptores';

  @override
  String get channelsSubscribe => 'Suscribirse';

  @override
  String get channelsUnsubscribe => 'Darse de baja';

  @override
  String get channelsSubscribedLabel => 'Estás suscrito';

  @override
  String get channelsSettings => 'Configuración del canal';

  @override
  String get channelsDelete => 'Eliminar canal';

  @override
  String get channelsDeleteConfirm => '¿Eliminar canal permanentemente?';

  @override
  String get channelsEmpty => 'No hay canales todavía';

  @override
  String get channelsOpen => 'Abrir';

  @override
  String get channelsNameLabel => 'Nombre';

  @override
  String get channelsDescriptionLabel => 'Descripción';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'El propietario no puede darse de baja. Elimina el canal en su lugar.';

  @override
  String get channelsNotFoundRedirect => 'El canal ya no existe';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count búsquedas',
      one: '$count búsqueda',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '$count archivo',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comandos',
      one: '$count comando',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imágenes',
      one: '$count imagen',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasos',
      one: '$count paso',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get savedTitle => 'Mensajes Guardados';

  @override
  String get savedSubtitle => 'Tu nube privada';

  @override
  String get savedOpenError => 'No se pudo abrir Mensajes Guardados';

  @override
  String get billingWalletTitle => 'Cartera';

  @override
  String get billingBuyPackage => 'Comprar paquete';

  @override
  String get billingCurrentBalance => 'Saldo actual';

  @override
  String get billingPackagesTitle => 'Paquetes';

  @override
  String get billingPackagesUnavailable => 'Paquetes no disponibles';

  @override
  String get billingRecentOperations => 'Operaciones recientes';

  @override
  String get billingAllOperations => 'Todas las operaciones';

  @override
  String get billingNoOperations => 'Sin operaciones';

  @override
  String get billingOperationsTitle => 'Operaciones';

  @override
  String get billingOperationsEmptyTitle => 'Aún no hay operaciones';

  @override
  String get billingOperationsEmptySubtitle =>
      'Las recargas y cargos por funciones de AI aparecerán aquí';

  @override
  String get billingPricebookTitle => 'Precios de funciones';

  @override
  String get billingPricebookUnavailable => 'Lista de precios no disponible';

  @override
  String get billingAiFeaturesTitle => 'Funciones de AI';

  @override
  String get billingInsufficientFundsTitle => 'Fondos insuficientes';

  @override
  String get billingInsufficientFundsSubtitle =>
      'Recarga tu saldo para usar esta función.';

  @override
  String billingRequiredLine(String required) {
    return 'Necesario: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'Disponible: $available μTAL';
  }

  @override
  String get billingTopUp => 'Recargar';

  @override
  String get billingCancel => 'Cancelar';

  @override
  String get billingRetry => 'Reintentar';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'Saldo bajo: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'Cartera y Saldo';

  @override
  String get billingSectionHeader => 'Facturación y AI';

  @override
  String get billingFeatureVoiceAssistant => 'Asistente de voz';

  @override
  String get billingFeatureWebSearch => 'Búsqueda web del asistente';

  @override
  String get billingFeatureAiTwin => 'Gemelo de voz';

  @override
  String get billingFeatureAiTwinLong => 'Gemelo de voz (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'Bot de llamadas salientes';

  @override
  String get billingFeatureOutboundCallLong => 'Bot de llamadas salientes';

  @override
  String get billingFeatureWhisperTranscribe => 'Transcripción de llamadas';

  @override
  String get billingFeatureMeetingSummary => 'Resúmenes de llamadas AI';

  @override
  String get billingConfigureAiTwin => 'Configurar gemelo AI';

  @override
  String get billingWebSearchSubtitle => '(usado por el asistente)';

  @override
  String billingPackagePurchased(String balance) {
    return 'Paquete comprado: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'Recomendado';

  @override
  String get billingSessionTerminatedNoFunds =>
      'Saldo agotado — sesión finalizada';

  @override
  String get billingSessionTerminatedGeneric =>
      'Sesión del asistente finalizada';

  @override
  String billingBuyForPrice(String price) {
    return 'Comprar por €$price';
  }

  @override
  String get billingTxTypeTopup => 'Recarga';

  @override
  String get billingTxTypeRefund => 'Reembolso';

  @override
  String get billingTxTypeSpend => 'Cargo';

  @override
  String get billingUnitMinute => 'minuto';

  @override
  String get billingUnitRequest => 'solicitud';

  @override
  String get billingUnitToken => 'token';

  @override
  String get billingUnitTokens1k => '1K tokens';

  @override
  String get billingUnitCall => 'llamada';

  @override
  String get groupCallSelectParticipants => 'Seleccionar participantes';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'Buscar';

  @override
  String get groupCallMaxReached => 'Máximo 7 participantes';

  @override
  String get groupCallLobbyTitle => 'Grupo • Lobby';

  @override
  String groupCallHostLabel(String name) {
    return 'Anfitrión: $name';
  }

  @override
  String get groupCallMicHint => 'El micrófono se activará al conectar';

  @override
  String get groupCallCancel => 'Cancelar';

  @override
  String get groupCallNoAnswer => 'Nadie respondió';

  @override
  String get groupCallEndedByHost => 'Llamada finalizada por el anfitrión';

  @override
  String get groupCallAllLeft => 'Todos abandonaron la llamada';

  @override
  String get groupCallEnded => 'Llamada finalizada';

  @override
  String groupCallActiveTitle(int count) {
    return 'Grupo • $count';
  }

  @override
  String get groupCallConnectionLost => 'Conexión perdida';

  @override
  String get groupCallMuteRequested => 'El anfitrión pidió a todos silenciar';

  @override
  String get groupCallUnmute => 'Activar sonido';

  @override
  String get groupCallMute => 'Silenciar';

  @override
  String get groupCallMuteAll => 'Silenciar a todos';

  @override
  String get groupCallLeave => 'Salir';

  @override
  String get groupCallStatusCalling => 'llamando…';

  @override
  String get groupCallStatusDeclined => 'rechazada';

  @override
  String get groupCallStatusTimeout => 'sin respuesta';

  @override
  String get groupCallStatusLeft => 'abandonó';

  @override
  String groupCallKickConfirm(String name) {
    return 'Eliminar a $name de la llamada';
  }

  @override
  String get groupCallCancelAction => 'Cancelar';

  @override
  String get groupCallActiveBanner => 'Llamada activa';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'Grupo: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'Grupo: $host';
  }

  @override
  String get groupCallCreateError => 'No se pudo crear la llamada';

  @override
  String get groupCallJoinError => 'No se pudo unir a la llamada';

  @override
  String get groupCallLivekitError => 'Error de LiveKit';

  @override
  String get groupCallDone => 'Hecho';

  @override
  String get groupCallNoResults => 'Sin resultados';

  @override
  String get groupCallNoContacts => 'Sin contactos';

  @override
  String get meshGcContactOffline => 'No en este Wi-Fi';

  @override
  String get meshGcOnlineViaMesh => 'En línea a través de mesh';

  @override
  String get meshGcMaxInvitees =>
      'Las llamadas grupales admiten hasta 4 invitados (5 personas en total).';

  @override
  String get meshGcStart => 'Iniciar llamada grupal';

  @override
  String get meshGcCancel => 'Cancelar';

  @override
  String get meshGcStatusCalling => 'Llamando…';

  @override
  String get meshGcStatusJoined => 'Unido';

  @override
  String get meshGcStatusDeclined => 'Rechazado';

  @override
  String get meshGcStatusNoAnswer => 'Sin respuesta';

  @override
  String get meshGcStatusConnectionFailed => 'Conexión fallida';

  @override
  String get meshGcStatusLeft => 'Salió';

  @override
  String get meshGcTopTitle => 'Malla';

  @override
  String get meshGcBusyOneOnOne => 'Termina tu llamada actual primero.';

  @override
  String get presenceOnline => 'en línea';

  @override
  String get presenceLastSeenJustNow => 'visto por última vez ahora';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'visto por última vez hace $minutes min';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'visto por última vez hoy a las $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'visto por última vez ayer a las $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'visto por última vez el $date';
  }

  @override
  String get presenceLastSeenRecently => 'visto por última vez recientemente';

  @override
  String get privacySectionTitle => 'Privacidad';

  @override
  String get privacyLastSeenLabel => 'Quién ve tu última hora de conexión';

  @override
  String get privacyEveryone => 'Todos';

  @override
  String get privacyContacts => 'Solo contactos';

  @override
  String get privacyNobody => 'Nadie';

  @override
  String get voiceTurnOffTranslation => 'Turn off translator';

  @override
  String get informerBotTitle => 'Informer';

  @override
  String get informerBotSubtitle => 'Wallet and balance monitoring';

  @override
  String seenByCount(int count) {
    return 'Seen by $count';
  }

  @override
  String get messageInfo => 'Message info';

  @override
  String get readBy => 'Read by';

  @override
  String get notReadYet => 'Not read yet';

  @override
  String get reactionsLabel => 'Reactions';

  @override
  String get noReactions => 'No reactions';

  @override
  String get mailTitle => 'Mail';

  @override
  String get mailSectionHeader => 'Mail';

  @override
  String get mailInboxEmpty => 'No emails yet';

  @override
  String get mailNoAccountTitle => 'Choose your @talerid.io address';

  @override
  String get mailNoAccountBody =>
      'Create your personal email address to send and receive mail.';

  @override
  String get mailChooseAddress => 'Choose address';

  @override
  String get mailAddressHint => 'username';

  @override
  String get mailAddressTaken => 'This address is already taken';

  @override
  String get mailAddressInvalid =>
      'Only latin letters, digits, dot, dash, underscore (3–64 chars)';

  @override
  String get mailAddressReserved => 'This name is reserved';

  @override
  String get mailAddressAvailable => 'Address is available';

  @override
  String get mailCreateAddress => 'Create address';

  @override
  String get mailSetupLater => 'Later';

  @override
  String get mailCompose => 'New email';

  @override
  String get mailTo => 'To';

  @override
  String get mailSubject => 'Subject';

  @override
  String get mailBody => 'Message';

  @override
  String get mailSend => 'Send';

  @override
  String get mailSent => 'Email sent';

  @override
  String get mailReply => 'Reply';

  @override
  String get mailDelete => 'Delete';

  @override
  String get mailMarkUnread => 'Mark as unread';

  @override
  String get mailAttachments => 'Attachments';

  @override
  String get mailAttachFile => 'Attach file';

  @override
  String get mailAppPasswords => 'App passwords';

  @override
  String get mailAppPasswordsHint =>
      'Use app passwords to connect Apple Mail, Gmail or other IMAP clients.';

  @override
  String get mailAppPasswordLabel => 'Name (e.g. iPhone Apple Mail)';

  @override
  String get mailAppPasswordCreate => 'Create password';

  @override
  String get mailAppPasswordShownOnce =>
      'Save this password now — it is shown only once.';

  @override
  String get mailAppPasswordCopied => 'Password copied';

  @override
  String get mailAppPasswordRevoke => 'Revoke';

  @override
  String get mailClientSettingsTitle => 'Client settings';

  @override
  String get mailSendLimitReached => 'Daily send limit reached';

  @override
  String get mailSendFailed => 'Failed to send email';

  @override
  String get mailAttachmentsTooLarge => 'Attachments must be under 10 MB total';

  @override
  String get mailQuotaTitle => 'Mailbox';

  @override
  String get mailFolders => 'Folders';

  @override
  String get mailFolderInbox => 'Inbox';

  @override
  String get mailFolderSent => 'Sent';

  @override
  String get mailFolderDrafts => 'Drafts';

  @override
  String get mailFolderJunk => 'Spam';

  @override
  String get mailFolderTrash => 'Trash';

  @override
  String get mailNewFolder => 'New folder';

  @override
  String get mailDeleteFolder => 'Delete folder?';

  @override
  String get mailMoveTo => 'Move to';

  @override
  String get mailMoved => 'Moved';

  @override
  String get mailSaveDraft => 'Save draft?';

  @override
  String get mailDraftSaved => 'Draft saved';

  @override
  String get deviceApprovalTitle => 'Confirm sign-in';

  @override
  String get deviceApprovalWaiting =>
      'We sent a request to your trusted devices. Open the notification and confirm.';

  @override
  String get deviceApprovalNoApprovers =>
      'No device was available to ask. Get a code by email instead.';

  @override
  String deviceApprovalExpiresIn(String time) {
    return '$time left';
  }

  @override
  String get deviceApprovalRejected =>
      'The sign-in was rejected from another device.';

  @override
  String get deviceApprovalExpired => 'The confirmation window has expired.';

  @override
  String get deviceApprovalBackToLogin => 'Back to sign-in';

  @override
  String get deviceApprovalSendEmail => 'Email me a code';

  @override
  String get deviceApprovalEmailSent => 'Code sent to your email';

  @override
  String get deviceApprovalEnterCode => 'Enter the code from the email';

  @override
  String get deviceApprovalSheetTitle => 'Account sign-in';

  @override
  String get deviceApprovalSheetBody =>
      'Someone is signing in to your account from this device. Is this you?';

  @override
  String get deviceApprovalAllow => 'Yes, allow';

  @override
  String get deviceApprovalDeny => 'This wasn\'t me';

  @override
  String get deviceApprovalApproved => 'Sign-in allowed';

  @override
  String get deviceApprovalDenied => 'Sign-in rejected';

  @override
  String get trustedDevicesTitle => 'Devices';

  @override
  String get trustedDevicesToggle => 'Confirm sign-ins from new devices';

  @override
  String get trustedDevicesToggleHint =>
      'Signing in on an unfamiliar device will need confirmation here, or a code by email';

  @override
  String get trustedDevicesEmpty => 'No trusted devices yet';

  @override
  String get trustedDevicesThisDevice => 'This device';

  @override
  String trustedDevicesLastSeen(String when) {
    return 'Last sign-in: $when';
  }

  @override
  String get trustedDevicesRevoke => 'Revoke';

  @override
  String get trustedDevicesRevokeConfirm =>
      'Revoke trust for this device? It will be signed out.';

  @override
  String get pinnedMessage => 'Pinned message';

  @override
  String get pinnedMessagesTitle => 'Pinned';

  @override
  String get pinAction => 'Pin';

  @override
  String get unpinAction => 'Unpin';

  @override
  String get unpinAllAction => 'Unpin all';

  @override
  String get noPinnedMessages => 'No pinned messages';

  @override
  String pinnedCounter(int current, int total) {
    return '$current of $total';
  }

  @override
  String messagePinnedBy(String actor) {
    return '$actor pinned a message';
  }

  @override
  String get unpinAllConfirm => 'Unpin all messages in this chat?';

  @override
  String get pinnedMessageNotLoaded =>
      'Message not loaded — scroll up to find it';

  @override
  String get chatReplyOriginalNotLoaded =>
      'Original not loaded — scroll up to find it';

  @override
  String get chatOriginalDeleted => 'Message deleted';

  @override
  String chatForwardedFrom(String name) {
    return 'Forwarded from $name';
  }

  @override
  String get chatUnreadDivider => 'Unread messages';

  @override
  String chatSelectedCount(int count) {
    return 'Selected: $count';
  }

  @override
  String chatSelectionLimit(int limit) {
    return 'You can select at most $limit messages';
  }
}
