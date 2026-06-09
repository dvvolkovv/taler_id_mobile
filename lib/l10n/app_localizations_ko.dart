// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => '검색';

  @override
  String get appSubtitle => '통합 생태계 신원';

  @override
  String get login => '로그인';

  @override
  String get loginButton => '로그인';

  @override
  String get register => '계정 생성';

  @override
  String get registerButton => '계정 생성';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get confirmPassword => '비밀번호 확인';

  @override
  String get firstName => '이름';

  @override
  String get lastName => '성';

  @override
  String get noAccount => '계정이 없으신가요?';

  @override
  String get createOne => '계정 생성';

  @override
  String get haveAccount => '이미 계정이 있으신가요?';

  @override
  String get signIn => '로그인';

  @override
  String get passwordMinLength => '최소 8자';

  @override
  String get invalidEmail => '유효한 이메일을 입력하세요';

  @override
  String get fieldRequired => '필수 입력란';

  @override
  String get twoFATitle => '이중 인증';

  @override
  String get twoFASubtitle => '인증 앱에서 6자리 코드를 입력하세요';

  @override
  String get twoFACode => '2FA 코드';

  @override
  String get verify => '확인';

  @override
  String get tabProfile => '프로필';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => '조직';

  @override
  String get tabSettings => '설정';

  @override
  String get profile => '프로필';

  @override
  String get editProfile => '프로필 수정';

  @override
  String get phone => '전화번호';

  @override
  String get country => '국가';

  @override
  String get dateOfBirth => '생년월일';

  @override
  String get documents => '문서';

  @override
  String get addDocument => '문서 추가';

  @override
  String get noDocuments => '업로드된 문서 없음';

  @override
  String get save => '저장';

  @override
  String get profileUpdated => '프로필이 업데이트되었습니다';

  @override
  String get personalData => '개인 정보';

  @override
  String get passport => '여권';

  @override
  String get drivingLicense => '운전면허증';

  @override
  String get diploma => '졸업장';

  @override
  String get nationalId => '주민등록증';

  @override
  String get certificate => '증명서';

  @override
  String get notSpecified => '지정되지 않음';

  @override
  String get notSpecifiedFemale => '지정되지 않음';

  @override
  String get documentType => '문서 유형';

  @override
  String get passportId => '여권 / 신분증';

  @override
  String get diplomaCertificate => '졸업장 / 증명서';

  @override
  String get loadError => '로딩 오류';

  @override
  String get verification => '검증';

  @override
  String get countryAustria => '오스트리아';

  @override
  String get countryGermany => '독일';

  @override
  String get countryRussia => '러시아';

  @override
  String get countryUkraine => '우크라이나';

  @override
  String get countryKazakhstan => '카자흐스탄';

  @override
  String get countryBelarus => '벨라루스';

  @override
  String get countryOther => '기타';

  @override
  String get kycTitle => 'KYC 검증';

  @override
  String get kycVerified => '검증됨';

  @override
  String get kycPending => '대기 중';

  @override
  String get kycRejected => '거부됨';

  @override
  String get kycUnverified => '미검증';

  @override
  String get kycVerifiedDesc =>
      '귀하의 신원이 확인되었습니다. Taler 생태계의 모든 기능에 완전한 접근이 가능합니다.';

  @override
  String get kycPendingDesc => '귀하의 문서가 검토 중입니다. 보통 1-2 영업일이 소요됩니다.';

  @override
  String get kycRejectedDesc => '검증 실패. 사유를 검토하고 문서를 다시 제출하세요.';

  @override
  String get kycUnverifiedDesc => 'Taler 생태계의 금융 기능에 완전한 접근을 위해 검증을 완료하세요.';

  @override
  String get startVerification => '검증 시작';

  @override
  String get retryVerification => '검증 재시도';

  @override
  String verifiedAt(String date) {
    return '검증됨: $date';
  }

  @override
  String get documentsSubmitted => '검토를 위해 문서 제출됨';

  @override
  String get documentsSubmittedDesc =>
      '검토는 보통 1-2 영업일이 소요됩니다. 결과는 푸시 알림으로 받게 됩니다.';

  @override
  String get securityAes => '귀하의 데이터는 AES-256 암호화로 보호됩니다';

  @override
  String get verificationTime => '검증은 1-2 영업일이 소요됩니다';

  @override
  String get pushNotification => '결과는 푸시 알림으로 받게 됩니다';

  @override
  String get kycWebOnly => 'KYC 검증은 모바일 앱에서만 가능합니다.';

  @override
  String verificationError(String code) {
    return '검증 오류: $code';
  }

  @override
  String get organizations => '조직';

  @override
  String get noOrganizations => '조직 없음';

  @override
  String get noOrganizationsDesc => '조직을 생성하거나 초대를 수락하세요';

  @override
  String get createOrganization => '조직 생성';

  @override
  String get newOrganization => '새 조직';

  @override
  String get orgName => '이름 *';

  @override
  String get orgDescription => '설명';

  @override
  String get orgEmail => '연락처 이메일';

  @override
  String get orgWebsite => '웹사이트';

  @override
  String get orgLegalAddress => '법적 주소';

  @override
  String get create => '생성';

  @override
  String get organization => '조직';

  @override
  String get contacts => '연락처';

  @override
  String members(int count) {
    return '멤버 ($count)';
  }

  @override
  String get inviteMember => '멤버 초대';

  @override
  String get invite => '초대';

  @override
  String get sendInvite => '초대장 보내기';

  @override
  String inviteSent(String email) {
    return '$email로 초대장이 발송되었습니다';
  }

  @override
  String get role => '역할';

  @override
  String get roleOwner => '소유자';

  @override
  String get roleAdmin => '관리자';

  @override
  String get roleOperator => '운영자';

  @override
  String get roleViewer => '뷰어';

  @override
  String get editOrganization => '편집';

  @override
  String get editOrganizationTitle => '조직 편집';

  @override
  String get removeMember => '멤버 제거';

  @override
  String removeMemberConfirm(String name) {
    return '조직에서 $name을(를) 제거하시겠습니까?';
  }

  @override
  String get memberRemoved => '멤버가 제거되었습니다';

  @override
  String get roleChanged => '역할이 변경되었습니다';

  @override
  String get kybVerified => '검증됨';

  @override
  String get kybPending => '대기 중';

  @override
  String get kybRejected => '거부됨';

  @override
  String get kybNone => '미검증';

  @override
  String get kybVerification => 'KYB 검증 시작';

  @override
  String get kybStartBusiness => '비즈니스 검증 시작';

  @override
  String get kybStatusLabel => 'KYB 상태';

  @override
  String get noKyb => 'KYB 없음';

  @override
  String get kybBusinessVerificationTitle => '비즈니스 검증 (KYB)';

  @override
  String get kybVerifiedOrgDesc => '조직이 성공적으로 검증되었습니다.';

  @override
  String get kybPendingOrgDesc => '문서가 검토 중입니다. 보통 1-3 영업일이 소요됩니다.';

  @override
  String get kybRejectedOrgDesc => '검증에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get kybNoneOrgDesc => '비즈니스 기능에 접근하려면 조직을 검증하세요.';

  @override
  String get invitePlus => '+ 초대';

  @override
  String get kybVerificationTitle => 'KYB 검증';

  @override
  String get kybWebOnlyBusiness => 'KYB 인증은 모바일 앱에서만 가능합니다.';

  @override
  String get unknownDevice => '알 수 없는 기기';

  @override
  String get ipUnknown => 'IP 알 수 없음';

  @override
  String get currentSessionLabel => '현재';

  @override
  String get endSessionAction => '종료';

  @override
  String get deviceLoggedOut => '기기가 로그아웃됩니다.';

  @override
  String get acceptInvitationTitle => '조직 초대';

  @override
  String get acceptInvitation => '초대 수락';

  @override
  String get acceptInvitationDesc => 'Taler 생태계의 조직에 초대되었습니다.';

  @override
  String get accept => '수락';

  @override
  String get reject => '거절';

  @override
  String get sessions => '활성 세션';

  @override
  String get currentSession => '현재 세션';

  @override
  String get deleteSession => '세션 종료';

  @override
  String get deleteSessionConfirm => '이 세션을 종료하시겠습니까?';

  @override
  String get sessionDeleted => '세션이 종료되었습니다';

  @override
  String get noSessions => '활성 세션 없음';

  @override
  String minutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String hoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String daysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get justNow => '방금';

  @override
  String get settings => '설정';

  @override
  String get security => '보안';

  @override
  String get biometrics => '생체 인식';

  @override
  String get biometricsDesc => 'Face ID 또는 지문으로 빠른 로그인';

  @override
  String get biometricsConfirm => '빠른 로그인을 활성화하려면 생체 인식을 확인하세요';

  @override
  String get biometricsError => '생체 인식을 활성화하지 못했습니다. 기기 설정을 확인하세요.';

  @override
  String get changePassword => '비밀번호 변경';

  @override
  String get twoFactorAuth => '이중 인증';

  @override
  String get currentPassword => '현재 비밀번호';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get confirmNewPassword => '새 비밀번호 확인';

  @override
  String get passwordChanged => '비밀번호가 변경되었습니다';

  @override
  String get wrongCurrentPassword => '현재 비밀번호가 틀렸습니다';

  @override
  String get passwordTooWeak => '비밀번호가 너무 약합니다: 최소 8자, 문자 및 숫자 필요';

  @override
  String get passwordChangeFailed => '비밀번호 변경 실패';

  @override
  String get notifications => '알림';

  @override
  String get permissions => '권한';

  @override
  String get permissionNotifications => '푸시 알림';

  @override
  String get permissionNotificationsDesc => '통화, 메시지, 상태';

  @override
  String get permissionMicrophone => '마이크';

  @override
  String get permissionMicrophoneDesc => '통화 및 음성 비서';

  @override
  String get permissionCamera => '카메라';

  @override
  String get permissionCameraDesc => '영상 통화 및 인증';

  @override
  String get permissionLocation => '위치';

  @override
  String get permissionLocationDesc => '인증에 사용됨';

  @override
  String get permissionOpenSettings => '권한을 취소하려면 시스템 설정을 엽니다';

  @override
  String get pushKycStatus => 'KYC 상태 푸시';

  @override
  String get pushKycStatusDesc => '인증 결과';

  @override
  String get pushLogins => '로그인 푸시';

  @override
  String get pushLoginsDesc => '새 기기에서 로그인할 때';

  @override
  String get account => '계정';

  @override
  String get language => '언어';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => '인터페이스 언어';

  @override
  String get exportData => '데이터 내보내기 (GDPR)';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get deleteAccountConfirm => '계정을 삭제하시겠습니까?';

  @override
  String get deleteAccountDesc => '모든 데이터가 삭제됩니다 (GDPR). 이 작업은 되돌릴 수 없습니다.';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutConfirm => '로그아웃하시겠습니까?';

  @override
  String get logoutDesc => '이 기기에서 Taler ID에서 로그아웃됩니다.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'PIN 코드';

  @override
  String get pinCodeDesc => '4자리 코드로 빠른 로그인';

  @override
  String get setupPin => 'PIN 설정';

  @override
  String get enterPin => 'PIN 입력';

  @override
  String get confirmPin => 'PIN 확인';

  @override
  String get pinMismatch => 'PIN이 일치하지 않습니다';

  @override
  String get passwordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get pinSet => 'PIN이 성공적으로 설정되었습니다';

  @override
  String get enterPinToLogin => '로그인하려면 PIN을 입력하세요';

  @override
  String get pinIncorrect => '잘못된 PIN';

  @override
  String get removePin => 'PIN 제거';

  @override
  String get pinRemoved => 'PIN이 제거되었습니다';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get ok => '확인';

  @override
  String get retry => '재시도';

  @override
  String get loading => '로딩 중...';

  @override
  String get error => '오류';

  @override
  String get success => '성공';

  @override
  String get noData => '데이터 없음';

  @override
  String get failedToLoad => '데이터를 불러오지 못했습니다';

  @override
  String get failedToLoadProfile => '프로필을 불러오지 못했습니다';

  @override
  String get failedToSave => '변경 사항을 저장하지 못했습니다';

  @override
  String get failedToLoadOrgs => '조직을 불러오지 못했습니다';

  @override
  String get failedToLoadOrg => '조직 데이터를 불러오지 못했습니다';

  @override
  String get failedToCreateOrg => '조직을 생성하지 못했습니다';

  @override
  String get failedToInvite => '초대를 보내지 못했습니다';

  @override
  String get failedToAcceptInvite => '초대를 수락하지 못했습니다';

  @override
  String get failedToLoadSessions => '세션을 불러오지 못했습니다';

  @override
  String get failedToDeleteSession => '세션을 종료하지 못했습니다';

  @override
  String get failedToLoadKyc => '인증 상태를 불러오지 못했습니다';

  @override
  String get failedToStartKyc => '인증을 시작하지 못했습니다';

  @override
  String get verifiedPersonalInfo => '인증된 데이터';

  @override
  String get middleName => '중간 이름';

  @override
  String get placeOfBirth => '출생지';

  @override
  String get nationality => '국적';

  @override
  String get gender => '성별';

  @override
  String get genderMale => '남성';

  @override
  String get genderFemale => '여성';

  @override
  String get docNumber => '번호';

  @override
  String get docIssuedDate => '발급일';

  @override
  String get docValidUntil => '유효기간';

  @override
  String get docIssuedBy => '발급 기관';

  @override
  String get address => '주소';

  @override
  String get refreshData => '데이터 새로고침';

  @override
  String get failedToLoadSumsubData => '인증 데이터를 불러오지 못했습니다';

  @override
  String get sumsubDataLoading => '인증 데이터를 불러오는 중...';

  @override
  String get reviewResultGreen => '인증 통과';

  @override
  String get reviewResultRed => '인증 실패';

  @override
  String get tabAssistant => '비서';

  @override
  String get assistantConnecting => '연결 중…';

  @override
  String get assistantSpeaking => '말하는 중…';

  @override
  String get assistantListening => '듣는 중…';

  @override
  String get assistantTapToStart => '시작하려면 탭하세요';

  @override
  String get assistantTapToTalk => 'AI와 대화하려면 탭하세요';

  @override
  String get assistantRealtimeDesc => '비서가 실시간으로 음성으로 응답합니다';

  @override
  String get assistantConnectingToAssistant => '비서에 연결 중...';

  @override
  String get assistantAiSpeaking => 'AI 말하는 중...';

  @override
  String get assistantAiListening => 'AI 듣는 중';

  @override
  String get assistantSpeakerOn => '스피커 켜기';

  @override
  String get assistantSpeaker => '스피커';

  @override
  String get assistantEnd => '종료';

  @override
  String get assistantUnmute => '음소거 해제';

  @override
  String get assistantMicrophone => '마이크';

  @override
  String get assistantConnectionError => '연결 오류';

  @override
  String get tabMessenger => '메시지';

  @override
  String get tabCalls => '통화';

  @override
  String get tabCalendar => '캘린더';

  @override
  String get appearance => '외관';

  @override
  String get appearanceSelect => '테마 선택';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get themeSystem => '시스템';

  @override
  String get onboardingTitle1 => '통합 신원';

  @override
  String get onboardingDesc1 =>
      'Taler ID는 Taler 생태계에서의 디지털 여권입니다. 모든 서비스에 하나의 계정으로.';

  @override
  String get onboardingTitle2 => '데이터 보안';

  @override
  String get onboardingDesc2 => 'KYC 인증, AES-256 암호화, 이중 인증으로 신원을 보호합니다.';

  @override
  String get onboardingTitle3 => '정보 유지';

  @override
  String get onboardingDesc3 => '인증 상태, 새로운 기기에서의 로그인, 수신 통화에 대한 알림을 받으세요.';

  @override
  String get onboardingNext => '다음';

  @override
  String get onboardingEnableNotifications => '알림 활성화';

  @override
  String get onboardingTitle4 => '음성 통화';

  @override
  String get onboardingDesc4 =>
      '음성 통화 및 AI 비서 사용을 위해 마이크 접근을 허용하세요. 설정에서 나중에 변경할 수 있습니다.';

  @override
  String get onboardingEnableMicrophone => '마이크 활성화';

  @override
  String get onboardingStart => '시작하기';

  @override
  String get onboardingSkip => '건너뛰기';

  @override
  String get meshLocalNetworkPromptTitle => '로컬 네트워크 접근 허용';

  @override
  String get meshLocalNetworkPromptBody =>
      'Wi-Fi에서 피어를 찾기 위해(iOS 오프라인 그룹 통화), 로컬 네트워크 권한이 필요합니다. 설정 열기 → 개인정보 보호 및 보안 → 로컬 네트워크 → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => '설정 열기';

  @override
  String get meshLocalNetworkPromptDismiss => '알겠습니다';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get forgotPasswordTitle => '비밀번호 재설정';

  @override
  String get forgotPasswordSubtitle => '재설정 코드를 받으려면 이메일을 입력하세요';

  @override
  String resetCodeSent(String email) {
    return '$email로 코드가 전송되었습니다';
  }

  @override
  String get enterResetCode => '코드를 입력하세요';

  @override
  String get resetPasswordButton => '비밀번호 재설정';

  @override
  String get passwordResetSuccess => '비밀번호가 성공적으로 재설정되었습니다';

  @override
  String get sendCode => '코드 보내기';

  @override
  String get resendCode => '코드 재전송';

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
  String get newGroup => '새 그룹';

  @override
  String get newChat => '새 채팅';

  @override
  String get groupName => '그룹 이름';

  @override
  String get createGroup => '그룹 생성';

  @override
  String get groupInfo => '그룹 정보';

  @override
  String groupMembers(int count) {
    return '멤버 ($count)';
  }

  @override
  String get addMembers => '멤버 추가';

  @override
  String get leaveGroup => '그룹 나가기';

  @override
  String get leaveGroupConfirm => '이 그룹을 나가시겠습니까?';

  @override
  String get deleteGroup => '그룹 삭제';

  @override
  String get deleteGroupConfirm => '이 그룹을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get groupRoleOwner => '소유자';

  @override
  String get groupRoleAdmin => '관리자';

  @override
  String get groupRoleMember => '멤버';

  @override
  String get selectParticipants => '참가자 선택';

  @override
  String selectedCount(int count) {
    return '$count명 선택됨';
  }

  @override
  String get changeRole => '역할 변경';

  @override
  String get groupCreated => '그룹 생성됨';

  @override
  String memberJoined(String name) {
    return '$name님이 참여했습니다';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name님이 나갔습니다';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name님이 제거되었습니다';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name님의 역할이 $role(으)로 변경되었습니다';
  }

  @override
  String participantsCount(int count) {
    return '$count명 참가자';
  }

  @override
  String get enterGroupName => '그룹 이름 입력';

  @override
  String get muteNotifications => '알림 끄기';

  @override
  String get unmuteNotifications => '알림 켜기';

  @override
  String get muteFor1Hour => '1시간 동안';

  @override
  String get muteFor8Hours => '8시간 동안';

  @override
  String get muteFor2Days => '2일 동안';

  @override
  String get muteForever => '영구적으로';

  @override
  String get muted => '음소거됨';

  @override
  String get tabTranslator => '번역';

  @override
  String get translatorTitle => '번역기';

  @override
  String get translatorSelectLanguage => '언어 선택';

  @override
  String get translatorDownloading => '언어 모델 다운로드 중...';

  @override
  String get translatorDownloadingHint => '첫 다운로드에만 인터넷이 필요합니다';

  @override
  String get translatorTypeHint => '텍스트를 입력하거나 마이크를 탭하세요';

  @override
  String get translatorListening => '듣는 중...';

  @override
  String get translatorTapToSpeak => '말하기 위해 탭하세요';

  @override
  String get translatorTapToStop => '중지하려면 탭하세요';

  @override
  String get translatorAutoSpeak => '자동 말하기';

  @override
  String get translatorCopied => '복사됨';

  @override
  String get translatorLangRu => '러시아어';

  @override
  String get translatorLangEn => '영어';

  @override
  String get translatorLangDe => '독일어';

  @override
  String get translatorLangFr => '프랑스어';

  @override
  String get translatorLangEs => '스페인어';

  @override
  String get translatorLangIt => '이탈리아어';

  @override
  String get translatorLangPt => '포르투갈어';

  @override
  String get translatorLangTr => '터키어';

  @override
  String get translatorLangZh => '중국어';

  @override
  String get translatorLangJa => '일본어';

  @override
  String get translatorLangKo => '한국어';

  @override
  String get translatorLangAr => '아랍어';

  @override
  String get translatorLangPl => '폴란드어';

  @override
  String get translatorLangSk => '슬로바키아어';

  @override
  String get translatorLangCs => '체코어';

  @override
  String get translatorLangNl => '네덜란드어';

  @override
  String get translatorLangSv => '스웨덴어';

  @override
  String get translatorLangDa => '덴마크어';

  @override
  String get translatorLangNo => '노르웨이어';

  @override
  String get translatorLangFi => '핀란드어';

  @override
  String get translatorLangUk => '우크라이나어';

  @override
  String get translatorLangEl => '그리스어';

  @override
  String get translatorLangRo => '루마니아어';

  @override
  String get translatorLangHu => '헝가리어';

  @override
  String get translatorLangBg => '불가리아어';

  @override
  String get translatorLangHr => '크로아티아어';

  @override
  String get translatorLangSr => '세르비아어';

  @override
  String get translatorLangHi => '힌디어';

  @override
  String get translatorLangTh => '태국어';

  @override
  String get translatorLangVi => '베트남어';

  @override
  String get translatorLangId => '인도네시아어';

  @override
  String get translatorLangMs => '말레이어';

  @override
  String get translatorLangHe => '히브리어';

  @override
  String get translatorLangFa => '페르시아어';

  @override
  String get callInProgress => '통화 진행 중';

  @override
  String get joinCall => '참여';

  @override
  String get createCallLink => '통화 링크';

  @override
  String get callLinkCopied => '링크가 복사되었습니다';

  @override
  String get callLinkTitle => '방 링크';

  @override
  String get connectionUnstable => '연결이 불안정합니다 — 인터넷을 확인하세요';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String get errorTimeout => '연결 시간이 초과되었습니다. 인터넷 연결을 확인하세요.';

  @override
  String get errorNoConnection => '인터넷 연결이 없습니다.';

  @override
  String get errorGeneral => '오류가 발생했습니다. 다시 시도하세요.';

  @override
  String errorWithMessage(String message) {
    return '오류: $message';
  }

  @override
  String get notifChannelMessages => '메시지';

  @override
  String get notifChannelMessagesDesc => '새 메시지 알림';

  @override
  String get notifChannelMissedCalls => '부재중 통화';

  @override
  String get notifChannelMissedCallsDesc => '부재중 통화 알림';

  @override
  String get notifMissedCall => '부재중 통화';

  @override
  String get notifAccept => '수락';

  @override
  String get notifDecline => '거절';

  @override
  String get notifIncomingCall => '수신 중인 통화';

  @override
  String get notifIncomingCallChannel => '수신 중인 통화';

  @override
  String get notifMissedCallChannel => '부재중 통화';

  @override
  String get notifUnknown => '알 수 없음';

  @override
  String get effectNone => '배경 없음';

  @override
  String get effectBlur => '흐림';

  @override
  String get effectOffice => '사무실';

  @override
  String get effectNature => '자연';

  @override
  String get effectGradient => '그라데이션';

  @override
  String get effectLibrary => '도서관';

  @override
  String get effectCity => '도시';

  @override
  String get effectMinimalism => '미니멀리즘';

  @override
  String get voiceParticipant => '참가자';

  @override
  String get voiceInvitesToRoom => '님이 방으로 초대합니다';

  @override
  String get voiceRoom => '방';

  @override
  String get voicePasswordProtected => '비밀번호로 보호됨';

  @override
  String get voicePasswordHint => '비밀번호';

  @override
  String get voiceEnter => '입장';

  @override
  String get voiceJoinRoom => '방에 참여';

  @override
  String get voiceYourName => '당신의 이름';

  @override
  String voiceInvitationSent(String name) {
    return '$name님에게 초대장이 발송되었습니다';
  }

  @override
  String get voiceNoActiveRoom => '활성화된 방이 없습니다';

  @override
  String get voiceCameraPermission =>
      '설정 → 개인정보 보호 → 카메라 → TalerID에서 카메라 접근을 허용하세요';

  @override
  String get voiceOpenSettings => '열기';

  @override
  String voiceCameraError(String error) {
    return '카메라 활성화 실패: $error';
  }

  @override
  String get voiceAllAgreedRecording => '모두 동의했습니다. 녹음이 시작되었습니다.';

  @override
  String get voiceNewParticipantAgreed => '새 참가자가 녹음에 동의했습니다.';

  @override
  String get voiceDeclinedRecording => '녹음을 거부했습니다. 통화를 종료합니다.';

  @override
  String get voiceRecordingEnded => '녹음이 종료되었습니다';

  @override
  String get voiceRecordingInProgress => '녹음 진행 중';

  @override
  String get voiceTranscriptionRequest => '필사 요청';

  @override
  String get voiceRecordingRequest => '녹음 요청';

  @override
  String get voiceAgree => '동의';

  @override
  String get voiceDeclineAndLeave => '거부하고 나가기';

  @override
  String get voiceAudioOutput => '오디오 출력';

  @override
  String get voiceAudioPhone => '전화';

  @override
  String get voiceAudioSpeaker => '스피커';

  @override
  String get voiceAudioBluetooth => '블루투스';

  @override
  String get voiceAudioHeadphones => '헤드폰';

  @override
  String get voiceLinkCopied => '링크가 복사되었습니다';

  @override
  String get voiceTranslateTo => '번역';

  @override
  String get voiceSearchLanguage => '언어 검색...';

  @override
  String voiceRoomWithCreator(String name) {
    return '방 $name';
  }

  @override
  String get voiceVoiceCall => '음성 통화';

  @override
  String get voiceOnHold => '대기 중';

  @override
  String get voiceActiveCall => '활성';

  @override
  String get voiceEndAllCalls => '모든 통화 종료';

  @override
  String get voiceEndThisCall => '이 통화 종료';

  @override
  String get voiceCopyLink => '링크 복사';

  @override
  String get voiceAddParticipant => '참가자 추가';

  @override
  String get voiceReconnecting => '재연결 중...';

  @override
  String get voiceConnectionError => '연결 오류';

  @override
  String get voiceClose => '닫기';

  @override
  String get voiceCalling => '통화 중...';

  @override
  String get voiceCallActive => '통화 활성';

  @override
  String get voiceWaiting => '대기 중';

  @override
  String get voiceWaitingUpper => '대기 중';

  @override
  String get voiceRec => '녹음';

  @override
  String get voiceStop => '중지';

  @override
  String get voiceRecord => '녹음 중';

  @override
  String get voiceTranslation => '번역';

  @override
  String get voiceAudio => '오디오';

  @override
  String get voiceFlipCamera => '카메라 전환';

  @override
  String get voiceBackground => '배경';

  @override
  String get voiceAssistantSpeakingStatus => '비서가 말하고 있습니다...';

  @override
  String get voiceAssistantListeningStatus => '비서가 듣고 있습니다...';

  @override
  String get voiceUnmute => '음소거 해제';

  @override
  String get voiceMic => '마이크';

  @override
  String get voiceAssistantLabel => '비서';

  @override
  String get voiceCameraOn => '카메라 켜기';

  @override
  String get voiceCameraLabel => '카메라';

  @override
  String get voiceEndCall => '통화 종료';

  @override
  String get voiceWaitingParticipants => '참가자 대기 중...';

  @override
  String get voiceYou => '당신';

  @override
  String get voiceAiAssistant => 'AI 비서';

  @override
  String get voiceVideoUnavailable => '비디오 사용 불가';

  @override
  String get voiceSearchNickname => '닉네임으로 검색...';

  @override
  String get voiceTranscriptionWord => '필사';

  @override
  String get voiceRecordingWord => '녹음';

  @override
  String get voiceConnecting => '연결 중...';

  @override
  String get voiceVideoBackground => '비디오 배경';

  @override
  String get voiceCallSettings => '통화 설정';

  @override
  String get voiceEnableAI => 'AI 비서 활성화';

  @override
  String get voiceAIParticipating => 'AI가 대화에 참여합니다';

  @override
  String get voiceNormalCall => 'AI 없는 일반 통화';

  @override
  String get voiceCallConfirm => '통화하시겠습니까?';

  @override
  String get chatAlreadyInCall => '이미 통화 중입니다';

  @override
  String chatCallError(String error) {
    return '통화 오류: $error';
  }

  @override
  String get chatPhotoVideo => '사진 / 비디오';

  @override
  String get chatCamera => '카메라';

  @override
  String get chatFile => '파일';

  @override
  String get chatContact => '연락처';

  @override
  String get chatSelectContact => '연락처 선택';

  @override
  String get chatNoContacts => '연락처 없음';

  @override
  String get chatUser => '사용자';

  @override
  String get chatFileAttachment => '📎 파일';

  @override
  String chatFileUploadError(String error) {
    return '파일 업로드 오류: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 음성 메시지';

  @override
  String get chatGroup => '그룹';

  @override
  String get chatDialog => '대화';

  @override
  String get chatCall => '통화';

  @override
  String get chatStartConversation => '대화 시작';

  @override
  String get chatYou => '당신';

  @override
  String get chatIsTyping => '입력 중...';

  @override
  String chatUserIsTyping(String name) {
    return '$name님이 입력 중...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names님들이 입력 중...';
  }

  @override
  String get chatPreparingFile => '파일 준비 중…';

  @override
  String chatUploading(int progress) {
    return '업로드 중… $progress%';
  }

  @override
  String get chatEdited => '수정됨';

  @override
  String get chatViaMesh => '메시를 통해';

  @override
  String get chatReply => '답장';

  @override
  String get chatEdit => '편집';

  @override
  String get chatCopy => '복사';

  @override
  String get chatCopied => '복사됨';

  @override
  String get chatSaveMedia => '저장';

  @override
  String get chatForward => '전달';

  @override
  String get chatSaving => '저장 중...';

  @override
  String get chatSavedToGallery => '갤러리에 저장됨';

  @override
  String get chatNoSavePermission => '저장 권한이 없습니다. 설정을 확인하세요.';

  @override
  String get chatFileSaveError => '파일 저장 오류';

  @override
  String get chatDeleteMessage => '메시지 삭제';

  @override
  String get chatDeleteForMe => '내 메시지 삭제';

  @override
  String get chatDeleteForEveryone => '모두에게서 삭제';

  @override
  String get chatMessageForwarded => '메시지 전달됨';

  @override
  String get chatContactTapToOpen => '연락처 · 열려면 탭하세요';

  @override
  String get chatForwardTo => '전달할 대상...';

  @override
  String get chatSearchHint => '검색...';

  @override
  String get chatRecording => '녹음 중...';

  @override
  String get chatMessageHint => '메시지...';

  @override
  String get chatHideKeyboard => '키보드 숨기기';

  @override
  String get chatEditing => '편집 중';

  @override
  String get chatFileDownloadError => '파일 다운로드 오류';

  @override
  String get chatVoiceMessageShort => '음성 메시지';

  @override
  String get chatVideoSavedToGallery => '비디오가 갤러리에 저장됨';

  @override
  String get chatSavingError => '저장 오류';

  @override
  String get convSetNickname => '닉네임 설정';

  @override
  String get convNicknameRequired =>
      '메신저를 사용하려면 닉네임이 필요합니다. 다른 사용자가 이를 통해 당신을 찾을 수 있습니다.';

  @override
  String get convNicknameRules => '3–30자: 문자, 숫자, _';

  @override
  String get convNicknameTaken => '이미 사용 중인 닉네임입니다';

  @override
  String get convSaveError => '저장 오류';

  @override
  String get convContactsLabel => '연락처';

  @override
  String get convDefaultUser => '사용자';

  @override
  String get convNoDialogs => '대화 없음';

  @override
  String get convFindUserToChat => '채팅을 시작할 사용자를 찾기';

  @override
  String get convDefaultContact => '연락처';

  @override
  String get dashboardUser => '사용자';

  @override
  String get dashboardIncomingCall => '수신 전화';

  @override
  String get dashboardDecline => '거절';

  @override
  String get dashboardAccept => '수락';

  @override
  String get dashboardActiveCall => '활성 통화 — 돌아가려면 탭하세요';

  @override
  String dashboardUpdateAvailable(String version) {
    return '업데이트 가능 $version';
  }

  @override
  String get dashboardUpdate => '업데이트';

  @override
  String get dashboardWhatsNew => '새로운 기능';

  @override
  String dashboardWhatsNewTitle(String version) {
    return '$version의 새로운 기능';
  }

  @override
  String get dashboardInstalling => '설치 중...';

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
  String get contactRequestsTitle => '연락처';

  @override
  String get messengerContactRequestsSection => '연락처 요청';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 새로운 요청',
      one: '1개의 새로운 요청',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => '검색';

  @override
  String get contactRequestsIncoming => '수신';

  @override
  String get contactRequestsSent => '발신';

  @override
  String get contactRequestsSearchHint => '닉네임 또는 이메일';

  @override
  String get contactRequestSent => '요청 보냄';

  @override
  String get contactRequestsNoUsers => '사용자를 찾을 수 없음';

  @override
  String get contactRequestsSearchHelp => '정확한 닉네임 또는 이메일을 입력하고\n검색을 누르세요';

  @override
  String get contactRequestsSendTooltip => '요청 보내기';

  @override
  String get contactRequestTitle => '연락처 요청';

  @override
  String contactRequestConfirm(String name) {
    return '$name에게 연락처 요청을 보내시겠습니까?';
  }

  @override
  String get contactRequestSend => '보내기';

  @override
  String get contactRequestsNoIncoming => '수신된 요청 없음';

  @override
  String get contactRequestsNoSent => '발신된 요청 없음';

  @override
  String get contactRequestStatusPending => '응답 대기 중';

  @override
  String get contactRequestStatusAccepted => '수락됨';

  @override
  String get contactRequestStatusRejected => '거절됨';

  @override
  String get userSearchTitle => '사용자 찾기';

  @override
  String get userSearchHint => '닉네임, 전화번호 또는 이메일';

  @override
  String get userSearchHelper => '@닉네임, 이메일 또는 이름을 입력하여 검색';

  @override
  String get userSearchNoUsers => '사용자를 찾을 수 없음';

  @override
  String get userProfileShareContact => '연락처 공유';

  @override
  String get userProfileShareContactDesc => '연락처 링크 보내기';

  @override
  String get userProfileCopyLink => '링크 복사';

  @override
  String get userProfileCopied => '복사됨';

  @override
  String get userProfileTitle => '프로필';

  @override
  String get userProfileLoadError => '프로필 로드 오류';

  @override
  String get userProfileMessage => '메시지';

  @override
  String get userProfileCall => '통화';

  @override
  String get userProfileRequestSent => '요청 전송됨';

  @override
  String get userProfileAccept => '수락';

  @override
  String get userProfileDecline => '거절';

  @override
  String get userProfileAddToContacts => '연락처에 추가';

  @override
  String get userProfileMediaTab => '미디어';

  @override
  String get userProfileFilesTab => '파일';

  @override
  String get userProfileLinksTab => '링크';

  @override
  String get userProfileRecordingsTab => '녹음';

  @override
  String get userProfileSummariesTab => '요약';

  @override
  String get userProfileNoMedia => '미디어 파일 없음';

  @override
  String get userProfileNoFiles => '파일 없음';

  @override
  String get userProfileNoLinks => '링크 없음';

  @override
  String get userProfileNoRecordings => '녹음 없음';

  @override
  String get userProfileNoSummaries => '요약 없음';

  @override
  String get userProfileMeetingSummary => '회의 요약';

  @override
  String get userProfileFailedOpenChat => '채팅 열기 실패';

  @override
  String get sharedMediaTitle => '미디어 및 파일';

  @override
  String get sharedMediaTab => '미디어';

  @override
  String get sharedFilesTab => '파일';

  @override
  String get sharedLinksTab => '링크';

  @override
  String get sharedNoMedia => '미디어 파일 없음';

  @override
  String get sharedNoFiles => '파일 없음';

  @override
  String get sharedNoLinks => '링크 없음';

  @override
  String get shareToChat => '채팅으로 전달';

  @override
  String get shareSelectChat => '채팅 선택';

  @override
  String get shareNoChats => '채팅 없음';

  @override
  String shareFilesCount(int count) {
    return '$count 파일';
  }

  @override
  String get contactsTitle => '연락처';

  @override
  String get contactsAddTooltip => '연락처 추가';

  @override
  String get contactsSearchHint => '연락처 검색...';

  @override
  String get contactsNotFound => '검색 결과 없음';

  @override
  String get contactsEmpty => '연락처 없음';

  @override
  String get contactsAdd => '연락처 추가';

  @override
  String get contactsPendingConfirmation => '확인 대기 중';

  @override
  String get contactsMessage => '메시지';

  @override
  String get contactsCall => '통화';

  @override
  String get contactsResend => '요청 재전송';

  @override
  String get contactsResendTimeout => '24시간 후에 다시 시도';

  @override
  String get contactsResent => '요청 재전송됨';

  @override
  String get contactsWantsToConnect => '연결을 원합니다';

  @override
  String get contactsSearchPeople => '사람 찾기';

  @override
  String get notesTitle => '메모';

  @override
  String get notesAssistantSpeaking => '비서가 말하고 있습니다...';

  @override
  String get notesListening => '듣고 있습니다...';

  @override
  String get notesEmpty => '메모 없음';

  @override
  String get notesEmptyHint => '마이크를 눌러 받아쓰기\n또는 +를 눌러 수동 입력';

  @override
  String get notesDeleteConfirm => '메모를 삭제하시겠습니까?';

  @override
  String get notesNew => '새 메모';

  @override
  String get notesEdit => '편집';

  @override
  String get notesTitleHint => '제목';

  @override
  String get notesContentHint => '생각을 적어보세요...';

  @override
  String get calendarTitle => '캘린더';

  @override
  String get calendarStop => '중지';

  @override
  String get calendarVoiceInput => '음성 입력';

  @override
  String get calendarNewEvent => '새 이벤트';

  @override
  String get calendarAssistantSpeaking => '비서가 말하고 있습니다...';

  @override
  String get calendarListening => '듣고 있습니다...';

  @override
  String calendarInvitations(int count) {
    return '초대장 ($count)';
  }

  @override
  String get calendarNoEvents => '이벤트 없음';

  @override
  String get calendarDayMon => '월';

  @override
  String get calendarDayTue => '화';

  @override
  String get calendarDayWed => '수';

  @override
  String get calendarDayThu => '목';

  @override
  String get calendarDayFri => '금';

  @override
  String get calendarDaySat => '토';

  @override
  String get calendarDaySun => '일';

  @override
  String get calendarEnterRoom => '방에 입장';

  @override
  String get calendarMeeting => '회의';

  @override
  String calendarLocationPrefix(String location) {
    return '위치: $location';
  }

  @override
  String get calendarEditEvent => '편집';

  @override
  String get calendarTitleHint => '제목';

  @override
  String get calendarDescriptionHint => '설명';

  @override
  String get calendarTypeEvent => '이벤트';

  @override
  String get calendarTypeMeeting => '회의';

  @override
  String get calendarTypeReminder => '알림';

  @override
  String get calendarTypeLabel => '유형';

  @override
  String get calendarMeetingLink => '회의 링크';

  @override
  String get calendarLocationHint => '위치';

  @override
  String get calendarDateLabel => '날짜';

  @override
  String get calendarTimeLabel => '시간';

  @override
  String get calendarReminderLabel => '알림';

  @override
  String get calendarReminderNone => '없음';

  @override
  String get calendarReminder15min => '15분 전';

  @override
  String get calendarReminder30min => '30분 전';

  @override
  String get calendarReminder1hour => '1시간 전';

  @override
  String get calendarRepeatLabel => '반복';

  @override
  String get calendarRepeatNone => '반복 없음';

  @override
  String get calendarRepeatDaily => '매일';

  @override
  String get calendarRepeatWeekly => '매주';

  @override
  String get calendarRepeatMonthly => '매월';

  @override
  String get calendarRepeatYearly => '매년';

  @override
  String get calendarParticipants => '참가자';

  @override
  String get calendarAddParticipant => '추가';

  @override
  String get calendarSearchContacts => '연락처 검색...';

  @override
  String get calendarNoContacts => '연락처 없음';

  @override
  String get calendarStatusAccepted => '수락됨';

  @override
  String get calendarStatusDeclined => '거절됨';

  @override
  String get calendarStatusMaybe => '아마도';

  @override
  String get calendarStatusPending => '대기 중';

  @override
  String get calendarEndTime => '종료 시간';

  @override
  String get calendarYourAnswer => '귀하의 답변:';

  @override
  String get calendarOrganizer => '주최자';

  @override
  String calendarDeleteError(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get calendarRsvpAccept => '수락';

  @override
  String get calendarRsvpMaybe => '아마도';

  @override
  String get calendarRsvpDecline => '거절';

  @override
  String get callHistoryTitle => '통화';

  @override
  String get callHistoryTab => '통화 기록';

  @override
  String get callHistoryTempMeeting => '임시 회의';

  @override
  String get callHistoryCopy => '복사';

  @override
  String get callHistoryLinkCopied => '링크 복사됨';

  @override
  String get callHistoryShare => '공유';

  @override
  String get callHistoryEnter => '입장';

  @override
  String get callHistoryAlreadyInCall => '이미 통화 중입니다';

  @override
  String get callHistoryCouldNotDeterminePeer => '상대방을 확인할 수 없습니다';

  @override
  String get callHistoryContacts => '연락처';

  @override
  String get callHistoryFailedLoadRoom => '방을 불러오지 못했습니다';

  @override
  String get callHistoryYourRoom => '당신의 방';

  @override
  String get callHistoryCreateMeeting => '회의 생성';

  @override
  String get callHistoryMeetingSummaries => '회의 요약';

  @override
  String get callHistoryMeetingRecordings => '회의 녹음';

  @override
  String get callHistoryNoCalls => '통화 없음';

  @override
  String get callHistoryMissed => '부재중';

  @override
  String get callHistoryRecording => '녹음 중';

  @override
  String get callHistorySummary => '요약';

  @override
  String get callHistoryCallAgain => '다시 전화하기';

  @override
  String callHistoryTodayTime(String time) {
    return '오늘, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return '어제, $time';
  }

  @override
  String get callHistoryUnknown => '알 수 없음';

  @override
  String get callHistoryDetails => '통화 세부 정보';

  @override
  String get callHistoryOutgoing => '발신 통화';

  @override
  String get callHistoryIncoming => '수신 통화';

  @override
  String callHistoryDuration(String duration) {
    return '기간: $duration';
  }

  @override
  String get callHistoryWithAI => 'AI 비서와 함께';

  @override
  String get callHistoryParticipants => '참가자';

  @override
  String get callDetailYouSuffix => '(당신)';

  @override
  String get callHistoryMeetingSummary => '회의 요약';

  @override
  String get callHistoryMoreDetails => '더 많은 세부 정보';

  @override
  String get callHistorySummaryProcessing => '요약 처리 중...';

  @override
  String get callHistoryMeetingRecording => '회의 녹음';

  @override
  String get callHistoryProcessing => '처리 중...';

  @override
  String get callHistoryCreateTranscript => '기록 생성';

  @override
  String get callHistoryNoSummaries => '요약 없음';

  @override
  String get callHistoryRecordDuringCall => '통화 중 \"녹음\"을 누르세요';

  @override
  String callHistoryMeetingTime(String time) {
    return '회의 $time';
  }

  @override
  String get callHistoryTranscribing => '기록 및 요약 중...';

  @override
  String get callHistoryTranscriptCreated => '기록 생성됨';

  @override
  String get callHistoryNoRecordings => '녹음 없음';

  @override
  String callHistoryRecordingDate(String date) {
    return '녹음 $date';
  }

  @override
  String get callHistoryRecordingUnavailable => '녹음 불가';

  @override
  String get callHistoryTranscriptReady => '기록 준비 완료';

  @override
  String get callHistoryTranscript => '기록';

  @override
  String get callHistoryKeyPoints => '핵심 포인트';

  @override
  String get callHistoryTasks => '작업';

  @override
  String callHistoryAssignedTo(String assignee) {
    return '할당 대상: $assignee';
  }

  @override
  String get callHistoryDecisions => '결정';

  @override
  String get callHistoryShowTranscript => '전체 기록 보기';

  @override
  String get profileScanQr => 'QR 스캔';

  @override
  String get profileMyQrCode => '내 QR 코드';

  @override
  String profileAddMeShare(String userId) {
    return 'Taler ID에서 나를 추가하세요!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => '추가하려면 이 코드를 보여주세요';

  @override
  String get profileEditDesc => '이름, 성, 부칭, 생년월일';

  @override
  String get profileAboutMe => '내 소개';

  @override
  String get profileAboutMeDesc => '가치관, 기술, 관심사 등';

  @override
  String get profileNotes => '메모';

  @override
  String get profileNotesDesc => '생각, 아이디어 및 메모';

  @override
  String get profileAvatarUpdated => '아바타가 업데이트되었습니다';

  @override
  String get profileNickname => '닉네임';

  @override
  String get profileNotSet => '설정되지 않음';

  @override
  String get profileChangeNickname => '닉네임 변경';

  @override
  String get profileNicknameUpdated => '닉네임이 업데이트되었습니다';

  @override
  String get profileShareLabel => '공유';

  @override
  String get profileScanQrCode => 'QR 코드 스캔';

  @override
  String get profilePointCamera => '카메라를 QR 코드에 맞추세요';

  @override
  String get profilePhotoCamera => '사진 촬영';

  @override
  String get profilePhotoGallery => '갤러리에서 선택';

  @override
  String get editProfilePatronymic => '부칭 (선택 사항)';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => '내 소개';

  @override
  String get aboutMeClickToFill => '클릭하여 입력';

  @override
  String get aboutMeCoreValues => '가치관';

  @override
  String get aboutMeWorldview => '세계관';

  @override
  String get aboutMeSkills => '기술';

  @override
  String get aboutMeInterests => '관심사';

  @override
  String get aboutMeDesires => '욕구';

  @override
  String get aboutMeBackground => '프로필';

  @override
  String get aboutMeLikes => '좋아하는 것';

  @override
  String get aboutMeDislikes => '싫어하는 것';

  @override
  String get aboutMeDeleteSection => '섹션 삭제?';

  @override
  String get aboutMeDeleteConfirm => '이 섹션의 모든 데이터가 삭제됩니다.';

  @override
  String aboutMeConnectionError(String error) {
    return '연결 오류: $error';
  }

  @override
  String get aboutMeVisibility => '가시성';

  @override
  String get aboutMeTags => '태그';

  @override
  String get aboutMeAddTag => '태그 추가...';

  @override
  String get aboutMeDescription => '설명';

  @override
  String get aboutMeDescribeLong => '더 알려주세요...';

  @override
  String get aboutMeVisibilityEveryone => '모두';

  @override
  String get aboutMeVisibilityContacts => '연락처';

  @override
  String get aboutMeVisibilityOnlyMe => '나만 보기';

  @override
  String get settingsProfileSubtitle => '프로필';

  @override
  String get settingsWallpaper => '배경화면';

  @override
  String get settingsWallpaperDesc => '앱 전체의 배경 이미지';

  @override
  String get settingsWallpaperNone => '없음';

  @override
  String get settingsAccount => '계정';

  @override
  String get settingsKycVerification => '신원 확인 (KYC)';

  @override
  String get settingsOrganizations => '조직';

  @override
  String get incomingCallLabel => '수신 전화';

  @override
  String get incomingCallDecline => '거절';

  @override
  String get incomingCallAccept => '수락';

  @override
  String get meshIncomingCallLabel => '📡 수신 메쉬 전화';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return '메쉬 장치 $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => '현재 통화를 먼저 종료하세요';

  @override
  String get callPopupTransportTitle => '통화 방식';

  @override
  String get callPopupTransportMesh => '📡 메쉬 (피어 투 피어)';

  @override
  String get callPopupTransportLk => '📞 서버';

  @override
  String get callPopupTransportMeshUnavailable => '메쉬로 연락할 수 없음';

  @override
  String get meshOnboardingTitle => '📡 메쉬 통화는 앱이 열려 있어야 합니다';

  @override
  String get meshOnboardingBody =>
      '전화가 잠겨 있으면 메쉬 통화가 약 30초 후에 끊길 수 있습니다 (iOS 제한).';

  @override
  String get meshOnboardingAck => '알겠습니다';

  @override
  String get meshHistoryBadge => '📡 메쉬';

  @override
  String get meshHistoryNoChatAvailable => '연락처가 목록에 없습니다';

  @override
  String get meshCallStatusInviting => '통화 중…';

  @override
  String get meshCallStatusConnecting => '연결 중…';

  @override
  String get meshCallEndedUserHangup => '통화 종료';

  @override
  String get meshCallEndedRemoteHangup => '상대방이 종료함';

  @override
  String get meshCallEndedRejected => '거절됨';

  @override
  String get meshCallEndedNoAnswer => '응답 없음';

  @override
  String get meshCallEndedConnectionLost => '연결 끊김';

  @override
  String get meshCallEndedError => '연결 오류';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 메쉬 · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 메쉬';

  @override
  String get batteryExemptionTitle => '📡 신뢰할 수 있는 메쉬 통화';

  @override
  String get batteryExemptionBody =>
      '앱이 배터리 제한 없이 실행되도록 허용하여 Android가 백그라운드에서 메쉬를 종료하지 않도록 합니다.';

  @override
  String get batteryExemptionAccept => '설정 열기';

  @override
  String get batteryExemptionDismiss => '지금은 안 함';

  @override
  String get groupCamera => '카메라';

  @override
  String get groupGallery => '갤러리';

  @override
  String get groupAvatarUpdated => '그룹 아바타가 업데이트되었습니다';

  @override
  String get groupNameTitle => '그룹 이름';

  @override
  String get groupEnterName => '이름 입력';

  @override
  String get groupDescriptionTitle => '그룹 설명';

  @override
  String get groupEnterDescription => '그룹 설명 입력';

  @override
  String get groupChangeRoleTitle => '역할 변경';

  @override
  String get groupRemoveMemberTitle => '멤버 제거';

  @override
  String get groupDescription => '설명';

  @override
  String get groupAddDescription => '그룹 설명 추가';

  @override
  String get groupNoDescription => '설명 없음';

  @override
  String get groupMediaAndFiles => '미디어 및 파일';

  @override
  String get groupMuteNotifications => '알림 음소거';

  @override
  String get groupMuted => '음소거됨';

  @override
  String get groupNoResults => '결과 없음';

  @override
  String get authInvalidCode => '잘못된 코드입니다. 다시 시도하세요.';

  @override
  String get loginSubtitle => '이메일과 비밀번호 사용';

  @override
  String get emailRequired => '이메일 입력';

  @override
  String get emailInvalid => '잘못된 이메일';

  @override
  String get passwordRequired => '비밀번호 입력';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'Taler 생태계 전체를 위한 하나의 계정';

  @override
  String get usernameOptional => '사용자 이름 (선택 사항)';

  @override
  String get usernameMinLength => '최소 3자';

  @override
  String get usernameMaxLength => '최대 30자';

  @override
  String get usernameInvalid => '문자, 숫자 및 _만 사용 가능';

  @override
  String get biometricLoginReason => 'Taler ID에 로그인';

  @override
  String get docTypePassport => '여권';

  @override
  String get docTypeIdCard => '신분증';

  @override
  String get docTypeDriverLicense => '운전면허증';

  @override
  String get docTypeResidencePermit => '거주 허가증';

  @override
  String addressApartment(String number) {
    return '아파트 $number';
  }

  @override
  String get failedToUpdateProfile => '프로필 업데이트 실패';

  @override
  String get failedToStartKyb => 'KYB 인증 시작 실패';

  @override
  String get orgUpdated => '조직이 업데이트되었습니다';

  @override
  String get failedToUpdateOrg => '조직 업데이트 실패';

  @override
  String get failedToChangeRole => '역할 변경 실패';

  @override
  String get failedToRemoveMember => '멤버 제거 실패';

  @override
  String get capabilityMessagesTitle => '메시지';

  @override
  String get capabilityMessagesDesc =>
      '메시지를 확인하거나 누군가에게 작성하세요. 예: \"빅터에게 작성: 한 시간 후에 도착할 예정\"';

  @override
  String get capabilityCallsTitle => '통화';

  @override
  String get capabilityCallsDesc => '음성으로 연락처에 전화하세요. 예: \"빅터 빅토로프에게 전화\"';

  @override
  String get capabilityChatTitle => '채팅 기록';

  @override
  String get capabilityChatDesc => '채팅 기록을 분석합니다. 예: \"Viktor와 무엇을 논의했나요?\"';

  @override
  String get capabilityProfileTitle => '프로필';

  @override
  String get capabilityProfileDesc => '프로필을 보여주거나 업데이트합니다. 예: \"내 프로필 보여줘\"';

  @override
  String get capabilityCoachingTitle => '코칭';

  @override
  String get capabilityCoachingDesc =>
      '모드: ICF 코칭, 심리학자, HR 상담. 말하세요: \"코칭하자\"';

  @override
  String get capabilityCalendarTitle => '캘린더';

  @override
  String get capabilityCalendarDesc =>
      '회의를 예약하거나 알림을 설정합니다. 예: \"Viktor와 내일 15:00에 회의 예약\"';

  @override
  String get capabilityNotesTitle => '노트';

  @override
  String get capabilityNotesDesc =>
      '생각을 저장하거나 최근 노트를 읽습니다. 예: \"아이디어 적어줘...\" 또는 \"최근 노트 읽기\"';

  @override
  String get assistantCallConfirm => '통화하시겠습니까?';

  @override
  String get callNoAnswer => '응답 없음';

  @override
  String get contactDelete => '연락처 삭제';

  @override
  String get contactDeleteTitle => '연락처 삭제';

  @override
  String get contactDeleteConfirm => '확실합니까? 이 연락처가 삭제됩니다.';

  @override
  String get contactBlock => '차단';

  @override
  String get contactBlockTitle => '사용자 차단';

  @override
  String get contactBlockConfirm => '이 사용자는 메시지나 전화를 할 수 없습니다.';

  @override
  String get contactUnblock => '차단 해제';

  @override
  String get contactBlocked => '차단됨';

  @override
  String get contactYouAreBlocked => '이 사용자가 당신을 차단했습니다';

  @override
  String get chatBlockedByYou => '이 사용자를 차단했습니다';

  @override
  String get chatYouAreBlocked => '이 사용자에게 차단되었습니다';

  @override
  String get chatNotContacts => '메시지를 보내려면 이 사용자를 연락처에 추가하세요';

  @override
  String get contactRevokeRequest => '요청 취소';

  @override
  String get messengerPoll => '투표';

  @override
  String get messengerCreatePoll => '투표 생성';

  @override
  String get messengerPollQuestion => '질문';

  @override
  String messengerPollOption(int number) {
    return '옵션 $number';
  }

  @override
  String get messengerPollAddOption => '옵션 추가';

  @override
  String get messengerPollAnonymous => '익명 투표';

  @override
  String get messengerPollMultiple => '다중 선택';

  @override
  String get messengerPollCreateError => '투표 생성 실패';

  @override
  String get messengerPollUnavailable => '투표 불가';

  @override
  String get messengerPollMultipleNote => '여러 개 선택 가능';

  @override
  String messengerPollVotes(int count) {
    return '$count표';
  }

  @override
  String get messengerVideoMessage => '비디오 메시지';

  @override
  String get messengerVideoRecordError => '비디오 녹화 오류';

  @override
  String get messengerVideoPlaybackError => '비디오 재생 불가';

  @override
  String get messengerGalleryAccessError => '갤러리에 접근할 수 없음';

  @override
  String get messengerSearchInChat => '채팅에서 검색...';

  @override
  String get messengerSaveToFavorites => '즐겨찾기에 저장';

  @override
  String get messengerSavedToFavorites => '즐겨찾기에 저장됨';

  @override
  String get messengerSearchInMessages => '메시지에서 검색...';

  @override
  String messengerFoundInMessages(int count) {
    return '메시지에서 찾음 ($count)';
  }

  @override
  String get messengerGroupDefault => '그룹';

  @override
  String get messengerUserDefault => '사용자';

  @override
  String get messengerPin => '고정';

  @override
  String get messengerUnpin => '고정 해제';

  @override
  String get messengerArchive => '보관';

  @override
  String get messengerUnarchive => '보관 해제';

  @override
  String get messengerDeleteChat => '채팅 삭제';

  @override
  String get messengerDeleteChatTitle => '채팅 삭제?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return '$name와의 채팅을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get messengerCreateChannel => '채널 생성';

  @override
  String get messengerChannelName => '이름';

  @override
  String get messengerChannelDescription => '설명 (선택 사항)';

  @override
  String get messengerChannelCreateError => '채널 생성 실패';

  @override
  String get messengerFilterAll => '전체';

  @override
  String get messengerFilterUnread => '읽지 않음';

  @override
  String get messengerFilterPersonal => '개인';

  @override
  String get messengerFilterGroups => '그룹';

  @override
  String get messengerFilterChannels => '채널';

  @override
  String get messengerArchivedSection => '보관됨';

  @override
  String get messengerSavedSection => '즐겨찾기';

  @override
  String get messengerSavedSubtitle => '기억에 저장';

  @override
  String messengerArchiveTitle(int count) {
    return '보관 ($count)';
  }

  @override
  String get messengerArchiveEmpty => '보관함이 비어 있습니다';

  @override
  String messengerYouPrefix(String message) {
    return '당신: $message';
  }

  @override
  String get messengerMissedCall => '부재중 전화';

  @override
  String get messengerSavedTitle => '즐겨찾기';

  @override
  String get messengerNoSavedMessages => '저장된 메시지가 없습니다';

  @override
  String get messengerSavedHint => '메시지를 길게 누르세요 → \"즐겨찾기에 저장\"';

  @override
  String get messengerDefaultFile => '파일';

  @override
  String get messengerTopicDefault => '일반';

  @override
  String get messengerTopicNew => '새 주제';

  @override
  String get messengerTopicNameHint => '주제 이름';

  @override
  String get messengerTopicIcon => '아이콘';

  @override
  String messengerTopicCount(int count) {
    return '$count개의 주제';
  }

  @override
  String get messengerNoTopics => '주제가 없습니다';

  @override
  String get messengerNoMessages => '메시지가 없습니다';

  @override
  String get you => '당신';

  @override
  String get messengerThread => '스레드';

  @override
  String get messengerThreadReply => '답장';

  @override
  String get messengerThreadReplies => '답장들';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => '답장이 없습니다';

  @override
  String get messengerReplyHint => '스레드에 답장...';

  @override
  String get messengerContactName => '연락처 이름';

  @override
  String messengerOriginalName(String name) {
    return '원래 이름: $name';
  }

  @override
  String get messengerDisplayName => '표시 이름';

  @override
  String messengerShareContact(String name) {
    return 'Taler ID의 연락처: $name';
  }

  @override
  String get messengerAutoDelete => '메시지 자동 삭제';

  @override
  String get messengerAutoDeleteOff => '끔';

  @override
  String get messengerAutoDelete7d => '7일';

  @override
  String get messengerAutoDelete30d => '30일';

  @override
  String get messengerAutoDelete90d => '90일';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count 일';
  }

  @override
  String get messengerSettingsHeader => '설정';

  @override
  String get messengerAdminOnly => '관리자 전용 게시';

  @override
  String get messengerAdminOnlyDesc => '회원은 읽기만 가능';

  @override
  String get messengerTopics => '주제';

  @override
  String get messengerTopicsDesc => '채팅을 주제로 나누기';

  @override
  String get aiTwinSection => 'AI 음성 트윈';

  @override
  String get aiTwinEnabled => 'AI 트윈 활성화';

  @override
  String get aiTwinEnabledDesc => '당신이 응답하지 않으면, AI 트윈이 당신의 목소리로 전화를 받습니다';

  @override
  String get aiTwinTimeout => '응답 시간 초과';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds 초';
  }

  @override
  String get aiTwinPrompt => 'AI 지침';

  @override
  String get aiTwinPromptSubtitle => 'AI 트윈이 자신을 소개하고 이야기할 내용을 설정';

  @override
  String aiTwinPromptHint(String name) {
    return '안녕하세요, $name의 AI 음성 트윈입니다. $name이 지금 전화를 받을 수 없습니다. 누가 전화했는지와 용건을 말씀해 주시면 전달하겠습니다.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return '맞춤형 음성 복제가 곧 제공됩니다. 현재는 AI가 $name의 목소리로 말합니다.';
  }

  @override
  String get aiTwinDefaultName => '소유자';

  @override
  String get aiTwinPromptReset => '초기화';

  @override
  String get callHistoryAiTwinAnswered => 'AI 트윈이 응답함';

  @override
  String get callHistoryAiTwinSummary => '통화 요약';

  @override
  String get callHistoryAiTwinTranscript => '전사';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return '$name로부터';
  }

  @override
  String get aiTwinOfferTitle => '응답하지 않음';

  @override
  String aiTwinOfferBody(String name) {
    return '$name이(가) 전화를 받지 않습니다. AI 음성 트윈에게 메시지를 남기시겠습니까?';
  }

  @override
  String get aiTwinOfferBodyUser => '사용자';

  @override
  String get aiTwinOfferAccept => '네, 메시지 남기기';

  @override
  String get aiTwinOfferKeepWaiting => '계속 기다리기';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => '당신의 AI 대리인';

  @override
  String get aiTwinHeroSubtitle => '전화를 받을 수 없을 때 당신의 목소리로 응답합니다.';

  @override
  String get aiTwinProfileTitle => 'AI 대리인';

  @override
  String get aiTwinProfileDesc => '당신의 목소리로 전화를 응답합니다';

  @override
  String get aiTwinBadgeOn => '켜짐';

  @override
  String get aiAnalystTitle => 'AI 분석가';

  @override
  String get aiAnalystSubtitle => '파일, 작업, 분석 — Claude';

  @override
  String get channelsDiscover => '채널 찾기';

  @override
  String get channelsSearchHint => '채널 검색';

  @override
  String get channelsSubscribers => '구독자';

  @override
  String get channelsSubscribe => '구독';

  @override
  String get channelsUnsubscribe => '구독 취소';

  @override
  String get channelsSubscribedLabel => '구독 중입니다';

  @override
  String get channelsSettings => '채널 설정';

  @override
  String get channelsDelete => '채널 삭제';

  @override
  String get channelsDeleteConfirm => '채널을 영구적으로 삭제하시겠습니까?';

  @override
  String get channelsEmpty => '아직 채널이 없습니다';

  @override
  String get channelsOpen => '열기';

  @override
  String get channelsNameLabel => '이름';

  @override
  String get channelsDescriptionLabel => '설명';

  @override
  String get channelsCannotUnsubscribeOwner =>
      '소유자는 구독 취소할 수 없습니다. 대신 채널을 삭제하세요.';

  @override
  String get channelsNotFoundRedirect => '채널이 더 이상 존재하지 않습니다';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 검색',
      one: '$count 검색',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 파일',
      one: '$count 파일',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 명령',
      one: '$count 명령',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 이미지',
      one: '$count 이미지',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 단계',
      one: '$count 단계',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '$seconds초';
  }

  @override
  String get savedTitle => '저장된 메시지';

  @override
  String get savedSubtitle => '당신의 개인 클라우드';

  @override
  String get savedOpenError => '저장된 메시지를 열 수 없습니다';

  @override
  String get billingWalletTitle => '지갑';

  @override
  String get billingBuyPackage => '패키지 구매';

  @override
  String get billingCurrentBalance => '현재 잔액';

  @override
  String get billingPackagesTitle => '패키지';

  @override
  String get billingPackagesUnavailable => '패키지를 사용할 수 없음';

  @override
  String get billingRecentOperations => '최근 작업';

  @override
  String get billingAllOperations => '모든 작업';

  @override
  String get billingNoOperations => '작업 없음';

  @override
  String get billingOperationsTitle => '작업';

  @override
  String get billingOperationsEmptyTitle => '아직 작업 없음';

  @override
  String get billingOperationsEmptySubtitle => 'AI 기능의 충전 및 요금이 여기에 표시됩니다';

  @override
  String get billingPricebookTitle => '기능 가격';

  @override
  String get billingPricebookUnavailable => '가격 목록을 사용할 수 없음';

  @override
  String get billingAiFeaturesTitle => 'AI 기능';

  @override
  String get billingInsufficientFundsTitle => '잔액 부족';

  @override
  String get billingInsufficientFundsSubtitle => '이 기능을 사용하려면 잔액을 충전하세요.';

  @override
  String billingRequiredLine(String required) {
    return '필요: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return '보유: $available μTAL';
  }

  @override
  String get billingTopUp => '충전';

  @override
  String get billingCancel => '취소';

  @override
  String get billingRetry => '재시도';

  @override
  String billingLowBalanceWarning(String balance) {
    return '잔액 부족: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => '지갑 및 잔액';

  @override
  String get billingSectionHeader => '청구 및 AI';

  @override
  String get billingFeatureVoiceAssistant => '음성 비서';

  @override
  String get billingFeatureWebSearch => '비서 웹 검색';

  @override
  String get billingFeatureAiTwin => '음성 트윈';

  @override
  String get billingFeatureAiTwinLong => '음성 트윈 (AI Twin)';

  @override
  String get billingFeatureOutboundCall => '아웃바운드 봇';

  @override
  String get billingFeatureOutboundCallLong => '아웃바운드 통화 봇';

  @override
  String get billingFeatureWhisperTranscribe => '통화 전사';

  @override
  String get billingFeatureMeetingSummary => 'AI 통화 요약';

  @override
  String get billingConfigureAiTwin => 'AI 트윈 구성';

  @override
  String get billingWebSearchSubtitle => '(비서가 사용함)';

  @override
  String billingPackagePurchased(String balance) {
    return '패키지 구매 완료: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => '추천';

  @override
  String get billingSessionTerminatedNoFunds => '잔액 소진 — 세션 종료';

  @override
  String get billingSessionTerminatedGeneric => '비서 세션 종료';

  @override
  String billingBuyForPrice(String price) {
    return '구매 가격: €$price';
  }

  @override
  String get billingTxTypeTopup => '충전';

  @override
  String get billingTxTypeRefund => '환불';

  @override
  String get billingTxTypeSpend => '요금';

  @override
  String get billingUnitMinute => '분';

  @override
  String get billingUnitRequest => '요청';

  @override
  String get billingUnitToken => '토큰';

  @override
  String get billingUnitTokens1k => '1K 토큰';

  @override
  String get billingUnitCall => '통화';

  @override
  String get groupCallSelectParticipants => '참가자 선택';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => '검색';

  @override
  String get groupCallMaxReached => '최대 7명 참가자';

  @override
  String get groupCallLobbyTitle => '그룹 • 로비';

  @override
  String groupCallHostLabel(String name) {
    return '호스트: $name';
  }

  @override
  String get groupCallMicHint => '연결 시 마이크가 활성화됩니다';

  @override
  String get groupCallCancel => '취소';

  @override
  String get groupCallNoAnswer => '응답 없음';

  @override
  String get groupCallEndedByHost => '호스트가 통화를 종료했습니다';

  @override
  String get groupCallAllLeft => '모두 통화를 떠났습니다';

  @override
  String get groupCallEnded => '통화 종료';

  @override
  String groupCallActiveTitle(int count) {
    return '그룹 • $count';
  }

  @override
  String get groupCallConnectionLost => '연결 끊김';

  @override
  String get groupCallMuteRequested => '호스트가 모두 음소거를 요청했습니다';

  @override
  String get groupCallUnmute => '음소거 해제';

  @override
  String get groupCallMute => '음소거';

  @override
  String get groupCallMuteAll => '모두 음소거';

  @override
  String get groupCallLeave => '떠나기';

  @override
  String get groupCallStatusCalling => '통화 중…';

  @override
  String get groupCallStatusDeclined => '거절됨';

  @override
  String get groupCallStatusTimeout => '응답 없음';

  @override
  String get groupCallStatusLeft => '떠남';

  @override
  String groupCallKickConfirm(String name) {
    return '$name을(를) 통화에서 제거';
  }

  @override
  String get groupCallCancelAction => '취소';

  @override
  String get groupCallActiveBanner => '활성 통화';

  @override
  String groupCallBannerSummary(String host, int count) {
    return '그룹: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return '그룹: $host';
  }

  @override
  String get groupCallCreateError => '통화를 생성할 수 없습니다';

  @override
  String get groupCallJoinError => '통화에 참여할 수 없습니다';

  @override
  String get groupCallLivekitError => 'LiveKit 오류';

  @override
  String get groupCallDone => '완료';

  @override
  String get groupCallNoResults => '결과 없음';

  @override
  String get groupCallNoContacts => '연락처 없음';

  @override
  String get meshGcContactOffline => '이 Wi-Fi에 없음';

  @override
  String get meshGcOnlineViaMesh => '메시를 통해 온라인';

  @override
  String get meshGcMaxInvitees => '그룹 통화는 최대 4명의 초대자를 지원합니다 (총 5명).';

  @override
  String get meshGcStart => '그룹 통화 시작';

  @override
  String get meshGcCancel => '취소';

  @override
  String get meshGcStatusCalling => '통화 중…';

  @override
  String get meshGcStatusJoined => '참여함';

  @override
  String get meshGcStatusDeclined => '거절됨';

  @override
  String get meshGcStatusNoAnswer => '응답 없음';

  @override
  String get meshGcStatusConnectionFailed => '연결 실패';

  @override
  String get meshGcStatusLeft => '떠남';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne => '현재 통화를 먼저 종료하세요.';

  @override
  String get presenceOnline => '온라인';

  @override
  String get presenceLastSeenJustNow => '방금 전 마지막으로 본 시간';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return '$minutes분 전 마지막으로 본 시간';
  }

  @override
  String presenceLastSeenToday(String time) {
    return '오늘 $time에 마지막으로 본 시간';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return '어제 $time에 마지막으로 본 시간';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return '$date에 마지막으로 본 시간';
  }

  @override
  String get presenceLastSeenRecently => '최근에 마지막으로 본 시간';

  @override
  String get privacySectionTitle => '개인정보';

  @override
  String get privacyLastSeenLabel => '누가 당신의 마지막 본 시간을 볼 수 있습니까';

  @override
  String get privacyEveryone => '모두';

  @override
  String get privacyContacts => '연락처만';

  @override
  String get privacyNobody => '아무도';
}
