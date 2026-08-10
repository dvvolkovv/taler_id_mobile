// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Buscar';

  @override
  String get appSubtitle => 'Identidade do ecossistema unificado';

  @override
  String get login => 'Entrar';

  @override
  String get loginButton => 'Entrar';

  @override
  String get register => 'Criar Conta';

  @override
  String get registerButton => 'Criar Conta';

  @override
  String get email => 'Email';

  @override
  String get password => 'Senha';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get firstName => 'Nome';

  @override
  String get lastName => 'Sobrenome';

  @override
  String get noAccount => 'Não tem uma conta?';

  @override
  String get createOne => 'Crie uma';

  @override
  String get haveAccount => 'Já tem uma conta?';

  @override
  String get signIn => 'Entrar';

  @override
  String get passwordMinLength => 'Mínimo 8 caracteres';

  @override
  String get invalidEmail => 'Insira um email válido';

  @override
  String get fieldRequired => 'Campo obrigatório';

  @override
  String get twoFATitle => 'Autenticação de Dois Fatores';

  @override
  String get twoFASubtitle =>
      'Insira o código de 6 dígitos do seu aplicativo autenticador';

  @override
  String get twoFACode => 'Código 2FA';

  @override
  String get verify => 'Verificar';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Organização';

  @override
  String get tabSettings => 'Configurações';

  @override
  String get profile => 'Perfil';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get phone => 'Telefone';

  @override
  String get country => 'País';

  @override
  String get dateOfBirth => 'Data de Nascimento';

  @override
  String get documents => 'Documentos';

  @override
  String get addDocument => 'Adicionar Documento';

  @override
  String get noDocuments => 'Nenhum documento enviado';

  @override
  String get save => 'Salvar';

  @override
  String get profileUpdated => 'Perfil atualizado';

  @override
  String get personalData => 'Dados Pessoais';

  @override
  String get passport => 'Passaporte';

  @override
  String get drivingLicense => 'Carteira de Motorista';

  @override
  String get diploma => 'Diploma';

  @override
  String get nationalId => 'Identidade Nacional';

  @override
  String get certificate => 'Certificado';

  @override
  String get notSpecified => 'Não especificado';

  @override
  String get notSpecifiedFemale => 'Não especificado';

  @override
  String get documentType => 'Tipo de Documento';

  @override
  String get passportId => 'Passaporte / ID';

  @override
  String get diplomaCertificate => 'Diploma / Certificado';

  @override
  String get loadError => 'Erro ao carregar';

  @override
  String get verification => 'Verificação';

  @override
  String get countryAustria => 'Áustria';

  @override
  String get countryGermany => 'Alemanha';

  @override
  String get countryRussia => 'Rússia';

  @override
  String get countryUkraine => 'Ucrânia';

  @override
  String get countryKazakhstan => 'Cazaquistão';

  @override
  String get countryBelarus => 'Bielorrússia';

  @override
  String get countryOther => 'Outro';

  @override
  String get kycTitle => 'Verificação KYC';

  @override
  String get kycVerified => 'Verificado';

  @override
  String get kycPending => 'Pendente';

  @override
  String get kycRejected => 'Rejeitado';

  @override
  String get kycUnverified => 'Não verificado';

  @override
  String get kycVerifiedDesc =>
      'Sua identidade foi verificada. Você tem acesso total a todos os recursos do ecossistema Taler.';

  @override
  String get kycPendingDesc =>
      'Seus documentos estão sendo revisados. Isso geralmente leva 1-2 dias úteis.';

  @override
  String get kycRejectedDesc =>
      'Verificação falhou. Por favor, revise o motivo e envie seus documentos novamente.';

  @override
  String get kycUnverifiedDesc =>
      'Complete a verificação para desbloquear o acesso total aos recursos financeiros do ecossistema Taler.';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get kycInProgress => 'In progress';

  @override
  String get kycInProgressDesc =>
      'You started verification but didn\'t finish it. Pick up right where you left off.';

  @override
  String get startVerification => 'Iniciar Verificação';

  @override
  String get retryVerification => 'Tentar Verificação Novamente';

  @override
  String verifiedAt(String date) {
    return 'Verificado: $date';
  }

  @override
  String get documentsSubmitted => 'Documentos enviados para revisão';

  @override
  String get documentsSubmittedDesc =>
      'A revisão geralmente leva 1-2 dias úteis. Você receberá uma notificação push com o resultado.';

  @override
  String get securityAes =>
      'Seus dados estão protegidos com criptografia AES-256';

  @override
  String get verificationTime => 'A verificação leva 1-2 dias úteis';

  @override
  String get pushNotification =>
      'Você receberá uma notificação push com o resultado';

  @override
  String get kycWebOnly =>
      'A verificação KYC está disponível apenas no aplicativo móvel.';

  @override
  String verificationError(String code) {
    return 'Erro de verificação: $code';
  }

  @override
  String get organizations => 'Organizações';

  @override
  String get noOrganizations => 'Nenhuma organização';

  @override
  String get noOrganizationsDesc => 'Crie uma organização ou aceite um convite';

  @override
  String get createOrganization => 'Criar Organização';

  @override
  String get newOrganization => 'Nova Organização';

  @override
  String get orgName => 'Nome *';

  @override
  String get orgDescription => 'Descrição';

  @override
  String get orgEmail => 'Email de Contato';

  @override
  String get orgWebsite => 'Website';

  @override
  String get orgLegalAddress => 'Endereço Legal';

  @override
  String get create => 'Criar';

  @override
  String get organization => 'Organização';

  @override
  String get contacts => 'Contatos';

  @override
  String members(int count) {
    return 'Membros ($count)';
  }

  @override
  String get inviteMember => 'Convidar Membro';

  @override
  String get invite => 'Convidar';

  @override
  String get sendInvite => 'Enviar Convite';

  @override
  String inviteSent(String email) {
    return 'Convite enviado para $email';
  }

  @override
  String get role => 'Função';

  @override
  String get roleOwner => 'Proprietário';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleOperator => 'Operador';

  @override
  String get roleViewer => 'Visualizador';

  @override
  String get editOrganization => 'Editar';

  @override
  String get editOrganizationTitle => 'Editar Organização';

  @override
  String get removeMember => 'Remover Membro';

  @override
  String removeMemberConfirm(String name) {
    return 'Remover $name da organização?';
  }

  @override
  String get memberRemoved => 'Membro removido';

  @override
  String get roleChanged => 'Função alterada';

  @override
  String get kybVerified => 'Verificado';

  @override
  String get kybPending => 'Pendente';

  @override
  String get kybRejected => 'Rejeitado';

  @override
  String get kybNone => 'Não verificado';

  @override
  String get kybVerification => 'Iniciar Verificação KYB';

  @override
  String get kybStartBusiness => 'Iniciar Verificação de Negócio';

  @override
  String get kybStatusLabel => 'Status KYB';

  @override
  String get noKyb => 'Sem KYB';

  @override
  String get kybBusinessVerificationTitle => 'Verificação de Negócio (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Organização verificada com sucesso.';

  @override
  String get kybPendingOrgDesc =>
      'Documentos estão sendo revisados. Isso geralmente leva de 1 a 3 dias úteis.';

  @override
  String get kybRejectedOrgDesc =>
      'Verificação falhou. Por favor, tente novamente.';

  @override
  String get kybNoneOrgDesc =>
      'Verifique sua organização para acessar recursos de negócios.';

  @override
  String get invitePlus => '+ Convidar';

  @override
  String get kybVerificationTitle => 'Verificação KYB';

  @override
  String get kybWebOnlyBusiness =>
      'A verificação KYB está disponível apenas no aplicativo móvel.';

  @override
  String get unknownDevice => 'Dispositivo desconhecido';

  @override
  String get ipUnknown => 'IP desconhecido';

  @override
  String get currentSessionLabel => 'Atual';

  @override
  String get endSessionAction => 'Encerrar';

  @override
  String get deviceLoggedOut => 'O dispositivo será desconectado.';

  @override
  String get acceptInvitationTitle => 'Convite para Organização';

  @override
  String get acceptInvitation => 'Aceitar Convite';

  @override
  String get acceptInvitationDesc =>
      'Você foi convidado para se juntar a uma organização no ecossistema Taler.';

  @override
  String get accept => 'Aceitar';

  @override
  String get reject => 'Rejeitar';

  @override
  String get sessions => 'Sessões Ativas';

  @override
  String get currentSession => 'Sessão atual';

  @override
  String get deleteSession => 'Encerrar Sessão';

  @override
  String get deleteSessionConfirm => 'Encerrar esta sessão?';

  @override
  String get sessionDeleted => 'Sessão encerrada';

  @override
  String get noSessions => 'Nenhuma sessão ativa';

  @override
  String minutesAgo(int count) {
    return '$count min atrás';
  }

  @override
  String hoursAgo(int count) {
    return '$count hr atrás';
  }

  @override
  String daysAgo(int count) {
    return '$count dias atrás';
  }

  @override
  String get justNow => 'Agora mesmo';

  @override
  String get settings => 'Configurações';

  @override
  String get security => 'Segurança';

  @override
  String get biometrics => 'Biometria';

  @override
  String get biometricsDesc => 'Login rápido com Face ID ou impressão digital';

  @override
  String get biometricsConfirm =>
      'Confirme a biometria para habilitar o login rápido';

  @override
  String get biometricsError =>
      'Falha ao habilitar biometria. Verifique as configurações do dispositivo.';

  @override
  String get changePassword => 'Alterar Senha';

  @override
  String get twoFactorAuth => 'Autenticação de Dois Fatores';

  @override
  String get currentPassword => 'Senha Atual';

  @override
  String get newPassword => 'Nova Senha';

  @override
  String get confirmNewPassword => 'Confirmar Nova Senha';

  @override
  String get passwordChanged => 'Senha alterada';

  @override
  String get wrongCurrentPassword => 'Senha atual incorreta';

  @override
  String get passwordTooWeak =>
      'Senha muito fraca: pelo menos 8 caracteres, letra e dígito necessários';

  @override
  String get passwordChangeFailed => 'Falha ao alterar a senha';

  @override
  String get notifications => 'Notificações';

  @override
  String get permissions => 'Permissões';

  @override
  String get permissionNotifications => 'Notificações Push';

  @override
  String get permissionNotificationsDesc => 'Chamadas, mensagens, status';

  @override
  String get permissionMicrophone => 'Microfone';

  @override
  String get permissionMicrophoneDesc => 'Chamadas e assistente de voz';

  @override
  String get permissionCamera => 'Câmera';

  @override
  String get permissionCameraDesc => 'Chamadas de vídeo e verificação';

  @override
  String get permissionLocation => 'Localização';

  @override
  String get permissionLocationDesc => 'Usado para verificação';

  @override
  String get permissionOpenSettings =>
      'Para revogar uma permissão, abra as configurações do sistema';

  @override
  String get pushKycStatus => 'Status KYC Push';

  @override
  String get pushKycStatusDesc => 'Resultado da verificação';

  @override
  String get pushLogins => 'Login Push';

  @override
  String get pushLoginsDesc => 'Ao entrar de um novo dispositivo';

  @override
  String get account => 'Conta';

  @override
  String get language => 'Idioma';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Idioma da Interface';

  @override
  String get exportData => 'Exportar Dados (GDPR)';

  @override
  String get deleteAccount => 'Excluir Conta';

  @override
  String get deleteAccountConfirm => 'Excluir conta?';

  @override
  String get deleteAccountDesc =>
      'Todos os seus dados serão excluídos (GDPR). Esta ação é irreversível.';

  @override
  String get logout => 'Sair';

  @override
  String get logoutConfirm => 'Sair?';

  @override
  String get logoutDesc =>
      'Você será desconectado do Taler ID neste dispositivo.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'Código PIN';

  @override
  String get pinCodeDesc => 'Login rápido com código de 4 dígitos';

  @override
  String get setupPin => 'Configurar PIN';

  @override
  String get enterPin => 'Digite o PIN';

  @override
  String get confirmPin => 'Confirme o PIN';

  @override
  String get pinMismatch => 'PINs não coincidem';

  @override
  String get passwordMismatch => 'As senhas não coincidem';

  @override
  String get pinSet => 'PIN configurado com sucesso';

  @override
  String get enterPinToLogin => 'Digite o PIN para entrar';

  @override
  String get pinIncorrect => 'PIN incorreto';

  @override
  String get removePin => 'Remover PIN';

  @override
  String get pinRemoved => 'PIN removido';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get loading => 'Carregando...';

  @override
  String get error => 'Erro';

  @override
  String get success => 'Sucesso';

  @override
  String get noData => 'Sem dados';

  @override
  String get failedToLoad => 'Falha ao carregar dados';

  @override
  String get failedToLoadProfile => 'Falha ao carregar perfil';

  @override
  String get failedToSave => 'Falha ao salvar alterações';

  @override
  String get failedToLoadOrgs => 'Falha ao carregar organizações';

  @override
  String get failedToLoadOrg => 'Falha ao carregar dados da organização';

  @override
  String get failedToCreateOrg => 'Falha ao criar organização';

  @override
  String get failedToInvite => 'Falha ao enviar convite';

  @override
  String get failedToAcceptInvite => 'Falha ao aceitar convite';

  @override
  String get failedToLoadSessions => 'Falha ao carregar sessões';

  @override
  String get failedToDeleteSession => 'Falha ao encerrar sessão';

  @override
  String get failedToLoadKyc => 'Falha ao carregar status de verificação';

  @override
  String get failedToStartKyc => 'Falha ao iniciar verificação';

  @override
  String get verifiedPersonalInfo => 'Dados Verificados';

  @override
  String get middleName => 'Nome do Meio';

  @override
  String get placeOfBirth => 'Local de Nascimento';

  @override
  String get nationality => 'Nacionalidade';

  @override
  String get gender => 'Gênero';

  @override
  String get genderMale => 'Masculino';

  @override
  String get genderFemale => 'Feminino';

  @override
  String get docNumber => 'Número';

  @override
  String get docIssuedDate => 'Emitido';

  @override
  String get docValidUntil => 'Válido Até';

  @override
  String get docIssuedBy => 'Emitido Por';

  @override
  String get address => 'Endereço';

  @override
  String get refreshData => 'Atualizar Dados';

  @override
  String get failedToLoadSumsubData => 'Falha ao carregar dados de verificação';

  @override
  String get sumsubDataLoading => 'Carregando dados de verificação...';

  @override
  String get reviewResultGreen => 'Verificação aprovada';

  @override
  String get reviewResultRed => 'Verificação reprovada';

  @override
  String get tabAssistant => 'Assistente';

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
  String get assistantSpeaking => 'Falando…';

  @override
  String get assistantListening => 'Ouvindo…';

  @override
  String get assistantTapToStart => 'Toque para começar';

  @override
  String get assistantTapToTalk => 'Toque para falar com a AI';

  @override
  String get assistantRealtimeDesc =>
      'Assistente responde com voz em tempo real';

  @override
  String get assistantConnectingToAssistant => 'Conectando ao assistente...';

  @override
  String get assistantAiSpeaking => 'AI falando...';

  @override
  String get assistantAiListening => 'AI ouvindo';

  @override
  String get assistantSpeakerOn => 'Alto-falante ligado';

  @override
  String get assistantSpeaker => 'Alto-falante';

  @override
  String get assistantEnd => 'Encerrar';

  @override
  String get assistantUnmute => 'Reativar som';

  @override
  String get assistantMicrophone => 'Microfone';

  @override
  String get assistantConnectionError => 'Erro de conexão';

  @override
  String get tabMessenger => 'Mensagens';

  @override
  String get tabCalls => 'Chamadas';

  @override
  String get tabCalendar => 'Calendário';

  @override
  String get appearance => 'Aparência';

  @override
  String get appearanceSelect => 'Escolher Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get onboardingTitle1 => 'Identidade Unificada';

  @override
  String get onboardingDesc1 =>
      'Taler ID é seu passaporte digital no ecossistema Taler. Uma conta para todos os serviços.';

  @override
  String get onboardingTitle2 => 'Segurança de Dados';

  @override
  String get onboardingDesc2 =>
      'Verificação KYC, criptografia AES-256 e autenticação de dois fatores protegem sua identidade.';

  @override
  String get onboardingTitle3 => 'Fique Informado';

  @override
  String get onboardingDesc3 =>
      'Receba notificações sobre status de verificação, logins de novos dispositivos e chamadas recebidas.';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingEnableNotifications => 'Ativar Notificações';

  @override
  String get onboardingTitle4 => 'Chamadas de Voz';

  @override
  String get onboardingDesc4 =>
      'Conceda acesso ao microfone para chamadas de voz e assistente AI. Você pode alterar isso depois nas configurações.';

  @override
  String get onboardingEnableMicrophone => 'Ativar Microfone';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get onboardingSkip => 'Pular';

  @override
  String get meshLocalNetworkPromptTitle => 'Permitir acesso à rede local';

  @override
  String get meshLocalNetworkPromptBody =>
      'Para encontrar pares no Wi-Fi (chamadas em grupo offline), o iOS requer a permissão de Rede Local. Abra Configurações → Privacidade e Segurança → Rede Local → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'Abrir Configurações';

  @override
  String get meshLocalNetworkPromptDismiss => 'Entendi';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get forgotPasswordTitle => 'Redefinir Senha';

  @override
  String get forgotPasswordSubtitle =>
      'Digite seu e-mail para receber um código de redefinição';

  @override
  String resetCodeSent(String email) {
    return 'Código enviado para $email';
  }

  @override
  String get enterResetCode => 'Digite o código';

  @override
  String get resetPasswordButton => 'Redefinir Senha';

  @override
  String get passwordResetSuccess => 'Senha redefinida com sucesso';

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
  String get newGroup => 'Novo grupo';

  @override
  String get newChat => 'Novo chat';

  @override
  String get groupName => 'Nome do grupo';

  @override
  String get createGroup => 'Criar grupo';

  @override
  String get groupInfo => 'Informações do grupo';

  @override
  String groupMembers(int count) {
    return 'Membros ($count)';
  }

  @override
  String get addMembers => 'Adicionar membros';

  @override
  String get leaveGroup => 'Sair do grupo';

  @override
  String get leaveGroupConfirm => 'Sair deste grupo?';

  @override
  String get deleteGroup => 'Excluir grupo';

  @override
  String get deleteGroupConfirm =>
      'Excluir este grupo? Isso não pode ser desfeito.';

  @override
  String get groupRoleOwner => 'Proprietário';

  @override
  String get groupRoleAdmin => 'Admin';

  @override
  String get groupRoleMember => 'Membro';

  @override
  String get selectParticipants => 'Selecionar participantes';

  @override
  String selectedCount(int count) {
    return '$count selecionados';
  }

  @override
  String get changeRole => 'Alterar função';

  @override
  String get groupCreated => 'Grupo criado';

  @override
  String memberJoined(String name) {
    return '$name entrou';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name saiu';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name foi removido';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name agora é $role';
  }

  @override
  String participantsCount(int count) {
    return '$count participantes';
  }

  @override
  String get enterGroupName => 'Digite o nome do grupo';

  @override
  String get muteNotifications => 'Silenciar notificações';

  @override
  String get unmuteNotifications => 'Reativar notificações';

  @override
  String get muteFor1Hour => 'Por 1 hora';

  @override
  String get muteFor8Hours => 'Por 8 horas';

  @override
  String get muteFor2Days => 'Por 2 dias';

  @override
  String get muteForever => 'Para sempre';

  @override
  String get muted => 'Silenciado';

  @override
  String get tabTranslator => 'Traduzir';

  @override
  String get translatorTitle => 'Tradutor';

  @override
  String get translatorSelectLanguage => 'Selecionar idioma';

  @override
  String get translatorDownloading => 'Baixando modelos de idioma...';

  @override
  String get translatorDownloadingHint =>
      'Internet é necessária apenas para o primeiro download';

  @override
  String get translatorTypeHint => 'Digite o texto ou toque no microfone';

  @override
  String get translatorListening => 'Ouvindo...';

  @override
  String get translatorTapToSpeak => 'Toque para falar';

  @override
  String get translatorTapToStop => 'Toque para parar';

  @override
  String get translatorAutoSpeak => 'Falar automaticamente';

  @override
  String get translatorCopied => 'Copiado';

  @override
  String get translatorLangRu => 'Russo';

  @override
  String get translatorLangEn => 'Inglês';

  @override
  String get translatorLangDe => 'Alemão';

  @override
  String get translatorLangFr => 'Francês';

  @override
  String get translatorLangEs => 'Espanhol';

  @override
  String get translatorLangIt => 'Italiano';

  @override
  String get translatorLangPt => 'Português';

  @override
  String get translatorLangTr => 'Turco';

  @override
  String get translatorLangZh => 'Chinês';

  @override
  String get translatorLangJa => 'Japonês';

  @override
  String get translatorLangKo => 'Coreano';

  @override
  String get translatorLangAr => 'Árabe';

  @override
  String get translatorLangPl => 'Polonês';

  @override
  String get translatorLangSk => 'Eslovaco';

  @override
  String get translatorLangCs => 'Tcheco';

  @override
  String get translatorLangNl => 'Holandês';

  @override
  String get translatorLangSv => 'Sueco';

  @override
  String get translatorLangDa => 'Dinamarquês';

  @override
  String get translatorLangNo => 'Norueguês';

  @override
  String get translatorLangFi => 'Finlandês';

  @override
  String get translatorLangUk => 'Ucraniano';

  @override
  String get translatorLangEl => 'Grego';

  @override
  String get translatorLangRo => 'Romeno';

  @override
  String get translatorLangHu => 'Húngaro';

  @override
  String get translatorLangBg => 'Búlgaro';

  @override
  String get translatorLangHr => 'Croata';

  @override
  String get translatorLangSr => 'Sérvio';

  @override
  String get translatorLangHi => 'Hindi';

  @override
  String get translatorLangTh => 'Tailandês';

  @override
  String get translatorLangVi => 'Vietnamita';

  @override
  String get translatorLangId => 'Indonésio';

  @override
  String get translatorLangMs => 'Malaio';

  @override
  String get translatorLangHe => 'Hebraico';

  @override
  String get translatorLangFa => 'Persa';

  @override
  String get callInProgress => 'Chamada em andamento';

  @override
  String get joinCall => 'Participar';

  @override
  String get createCallLink => 'Link de chamada';

  @override
  String get callLinkCopied => 'Link copiado';

  @override
  String get callLinkTitle => 'Link da sala';

  @override
  String get connectionUnstable => 'Conexão instável — verifique sua internet';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get errorTimeout =>
      'Tempo de conexão esgotado. Verifique sua conexão com a internet.';

  @override
  String get errorNoConnection => 'Sem conexão com a internet.';

  @override
  String get errorGeneral => 'Ocorreu um erro. Por favor, tente novamente.';

  @override
  String errorWithMessage(String message) {
    return 'Erro: $message';
  }

  @override
  String get notifChannelMessages => 'Mensagens';

  @override
  String get notifChannelMessagesDesc => 'Notificações de novas mensagens';

  @override
  String get notifChannelMissedCalls => 'Chamadas perdidas';

  @override
  String get notifChannelMissedCallsDesc => 'Notificações de chamadas perdidas';

  @override
  String get notifMissedCall => 'Chamada perdida';

  @override
  String get notifAccept => 'Aceitar';

  @override
  String get notifDecline => 'Recusar';

  @override
  String get notifIncomingCall => 'Chamada recebida';

  @override
  String get notifIncomingCallChannel => 'Chamada recebida';

  @override
  String get notifMissedCallChannel => 'Chamada perdida';

  @override
  String get notifUnknown => 'Desconhecido';

  @override
  String get effectNone => 'Sem fundo';

  @override
  String get effectBlur => 'Desfoque';

  @override
  String get effectOffice => 'Escritório';

  @override
  String get effectNature => 'Natureza';

  @override
  String get effectGradient => 'Gradiente';

  @override
  String get effectLibrary => 'Biblioteca';

  @override
  String get effectCity => 'Cidade';

  @override
  String get effectMinimalism => 'Minimalismo';

  @override
  String get voiceParticipant => 'Participante';

  @override
  String get voiceInvitesToRoom => 'convida você para a sala';

  @override
  String get voiceRoom => 'Sala';

  @override
  String get voicePasswordProtected => 'Protegido por senha';

  @override
  String get voicePasswordHint => 'Senha';

  @override
  String get voiceEnter => 'Entrar';

  @override
  String get voiceJoinRoom => 'Entrar na sala';

  @override
  String get voiceYourName => 'Seu nome';

  @override
  String voiceInvitationSent(String name) {
    return 'Convite enviado para $name';
  }

  @override
  String get voiceNoActiveRoom => 'Nenhuma sala ativa';

  @override
  String get voiceCameraPermission =>
      'Permitir acesso à câmera em Configurações → Privacidade → Câmera → TalerID';

  @override
  String get voiceOpenSettings => 'Abrir';

  @override
  String voiceCameraError(String error) {
    return 'Falha ao ativar a câmera: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'Todos concordaram. Gravação iniciada.';

  @override
  String get voiceNewParticipantAgreed =>
      'Novo participante concordou com a gravação.';

  @override
  String get voiceDeclinedRecording =>
      'Você recusou a gravação. Saindo da chamada.';

  @override
  String get voiceRecordingEnded => 'Gravação encerrada';

  @override
  String get voiceRecordingInProgress => 'Gravação em andamento';

  @override
  String get voiceTranscriptionRequest => 'Solicitação de transcrição';

  @override
  String get voiceRecordingRequest => 'Solicitação de gravação';

  @override
  String get voiceAgree => 'Concordar';

  @override
  String get voiceDeclineAndLeave => 'Recusar e sair';

  @override
  String get voiceAudioOutput => 'Saída de áudio';

  @override
  String get voiceAudioPhone => 'Telefone';

  @override
  String get voiceAudioSpeaker => 'Alto-falante';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Fones de ouvido';

  @override
  String get voiceLinkCopied => 'Link copiado';

  @override
  String get voiceTranslateTo => 'Traduzir para';

  @override
  String get voiceSearchLanguage => 'Buscar idioma...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Sala $name';
  }

  @override
  String get voiceVoiceCall => 'Chamada de voz';

  @override
  String get voiceOnHold => 'Em espera';

  @override
  String get voiceActiveCall => 'Ativa';

  @override
  String get voiceEndAllCalls => 'Encerrar todas as chamadas';

  @override
  String get voiceEndThisCall => 'Encerrar esta chamada';

  @override
  String get voiceCopyLink => 'Copiar link';

  @override
  String get voiceAddParticipant => 'Adicionar participante';

  @override
  String get voiceReconnecting => 'Reconectando...';

  @override
  String get voiceConnectionError => 'Erro de conexão';

  @override
  String get voiceClose => 'Fechar';

  @override
  String get voiceCalling => 'Chamando...';

  @override
  String get voiceCallActive => 'Chamada ativa';

  @override
  String get voiceWaiting => 'Aguardando';

  @override
  String get voiceWaitingUpper => 'AGUARDANDO';

  @override
  String get voiceRec => 'REC';

  @override
  String get voiceStop => 'Parar';

  @override
  String get voiceRecord => 'Gravando';

  @override
  String get voiceTranslation => 'Tradução';

  @override
  String get voiceAudio => 'Áudio';

  @override
  String get voiceFlipCamera => 'Inverter';

  @override
  String get voiceBackground => 'Fundo';

  @override
  String get voiceAssistantSpeakingStatus => 'Assistente falando...';

  @override
  String get voiceAssistantListeningStatus => 'Assistente ouvindo...';

  @override
  String get voiceUnmute => 'Ativar som';

  @override
  String get voiceMic => 'Microfone';

  @override
  String get voiceAssistantLabel => 'Assistente';

  @override
  String get voiceCameraOn => 'Câmera ligada';

  @override
  String get voiceCameraLabel => 'Câmera';

  @override
  String get voiceEndCall => 'Encerrar chamada';

  @override
  String get voiceWaitingParticipants => 'Aguardando participantes...';

  @override
  String get voiceYou => 'Você';

  @override
  String get voiceAiAssistant => 'Assistente de IA';

  @override
  String get voiceVideoUnavailable => 'Vídeo indisponível';

  @override
  String get voiceSearchNickname => 'Buscar por apelido...';

  @override
  String get voiceTranscriptionWord => 'transcrição';

  @override
  String get voiceRecordingWord => 'gravação';

  @override
  String get voiceConnecting => 'Conectando...';

  @override
  String get voiceVideoBackground => 'Fundo de vídeo';

  @override
  String get voiceCallSettings => 'Configurações de chamada';

  @override
  String get voiceEnableAI => 'Ativar assistente de IA';

  @override
  String get voiceAIParticipating => 'IA participará da conversa';

  @override
  String get voiceNormalCall => 'Chamada normal sem IA';

  @override
  String get voiceCallConfirm => 'Fazer uma chamada?';

  @override
  String get chatAlreadyInCall => 'Já em uma chamada';

  @override
  String chatCallError(String error) {
    return 'Erro na chamada: $error';
  }

  @override
  String get chatPhotoVideo => 'Foto / Vídeo';

  @override
  String get chatCamera => 'Câmera';

  @override
  String get chatFile => 'Arquivo';

  @override
  String get chatContact => 'Contato';

  @override
  String get chatSelectContact => 'Selecionar um contato';

  @override
  String get chatNoContacts => 'Sem contatos';

  @override
  String get chatUser => 'Usuário';

  @override
  String get chatFileAttachment => '📎 Arquivo';

  @override
  String chatFileUploadError(String error) {
    return 'Erro no upload do arquivo: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Mensagem de voz';

  @override
  String get chatGroup => 'Grupo';

  @override
  String get chatDialog => 'Diálogo';

  @override
  String get chatCall => 'Chamada';

  @override
  String get chatStartConversation => 'Iniciar uma conversa';

  @override
  String get chatYou => 'Você';

  @override
  String get chatIsTyping => 'está digitando...';

  @override
  String chatUserIsTyping(String name) {
    return '$name está digitando...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names estão digitando...';
  }

  @override
  String get chatPreparingFile => 'Preparando arquivo…';

  @override
  String chatUploading(int progress) {
    return 'Enviando… $progress%';
  }

  @override
  String get chatEdited => 'Editado';

  @override
  String get chatViaMesh => 'via mesh';

  @override
  String get chatReply => 'Responder';

  @override
  String get chatEdit => 'Editar';

  @override
  String get chatCopy => 'Copiar';

  @override
  String get chatCopied => 'Copiado';

  @override
  String get chatSaveMedia => 'Salvar';

  @override
  String get chatForward => 'Encaminhar';

  @override
  String get chatSaving => 'Salvando...';

  @override
  String get chatSavedToGallery => 'Salvo na galeria';

  @override
  String get chatNoSavePermission =>
      'Sem permissão para salvar. Verifique as configurações.';

  @override
  String get chatFileSaved => 'File saved';

  @override
  String get chatFileSaveError => 'Erro ao salvar arquivo';

  @override
  String get chatDeleteMessage => 'Excluir mensagem';

  @override
  String get chatDeleteForMe => 'Excluir para mim';

  @override
  String get chatDeleteForEveryone => 'Excluir para todos';

  @override
  String get chatMessageForwarded => 'Mensagem encaminhada';

  @override
  String get chatContactTapToOpen => 'Contato · toque para abrir';

  @override
  String get chatForwardTo => 'Encaminhar para...';

  @override
  String get chatSearchHint => 'Buscar...';

  @override
  String get chatRecording => 'Gravando...';

  @override
  String get chatMessageHint => 'Mensagem...';

  @override
  String get chatHideKeyboard => 'Ocultar teclado';

  @override
  String get chatEditing => 'Editando';

  @override
  String get chatFileDownloadError => 'Erro ao baixar arquivo';

  @override
  String get chatVoiceMessageShort => 'Mensagem de voz';

  @override
  String get chatVideoSavedToGallery => 'Vídeo salvo na galeria';

  @override
  String get chatSavingError => 'Erro ao salvar';

  @override
  String get convSetNickname => 'Definir um apelido';

  @override
  String get convNicknameRequired =>
      'Um apelido é necessário para usar o mensageiro. Outros usuários podem encontrá-lo por ele.';

  @override
  String get convNicknameRules => '3–30 caracteres: letras, dígitos, _';

  @override
  String get convNicknameTaken => 'Apelido já em uso';

  @override
  String get convSaveError => 'Erro ao salvar';

  @override
  String get convContactsLabel => 'Contatos';

  @override
  String get convDefaultUser => 'Usuário';

  @override
  String get convNoDialogs => 'Sem conversas';

  @override
  String get convFindUserToChat =>
      'Encontre um usuário para começar a conversar';

  @override
  String get convDefaultContact => 'Contato';

  @override
  String get dashboardUser => 'Usuário';

  @override
  String get dashboardIncomingCall => 'Chamada recebida';

  @override
  String get dashboardDecline => 'Recusar';

  @override
  String get dashboardAccept => 'Aceitar';

  @override
  String get dashboardActiveCall => 'Chamada ativa — toque para retornar';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Atualização disponível $version';
  }

  @override
  String get dashboardUpdate => 'Atualizar';

  @override
  String get dashboardWhatsNew => 'Novidades';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'Novidades na $version';
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
  String get contactRequestsTitle => 'Contatos';

  @override
  String get messengerContactRequestsSection => 'Solicitações de contato';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count novas solicitações',
      one: '1 nova solicitação',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Buscar';

  @override
  String get contactRequestsIncoming => 'Recebidas';

  @override
  String get contactRequestsSent => 'Enviadas';

  @override
  String get contactRequestsSearchHint => 'Apelido ou email';

  @override
  String get contactRequestSent => 'Solicitação enviada';

  @override
  String get contactRequestsNoUsers => 'Nenhum usuário encontrado';

  @override
  String get contactRequestsSearchHelp =>
      'Digite o apelido ou email exato\ne pressione buscar';

  @override
  String get contactRequestsSendTooltip => 'Enviar solicitação';

  @override
  String get contactRequestTitle => 'Solicitação de contato';

  @override
  String contactRequestConfirm(String name) {
    return 'Enviar solicitação de contato para $name?';
  }

  @override
  String get contactRequestSend => 'Enviar';

  @override
  String get contactRequestsNoIncoming => 'Nenhuma solicitação recebida';

  @override
  String get contactRequestsNoSent => 'Nenhuma solicitação enviada';

  @override
  String get contactRequestStatusPending => 'Aguardando resposta';

  @override
  String get contactRequestStatusAccepted => 'Aceita';

  @override
  String get contactRequestStatusRejected => 'Rejeitada';

  @override
  String get userSearchTitle => 'Encontrar usuário';

  @override
  String get userSearchHint => 'Apelido, telefone ou email';

  @override
  String get userSearchHelper => 'Digite @apelido, email ou nome para buscar';

  @override
  String get userSearchNoUsers => 'Nenhum usuário encontrado';

  @override
  String get userProfileShareContact => 'Compartilhar contato';

  @override
  String get userProfileShareContactDesc => 'Enviar link do contato';

  @override
  String get userProfileCopyLink => 'Copiar link';

  @override
  String get userProfileCopied => 'Copiado';

  @override
  String get userProfileTitle => 'Perfil';

  @override
  String get userProfileLoadError => 'Erro ao carregar perfil';

  @override
  String get userProfileMessage => 'Mensagem';

  @override
  String get userProfileCall => 'Chamada';

  @override
  String get userProfileRequestSent => 'Solicitação enviada';

  @override
  String get userProfileAccept => 'Aceitar';

  @override
  String get userProfileDecline => 'Recusar';

  @override
  String get userProfileAddToContacts => 'Adicionar aos contatos';

  @override
  String get userProfileMediaTab => 'Mídia';

  @override
  String get userProfileFilesTab => 'Arquivos';

  @override
  String get userProfileLinksTab => 'Links';

  @override
  String get userProfileRecordingsTab => 'Gravações';

  @override
  String get userProfileSummariesTab => 'Resumos';

  @override
  String get userProfileNoMedia => 'Nenhum arquivo de mídia';

  @override
  String get userProfileNoFiles => 'Nenhum arquivo';

  @override
  String get userProfileNoLinks => 'Nenhum link';

  @override
  String get userProfileNoRecordings => 'Nenhuma gravação';

  @override
  String get userProfileNoSummaries => 'Nenhum resumo';

  @override
  String get userProfileMeetingSummary => 'Resumo da reunião';

  @override
  String get userProfileFailedOpenChat => 'Falha ao abrir o chat';

  @override
  String get sharedMediaTitle => 'Mídia e arquivos';

  @override
  String get sharedMediaTab => 'Mídia';

  @override
  String get sharedFilesTab => 'Arquivos';

  @override
  String get sharedLinksTab => 'Links';

  @override
  String get sharedNoMedia => 'Nenhum arquivo de mídia';

  @override
  String get sharedNoFiles => 'Nenhum arquivo';

  @override
  String get sharedNoLinks => 'Nenhum link';

  @override
  String get shareToChat => 'Encaminhar para o chat';

  @override
  String get shareSelectChat => 'Selecionar chat';

  @override
  String get shareNoChats => 'Nenhum chat';

  @override
  String shareFilesCount(int count) {
    return '$count arquivos';
  }

  @override
  String get contactsTitle => 'Contatos';

  @override
  String get contactsAddTooltip => 'Adicionar contato';

  @override
  String get contactsSearchHint => 'Buscar contatos...';

  @override
  String get contactsNotFound => 'Nada encontrado';

  @override
  String get contactsEmpty => 'Nenhum contato';

  @override
  String get contactsAdd => 'Adicionar contato';

  @override
  String get contactsPendingConfirmation => 'Aguardando confirmação';

  @override
  String get contactsMessage => 'Mensagem';

  @override
  String get contactsCall => 'Chamada';

  @override
  String get contactsResend => 'Reenviar solicitação';

  @override
  String get contactsResendTimeout => 'Tentar novamente em 24h';

  @override
  String get contactsResent => 'Solicitação reenviada';

  @override
  String get contactsWantsToConnect => 'Quer se conectar com você';

  @override
  String get contactsSearchPeople => 'Encontrar pessoas';

  @override
  String get notesTitle => 'Notas';

  @override
  String get notesAssistantSpeaking => 'Assistente falando...';

  @override
  String get notesListening => 'Ouvindo...';

  @override
  String get notesEmpty => 'Sem notas';

  @override
  String get notesEmptyHint =>
      'Pressione o microfone para ditar\nou + para entrada manual';

  @override
  String get notesDeleteConfirm => 'Excluir nota?';

  @override
  String get notesNew => 'Nova nota';

  @override
  String get notesEdit => 'Editar';

  @override
  String get notesTitleHint => 'Título';

  @override
  String get notesContentHint => 'Escreva seus pensamentos...';

  @override
  String get calendarTitle => 'Calendário';

  @override
  String get calendarStop => 'Parar';

  @override
  String get calendarVoiceInput => 'Entrada por voz';

  @override
  String get calendarNewEvent => 'Novo evento';

  @override
  String get calendarAssistantSpeaking => 'Assistente falando...';

  @override
  String get calendarListening => 'Ouvindo...';

  @override
  String calendarInvitations(int count) {
    return 'Convites ($count)';
  }

  @override
  String get calendarNoEvents => 'Sem eventos';

  @override
  String get calendarDayMon => 'Seg';

  @override
  String get calendarDayTue => 'Ter';

  @override
  String get calendarDayWed => 'Qua';

  @override
  String get calendarDayThu => 'Qui';

  @override
  String get calendarDayFri => 'Sex';

  @override
  String get calendarDaySat => 'Sáb';

  @override
  String get calendarDaySun => 'Dom';

  @override
  String get calendarEnterRoom => 'Entrar na sala';

  @override
  String get calendarMeeting => 'Reunião';

  @override
  String calendarLocationPrefix(String location) {
    return 'Local: $location';
  }

  @override
  String get calendarEditEvent => 'Editar';

  @override
  String get calendarTitleHint => 'Título';

  @override
  String get calendarDescriptionHint => 'Descrição';

  @override
  String get calendarTypeEvent => 'Evento';

  @override
  String get calendarTypeMeeting => 'Reunião';

  @override
  String get calendarTypeReminder => 'Lembrete';

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
  String get calendarMeetingLink => 'Link da reunião';

  @override
  String get calendarLocationHint => 'Localização';

  @override
  String get calendarDateLabel => 'Data';

  @override
  String get calendarTimeLabel => 'Hora';

  @override
  String get calendarReminderLabel => 'Lembrete';

  @override
  String get calendarReminderNone => 'Nenhum';

  @override
  String get calendarReminder15min => '15 min antes';

  @override
  String get calendarReminder30min => '30 min antes';

  @override
  String get calendarReminder1hour => '1 hora antes';

  @override
  String get calendarRepeatLabel => 'Repetir';

  @override
  String get calendarRepeatNone => 'Não repetir';

  @override
  String get calendarRepeatDaily => 'Todo dia';

  @override
  String get calendarRepeatWeekly => 'Toda semana';

  @override
  String get calendarRepeatMonthly => 'Todo mês';

  @override
  String get calendarRepeatYearly => 'Todo ano';

  @override
  String get calendarParticipants => 'Participantes';

  @override
  String get calendarAddParticipant => 'Adicionar';

  @override
  String get calendarSearchContacts => 'Buscar contatos...';

  @override
  String get calendarNoContacts => 'Sem contatos';

  @override
  String get calendarStatusAccepted => 'Aceito';

  @override
  String get calendarStatusDeclined => 'Recusado';

  @override
  String get calendarStatusMaybe => 'Talvez';

  @override
  String get calendarStatusPending => 'Pendente';

  @override
  String get calendarEndTime => 'Hora de término';

  @override
  String get calendarYourAnswer => 'Sua resposta:';

  @override
  String get calendarOrganizer => 'Organizador';

  @override
  String calendarDeleteError(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String get calendarRsvpAccept => 'Aceitar';

  @override
  String get calendarRsvpMaybe => 'Talvez';

  @override
  String get calendarRsvpDecline => 'Recusar';

  @override
  String get callHistoryTitle => 'Chamadas';

  @override
  String get callHistoryTab => 'Histórico de chamadas';

  @override
  String get callHistoryTempMeeting => 'Reunião temporária';

  @override
  String get callHistoryCopy => 'Copiar';

  @override
  String get callHistoryLinkCopied => 'Link copiado';

  @override
  String get callHistoryShare => 'Compartilhar';

  @override
  String get callHistoryEnter => 'Entrar';

  @override
  String get callHistoryAlreadyInCall => 'Já em uma chamada';

  @override
  String get callHistoryCouldNotDeterminePeer =>
      'Não foi possível determinar a outra parte';

  @override
  String get callHistoryContacts => 'Contatos';

  @override
  String get callHistoryFailedLoadRoom => 'Falha ao carregar sua sala';

  @override
  String get callHistoryYourRoom => 'Sua sala';

  @override
  String get callHistoryCreateMeeting => 'Criar reunião';

  @override
  String get callHistoryMeetingSummaries => 'Resumos de reuniões';

  @override
  String get callHistoryMeetingRecordings => 'Gravações de reuniões';

  @override
  String get callHistoryNoCalls => 'Sem chamadas';

  @override
  String get callHistoryMissed => 'Perdida';

  @override
  String get callHistoryRecording => 'Gravação';

  @override
  String get callHistorySummary => 'Resumo';

  @override
  String get callHistoryCallAgain => 'Ligar novamente';

  @override
  String callHistoryTodayTime(String time) {
    return 'Hoje, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Ontem, $time';
  }

  @override
  String get callHistoryUnknown => 'Desconhecido';

  @override
  String get callHistoryDetails => 'Detalhes da chamada';

  @override
  String get callHistoryOutgoing => 'Chamada realizada';

  @override
  String get callHistoryIncoming => 'Chamada recebida';

  @override
  String callHistoryDuration(String duration) {
    return 'Duração: $duration';
  }

  @override
  String get callHistoryWithAI => 'Com assistente de AI';

  @override
  String get callHistoryParticipants => 'Participantes';

  @override
  String get callDetailYouSuffix => '(Você)';

  @override
  String get callHistoryMeetingSummary => 'Resumo da reunião';

  @override
  String get callHistoryMoreDetails => 'Mais detalhes';

  @override
  String get callHistorySummaryProcessing => 'Processando resumo...';

  @override
  String get callHistoryMeetingRecording => 'Gravação da reunião';

  @override
  String get callHistoryProcessing => 'Processando...';

  @override
  String get callHistoryCreateTranscript => 'Criar transcrição';

  @override
  String get callHistoryNoSummaries => 'Sem resumos';

  @override
  String get callHistoryRecordDuringCall =>
      'Pressione \"Gravar\" durante a chamada';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Reunião $time';
  }

  @override
  String get callHistoryTranscribing => 'Transcrevendo e resumindo...';

  @override
  String get callHistoryTranscriptCreated => 'Transcrição criada';

  @override
  String get callHistoryNoRecordings => 'Sem gravações';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Gravação $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Gravação indisponível';

  @override
  String get callHistoryTranscriptReady => 'Transcrição pronta';

  @override
  String get callHistoryTranscript => 'Transcrição';

  @override
  String get callHistoryKeyPoints => 'Pontos principais';

  @override
  String get callHistoryTasks => 'Tarefas';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'Atribuído a: $assignee';
  }

  @override
  String get callHistoryDecisions => 'Decisões';

  @override
  String get callHistoryShowTranscript => 'Mostrar transcrição completa';

  @override
  String get profileScanQr => 'Escanear QR';

  @override
  String get profileMyQrCode => 'Meu código QR';

  @override
  String profileAddMeShare(String userId) {
    return 'Adicione-me no Taler ID!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Mostre este código para adicionar você';

  @override
  String get profileEditDesc =>
      'Nome, sobrenome, patronímico, data de nascimento';

  @override
  String get profileAboutMe => 'Sobre mim';

  @override
  String get profileAboutMeDesc => 'Valores, habilidades, interesses e mais';

  @override
  String get profileNotes => 'Notas';

  @override
  String get profileNotesDesc => 'Pensamentos, ideias e notas';

  @override
  String get profileAvatarUpdated => 'Avatar atualizado';

  @override
  String get profileNickname => 'Apelido';

  @override
  String get profileNotSet => 'Não definido';

  @override
  String get profileChangeNickname => 'Alterar apelido';

  @override
  String get profileNicknameUpdated => 'Apelido atualizado';

  @override
  String get profileShareLabel => 'Compartilhar';

  @override
  String get profileScanQrCode => 'Escanear código QR';

  @override
  String get profilePointCamera => 'Aponte a câmera para o código QR';

  @override
  String get profilePhotoCamera => 'Tirar foto';

  @override
  String get profilePhotoGallery => 'Escolher da galeria';

  @override
  String get editProfilePatronymic => 'Patronímico (opcional)';

  @override
  String get editProfileDateFormat => 'DD.MM.AAAA';

  @override
  String get aboutMeTitle => 'Sobre mim';

  @override
  String get aboutMeClickToFill => 'Clique para preencher';

  @override
  String get aboutMeCoreValues => 'Valores';

  @override
  String get aboutMeWorldview => 'Visão de mundo';

  @override
  String get aboutMeSkills => 'Habilidades';

  @override
  String get aboutMeInterests => 'Interesses';

  @override
  String get aboutMeDesires => 'Desejos';

  @override
  String get aboutMeBackground => 'Perfil';

  @override
  String get aboutMeLikes => 'Gostos';

  @override
  String get aboutMeDislikes => 'Desgostos';

  @override
  String get aboutMeDeleteSection => 'Excluir seção?';

  @override
  String get aboutMeDeleteConfirm =>
      'Todos os dados nesta seção serão excluídos.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Erro de conexão: $error';
  }

  @override
  String get aboutMeVisibility => 'Visibilidade';

  @override
  String get aboutMeTags => 'Tags';

  @override
  String get aboutMeAddTag => 'Adicionar tag...';

  @override
  String get aboutMeDescription => 'Descrição';

  @override
  String get aboutMeDescribeLong => 'Conte-nos mais...';

  @override
  String get aboutMeVisibilityEveryone => 'Todos';

  @override
  String get aboutMeVisibilityContacts => 'Contatos';

  @override
  String get aboutMeVisibilityOnlyMe => 'Somente eu';

  @override
  String get settingsProfileSubtitle => 'Perfil';

  @override
  String get settingsWallpaper => 'Papel de parede';

  @override
  String get settingsWallpaperDesc => 'Imagem de fundo para todo o app';

  @override
  String get settingsWallpaperNone => 'Nenhum';

  @override
  String get settingsAccount => 'Conta';

  @override
  String get settingsKycVerification => 'Verificação de Identidade (KYC)';

  @override
  String get settingsOrganizations => 'Organizações';

  @override
  String get incomingCallLabel => 'Chamada recebida';

  @override
  String get incomingCallDecline => 'Recusar';

  @override
  String get incomingCallAccept => 'Aceitar';

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
  String get meshIncomingCallLabel => '📡 Chamada mesh recebida';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'Dispositivo mesh $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'Termine a chamada atual primeiro';

  @override
  String get callPopupTransportTitle => 'Chamar via';

  @override
  String get callPopupTransportMesh => '📡 Mesh (peer-to-peer)';

  @override
  String get callPopupTransportLk => '📞 Servidor';

  @override
  String get callPopupTransportMeshUnavailable =>
      'Contato não acessível via mesh';

  @override
  String get meshOnboardingTitle => '📡 Chamadas mesh precisam do app aberto';

  @override
  String get meshOnboardingBody =>
      'Quando o telefone está bloqueado, chamadas mesh podem cair após ~30 segundos (limitação do iOS).';

  @override
  String get meshOnboardingAck => 'Entendi';

  @override
  String get meshHistoryBadge => '📡 Mesh';

  @override
  String get meshHistoryNoChatAvailable => 'Contato não está na sua lista';

  @override
  String get meshCallStatusInviting => 'Chamando…';

  @override
  String get meshCallStatusConnecting => 'Conectando…';

  @override
  String get meshCallEndedUserHangup => 'Chamada encerrada';

  @override
  String get meshCallEndedRemoteHangup => 'Encerrada pelo par';

  @override
  String get meshCallEndedRejected => 'Recusada';

  @override
  String get meshCallEndedNoAnswer => 'Sem resposta';

  @override
  String get meshCallEndedConnectionLost => 'Conexão perdida';

  @override
  String get meshCallEndedError => 'Erro de conexão';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 Mesh · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 Mesh';

  @override
  String get batteryExemptionTitle => '📡 Chamadas mesh confiáveis';

  @override
  String get batteryExemptionBody =>
      'Permita que o app funcione sem restrições de bateria para que o Android não interrompa o mesh em segundo plano.';

  @override
  String get batteryExemptionAccept => 'Abrir configurações';

  @override
  String get batteryExemptionDismiss => 'Agora não';

  @override
  String get groupCamera => 'Câmera';

  @override
  String get groupGallery => 'Galeria';

  @override
  String get groupAvatarUpdated => 'Avatar do grupo atualizado';

  @override
  String get groupNameTitle => 'Nome do grupo';

  @override
  String get groupEnterName => 'Digite o nome';

  @override
  String get groupDescriptionTitle => 'Descrição do grupo';

  @override
  String get groupEnterDescription => 'Digite a descrição do grupo';

  @override
  String get groupChangeRoleTitle => 'Alterar função';

  @override
  String get groupRemoveMemberTitle => 'Remover membro';

  @override
  String get groupDescription => 'Descrição';

  @override
  String get groupAddDescription => 'Adicionar descrição do grupo';

  @override
  String get groupNoDescription => 'Sem descrição';

  @override
  String get groupMediaAndFiles => 'Mídia e arquivos';

  @override
  String get groupMuteNotifications => 'Silenciar notificações';

  @override
  String get groupMuted => 'Silenciado';

  @override
  String get groupNoResults => 'Sem resultados';

  @override
  String get authInvalidCode => 'Código inválido. Tente novamente.';

  @override
  String get loginSubtitle => 'Use email e senha';

  @override
  String get emailRequired => 'Digite o email';

  @override
  String get emailInvalid => 'Email inválido';

  @override
  String get passwordRequired => 'Digite a senha';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'Uma conta para todo o ecossistema Taler';

  @override
  String get usernameOptional => 'Nome de usuário (opcional)';

  @override
  String get usernameMinLength => 'Mínimo de 3 caracteres';

  @override
  String get usernameMaxLength => 'Máximo de 30 caracteres';

  @override
  String get usernameInvalid => 'Apenas letras, dígitos e _';

  @override
  String get biometricLoginReason => 'Entrar no Taler ID';

  @override
  String get docTypePassport => 'Passaporte';

  @override
  String get docTypeIdCard => 'Carteira de Identidade';

  @override
  String get docTypeDriverLicense => 'Carteira de Motorista';

  @override
  String get docTypeResidencePermit => 'Permissão de Residência';

  @override
  String addressApartment(String number) {
    return 'apto. $number';
  }

  @override
  String get failedToUpdateProfile => 'Falha ao atualizar o perfil';

  @override
  String get failedToStartKyb => 'Falha ao iniciar a verificação KYB';

  @override
  String get orgUpdated => 'Organização atualizada';

  @override
  String get failedToUpdateOrg => 'Falha ao atualizar a organização';

  @override
  String get failedToChangeRole => 'Falha ao alterar a função';

  @override
  String get failedToRemoveMember => 'Falha ao remover membro';

  @override
  String get capabilityMessagesTitle => 'Mensagens';

  @override
  String get capabilityMessagesDesc =>
      'Verifique mensagens ou escreva para alguém. Por exemplo: \"Escrever para Viktor: estarei lá em uma hora\"';

  @override
  String get capabilityCallsTitle => 'Chamadas';

  @override
  String get capabilityCallsDesc =>
      'Ligue para qualquer contato por voz. Por exemplo: \"Ligar para Viktor Viktorov\"';

  @override
  String get capabilityChatTitle => 'Histórico de Chat';

  @override
  String get capabilityChatDesc =>
      'Vou analisar o histórico de chat. Por exemplo: \"Sobre o que discutimos com Viktor?\"';

  @override
  String get capabilityProfileTitle => 'Perfil';

  @override
  String get capabilityProfileDesc =>
      'Vou mostrar ou atualizar seu perfil. Por exemplo: \"Mostrar meu perfil\"';

  @override
  String get capabilityCoachingTitle => 'Coaching';

  @override
  String get capabilityCoachingDesc =>
      'Modos: coaching ICF, psicólogo, consulta de RH. Diga: \"Vamos fazer coaching\"';

  @override
  String get capabilityCalendarTitle => 'Calendário';

  @override
  String get capabilityCalendarDesc =>
      'Agende uma reunião ou defina um lembrete. Por exemplo: \"Agendar uma reunião com Viktor para amanhã às 15:00\"';

  @override
  String get capabilityNotesTitle => 'Notas';

  @override
  String get capabilityNotesDesc =>
      'Salve um pensamento ou leia notas recentes. Por exemplo: \"Anotar uma ideia...\" ou \"Ler notas recentes\"';

  @override
  String get assistantCallConfirm => 'Fazer uma chamada?';

  @override
  String get callNoAnswer => 'Sem resposta';

  @override
  String get contactDelete => 'Remover contato';

  @override
  String get contactDeleteTitle => 'Remover contato';

  @override
  String get contactDeleteConfirm =>
      'Você tem certeza? Este contato será removido.';

  @override
  String get contactBlock => 'Bloquear';

  @override
  String get contactBlockTitle => 'Bloquear usuário';

  @override
  String get contactBlockConfirm =>
      'Este usuário não poderá enviar mensagens ou ligar para você.';

  @override
  String get contactUnblock => 'Desbloquear';

  @override
  String get contactBlocked => 'Bloqueado';

  @override
  String get contactYouAreBlocked => 'Este usuário te bloqueou';

  @override
  String get chatBlockedByYou => 'Você bloqueou este usuário';

  @override
  String get chatYouAreBlocked => 'Você foi bloqueado por este usuário';

  @override
  String get chatNotContacts =>
      'Adicione este usuário aos contatos para enviar mensagens';

  @override
  String get contactRevokeRequest => 'Revogar solicitação';

  @override
  String get messengerPoll => 'Enquete';

  @override
  String get messengerCreatePoll => 'Criar Enquete';

  @override
  String get messengerPollQuestion => 'Pergunta';

  @override
  String messengerPollOption(int number) {
    return 'Opção $number';
  }

  @override
  String get messengerPollAddOption => 'Adicionar opção';

  @override
  String get messengerPollAnonymous => 'Votação anônima';

  @override
  String get messengerPollMultiple => 'Escolha múltipla';

  @override
  String get messengerPollCreateError => 'Falha ao criar enquete';

  @override
  String get messengerPollUnavailable => 'Enquete indisponível';

  @override
  String get messengerPollMultipleNote => 'Você pode selecionar várias';

  @override
  String messengerPollVotes(int count) {
    return '$count votos';
  }

  @override
  String get messengerVideoMessage => 'Mensagem de vídeo';

  @override
  String get messengerVideoRecordError => 'Erro na gravação de vídeo';

  @override
  String get messengerVideoPlaybackError =>
      'Não foi possível reproduzir o vídeo';

  @override
  String get messengerGalleryAccessError => 'Sem acesso à galeria';

  @override
  String get messengerSearchInChat => 'Buscar no chat...';

  @override
  String get messengerSaveToFavorites => 'Salvar nos favoritos';

  @override
  String get messengerSavedToFavorites => 'Salvo nos favoritos';

  @override
  String get messengerSearchInMessages => 'Buscar nas mensagens...';

  @override
  String messengerFoundInMessages(int count) {
    return 'Encontrado nas mensagens ($count)';
  }

  @override
  String get messengerGroupDefault => 'Grupo';

  @override
  String get messengerUserDefault => 'Usuário';

  @override
  String get messengerPin => 'Fixar';

  @override
  String get messengerUnpin => 'Desafixar';

  @override
  String get messengerArchive => 'Arquivar';

  @override
  String get messengerUnarchive => 'Desarquivar';

  @override
  String get messengerDeleteChat => 'Excluir chat';

  @override
  String get messengerDeleteChatTitle => 'Excluir chat?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'Excluir chat com $name? Isso não pode ser desfeito.';
  }

  @override
  String get messengerCreateChannel => 'Criar Canal';

  @override
  String get messengerChannelName => 'Nome';

  @override
  String get messengerChannelDescription => 'Descrição (opcional)';

  @override
  String get messengerChannelCreateError => 'Falha ao criar canal';

  @override
  String get messengerFilterAll => 'Todos';

  @override
  String get messengerFilterUnread => 'Não lidos';

  @override
  String get messengerFilterPersonal => 'Pessoal';

  @override
  String get messengerFilterGroups => 'Grupos';

  @override
  String get messengerFilterChannels => 'Canais';

  @override
  String get messengerArchivedSection => 'Arquivados';

  @override
  String get messengerSavedSection => 'Favoritos';

  @override
  String get messengerSavedSubtitle => 'Salvar na memória';

  @override
  String messengerArchiveTitle(int count) {
    return 'Arquivar ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'Arquivo está vazio';

  @override
  String messengerYouPrefix(String message) {
    return 'Você: $message';
  }

  @override
  String get messengerMissedCall => 'Chamada perdida';

  @override
  String get messengerSavedTitle => 'Favoritos';

  @override
  String get messengerNoSavedMessages => 'Nenhuma mensagem salva';

  @override
  String get messengerSavedHint =>
      'Pressione uma mensagem por um tempo → \"Salvar nos favoritos\"';

  @override
  String get messengerDefaultFile => 'Arquivo';

  @override
  String get messengerTopicDefault => 'Geral';

  @override
  String get messengerTopicNew => 'Novo Tópico';

  @override
  String get messengerTopicNameHint => 'Nome do tópico';

  @override
  String get messengerTopicIcon => 'Ícone';

  @override
  String messengerTopicCount(int count) {
    return '$count tópicos';
  }

  @override
  String get messengerNoTopics => 'Nenhum tópico';

  @override
  String get messengerNoMessages => 'Sem mensagens';

  @override
  String get you => 'Você';

  @override
  String get messengerThread => 'Tópico';

  @override
  String get messengerThreadReply => 'resposta';

  @override
  String get messengerThreadReplies => 'respostas';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'Sem respostas';

  @override
  String get messengerReplyHint => 'Responder ao tópico...';

  @override
  String get messengerContactName => 'Nome do contato';

  @override
  String messengerOriginalName(String name) {
    return 'Nome original: $name';
  }

  @override
  String get messengerDisplayName => 'Nome de exibição';

  @override
  String messengerShareContact(String name) {
    return 'Contato no Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'Autoexcluir mensagens';

  @override
  String get messengerAutoDeleteOff => 'Desligado';

  @override
  String get messengerAutoDelete7d => '7 dias';

  @override
  String get messengerAutoDelete30d => '30 dias';

  @override
  String get messengerAutoDelete90d => '90 dias';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count dias';
  }

  @override
  String get messengerSettingsHeader => 'Configurações';

  @override
  String get messengerAdminOnly => 'Postagem apenas para admin';

  @override
  String get messengerAdminOnlyDesc => 'Membros podem apenas ler';

  @override
  String get messengerTopics => 'Tópicos';

  @override
  String get messengerTopicsDesc => 'Dividir chat em tópicos';

  @override
  String get aiTwinSection => 'Gêmeo de Voz AI';

  @override
  String get aiTwinEnabled => 'Ativar Gêmeo AI';

  @override
  String get aiTwinEnabledDesc =>
      'Se você não atender, seu gêmeo AI atende a chamada com sua voz';

  @override
  String get aiTwinTimeout => 'Tempo limite de resposta';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds seg';
  }

  @override
  String get aiTwinPrompt => 'Instruções AI';

  @override
  String get aiTwinPromptSubtitle =>
      'Como o gêmeo AI deve se apresentar e sobre o que falar';

  @override
  String aiTwinPromptHint(String name) {
    return 'Oi, aqui é o gêmeo de voz AI de $name. $name não pôde atender agora. Diga-me quem está ligando e sobre o que é — eu passarei a mensagem.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Clonagem de voz personalizada em breve. Por enquanto, a AI fala com a voz de $name.';
  }

  @override
  String get aiTwinDefaultName => 'o proprietário';

  @override
  String get aiTwinPromptReset => 'Redefinir';

  @override
  String get callHistoryAiTwinAnswered => 'GÊMEO AI ATENDEU';

  @override
  String get callHistoryAiTwinSummary => 'RESUMO DA CHAMADA';

  @override
  String get callHistoryAiTwinTranscript => 'TRANSCRIÇÃO';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'De $name';
  }

  @override
  String get aiTwinOfferTitle => 'Não atendendo';

  @override
  String aiTwinOfferBody(String name) {
    return '$name não está atendendo. Deixar uma mensagem com o gêmeo de voz AI?';
  }

  @override
  String get aiTwinOfferBodyUser => 'Usuário';

  @override
  String get aiTwinOfferAccept => 'Sim, deixar mensagem';

  @override
  String get aiTwinOfferKeepWaiting => 'Continuar esperando';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'Seu substituto AI';

  @override
  String get aiTwinHeroSubtitle =>
      'Atende chamadas com sua voz quando você não pode.';

  @override
  String get aiTwinProfileTitle => 'Substituto AI';

  @override
  String get aiTwinProfileDesc => 'Atende chamadas com sua voz';

  @override
  String get aiTwinBadgeOn => 'LIGADO';

  @override
  String get aiAnalystTitle => 'Analista AI';

  @override
  String get aiAnalystSubtitle => 'Arquivos, tarefas, análise — Claude';

  @override
  String get channelsDiscover => 'Encontrar canal';

  @override
  String get channelsSearchHint => 'Buscar canais';

  @override
  String get channelsSubscribers => 'inscritos';

  @override
  String get channelsSubscribe => 'Inscrever-se';

  @override
  String get channelsUnsubscribe => 'Cancelar inscrição';

  @override
  String get channelsSubscribedLabel => 'Você está inscrito';

  @override
  String get channelsSettings => 'Configurações do canal';

  @override
  String get channelsDelete => 'Excluir canal';

  @override
  String get channelsDeleteConfirm => 'Excluir canal permanentemente?';

  @override
  String get channelsEmpty => 'Nenhum canal ainda';

  @override
  String get channelsOpen => 'Abrir';

  @override
  String get channelsNameLabel => 'Nome';

  @override
  String get channelsDescriptionLabel => 'Descrição';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'Proprietário não pode cancelar inscrição. Exclua o canal em vez disso.';

  @override
  String get channelsNotFoundRedirect => 'Canal não existe mais';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buscas',
      one: '$count busca',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos',
      one: '$count arquivo',
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
      other: '$count imagens',
      one: '$count imagem',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etapas',
      one: '$count etapa',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get savedTitle => 'Mensagens Salvas';

  @override
  String get savedSubtitle => 'Seu cloud privado';

  @override
  String get savedOpenError => 'Não foi possível abrir Mensagens Salvas';

  @override
  String get billingWalletTitle => 'Carteira';

  @override
  String get billingBuyPackage => 'Comprar pacote';

  @override
  String get billingCurrentBalance => 'Saldo atual';

  @override
  String get billingPackagesTitle => 'Pacotes';

  @override
  String get billingPackagesUnavailable => 'Pacotes indisponíveis';

  @override
  String get billingRecentOperations => 'Operações recentes';

  @override
  String get billingAllOperations => 'Todas as operações';

  @override
  String get billingNoOperations => 'Nenhuma operação';

  @override
  String get billingOperationsTitle => 'Operações';

  @override
  String get billingOperationsEmptyTitle => 'Nenhuma operação ainda';

  @override
  String get billingOperationsEmptySubtitle =>
      'Recargas e cobranças por recursos de IA aparecerão aqui';

  @override
  String get billingPricebookTitle => 'Preços dos recursos';

  @override
  String get billingPricebookUnavailable => 'Lista de preços indisponível';

  @override
  String get billingAiFeaturesTitle => 'Recursos de IA';

  @override
  String get billingInsufficientFundsTitle => 'Fundos insuficientes';

  @override
  String get billingInsufficientFundsSubtitle =>
      'Recarregue seu saldo para usar este recurso.';

  @override
  String billingRequiredLine(String required) {
    return 'Necessário: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'Disponível: $available μTAL';
  }

  @override
  String get billingTopUp => 'Recarregar';

  @override
  String get billingCancel => 'Cancelar';

  @override
  String get billingRetry => 'Tentar novamente';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'Saldo baixo: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'Carteira & Saldo';

  @override
  String get billingSectionHeader => 'Cobrança & IA';

  @override
  String get billingFeatureVoiceAssistant => 'Assistente de voz';

  @override
  String get billingFeatureWebSearch => 'Pesquisa na web do assistente';

  @override
  String get billingFeatureAiTwin => 'Gêmeo de voz';

  @override
  String get billingFeatureAiTwinLong => 'Gêmeo de voz (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'Bot de saída';

  @override
  String get billingFeatureOutboundCallLong => 'Bot de chamadas de saída';

  @override
  String get billingFeatureWhisperTranscribe => 'Transcrição de chamadas';

  @override
  String get billingFeatureMeetingSummary => 'Resumos de chamadas de IA';

  @override
  String get billingConfigureAiTwin => 'Configurar gêmeo de IA';

  @override
  String get billingWebSearchSubtitle => '(usado pelo assistente)';

  @override
  String billingPackagePurchased(String balance) {
    return 'Pacote comprado: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'Recomendado';

  @override
  String get billingSessionTerminatedNoFunds =>
      'Saldo esgotado — sessão encerrada';

  @override
  String get billingSessionTerminatedGeneric =>
      'Sessão do assistente encerrada';

  @override
  String billingBuyForPrice(String price) {
    return 'Comprar por €$price';
  }

  @override
  String get billingTxTypeTopup => 'Recarga';

  @override
  String get billingTxTypeRefund => 'Reembolso';

  @override
  String get billingTxTypeSpend => 'Cobrança';

  @override
  String get billingUnitMinute => 'minuto';

  @override
  String get billingUnitRequest => 'solicitação';

  @override
  String get billingUnitToken => 'token';

  @override
  String get billingUnitTokens1k => '1K tokens';

  @override
  String get billingUnitCall => 'chamada';

  @override
  String get groupCallSelectParticipants => 'Selecionar participantes';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'Buscar';

  @override
  String get groupCallMaxReached => 'Máximo de 7 participantes';

  @override
  String get groupCallLobbyTitle => 'Grupo • Lobby';

  @override
  String groupCallHostLabel(String name) {
    return 'Host: $name';
  }

  @override
  String get groupCallMicHint => 'Mic ativará ao conectar';

  @override
  String get groupCallCancel => 'Cancelar';

  @override
  String get groupCallNoAnswer => 'Ninguém atendeu';

  @override
  String get groupCallEndedByHost => 'Chamada encerrada pelo host';

  @override
  String get groupCallAllLeft => 'Todos saíram da chamada';

  @override
  String get groupCallEnded => 'Chamada encerrada';

  @override
  String groupCallActiveTitle(int count) {
    return 'Grupo • $count';
  }

  @override
  String get groupCallConnectionLost => 'Conexão perdida';

  @override
  String get groupCallMuteRequested => 'Host pediu para todos silenciarem';

  @override
  String get groupCallUnmute => 'Reativar som';

  @override
  String get groupCallMute => 'Silenciar';

  @override
  String get groupCallMuteAll => 'Silenciar todos';

  @override
  String get groupCallLeave => 'Sair';

  @override
  String get groupCallStatusCalling => 'chamando…';

  @override
  String get groupCallStatusDeclined => 'recusado';

  @override
  String get groupCallStatusTimeout => 'sem resposta';

  @override
  String get groupCallStatusLeft => 'saiu';

  @override
  String groupCallKickConfirm(String name) {
    return 'Remover $name da chamada';
  }

  @override
  String get groupCallCancelAction => 'Cancelar';

  @override
  String get groupCallActiveBanner => 'Chamada ativa';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'Grupo: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'Grupo: $host';
  }

  @override
  String get groupCallCreateError => 'Não foi possível criar a chamada';

  @override
  String get groupCallJoinError => 'Não foi possível entrar na chamada';

  @override
  String get groupCallLivekitError => 'Erro do LiveKit';

  @override
  String get groupCallDone => 'Concluído';

  @override
  String get groupCallNoResults => 'Nenhum resultado';

  @override
  String get groupCallNoContacts => 'Nenhum contato';

  @override
  String get meshGcContactOffline => 'Não está neste Wi-Fi';

  @override
  String get meshGcOnlineViaMesh => 'Online via mesh';

  @override
  String get meshGcMaxInvitees =>
      'Chamadas em grupo suportam até 4 convidados (5 pessoas no total).';

  @override
  String get meshGcStart => 'Iniciar chamada em grupo';

  @override
  String get meshGcCancel => 'Cancelar';

  @override
  String get meshGcStatusCalling => 'Chamando…';

  @override
  String get meshGcStatusJoined => 'Participando';

  @override
  String get meshGcStatusDeclined => 'Recusado';

  @override
  String get meshGcStatusNoAnswer => 'Sem resposta';

  @override
  String get meshGcStatusConnectionFailed => 'Conexão falhou';

  @override
  String get meshGcStatusLeft => 'Saiu';

  @override
  String get meshGcTopTitle => 'Malha';

  @override
  String get meshGcBusyOneOnOne => 'Termine sua chamada atual primeiro.';

  @override
  String get presenceOnline => 'online';

  @override
  String get presenceLastSeenJustNow => 'visto agora mesmo';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'visto há $minutes min';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'visto hoje às $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'visto ontem às $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'visto em $date';
  }

  @override
  String get presenceLastSeenRecently => 'visto recentemente';

  @override
  String get privacySectionTitle => 'Privacidade';

  @override
  String get privacyLastSeenLabel => 'Quem vê seu último horário visto';

  @override
  String get privacyEveryone => 'Todos';

  @override
  String get privacyContacts => 'Apenas contatos';

  @override
  String get privacyNobody => 'Ninguém';

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

  @override
  String get chatSelect => 'Select';

  @override
  String get convDraftLabel => 'Draft';

  @override
  String get chatMentionNotFound => 'User not found';

  @override
  String get chatTranscribeVoice => 'Transcribe';

  @override
  String get chatTranscribing => 'Transcribing…';

  @override
  String get chatTranscribeEmpty => 'Nothing audible in this recording';

  @override
  String get chatTranscribeFailed => 'Could not transcribe';
}
