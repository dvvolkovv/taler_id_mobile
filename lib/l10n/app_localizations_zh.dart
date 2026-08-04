// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => '搜索';

  @override
  String get appSubtitle => '统一生态系统身份';

  @override
  String get login => '登录';

  @override
  String get loginButton => '登录';

  @override
  String get register => '创建账户';

  @override
  String get registerButton => '创建账户';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get firstName => '名字';

  @override
  String get lastName => '姓氏';

  @override
  String get noAccount => '没有账户？';

  @override
  String get createOne => '创建一个';

  @override
  String get haveAccount => '已有账户？';

  @override
  String get signIn => '登录';

  @override
  String get passwordMinLength => '至少8个字符';

  @override
  String get invalidEmail => '请输入有效的邮箱';

  @override
  String get fieldRequired => '必填字段';

  @override
  String get twoFATitle => '双因素认证';

  @override
  String get twoFASubtitle => '输入来自验证器应用的6位数代码';

  @override
  String get twoFACode => '2FA代码';

  @override
  String get verify => '验证';

  @override
  String get tabProfile => '个人资料';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => '组织';

  @override
  String get tabSettings => '设置';

  @override
  String get profile => '个人资料';

  @override
  String get editProfile => '编辑个人资料';

  @override
  String get phone => '电话';

  @override
  String get country => '国家';

  @override
  String get dateOfBirth => '出生日期';

  @override
  String get documents => '文件';

  @override
  String get addDocument => '添加文件';

  @override
  String get noDocuments => '未上传文件';

  @override
  String get save => '保存';

  @override
  String get profileUpdated => '个人资料已更新';

  @override
  String get personalData => '个人数据';

  @override
  String get passport => '护照';

  @override
  String get drivingLicense => '驾驶执照';

  @override
  String get diploma => '文凭';

  @override
  String get nationalId => '国家身份证';

  @override
  String get certificate => '证书';

  @override
  String get notSpecified => '未指定';

  @override
  String get notSpecifiedFemale => '未指定';

  @override
  String get documentType => '文件类型';

  @override
  String get passportId => '护照 / 身份证';

  @override
  String get diplomaCertificate => '文凭 / 证书';

  @override
  String get loadError => '加载错误';

  @override
  String get verification => '验证';

  @override
  String get countryAustria => '奥地利';

  @override
  String get countryGermany => '德国';

  @override
  String get countryRussia => '俄罗斯';

  @override
  String get countryUkraine => '乌克兰';

  @override
  String get countryKazakhstan => '哈萨克斯坦';

  @override
  String get countryBelarus => '白俄罗斯';

  @override
  String get countryOther => '其他';

  @override
  String get kycTitle => 'KYC 验证';

  @override
  String get kycVerified => '已验证';

  @override
  String get kycPending => '待处理';

  @override
  String get kycRejected => '已拒绝';

  @override
  String get kycUnverified => '未验证';

  @override
  String get kycVerifiedDesc => '您的身份已验证。您可以完全访问 Taler 生态系统的所有功能。';

  @override
  String get kycPendingDesc => '您的文件正在审核中。通常需要 1-2 个工作日。';

  @override
  String get kycRejectedDesc => '验证失败。请查看原因并重新提交您的文件。';

  @override
  String get kycUnverifiedDesc => '完成验证以解锁 Taler 生态系统的全部金融功能。';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get kycInProgress => 'In progress';

  @override
  String get kycInProgressDesc =>
      'You started verification but didn\'t finish it. Pick up right where you left off.';

  @override
  String get startVerification => '开始验证';

  @override
  String get retryVerification => '重试验证';

  @override
  String verifiedAt(String date) {
    return '验证时间：$date';
  }

  @override
  String get documentsSubmitted => '文件已提交审核';

  @override
  String get documentsSubmittedDesc => '审核通常需要 1-2 个工作日。您将收到结果的推送通知。';

  @override
  String get securityAes => '您的数据通过 AES-256 加密保护';

  @override
  String get verificationTime => '验证需要 1-2 个工作日';

  @override
  String get pushNotification => '您将收到结果的推送通知';

  @override
  String get kycWebOnly => 'KYC 验证仅在移动应用中可用。';

  @override
  String verificationError(String code) {
    return '验证错误：$code';
  }

  @override
  String get organizations => '组织';

  @override
  String get noOrganizations => '没有组织';

  @override
  String get noOrganizationsDesc => '创建一个组织或接受邀请';

  @override
  String get createOrganization => '创建组织';

  @override
  String get newOrganization => '新组织';

  @override
  String get orgName => '名称 *';

  @override
  String get orgDescription => '描述';

  @override
  String get orgEmail => '联系邮箱';

  @override
  String get orgWebsite => '网站';

  @override
  String get orgLegalAddress => '法律地址';

  @override
  String get create => '创建';

  @override
  String get organization => '组织';

  @override
  String get contacts => '联系人';

  @override
  String members(int count) {
    return '成员 ($count)';
  }

  @override
  String get inviteMember => '邀请成员';

  @override
  String get invite => '邀请';

  @override
  String get sendInvite => '发送邀请';

  @override
  String inviteSent(String email) {
    return '邀请已发送至 $email';
  }

  @override
  String get role => '角色';

  @override
  String get roleOwner => '所有者';

  @override
  String get roleAdmin => '管理员';

  @override
  String get roleOperator => '操作员';

  @override
  String get roleViewer => '查看者';

  @override
  String get editOrganization => '编辑';

  @override
  String get editOrganizationTitle => '编辑组织';

  @override
  String get removeMember => '移除成员';

  @override
  String removeMemberConfirm(String name) {
    return '从组织中移除 $name?';
  }

  @override
  String get memberRemoved => '成员已移除';

  @override
  String get roleChanged => '角色已更改';

  @override
  String get kybVerified => '已验证';

  @override
  String get kybPending => '待处理';

  @override
  String get kybRejected => '已拒绝';

  @override
  String get kybNone => '未验证';

  @override
  String get kybVerification => '开始 KYB 验证';

  @override
  String get kybStartBusiness => '开始业务验证';

  @override
  String get kybStatusLabel => 'KYB 状态';

  @override
  String get noKyb => '无 KYB';

  @override
  String get kybBusinessVerificationTitle => '业务验证 (KYB)';

  @override
  String get kybVerifiedOrgDesc => '组织验证成功。';

  @override
  String get kybPendingOrgDesc => '文件正在审核中。通常需要 1-3 个工作日。';

  @override
  String get kybRejectedOrgDesc => '验证失败。请重试。';

  @override
  String get kybNoneOrgDesc => '验证您的组织以访问业务功能。';

  @override
  String get invitePlus => '+ 邀请';

  @override
  String get kybVerificationTitle => 'KYB 验证';

  @override
  String get kybWebOnlyBusiness => 'KYB验证仅在移动应用中可用。';

  @override
  String get unknownDevice => '未知设备';

  @override
  String get ipUnknown => 'IP未知';

  @override
  String get currentSessionLabel => '当前';

  @override
  String get endSessionAction => '结束';

  @override
  String get deviceLoggedOut => '设备将被登出。';

  @override
  String get acceptInvitationTitle => '组织邀请';

  @override
  String get acceptInvitation => '接受邀请';

  @override
  String get acceptInvitationDesc => '您已被邀请加入Taler生态系统中的一个组织。';

  @override
  String get accept => '接受';

  @override
  String get reject => '拒绝';

  @override
  String get sessions => '活动会话';

  @override
  String get currentSession => '当前会话';

  @override
  String get deleteSession => '结束会话';

  @override
  String get deleteSessionConfirm => '结束此会话？';

  @override
  String get sessionDeleted => '会话已结束';

  @override
  String get noSessions => '没有活动会话';

  @override
  String minutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String get justNow => '刚刚';

  @override
  String get settings => '设置';

  @override
  String get security => '安全';

  @override
  String get biometrics => '生物识别';

  @override
  String get biometricsDesc => '使用Face ID或指纹快速登录';

  @override
  String get biometricsConfirm => '确认生物识别以启用快速登录';

  @override
  String get biometricsError => '启用生物识别失败。检查设备设置。';

  @override
  String get changePassword => '更改密码';

  @override
  String get twoFactorAuth => '双因素认证';

  @override
  String get currentPassword => '当前密码';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmNewPassword => '确认新密码';

  @override
  String get passwordChanged => '密码已更改';

  @override
  String get wrongCurrentPassword => '当前密码错误';

  @override
  String get passwordTooWeak => '密码太弱：至少8个字符，需包含字母和数字';

  @override
  String get passwordChangeFailed => '更改密码失败';

  @override
  String get notifications => '通知';

  @override
  String get permissions => '权限';

  @override
  String get permissionNotifications => '推送通知';

  @override
  String get permissionNotificationsDesc => '通话、消息、状态';

  @override
  String get permissionMicrophone => '麦克风';

  @override
  String get permissionMicrophoneDesc => '通话和语音助手';

  @override
  String get permissionCamera => '相机';

  @override
  String get permissionCameraDesc => '视频通话和验证';

  @override
  String get permissionLocation => '位置';

  @override
  String get permissionLocationDesc => '用于验证';

  @override
  String get permissionOpenSettings => '要撤销权限，请打开系统设置';

  @override
  String get pushKycStatus => 'KYC 状态推送';

  @override
  String get pushKycStatusDesc => '验证结果';

  @override
  String get pushLogins => '登录推送';

  @override
  String get pushLoginsDesc => '从新设备登录时';

  @override
  String get account => '账户';

  @override
  String get language => '语言';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => '界面语言';

  @override
  String get exportData => '导出数据 (GDPR)';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get deleteAccountConfirm => '删除账户？';

  @override
  String get deleteAccountDesc => '您的所有数据将被删除 (GDPR)。此操作不可逆。';

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirm => '退出登录？';

  @override
  String get logoutDesc => '您将在此设备上退出 Taler ID。';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'PIN 码';

  @override
  String get pinCodeDesc => '使用4位数代码快速登录';

  @override
  String get setupPin => '设置 PIN';

  @override
  String get enterPin => '输入 PIN';

  @override
  String get confirmPin => '确认 PIN';

  @override
  String get pinMismatch => 'PIN 不匹配';

  @override
  String get passwordMismatch => '密码不匹配';

  @override
  String get pinSet => 'PIN 设置成功';

  @override
  String get enterPinToLogin => '输入 PIN 以登录';

  @override
  String get pinIncorrect => 'PIN 错误';

  @override
  String get removePin => '移除 PIN';

  @override
  String get pinRemoved => 'PIN 已移除';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get ok => '确定';

  @override
  String get retry => '重试';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get success => '成功';

  @override
  String get noData => '无数据';

  @override
  String get failedToLoad => '加载数据失败';

  @override
  String get failedToLoadProfile => '加载个人资料失败';

  @override
  String get failedToSave => '保存更改失败';

  @override
  String get failedToLoadOrgs => '加载组织失败';

  @override
  String get failedToLoadOrg => '加载组织数据失败';

  @override
  String get failedToCreateOrg => '创建组织失败';

  @override
  String get failedToInvite => '发送邀请失败';

  @override
  String get failedToAcceptInvite => '接受邀请失败';

  @override
  String get failedToLoadSessions => '加载会话失败';

  @override
  String get failedToDeleteSession => '结束会话失败';

  @override
  String get failedToLoadKyc => '加载验证状态失败';

  @override
  String get failedToStartKyc => '开始验证失败';

  @override
  String get verifiedPersonalInfo => '已验证数据';

  @override
  String get middleName => '中间名';

  @override
  String get placeOfBirth => '出生地';

  @override
  String get nationality => '国籍';

  @override
  String get gender => '性别';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get docNumber => '编号';

  @override
  String get docIssuedDate => '签发日期';

  @override
  String get docValidUntil => '有效期至';

  @override
  String get docIssuedBy => '签发机构';

  @override
  String get address => '地址';

  @override
  String get refreshData => '刷新数据';

  @override
  String get failedToLoadSumsubData => '加载验证数据失败';

  @override
  String get sumsubDataLoading => '正在加载验证数据...';

  @override
  String get reviewResultGreen => '验证通过';

  @override
  String get reviewResultRed => '验证失败';

  @override
  String get tabAssistant => '助手';

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
  String get assistantConnecting => '正在连接…';

  @override
  String get assistantSpeaking => '正在说话…';

  @override
  String get assistantListening => '正在聆听…';

  @override
  String get assistantTapToStart => '点击开始';

  @override
  String get assistantTapToTalk => '点击与AI对话';

  @override
  String get assistantRealtimeDesc => '助手实时语音响应';

  @override
  String get assistantConnectingToAssistant => '正在连接助手...';

  @override
  String get assistantAiSpeaking => 'AI 说话中...';

  @override
  String get assistantAiListening => 'AI 听中';

  @override
  String get assistantSpeakerOn => '扬声器开';

  @override
  String get assistantSpeaker => '扬声器';

  @override
  String get assistantEnd => '结束';

  @override
  String get assistantUnmute => '取消静音';

  @override
  String get assistantMicrophone => '麦克风';

  @override
  String get assistantConnectionError => '连接错误';

  @override
  String get tabMessenger => '消息';

  @override
  String get tabCalls => '通话';

  @override
  String get tabCalendar => '日历';

  @override
  String get appearance => '外观';

  @override
  String get appearanceSelect => '选择主题';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '系统';

  @override
  String get onboardingTitle1 => '统一身份';

  @override
  String get onboardingDesc1 => 'Taler ID 是您在 Taler 生态系统中的数字护照。一个账户，所有服务。';

  @override
  String get onboardingTitle2 => '数据安全';

  @override
  String get onboardingDesc2 => 'KYC 验证、AES-256 加密和双因素认证保护您的身份。';

  @override
  String get onboardingTitle3 => '保持知情';

  @override
  String get onboardingDesc3 => '获取关于验证状态、新设备登录和来电的通知。';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingEnableNotifications => '启用通知';

  @override
  String get onboardingTitle4 => '语音通话';

  @override
  String get onboardingDesc4 => '授予麦克风访问权限以进行语音通话和 AI 助手。您可以稍后在设置中更改此项。';

  @override
  String get onboardingEnableMicrophone => '启用麦克风';

  @override
  String get onboardingStart => '开始使用';

  @override
  String get onboardingSkip => '跳过';

  @override
  String get meshLocalNetworkPromptTitle => '允许本地网络访问';

  @override
  String get meshLocalNetworkPromptBody =>
      '要在 Wi-Fi 上找到对等设备（离线群组通话），iOS 需要本地网络权限。打开设置 → 隐私与安全 → 本地网络 → Taler ID。';

  @override
  String get meshLocalNetworkPromptOpenSettings => '打开设置';

  @override
  String get meshLocalNetworkPromptDismiss => '知道了';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get forgotPasswordTitle => '重置密码';

  @override
  String get forgotPasswordSubtitle => '输入您的电子邮件以接收重置代码';

  @override
  String resetCodeSent(String email) {
    return '代码已发送至 $email';
  }

  @override
  String get enterResetCode => '输入代码';

  @override
  String get resetPasswordButton => '重置密码';

  @override
  String get passwordResetSuccess => '密码重置成功';

  @override
  String get sendCode => '发送验证码';

  @override
  String get resendCode => '重新发送验证码';

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
  String get newGroup => '新建群组';

  @override
  String get newChat => '新建聊天';

  @override
  String get groupName => '群组名称';

  @override
  String get createGroup => '创建群组';

  @override
  String get groupInfo => '群组信息';

  @override
  String groupMembers(int count) {
    return '成员 ($count)';
  }

  @override
  String get addMembers => '添加成员';

  @override
  String get leaveGroup => '退出群组';

  @override
  String get leaveGroupConfirm => '确定退出该群组？';

  @override
  String get deleteGroup => '删除群组';

  @override
  String get deleteGroupConfirm => '确定删除该群组？此操作无法撤销。';

  @override
  String get groupRoleOwner => '所有者';

  @override
  String get groupRoleAdmin => '管理员';

  @override
  String get groupRoleMember => '成员';

  @override
  String get selectParticipants => '选择参与者';

  @override
  String selectedCount(int count) {
    return '已选择 $count 个';
  }

  @override
  String get changeRole => '更改角色';

  @override
  String get groupCreated => '群组已创建';

  @override
  String memberJoined(String name) {
    return '$name 加入了群组';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name 退出了群组';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name 被移除';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name 现在是 $role';
  }

  @override
  String participantsCount(int count) {
    return '$count 位参与者';
  }

  @override
  String get enterGroupName => '输入群组名称';

  @override
  String get muteNotifications => '静音通知';

  @override
  String get unmuteNotifications => '取消静音通知';

  @override
  String get muteFor1Hour => '静音 1 小时';

  @override
  String get muteFor8Hours => '静音 8 小时';

  @override
  String get muteFor2Days => '静音 2 天';

  @override
  String get muteForever => '永久静音';

  @override
  String get muted => '已静音';

  @override
  String get tabTranslator => '翻译';

  @override
  String get translatorTitle => '翻译器';

  @override
  String get translatorSelectLanguage => '选择语言';

  @override
  String get translatorDownloading => '正在下载语言模型...';

  @override
  String get translatorDownloadingHint => '首次下载需要网络连接';

  @override
  String get translatorTypeHint => '输入文本或点击麦克风';

  @override
  String get translatorListening => '正在聆听...';

  @override
  String get translatorTapToSpeak => '点击说话';

  @override
  String get translatorTapToStop => '点击停止';

  @override
  String get translatorAutoSpeak => '自动说话';

  @override
  String get translatorCopied => '已复制';

  @override
  String get translatorLangRu => '俄语';

  @override
  String get translatorLangEn => '英语';

  @override
  String get translatorLangDe => '德语';

  @override
  String get translatorLangFr => '法语';

  @override
  String get translatorLangEs => '西班牙语';

  @override
  String get translatorLangIt => '意大利语';

  @override
  String get translatorLangPt => '葡萄牙语';

  @override
  String get translatorLangTr => '土耳其语';

  @override
  String get translatorLangZh => '中文';

  @override
  String get translatorLangJa => '日语';

  @override
  String get translatorLangKo => '韩语';

  @override
  String get translatorLangAr => '阿拉伯语';

  @override
  String get translatorLangPl => '波兰语';

  @override
  String get translatorLangSk => '斯洛伐克语';

  @override
  String get translatorLangCs => '捷克语';

  @override
  String get translatorLangNl => '荷兰语';

  @override
  String get translatorLangSv => '瑞典语';

  @override
  String get translatorLangDa => '丹麦语';

  @override
  String get translatorLangNo => '挪威语';

  @override
  String get translatorLangFi => '芬兰语';

  @override
  String get translatorLangUk => '乌克兰语';

  @override
  String get translatorLangEl => '希腊语';

  @override
  String get translatorLangRo => '罗马尼亚语';

  @override
  String get translatorLangHu => '匈牙利语';

  @override
  String get translatorLangBg => '保加利亚语';

  @override
  String get translatorLangHr => '克罗地亚语';

  @override
  String get translatorLangSr => '塞尔维亚语';

  @override
  String get translatorLangHi => '印地语';

  @override
  String get translatorLangTh => '泰语';

  @override
  String get translatorLangVi => '越南语';

  @override
  String get translatorLangId => '印度尼西亚语';

  @override
  String get translatorLangMs => '马来语';

  @override
  String get translatorLangHe => '希伯来语';

  @override
  String get translatorLangFa => '波斯语';

  @override
  String get callInProgress => '通话进行中';

  @override
  String get joinCall => '加入';

  @override
  String get createCallLink => '通话链接';

  @override
  String get callLinkCopied => '链接已复制';

  @override
  String get callLinkTitle => '房间链接';

  @override
  String get connectionUnstable => '连接不稳定 — 检查您的网络';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get errorTimeout => '连接超时。检查您的网络连接。';

  @override
  String get errorNoConnection => '没有网络连接。';

  @override
  String get errorGeneral => '发生错误。请重试。';

  @override
  String errorWithMessage(String message) {
    return '错误：$message';
  }

  @override
  String get notifChannelMessages => '消息';

  @override
  String get notifChannelMessagesDesc => '新消息通知';

  @override
  String get notifChannelMissedCalls => '未接来电';

  @override
  String get notifChannelMissedCallsDesc => '未接来电通知';

  @override
  String get notifMissedCall => '未接来电';

  @override
  String get notifAccept => '接受';

  @override
  String get notifDecline => '拒绝';

  @override
  String get notifIncomingCall => '来电';

  @override
  String get notifIncomingCallChannel => '来电';

  @override
  String get notifMissedCallChannel => '未接来电';

  @override
  String get notifUnknown => '未知';

  @override
  String get effectNone => '无背景';

  @override
  String get effectBlur => '模糊';

  @override
  String get effectOffice => '办公室';

  @override
  String get effectNature => '自然';

  @override
  String get effectGradient => '渐变';

  @override
  String get effectLibrary => '图书馆';

  @override
  String get effectCity => '城市';

  @override
  String get effectMinimalism => '极简主义';

  @override
  String get voiceParticipant => '参与者';

  @override
  String get voiceInvitesToRoom => '邀请您进入房间';

  @override
  String get voiceRoom => '房间';

  @override
  String get voicePasswordProtected => '密码保护';

  @override
  String get voicePasswordHint => '密码';

  @override
  String get voiceEnter => '进入';

  @override
  String get voiceJoinRoom => '加入房间';

  @override
  String get voiceYourName => '您的名字';

  @override
  String voiceInvitationSent(String name) {
    return '邀请已发送给$name';
  }

  @override
  String get voiceNoActiveRoom => '没有活跃的房间';

  @override
  String get voiceCameraPermission => '在设置中允许相机访问 → 隐私 → 相机 → TalerID';

  @override
  String get voiceOpenSettings => '打开';

  @override
  String voiceCameraError(String error) {
    return '启用相机失败：$error';
  }

  @override
  String get voiceAllAgreedRecording => '全部同意。录音已开始。';

  @override
  String get voiceNewParticipantAgreed => '新参与者同意录音。';

  @override
  String get voiceDeclinedRecording => '您拒绝了录音。正在离开通话。';

  @override
  String get voiceRecordingEnded => '录音结束';

  @override
  String get voiceRecordingInProgress => '录音进行中';

  @override
  String get voiceTranscriptionRequest => '转录请求';

  @override
  String get voiceRecordingRequest => '录音请求';

  @override
  String get voiceAgree => '同意';

  @override
  String get voiceDeclineAndLeave => '拒绝并离开';

  @override
  String get voiceAudioOutput => '音频输出';

  @override
  String get voiceAudioPhone => '手机';

  @override
  String get voiceAudioSpeaker => '扬声器';

  @override
  String get voiceAudioBluetooth => '蓝牙';

  @override
  String get voiceAudioHeadphones => '耳机';

  @override
  String get voiceLinkCopied => '链接已复制';

  @override
  String get voiceTranslateTo => '翻译为';

  @override
  String get voiceSearchLanguage => '搜索语言...';

  @override
  String voiceRoomWithCreator(String name) {
    return '房间 $name';
  }

  @override
  String get voiceVoiceCall => '语音通话';

  @override
  String get voiceOnHold => '保持';

  @override
  String get voiceActiveCall => '通话中';

  @override
  String get voiceEndAllCalls => '结束所有通话';

  @override
  String get voiceEndThisCall => '结束此通话';

  @override
  String get voiceCopyLink => '复制链接';

  @override
  String get voiceAddParticipant => '添加参与者';

  @override
  String get voiceReconnecting => '重新连接中...';

  @override
  String get voiceConnectionError => '连接错误';

  @override
  String get voiceClose => '关闭';

  @override
  String get voiceCalling => '正在呼叫...';

  @override
  String get voiceCallActive => '通话激活';

  @override
  String get voiceWaiting => '等待中';

  @override
  String get voiceWaitingUpper => '等待中';

  @override
  String get voiceRec => '录音';

  @override
  String get voiceStop => '停止';

  @override
  String get voiceRecord => '录音';

  @override
  String get voiceTranslation => '翻译';

  @override
  String get voiceAudio => '音频';

  @override
  String get voiceFlipCamera => '翻转';

  @override
  String get voiceBackground => '背景';

  @override
  String get voiceAssistantSpeakingStatus => '助手正在说话...';

  @override
  String get voiceAssistantListeningStatus => '助手正在聆听...';

  @override
  String get voiceUnmute => '取消静音';

  @override
  String get voiceMic => '麦克风';

  @override
  String get voiceAssistantLabel => '助手';

  @override
  String get voiceCameraOn => '摄像头开启';

  @override
  String get voiceCameraLabel => '摄像头';

  @override
  String get voiceEndCall => '结束通话';

  @override
  String get voiceWaitingParticipants => '等待参与者...';

  @override
  String get voiceYou => '你';

  @override
  String get voiceAiAssistant => 'AI助手';

  @override
  String get voiceVideoUnavailable => '视频不可用';

  @override
  String get voiceSearchNickname => '按昵称搜索...';

  @override
  String get voiceTranscriptionWord => '转录';

  @override
  String get voiceRecordingWord => '录音';

  @override
  String get voiceConnecting => '连接中...';

  @override
  String get voiceVideoBackground => '视频背景';

  @override
  String get voiceCallSettings => '通话设置';

  @override
  String get voiceEnableAI => '启用AI助手';

  @override
  String get voiceAIParticipating => 'AI将参与对话';

  @override
  String get voiceNormalCall => '普通通话，无AI';

  @override
  String get voiceCallConfirm => '拨打电话？';

  @override
  String get chatAlreadyInCall => '已在通话中';

  @override
  String chatCallError(String error) {
    return '通话错误：$error';
  }

  @override
  String get chatPhotoVideo => '照片 / 视频';

  @override
  String get chatCamera => '摄像头';

  @override
  String get chatFile => '文件';

  @override
  String get chatContact => '联系人';

  @override
  String get chatSelectContact => '选择联系人';

  @override
  String get chatNoContacts => '没有联系人';

  @override
  String get chatUser => '用户';

  @override
  String get chatFileAttachment => '📎 文件';

  @override
  String chatFileUploadError(String error) {
    return '文件上传错误：$error';
  }

  @override
  String get chatVoiceMessage => '🎤 语音消息';

  @override
  String get chatGroup => '群组';

  @override
  String get chatDialog => '对话';

  @override
  String get chatCall => '通话';

  @override
  String get chatStartConversation => '开始对话';

  @override
  String get chatYou => '你';

  @override
  String get chatIsTyping => '正在输入...';

  @override
  String chatUserIsTyping(String name) {
    return '$name 正在输入...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names 正在输入...';
  }

  @override
  String get chatPreparingFile => '准备文件...';

  @override
  String chatUploading(int progress) {
    return '上传中... $progress%';
  }

  @override
  String get chatEdited => '已编辑';

  @override
  String get chatViaMesh => '通过网状网络';

  @override
  String get chatReply => '回复';

  @override
  String get chatEdit => '编辑';

  @override
  String get chatCopy => '复制';

  @override
  String get chatCopied => '已复制';

  @override
  String get chatSaveMedia => '保存';

  @override
  String get chatForward => '转发';

  @override
  String get chatSaving => '保存中...';

  @override
  String get chatSavedToGallery => '已保存到图库';

  @override
  String get chatNoSavePermission => '没有保存权限。请检查设置。';

  @override
  String get chatFileSaved => 'File saved';

  @override
  String get chatFileSaveError => '文件保存错误';

  @override
  String get chatDeleteMessage => '删除消息';

  @override
  String get chatDeleteForMe => '为我删除';

  @override
  String get chatDeleteForEveryone => '为所有人删除';

  @override
  String get chatMessageForwarded => '消息已转发';

  @override
  String get chatContactTapToOpen => '联系人 · 点击打开';

  @override
  String get chatForwardTo => '转发到...';

  @override
  String get chatSearchHint => '搜索...';

  @override
  String get chatRecording => '录音中...';

  @override
  String get chatMessageHint => '消息...';

  @override
  String get chatHideKeyboard => '隐藏键盘';

  @override
  String get chatEditing => '编辑中';

  @override
  String get chatFileDownloadError => '文件下载错误';

  @override
  String get chatVoiceMessageShort => '语音消息';

  @override
  String get chatVideoSavedToGallery => '视频已保存到图库';

  @override
  String get chatSavingError => '保存错误';

  @override
  String get convSetNickname => '设置昵称';

  @override
  String get convNicknameRequired => '需要一个昵称才能使用此消息应用。其他用户可以通过它找到您。';

  @override
  String get convNicknameRules => '3–30 个字符：字母、数字、_';

  @override
  String get convNicknameTaken => '昵称已被占用';

  @override
  String get convSaveError => '保存错误';

  @override
  String get convContactsLabel => '联系人';

  @override
  String get convDefaultUser => '用户';

  @override
  String get convNoDialogs => '没有对话';

  @override
  String get convFindUserToChat => '查找用户开始聊天';

  @override
  String get convDefaultContact => '联系人';

  @override
  String get dashboardUser => '用户';

  @override
  String get dashboardIncomingCall => '来电';

  @override
  String get dashboardDecline => '拒绝';

  @override
  String get dashboardAccept => '接受';

  @override
  String get dashboardActiveCall => '通话中 — 点击返回';

  @override
  String dashboardUpdateAvailable(String version) {
    return '可用更新 $version';
  }

  @override
  String get dashboardUpdate => '更新';

  @override
  String get dashboardWhatsNew => '新功能';

  @override
  String dashboardWhatsNewTitle(String version) {
    return '$version 的新功能';
  }

  @override
  String get dashboardInstalling => '正在安装...';

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
  String get contactRequestsTitle => '联系人';

  @override
  String get messengerContactRequestsSection => '联系人请求';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个新请求',
      one: '1 个新请求',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => '搜索';

  @override
  String get contactRequestsIncoming => '收到的';

  @override
  String get contactRequestsSent => '已发送';

  @override
  String get contactRequestsSearchHint => '昵称或邮箱';

  @override
  String get contactRequestSent => '请求已发送';

  @override
  String get contactRequestsNoUsers => '未找到用户';

  @override
  String get contactRequestsSearchHelp => '输入准确的昵称或邮箱\n然后按搜索';

  @override
  String get contactRequestsSendTooltip => '发送请求';

  @override
  String get contactRequestTitle => '联系人请求';

  @override
  String contactRequestConfirm(String name) {
    return '发送联系人请求给 $name?';
  }

  @override
  String get contactRequestSend => '发送';

  @override
  String get contactRequestsNoIncoming => '没有收到的请求';

  @override
  String get contactRequestsNoSent => '没有已发送的请求';

  @override
  String get contactRequestStatusPending => '等待回应';

  @override
  String get contactRequestStatusAccepted => '已接受';

  @override
  String get contactRequestStatusRejected => '已拒绝';

  @override
  String get userSearchTitle => '查找用户';

  @override
  String get userSearchHint => '昵称、电话或邮箱';

  @override
  String get userSearchHelper => '输入 @昵称、邮箱或姓名进行搜索';

  @override
  String get userSearchNoUsers => '未找到用户';

  @override
  String get userProfileShareContact => '分享联系人';

  @override
  String get userProfileShareContactDesc => '发送联系人链接';

  @override
  String get userProfileCopyLink => '复制链接';

  @override
  String get userProfileCopied => '已复制';

  @override
  String get userProfileTitle => '个人资料';

  @override
  String get userProfileLoadError => '加载个人资料错误';

  @override
  String get userProfileMessage => '消息';

  @override
  String get userProfileCall => '通话';

  @override
  String get userProfileRequestSent => '请求已发送';

  @override
  String get userProfileAccept => '接受';

  @override
  String get userProfileDecline => '拒绝';

  @override
  String get userProfileAddToContacts => '添加到联系人';

  @override
  String get userProfileMediaTab => '媒体';

  @override
  String get userProfileFilesTab => '文件';

  @override
  String get userProfileLinksTab => '链接';

  @override
  String get userProfileRecordingsTab => '录音';

  @override
  String get userProfileSummariesTab => '摘要';

  @override
  String get userProfileNoMedia => '没有媒体文件';

  @override
  String get userProfileNoFiles => '没有文件';

  @override
  String get userProfileNoLinks => '没有链接';

  @override
  String get userProfileNoRecordings => '没有录音';

  @override
  String get userProfileNoSummaries => '没有摘要';

  @override
  String get userProfileMeetingSummary => '会议摘要';

  @override
  String get userProfileFailedOpenChat => '打开聊天失败';

  @override
  String get sharedMediaTitle => '媒体和文件';

  @override
  String get sharedMediaTab => '媒体';

  @override
  String get sharedFilesTab => '文件';

  @override
  String get sharedLinksTab => '链接';

  @override
  String get sharedNoMedia => '没有媒体文件';

  @override
  String get sharedNoFiles => '没有文件';

  @override
  String get sharedNoLinks => '没有链接';

  @override
  String get shareToChat => '转发到聊天';

  @override
  String get shareSelectChat => '选择聊天';

  @override
  String get shareNoChats => '没有聊天';

  @override
  String shareFilesCount(int count) {
    return '$count 个文件';
  }

  @override
  String get contactsTitle => '联系人';

  @override
  String get contactsAddTooltip => '添加联系人';

  @override
  String get contactsSearchHint => '搜索联系人...';

  @override
  String get contactsNotFound => '未找到';

  @override
  String get contactsEmpty => '没有联系人';

  @override
  String get contactsAdd => '添加联系人';

  @override
  String get contactsPendingConfirmation => '等待确认';

  @override
  String get contactsMessage => '消息';

  @override
  String get contactsCall => '通话';

  @override
  String get contactsResend => '重新发送请求';

  @override
  String get contactsResendTimeout => '24小时后重试';

  @override
  String get contactsResent => '请求已重发';

  @override
  String get contactsWantsToConnect => '想与你连接';

  @override
  String get contactsSearchPeople => '找人';

  @override
  String get notesTitle => '笔记';

  @override
  String get notesAssistantSpeaking => '助手正在说话...';

  @override
  String get notesListening => '正在听...';

  @override
  String get notesEmpty => '没有笔记';

  @override
  String get notesEmptyHint => '按下麦克风进行听写\n或按+手动输入';

  @override
  String get notesDeleteConfirm => '删除笔记？';

  @override
  String get notesNew => '新笔记';

  @override
  String get notesEdit => '编辑';

  @override
  String get notesTitleHint => '标题';

  @override
  String get notesContentHint => '写下你的想法...';

  @override
  String get calendarTitle => '日历';

  @override
  String get calendarStop => '停止';

  @override
  String get calendarVoiceInput => '语音输入';

  @override
  String get calendarNewEvent => '新事件';

  @override
  String get calendarAssistantSpeaking => '助手正在说话...';

  @override
  String get calendarListening => '正在听...';

  @override
  String calendarInvitations(int count) {
    return '邀请 ($count)';
  }

  @override
  String get calendarNoEvents => '没有事件';

  @override
  String get calendarDayMon => '周一';

  @override
  String get calendarDayTue => '周二';

  @override
  String get calendarDayWed => '周三';

  @override
  String get calendarDayThu => '周四';

  @override
  String get calendarDayFri => '周五';

  @override
  String get calendarDaySat => '周六';

  @override
  String get calendarDaySun => '周日';

  @override
  String get calendarEnterRoom => '进入房间';

  @override
  String get calendarMeeting => '会议';

  @override
  String calendarLocationPrefix(String location) {
    return '地点: $location';
  }

  @override
  String get calendarEditEvent => '编辑';

  @override
  String get calendarTitleHint => '标题';

  @override
  String get calendarDescriptionHint => '描述';

  @override
  String get calendarTypeEvent => '事件';

  @override
  String get calendarTypeMeeting => '会议';

  @override
  String get calendarTypeReminder => '提醒';

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
  String get calendarTypeLabel => '类型';

  @override
  String get calendarMeetingLink => '会议链接';

  @override
  String get calendarLocationHint => '位置';

  @override
  String get calendarDateLabel => '日期';

  @override
  String get calendarTimeLabel => '时间';

  @override
  String get calendarReminderLabel => '提醒';

  @override
  String get calendarReminderNone => '无';

  @override
  String get calendarReminder15min => '提前15分钟';

  @override
  String get calendarReminder30min => '提前30分钟';

  @override
  String get calendarReminder1hour => '提前1小时';

  @override
  String get calendarRepeatLabel => '重复';

  @override
  String get calendarRepeatNone => '不重复';

  @override
  String get calendarRepeatDaily => '每天';

  @override
  String get calendarRepeatWeekly => '每周';

  @override
  String get calendarRepeatMonthly => '每月';

  @override
  String get calendarRepeatYearly => '每年';

  @override
  String get calendarParticipants => '参与者';

  @override
  String get calendarAddParticipant => '添加';

  @override
  String get calendarSearchContacts => '搜索联系人...';

  @override
  String get calendarNoContacts => '无联系人';

  @override
  String get calendarStatusAccepted => '已接受';

  @override
  String get calendarStatusDeclined => '已拒绝';

  @override
  String get calendarStatusMaybe => '可能';

  @override
  String get calendarStatusPending => '待定';

  @override
  String get calendarEndTime => '结束时间';

  @override
  String get calendarYourAnswer => '你的回答：';

  @override
  String get calendarOrganizer => '组织者';

  @override
  String calendarDeleteError(String error) {
    return '删除失败：$error';
  }

  @override
  String get calendarRsvpAccept => '接受';

  @override
  String get calendarRsvpMaybe => '可能';

  @override
  String get calendarRsvpDecline => '拒绝';

  @override
  String get callHistoryTitle => '通话';

  @override
  String get callHistoryTab => '通话记录';

  @override
  String get callHistoryTempMeeting => '临时会议';

  @override
  String get callHistoryCopy => '复制';

  @override
  String get callHistoryLinkCopied => '链接已复制';

  @override
  String get callHistoryShare => '分享';

  @override
  String get callHistoryEnter => '进入';

  @override
  String get callHistoryAlreadyInCall => '已在通话中';

  @override
  String get callHistoryCouldNotDeterminePeer => '无法确定对方';

  @override
  String get callHistoryContacts => '联系人';

  @override
  String get callHistoryFailedLoadRoom => '加载房间失败';

  @override
  String get callHistoryYourRoom => '您的房间';

  @override
  String get callHistoryCreateMeeting => '创建会议';

  @override
  String get callHistoryMeetingSummaries => '会议摘要';

  @override
  String get callHistoryMeetingRecordings => '会议录音';

  @override
  String get callHistoryNoCalls => '无通话';

  @override
  String get callHistoryMissed => '未接';

  @override
  String get callHistoryRecording => '录音';

  @override
  String get callHistorySummary => '摘要';

  @override
  String get callHistoryCallAgain => '再次呼叫';

  @override
  String callHistoryTodayTime(String time) {
    return '今天，$time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return '昨天，$time';
  }

  @override
  String get callHistoryUnknown => '未知';

  @override
  String get callHistoryDetails => '通话详情';

  @override
  String get callHistoryOutgoing => '呼出电话';

  @override
  String get callHistoryIncoming => '呼入电话';

  @override
  String callHistoryDuration(String duration) {
    return '时长：$duration';
  }

  @override
  String get callHistoryWithAI => '与AI助手';

  @override
  String get callHistoryParticipants => '参与者';

  @override
  String get callDetailYouSuffix => '（您）';

  @override
  String get callHistoryMeetingSummary => '会议摘要';

  @override
  String get callHistoryMoreDetails => '更多详情';

  @override
  String get callHistorySummaryProcessing => '摘要处理中...';

  @override
  String get callHistoryMeetingRecording => '会议录音';

  @override
  String get callHistoryProcessing => '处理中...';

  @override
  String get callHistoryCreateTranscript => '创建记录';

  @override
  String get callHistoryNoSummaries => '无摘要';

  @override
  String get callHistoryRecordDuringCall => '通话时按“录音”';

  @override
  String callHistoryMeetingTime(String time) {
    return '会议 $time';
  }

  @override
  String get callHistoryTranscribing => '转录和总结中...';

  @override
  String get callHistoryTranscriptCreated => '记录已创建';

  @override
  String get callHistoryNoRecordings => '无录音';

  @override
  String callHistoryRecordingDate(String date) {
    return '录音 $date';
  }

  @override
  String get callHistoryRecordingUnavailable => '录音不可用';

  @override
  String get callHistoryTranscriptReady => '记录已准备好';

  @override
  String get callHistoryTranscript => '记录';

  @override
  String get callHistoryKeyPoints => '关键点';

  @override
  String get callHistoryTasks => '任务';

  @override
  String callHistoryAssignedTo(String assignee) {
    return '分配给：$assignee';
  }

  @override
  String get callHistoryDecisions => '决策';

  @override
  String get callHistoryShowTranscript => '显示完整记录';

  @override
  String get profileScanQr => '扫描二维码';

  @override
  String get profileMyQrCode => '我的二维码';

  @override
  String profileAddMeShare(String userId) {
    return '在 Taler ID 中添加我！\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => '显示此代码以添加您';

  @override
  String get profileEditDesc => '名字，姓氏，父名，出生日期';

  @override
  String get profileAboutMe => '关于我';

  @override
  String get profileAboutMeDesc => '价值观、技能、兴趣等';

  @override
  String get profileNotes => '笔记';

  @override
  String get profileNotesDesc => '想法、创意和笔记';

  @override
  String get profileAvatarUpdated => '头像已更新';

  @override
  String get profileNickname => '昵称';

  @override
  String get profileNotSet => '未设置';

  @override
  String get profileChangeNickname => '更改昵称';

  @override
  String get profileNicknameUpdated => '昵称已更新';

  @override
  String get profileShareLabel => '分享';

  @override
  String get profileScanQrCode => '扫描二维码';

  @override
  String get profilePointCamera => '将相机对准二维码';

  @override
  String get profilePhotoCamera => '拍照';

  @override
  String get profilePhotoGallery => '从图库中选择';

  @override
  String get editProfilePatronymic => '父名（可选）';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => '关于我';

  @override
  String get aboutMeClickToFill => '点击填写';

  @override
  String get aboutMeCoreValues => '价值观';

  @override
  String get aboutMeWorldview => '世界观';

  @override
  String get aboutMeSkills => '技能';

  @override
  String get aboutMeInterests => '兴趣';

  @override
  String get aboutMeDesires => '愿望';

  @override
  String get aboutMeBackground => '简介';

  @override
  String get aboutMeLikes => '喜欢';

  @override
  String get aboutMeDislikes => '不喜欢';

  @override
  String get aboutMeDeleteSection => '删除部分？';

  @override
  String get aboutMeDeleteConfirm => '此部分中的所有数据将被删除。';

  @override
  String aboutMeConnectionError(String error) {
    return '连接错误：$error';
  }

  @override
  String get aboutMeVisibility => '可见性';

  @override
  String get aboutMeTags => '标签';

  @override
  String get aboutMeAddTag => '添加标签...';

  @override
  String get aboutMeDescription => '描述';

  @override
  String get aboutMeDescribeLong => '告诉我们更多...';

  @override
  String get aboutMeVisibilityEveryone => '所有人';

  @override
  String get aboutMeVisibilityContacts => '联系人';

  @override
  String get aboutMeVisibilityOnlyMe => '仅自己';

  @override
  String get settingsProfileSubtitle => '个人资料';

  @override
  String get settingsWallpaper => '壁纸';

  @override
  String get settingsWallpaperDesc => '整个应用的背景图片';

  @override
  String get settingsWallpaperNone => '无';

  @override
  String get settingsAccount => '账户';

  @override
  String get settingsKycVerification => '身份验证 (KYC)';

  @override
  String get settingsOrganizations => '组织';

  @override
  String get incomingCallLabel => '来电';

  @override
  String get incomingCallDecline => '拒接';

  @override
  String get incomingCallAccept => '接听';

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
  String get meshIncomingCallLabel => '📡 网状网络来电';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return '网状设备 $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => '请先结束当前通话';

  @override
  String get callPopupTransportTitle => '通话方式';

  @override
  String get callPopupTransportMesh => '📡 网状网络 (点对点)';

  @override
  String get callPopupTransportLk => '📞 服务器';

  @override
  String get callPopupTransportMeshUnavailable => '联系人无法通过网状网络联系';

  @override
  String get meshOnboardingTitle => '📡 网状网络通话需要应用打开';

  @override
  String get meshOnboardingBody => '当手机锁定时，网状网络通话可能会在约30秒后断开 (iOS 限制)。';

  @override
  String get meshOnboardingAck => '知道了';

  @override
  String get meshHistoryBadge => '📡 网状网络';

  @override
  String get meshHistoryNoChatAvailable => '联系人不在您的列表中';

  @override
  String get meshCallStatusInviting => '正在呼叫…';

  @override
  String get meshCallStatusConnecting => '正在连接…';

  @override
  String get meshCallEndedUserHangup => '通话结束';

  @override
  String get meshCallEndedRemoteHangup => '对方已结束';

  @override
  String get meshCallEndedRejected => '已拒绝';

  @override
  String get meshCallEndedNoAnswer => '无人接听';

  @override
  String get meshCallEndedConnectionLost => '连接丢失';

  @override
  String get meshCallEndedError => '连接错误';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 网状网络 · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 网状网络';

  @override
  String get batteryExemptionTitle => '📡 可靠的网状网络通话';

  @override
  String get batteryExemptionBody => '允许应用在没有电池限制的情况下运行，以防止 Android 在后台关闭网状网络。';

  @override
  String get batteryExemptionAccept => '打开设置';

  @override
  String get batteryExemptionDismiss => '暂不';

  @override
  String get groupCamera => '相机';

  @override
  String get groupGallery => '图库';

  @override
  String get groupAvatarUpdated => '群组头像已更新';

  @override
  String get groupNameTitle => '群组名称';

  @override
  String get groupEnterName => '输入名称';

  @override
  String get groupDescriptionTitle => '群组描述';

  @override
  String get groupEnterDescription => '输入群组描述';

  @override
  String get groupChangeRoleTitle => '更改角色';

  @override
  String get groupRemoveMemberTitle => '移除成员';

  @override
  String get groupDescription => '描述';

  @override
  String get groupAddDescription => '添加群组描述';

  @override
  String get groupNoDescription => '无描述';

  @override
  String get groupMediaAndFiles => '媒体和文件';

  @override
  String get groupMuteNotifications => '静音通知';

  @override
  String get groupMuted => '已静音';

  @override
  String get groupNoResults => '无结果';

  @override
  String get authInvalidCode => '验证码无效。请重试。';

  @override
  String get loginSubtitle => '使用邮箱和密码';

  @override
  String get emailRequired => '输入邮箱';

  @override
  String get emailInvalid => '邮箱无效';

  @override
  String get passwordRequired => '输入密码';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => '一个账户畅享整个 Taler 生态系统';

  @override
  String get usernameOptional => '用户名（可选）';

  @override
  String get usernameMinLength => '最少 3 个字符';

  @override
  String get usernameMaxLength => '最多 30 个字符';

  @override
  String get usernameInvalid => '仅限字母、数字和_';

  @override
  String get biometricLoginReason => '登录 Taler ID';

  @override
  String get docTypePassport => '护照';

  @override
  String get docTypeIdCard => '身份证';

  @override
  String get docTypeDriverLicense => '驾驶执照';

  @override
  String get docTypeResidencePermit => '居留许可';

  @override
  String addressApartment(String number) {
    return '公寓 $number';
  }

  @override
  String get failedToUpdateProfile => '更新个人资料失败';

  @override
  String get failedToStartKyb => '启动 KYB 验证失败';

  @override
  String get orgUpdated => '组织已更新';

  @override
  String get failedToUpdateOrg => '更新组织失败';

  @override
  String get failedToChangeRole => '更改角色失败';

  @override
  String get failedToRemoveMember => '移除成员失败';

  @override
  String get capabilityMessagesTitle => '消息';

  @override
  String get capabilityMessagesDesc => '查看消息或给某人写信。例如：“写信给 Viktor：一小时后到”';

  @override
  String get capabilityCallsTitle => '通话';

  @override
  String get capabilityCallsDesc => '通过语音拨打任何联系人的电话。例如：“呼叫 Viktor Viktorov”';

  @override
  String get capabilityChatTitle => '聊天记录';

  @override
  String get capabilityChatDesc => '我会分析聊天记录。例如：“我们和Viktor讨论了什么？”';

  @override
  String get capabilityProfileTitle => '个人资料';

  @override
  String get capabilityProfileDesc => '我会显示或更新您的个人资料。例如：“显示我的个人资料”';

  @override
  String get capabilityCoachingTitle => '辅导';

  @override
  String get capabilityCoachingDesc => '模式：ICF辅导、心理学家、HR咨询。说：“让我们进行辅导”';

  @override
  String get capabilityCalendarTitle => '日历';

  @override
  String get capabilityCalendarDesc => '安排会议或设置提醒。例如：“安排明天下午15:00与Viktor的会议”';

  @override
  String get capabilityNotesTitle => '笔记';

  @override
  String get capabilityNotesDesc => '保存想法或阅读最近的笔记。例如：“记下一个想法...”或“阅读最近的笔记”';

  @override
  String get assistantCallConfirm => '拨打电话？';

  @override
  String get callNoAnswer => '无人接听';

  @override
  String get contactDelete => '删除联系人';

  @override
  String get contactDeleteTitle => '删除联系人';

  @override
  String get contactDeleteConfirm => '您确定吗？此联系人将被删除。';

  @override
  String get contactBlock => '屏蔽';

  @override
  String get contactBlockTitle => '屏蔽用户';

  @override
  String get contactBlockConfirm => '此用户将无法给您发送消息或拨打电话。';

  @override
  String get contactUnblock => '取消屏蔽';

  @override
  String get contactBlocked => '已屏蔽';

  @override
  String get contactYouAreBlocked => '此用户已屏蔽您';

  @override
  String get chatBlockedByYou => '您已屏蔽此用户';

  @override
  String get chatYouAreBlocked => '您已被此用户屏蔽';

  @override
  String get chatNotContacts => '将此用户添加到联系人以发送消息';

  @override
  String get contactRevokeRequest => '撤销请求';

  @override
  String get messengerPoll => '投票';

  @override
  String get messengerCreatePoll => '创建投票';

  @override
  String get messengerPollQuestion => '问题';

  @override
  String messengerPollOption(int number) {
    return '选项 $number';
  }

  @override
  String get messengerPollAddOption => '添加选项';

  @override
  String get messengerPollAnonymous => '匿名投票';

  @override
  String get messengerPollMultiple => '多选';

  @override
  String get messengerPollCreateError => '创建投票失败';

  @override
  String get messengerPollUnavailable => '投票不可用';

  @override
  String get messengerPollMultipleNote => '您可以选择多个';

  @override
  String messengerPollVotes(int count) {
    return '$count 票';
  }

  @override
  String get messengerVideoMessage => '视频消息';

  @override
  String get messengerVideoRecordError => '视频录制错误';

  @override
  String get messengerVideoPlaybackError => '无法播放视频';

  @override
  String get messengerGalleryAccessError => '无法访问图库';

  @override
  String get messengerSearchInChat => '在聊天中搜索...';

  @override
  String get messengerSaveToFavorites => '保存到收藏夹';

  @override
  String get messengerSavedToFavorites => '已保存到收藏夹';

  @override
  String get messengerSearchInMessages => '在消息中搜索...';

  @override
  String messengerFoundInMessages(int count) {
    return '在消息中找到 ($count)';
  }

  @override
  String get messengerGroupDefault => '群组';

  @override
  String get messengerUserDefault => '用户';

  @override
  String get messengerPin => '置顶';

  @override
  String get messengerUnpin => '取消置顶';

  @override
  String get messengerArchive => '存档';

  @override
  String get messengerUnarchive => '取消存档';

  @override
  String get messengerDeleteChat => '删除聊天';

  @override
  String get messengerDeleteChatTitle => '删除聊天？';

  @override
  String messengerDeleteChatConfirm(String name) {
    return '删除与 $name 的聊天？此操作无法撤销。';
  }

  @override
  String get messengerCreateChannel => '创建频道';

  @override
  String get messengerChannelName => '名称';

  @override
  String get messengerChannelDescription => '描述（可选）';

  @override
  String get messengerChannelCreateError => '创建频道失败';

  @override
  String get messengerFilterAll => '全部';

  @override
  String get messengerFilterUnread => '未读';

  @override
  String get messengerFilterPersonal => '个人';

  @override
  String get messengerFilterGroups => '群组';

  @override
  String get messengerFilterChannels => '频道';

  @override
  String get messengerArchivedSection => '已存档';

  @override
  String get messengerSavedSection => '收藏夹';

  @override
  String get messengerSavedSubtitle => '保存到记忆';

  @override
  String messengerArchiveTitle(int count) {
    return '存档 ($count)';
  }

  @override
  String get messengerArchiveEmpty => '存档为空';

  @override
  String messengerYouPrefix(String message) {
    return '你: $message';
  }

  @override
  String get messengerMissedCall => '未接来电';

  @override
  String get messengerSavedTitle => '收藏夹';

  @override
  String get messengerNoSavedMessages => '没有保存的消息';

  @override
  String get messengerSavedHint => '长按消息 → \"保存到收藏夹\"';

  @override
  String get messengerDefaultFile => '文件';

  @override
  String get messengerTopicDefault => '常规';

  @override
  String get messengerTopicNew => '新话题';

  @override
  String get messengerTopicNameHint => '话题名称';

  @override
  String get messengerTopicIcon => '图标';

  @override
  String messengerTopicCount(int count) {
    return '$count 个话题';
  }

  @override
  String get messengerNoTopics => '没有话题';

  @override
  String get messengerNoMessages => '没有消息';

  @override
  String get you => '你';

  @override
  String get messengerThread => '线程';

  @override
  String get messengerThreadReply => '回复';

  @override
  String get messengerThreadReplies => '回复';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => '没有回复';

  @override
  String get messengerReplyHint => '回复线程...';

  @override
  String get messengerContactName => '联系人姓名';

  @override
  String messengerOriginalName(String name) {
    return '原始姓名: $name';
  }

  @override
  String get messengerDisplayName => '显示名称';

  @override
  String messengerShareContact(String name) {
    return 'Taler ID 中的联系人: $name';
  }

  @override
  String get messengerAutoDelete => '自动删除消息';

  @override
  String get messengerAutoDeleteOff => '关闭';

  @override
  String get messengerAutoDelete7d => '7 天';

  @override
  String get messengerAutoDelete30d => '30 天';

  @override
  String get messengerAutoDelete90d => '90 天';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count 天';
  }

  @override
  String get messengerSettingsHeader => '设置';

  @override
  String get messengerAdminOnly => '仅管理员发布';

  @override
  String get messengerAdminOnlyDesc => '成员只能阅读';

  @override
  String get messengerTopics => '话题';

  @override
  String get messengerTopicsDesc => '将聊天分成话题';

  @override
  String get aiTwinSection => 'AI 语音双胞胎';

  @override
  String get aiTwinEnabled => '启用 AI 双胞胎';

  @override
  String get aiTwinEnabledDesc => '如果你不接电话，你的 AI 双胞胎会用你的声音接听';

  @override
  String get aiTwinTimeout => '响应超时';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get aiTwinPrompt => 'AI 指令';

  @override
  String get aiTwinPromptSubtitle => 'AI 双胞胎应如何介绍自己以及谈论什么';

  @override
  String aiTwinPromptHint(String name) {
    return '你好，这是 $name 的 AI 语音双胞胎。$name 现在无法接听。告诉我是谁打来的以及有什么事——我会转告。';
  }

  @override
  String aiTwinComingSoon(String name) {
    return '自定义语音克隆即将推出。目前 AI 使用 $name 的声音。';
  }

  @override
  String get aiTwinDefaultName => '所有者';

  @override
  String get aiTwinPromptReset => '重置';

  @override
  String get callHistoryAiTwinAnswered => 'AI 双胞胎已接听';

  @override
  String get callHistoryAiTwinSummary => '通话摘要';

  @override
  String get callHistoryAiTwinTranscript => '文字记录';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return '来自 $name';
  }

  @override
  String get aiTwinOfferTitle => '未接听';

  @override
  String aiTwinOfferBody(String name) {
    return '$name 没有接听。用他们的AI语音替身留言吗？';
  }

  @override
  String get aiTwinOfferBodyUser => '用户';

  @override
  String get aiTwinOfferAccept => '是的，留言';

  @override
  String get aiTwinOfferKeepWaiting => '继续等待';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => '您的AI替身';

  @override
  String get aiTwinHeroSubtitle => '当您无法接听时，用您的声音接听电话。';

  @override
  String get aiTwinProfileTitle => 'AI替身';

  @override
  String get aiTwinProfileDesc => '用您的声音接听电话';

  @override
  String get aiTwinBadgeOn => '开启';

  @override
  String get aiAnalystTitle => 'AI分析师';

  @override
  String get aiAnalystSubtitle => '文件、任务、分析 — Claude';

  @override
  String get channelsDiscover => '发现频道';

  @override
  String get channelsSearchHint => '搜索频道';

  @override
  String get channelsSubscribers => '订阅者';

  @override
  String get channelsSubscribe => '订阅';

  @override
  String get channelsUnsubscribe => '取消订阅';

  @override
  String get channelsSubscribedLabel => '您已订阅';

  @override
  String get channelsSettings => '频道设置';

  @override
  String get channelsDelete => '删除频道';

  @override
  String get channelsDeleteConfirm => '永久删除频道？';

  @override
  String get channelsEmpty => '暂无频道';

  @override
  String get channelsOpen => '打开';

  @override
  String get channelsNameLabel => '名称';

  @override
  String get channelsDescriptionLabel => '描述';

  @override
  String get channelsCannotUnsubscribeOwner => '所有者无法取消订阅。请删除频道。';

  @override
  String get channelsNotFoundRedirect => '频道不存在';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次搜索',
      one: '$count 次搜索',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件',
      one: '$count 个文件',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个命令',
      one: '$count 个命令',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张图片',
      one: '$count 张图片',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 步',
      one: '$count 步',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get savedTitle => '已保存的消息';

  @override
  String get savedSubtitle => '您的私人云';

  @override
  String get savedOpenError => '无法打开已保存的消息';

  @override
  String get billingWalletTitle => '钱包';

  @override
  String get billingBuyPackage => '购买套餐';

  @override
  String get billingCurrentBalance => '当前余额';

  @override
  String get billingPackagesTitle => '套餐';

  @override
  String get billingPackagesUnavailable => '套餐不可用';

  @override
  String get billingRecentOperations => '最近操作';

  @override
  String get billingAllOperations => '所有操作';

  @override
  String get billingNoOperations => '无操作';

  @override
  String get billingOperationsTitle => '操作';

  @override
  String get billingOperationsEmptyTitle => '尚无操作';

  @override
  String get billingOperationsEmptySubtitle => 'AI功能的充值和扣费将在此显示';

  @override
  String get billingPricebookTitle => '功能价格';

  @override
  String get billingPricebookUnavailable => '价格表不可用';

  @override
  String get billingAiFeaturesTitle => 'AI功能';

  @override
  String get billingInsufficientFundsTitle => '资金不足';

  @override
  String get billingInsufficientFundsSubtitle => '充值余额以使用此功能。';

  @override
  String billingRequiredLine(String required) {
    return '需要：$required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return '拥有：$available μTAL';
  }

  @override
  String get billingTopUp => '充值';

  @override
  String get billingCancel => '取消';

  @override
  String get billingRetry => '重试';

  @override
  String billingLowBalanceWarning(String balance) {
    return '余额不足：$balance μTAL';
  }

  @override
  String get billingWalletAndBalance => '钱包与余额';

  @override
  String get billingSectionHeader => '计费与AI';

  @override
  String get billingFeatureVoiceAssistant => '语音助手';

  @override
  String get billingFeatureWebSearch => '助手网页搜索';

  @override
  String get billingFeatureAiTwin => '语音双胞胎';

  @override
  String get billingFeatureAiTwinLong => '语音双胞胎（AI Twin）';

  @override
  String get billingFeatureOutboundCall => '外呼机器人';

  @override
  String get billingFeatureOutboundCallLong => '外呼拨号机器人';

  @override
  String get billingFeatureWhisperTranscribe => '通话转录';

  @override
  String get billingFeatureMeetingSummary => 'AI通话总结';

  @override
  String get billingConfigureAiTwin => '配置AI双胞胎';

  @override
  String get billingWebSearchSubtitle => '（由助手使用）';

  @override
  String billingPackagePurchased(String balance) {
    return '已购买套餐：$balance μTAL';
  }

  @override
  String get billingRecommendedBadge => '推荐';

  @override
  String get billingSessionTerminatedNoFunds => '余额耗尽 — 会话结束';

  @override
  String get billingSessionTerminatedGeneric => '助手会话结束';

  @override
  String billingBuyForPrice(String price) {
    return '购买价格：€$price';
  }

  @override
  String get billingTxTypeTopup => '充值';

  @override
  String get billingTxTypeRefund => '退款';

  @override
  String get billingTxTypeSpend => '扣费';

  @override
  String get billingUnitMinute => '分钟';

  @override
  String get billingUnitRequest => '请求';

  @override
  String get billingUnitToken => 'token';

  @override
  String get billingUnitTokens1k => '1K tokens';

  @override
  String get billingUnitCall => '通话';

  @override
  String get groupCallSelectParticipants => '选择参与者';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => '搜索';

  @override
  String get groupCallMaxReached => '最多7位参与者';

  @override
  String get groupCallLobbyTitle => '群组 • 大厅';

  @override
  String groupCallHostLabel(String name) {
    return '主持人: $name';
  }

  @override
  String get groupCallMicHint => '连接时麦克风将激活';

  @override
  String get groupCallCancel => '取消';

  @override
  String get groupCallNoAnswer => '无人接听';

  @override
  String get groupCallEndedByHost => '通话已被主持人结束';

  @override
  String get groupCallAllLeft => '所有人已离开通话';

  @override
  String get groupCallEnded => '通话已结束';

  @override
  String groupCallActiveTitle(int count) {
    return '群组 • $count';
  }

  @override
  String get groupCallConnectionLost => '连接已断开';

  @override
  String get groupCallMuteRequested => '主持人要求所有人静音';

  @override
  String get groupCallUnmute => '取消静音';

  @override
  String get groupCallMute => '静音';

  @override
  String get groupCallMuteAll => '全部静音';

  @override
  String get groupCallLeave => '离开';

  @override
  String get groupCallStatusCalling => '正在呼叫…';

  @override
  String get groupCallStatusDeclined => '已拒绝';

  @override
  String get groupCallStatusTimeout => '无人接听';

  @override
  String get groupCallStatusLeft => '已离开';

  @override
  String groupCallKickConfirm(String name) {
    return '将 $name 移出通话';
  }

  @override
  String get groupCallCancelAction => '取消';

  @override
  String get groupCallActiveBanner => '正在通话';

  @override
  String groupCallBannerSummary(String host, int count) {
    return '群组: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return '群组: $host';
  }

  @override
  String get groupCallCreateError => '无法创建通话';

  @override
  String get groupCallJoinError => '无法加入通话';

  @override
  String get groupCallLivekitError => 'LiveKit 错误';

  @override
  String get groupCallDone => '完成';

  @override
  String get groupCallNoResults => '无结果';

  @override
  String get groupCallNoContacts => '无联系人';

  @override
  String get meshGcContactOffline => '不在此 Wi-Fi 上';

  @override
  String get meshGcOnlineViaMesh => '通过网格在线';

  @override
  String get meshGcMaxInvitees => '群组通话最多支持4位受邀者（共5人）。';

  @override
  String get meshGcStart => '开始群组通话';

  @override
  String get meshGcCancel => '取消';

  @override
  String get meshGcStatusCalling => '正在呼叫…';

  @override
  String get meshGcStatusJoined => '已加入';

  @override
  String get meshGcStatusDeclined => '已拒绝';

  @override
  String get meshGcStatusNoAnswer => '无人接听';

  @override
  String get meshGcStatusConnectionFailed => '连接失败';

  @override
  String get meshGcStatusLeft => '已离开';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne => '请先结束当前通话。';

  @override
  String get presenceOnline => '在线';

  @override
  String get presenceLastSeenJustNow => '刚刚在线';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return '$minutes分钟前在线';
  }

  @override
  String presenceLastSeenToday(String time) {
    return '今天$time在线';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return '昨天$time在线';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return '$date在线';
  }

  @override
  String get presenceLastSeenRecently => '最近在线';

  @override
  String get privacySectionTitle => '隐私';

  @override
  String get privacyLastSeenLabel => '谁可以看到你的最后上线时间';

  @override
  String get privacyEveryone => '所有人';

  @override
  String get privacyContacts => '仅联系人';

  @override
  String get privacyNobody => '无人';

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
}
