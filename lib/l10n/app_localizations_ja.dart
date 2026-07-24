// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => '検索';

  @override
  String get appSubtitle => '統合エコシステムID';

  @override
  String get login => 'サインイン';

  @override
  String get loginButton => 'サインイン';

  @override
  String get register => 'アカウント作成';

  @override
  String get registerButton => 'アカウント作成';

  @override
  String get email => 'メール';

  @override
  String get password => 'パスワード';

  @override
  String get confirmPassword => 'パスワード確認';

  @override
  String get firstName => '名';

  @override
  String get lastName => '姓';

  @override
  String get noAccount => 'アカウントをお持ちでないですか？';

  @override
  String get createOne => '作成する';

  @override
  String get haveAccount => 'すでにアカウントをお持ちですか？';

  @override
  String get signIn => 'サインイン';

  @override
  String get passwordMinLength => '8文字以上';

  @override
  String get invalidEmail => '有効なメールアドレスを入力してください';

  @override
  String get fieldRequired => '必須フィールド';

  @override
  String get twoFATitle => '二要素認証';

  @override
  String get twoFASubtitle => '認証アプリから6桁のコードを入力してください';

  @override
  String get twoFACode => '2FAコード';

  @override
  String get verify => '確認';

  @override
  String get tabProfile => 'プロフィール';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => '組織';

  @override
  String get tabSettings => '設定';

  @override
  String get profile => 'プロフィール';

  @override
  String get editProfile => 'プロフィール編集';

  @override
  String get phone => '電話';

  @override
  String get country => '国';

  @override
  String get dateOfBirth => '生年月日';

  @override
  String get documents => '書類';

  @override
  String get addDocument => '書類を追加';

  @override
  String get noDocuments => 'アップロードされた書類はありません';

  @override
  String get save => '保存';

  @override
  String get profileUpdated => 'プロフィールが更新されました';

  @override
  String get personalData => '個人データ';

  @override
  String get passport => 'パスポート';

  @override
  String get drivingLicense => '運転免許証';

  @override
  String get diploma => '卒業証書';

  @override
  String get nationalId => '国民ID';

  @override
  String get certificate => '証明書';

  @override
  String get notSpecified => '指定なし';

  @override
  String get notSpecifiedFemale => '指定なし';

  @override
  String get documentType => '書類の種類';

  @override
  String get passportId => 'パスポート / ID';

  @override
  String get diplomaCertificate => '卒業証書 / 証明書';

  @override
  String get loadError => '読み込みエラー';

  @override
  String get verification => '確認';

  @override
  String get countryAustria => 'オーストリア';

  @override
  String get countryGermany => 'ドイツ';

  @override
  String get countryRussia => 'ロシア';

  @override
  String get countryUkraine => 'ウクライナ';

  @override
  String get countryKazakhstan => 'カザフスタン';

  @override
  String get countryBelarus => 'ベラルーシ';

  @override
  String get countryOther => 'その他';

  @override
  String get kycTitle => 'KYC確認';

  @override
  String get kycVerified => '確認済み';

  @override
  String get kycPending => '保留中';

  @override
  String get kycRejected => '拒否されました';

  @override
  String get kycUnverified => '未確認';

  @override
  String get kycVerifiedDesc => 'あなたの身元は確認されました。Talerエコシステムのすべての機能にフルアクセスできます。';

  @override
  String get kycPendingDesc => 'あなたの書類は審査中です。通常1〜2営業日かかります。';

  @override
  String get kycRejectedDesc => '確認に失敗しました。理由を確認し、書類を再提出してください。';

  @override
  String get kycUnverifiedDesc => 'Talerエコシステムの金融機能にフルアクセスするには、確認を完了してください。';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get kycInProgress => 'In progress';

  @override
  String get kycInProgressDesc =>
      'You started verification but didn\'t finish it. Pick up right where you left off.';

  @override
  String get startVerification => '確認を開始';

  @override
  String get retryVerification => '確認を再試行';

  @override
  String verifiedAt(String date) {
    return '確認済み: $date';
  }

  @override
  String get documentsSubmitted => '審査のために書類を提出しました';

  @override
  String get documentsSubmittedDesc => '審査には通常1〜2営業日かかります。結果はプッシュ通知でお知らせします。';

  @override
  String get securityAes => 'あなたのデータはAES-256暗号化で保護されています';

  @override
  String get verificationTime => '確認には1〜2営業日かかります';

  @override
  String get pushNotification => '結果はプッシュ通知でお知らせします';

  @override
  String get kycWebOnly => 'KYC確認はモバイルアプリでのみ利用可能です。';

  @override
  String verificationError(String code) {
    return '確認エラー: $code';
  }

  @override
  String get organizations => '組織';

  @override
  String get noOrganizations => '組織なし';

  @override
  String get noOrganizationsDesc => '組織を作成するか、招待を受け入れてください';

  @override
  String get createOrganization => '組織を作成';

  @override
  String get newOrganization => '新しい組織';

  @override
  String get orgName => '名前 *';

  @override
  String get orgDescription => '説明';

  @override
  String get orgEmail => '連絡先メール';

  @override
  String get orgWebsite => 'ウェブサイト';

  @override
  String get orgLegalAddress => '法的住所';

  @override
  String get create => '作成';

  @override
  String get organization => '組織';

  @override
  String get contacts => '連絡先';

  @override
  String members(int count) {
    return 'メンバー ($count)';
  }

  @override
  String get inviteMember => 'メンバーを招待';

  @override
  String get invite => '招待';

  @override
  String get sendInvite => '招待を送信';

  @override
  String inviteSent(String email) {
    return '$email に招待を送信しました';
  }

  @override
  String get role => '役割';

  @override
  String get roleOwner => 'オーナー';

  @override
  String get roleAdmin => '管理者';

  @override
  String get roleOperator => 'オペレーター';

  @override
  String get roleViewer => '閲覧者';

  @override
  String get editOrganization => '編集';

  @override
  String get editOrganizationTitle => '組織を編集';

  @override
  String get removeMember => 'メンバーを削除';

  @override
  String removeMemberConfirm(String name) {
    return '組織から $name を削除しますか？';
  }

  @override
  String get memberRemoved => 'メンバーを削除しました';

  @override
  String get roleChanged => '役割を変更しました';

  @override
  String get kybVerified => '確認済み';

  @override
  String get kybPending => '保留中';

  @override
  String get kybRejected => '拒否されました';

  @override
  String get kybNone => '未確認';

  @override
  String get kybVerification => 'KYB確認を開始';

  @override
  String get kybStartBusiness => 'ビジネス確認を開始';

  @override
  String get kybStatusLabel => 'KYBステータス';

  @override
  String get noKyb => 'KYBなし';

  @override
  String get kybBusinessVerificationTitle => 'ビジネス確認 (KYB)';

  @override
  String get kybVerifiedOrgDesc => '組織が正常に確認されました。';

  @override
  String get kybPendingOrgDesc => '書類が審査中です。通常、1〜3営業日かかります。';

  @override
  String get kybRejectedOrgDesc => '確認に失敗しました。もう一度お試しください。';

  @override
  String get kybNoneOrgDesc => 'ビジネス機能にアクセスするには、組織を確認してください。';

  @override
  String get invitePlus => '+ 招待';

  @override
  String get kybVerificationTitle => 'KYB確認';

  @override
  String get kybWebOnlyBusiness => 'KYB認証はモバイルアプリでのみ利用可能です。';

  @override
  String get unknownDevice => '不明なデバイス';

  @override
  String get ipUnknown => 'IP不明';

  @override
  String get currentSessionLabel => '現在';

  @override
  String get endSessionAction => '終了';

  @override
  String get deviceLoggedOut => 'デバイスはサインアウトされます。';

  @override
  String get acceptInvitationTitle => '組織招待';

  @override
  String get acceptInvitation => '招待を受け入れる';

  @override
  String get acceptInvitationDesc => 'Talerエコシステムの組織に招待されました。';

  @override
  String get accept => '受け入れる';

  @override
  String get reject => '拒否';

  @override
  String get sessions => 'アクティブセッション';

  @override
  String get currentSession => '現在のセッション';

  @override
  String get deleteSession => 'セッションを終了';

  @override
  String get deleteSessionConfirm => 'このセッションを終了しますか？';

  @override
  String get sessionDeleted => 'セッションが終了しました';

  @override
  String get noSessions => 'アクティブなセッションはありません';

  @override
  String minutesAgo(int count) {
    return '$count分前';
  }

  @override
  String hoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String daysAgo(int count) {
    return '$count日前';
  }

  @override
  String get justNow => 'たった今';

  @override
  String get settings => '設定';

  @override
  String get security => 'セキュリティ';

  @override
  String get biometrics => '生体認証';

  @override
  String get biometricsDesc => 'Face IDまたは指紋でのクイックログイン';

  @override
  String get biometricsConfirm => 'クイックログインを有効にするには生体認証を確認してください';

  @override
  String get biometricsError => '生体認証の有効化に失敗しました。デバイス設定を確認してください。';

  @override
  String get changePassword => 'パスワードを変更';

  @override
  String get twoFactorAuth => '二要素認証';

  @override
  String get currentPassword => '現在のパスワード';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get confirmNewPassword => '新しいパスワードを確認';

  @override
  String get passwordChanged => 'パスワードが変更されました';

  @override
  String get wrongCurrentPassword => '現在のパスワードが間違っています';

  @override
  String get passwordTooWeak => 'パスワードが弱すぎます：8文字以上、文字と数字が必要です';

  @override
  String get passwordChangeFailed => 'パスワードの変更に失敗しました';

  @override
  String get notifications => '通知';

  @override
  String get permissions => '権限';

  @override
  String get permissionNotifications => 'プッシュ通知';

  @override
  String get permissionNotificationsDesc => '通話、メッセージ、ステータス';

  @override
  String get permissionMicrophone => 'マイク';

  @override
  String get permissionMicrophoneDesc => '通話と音声アシスタント';

  @override
  String get permissionCamera => 'カメラ';

  @override
  String get permissionCameraDesc => 'ビデオ通話と認証';

  @override
  String get permissionLocation => '位置情報';

  @override
  String get permissionLocationDesc => '認証に使用';

  @override
  String get permissionOpenSettings => '権限を取り消すには、システム設定を開いてください';

  @override
  String get pushKycStatus => 'KYCステータス通知';

  @override
  String get pushKycStatusDesc => '認証結果';

  @override
  String get pushLogins => 'ログイン通知';

  @override
  String get pushLoginsDesc => '新しいデバイスからサインインする際';

  @override
  String get account => 'アカウント';

  @override
  String get language => '言語';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'インターフェース言語';

  @override
  String get exportData => 'データをエクスポート (GDPR)';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get deleteAccountConfirm => 'アカウントを削除しますか？';

  @override
  String get deleteAccountDesc => 'すべてのデータが削除されます (GDPR)。この操作は元に戻せません。';

  @override
  String get logout => 'サインアウト';

  @override
  String get logoutConfirm => 'サインアウトしますか？';

  @override
  String get logoutDesc => 'このデバイスでTaler IDからサインアウトします。';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'PINコード';

  @override
  String get pinCodeDesc => '4桁のコードでクイックログイン';

  @override
  String get setupPin => 'PINを設定';

  @override
  String get enterPin => 'PINを入力';

  @override
  String get confirmPin => 'PINを確認';

  @override
  String get pinMismatch => 'PINが一致しません';

  @override
  String get passwordMismatch => 'パスワードが一致しません';

  @override
  String get pinSet => 'PINが正常に設定されました';

  @override
  String get enterPinToLogin => 'サインインするにはPINを入力';

  @override
  String get pinIncorrect => 'PINが正しくありません';

  @override
  String get removePin => 'PINを削除';

  @override
  String get pinRemoved => 'PINが削除されました';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get ok => 'OK';

  @override
  String get retry => '再試行';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get success => '成功';

  @override
  String get noData => 'データなし';

  @override
  String get failedToLoad => 'データの読み込みに失敗しました';

  @override
  String get failedToLoadProfile => 'プロフィールの読み込みに失敗しました';

  @override
  String get failedToSave => '変更の保存に失敗しました';

  @override
  String get failedToLoadOrgs => '組織の読み込みに失敗しました';

  @override
  String get failedToLoadOrg => '組織データの読み込みに失敗しました';

  @override
  String get failedToCreateOrg => '組織の作成に失敗しました';

  @override
  String get failedToInvite => '招待の送信に失敗しました';

  @override
  String get failedToAcceptInvite => '招待の受諾に失敗しました';

  @override
  String get failedToLoadSessions => 'セッションの読み込みに失敗しました';

  @override
  String get failedToDeleteSession => 'セッションの終了に失敗しました';

  @override
  String get failedToLoadKyc => '確認ステータスの読み込みに失敗しました';

  @override
  String get failedToStartKyc => '確認の開始に失敗しました';

  @override
  String get verifiedPersonalInfo => '確認済みデータ';

  @override
  String get middleName => 'ミドルネーム';

  @override
  String get placeOfBirth => '出生地';

  @override
  String get nationality => '国籍';

  @override
  String get gender => '性別';

  @override
  String get genderMale => '男性';

  @override
  String get genderFemale => '女性';

  @override
  String get docNumber => '番号';

  @override
  String get docIssuedDate => '発行日';

  @override
  String get docValidUntil => '有効期限';

  @override
  String get docIssuedBy => '発行者';

  @override
  String get address => '住所';

  @override
  String get refreshData => 'データを更新';

  @override
  String get failedToLoadSumsubData => '確認データの読み込みに失敗しました';

  @override
  String get sumsubDataLoading => '確認データを読み込み中...';

  @override
  String get reviewResultGreen => '確認に合格しました';

  @override
  String get reviewResultRed => '確認に失敗しました';

  @override
  String get tabAssistant => 'アシスタント';

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
  String get assistantConnecting => '接続中…';

  @override
  String get assistantSpeaking => '話しています…';

  @override
  String get assistantListening => '聞いています…';

  @override
  String get assistantTapToStart => 'タップして開始';

  @override
  String get assistantTapToTalk => 'AIと話すにはタップ';

  @override
  String get assistantRealtimeDesc => 'アシスタントがリアルタイムで音声で応答します';

  @override
  String get assistantConnectingToAssistant => 'アシスタントに接続中...';

  @override
  String get assistantAiSpeaking => 'AIが話しています...';

  @override
  String get assistantAiListening => 'AIが聞いています';

  @override
  String get assistantSpeakerOn => 'スピーカーオン';

  @override
  String get assistantSpeaker => 'スピーカー';

  @override
  String get assistantEnd => '終了';

  @override
  String get assistantUnmute => 'ミュート解除';

  @override
  String get assistantMicrophone => 'マイク';

  @override
  String get assistantConnectionError => '接続エラー';

  @override
  String get tabMessenger => 'メッセージ';

  @override
  String get tabCalls => '通話';

  @override
  String get tabCalendar => 'カレンダー';

  @override
  String get appearance => '外観';

  @override
  String get appearanceSelect => 'テーマを選択';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeSystem => 'システム';

  @override
  String get onboardingTitle1 => '統合されたアイデンティティ';

  @override
  String get onboardingDesc1 =>
      'Taler IDはTalerエコシステム内のデジタルパスポートです。すべてのサービスに1つのアカウント。';

  @override
  String get onboardingTitle2 => 'データセキュリティ';

  @override
  String get onboardingDesc2 => 'KYC認証、AES-256暗号化、二要素認証であなたのアイデンティティを保護します。';

  @override
  String get onboardingTitle3 => '情報を常に把握';

  @override
  String get onboardingDesc3 => '認証状況、新しいデバイスからのログイン、着信について通知を受け取ります。';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingEnableNotifications => '通知を有効にする';

  @override
  String get onboardingTitle4 => '音声通話';

  @override
  String get onboardingDesc4 =>
      '音声通話とAIアシスタントのためにマイクアクセスを許可してください。後で設定で変更できます。';

  @override
  String get onboardingEnableMicrophone => 'マイクを有効にする';

  @override
  String get onboardingStart => '始める';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get meshLocalNetworkPromptTitle => 'ローカルネットワークアクセスを許可';

  @override
  String get meshLocalNetworkPromptBody =>
      'Wi-Fi上でピアを見つけるために（オフライングループ通話）、iOSはローカルネットワークの許可が必要です。設定を開く → プライバシーとセキュリティ → ローカルネットワーク → Taler ID。';

  @override
  String get meshLocalNetworkPromptOpenSettings => '設定を開く';

  @override
  String get meshLocalNetworkPromptDismiss => '了解';

  @override
  String get forgotPassword => 'パスワードを忘れましたか？';

  @override
  String get forgotPasswordTitle => 'パスワードをリセット';

  @override
  String get forgotPasswordSubtitle => 'リセットコードを受け取るためにメールアドレスを入力してください';

  @override
  String resetCodeSent(String email) {
    return 'コードが$emailに送信されました';
  }

  @override
  String get enterResetCode => 'コードを入力';

  @override
  String get resetPasswordButton => 'パスワードをリセット';

  @override
  String get passwordResetSuccess => 'パスワードが正常にリセットされました';

  @override
  String get sendCode => 'コードを送信';

  @override
  String get resendCode => 'コードを再送信';

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
  String get newGroup => '新しいグループ';

  @override
  String get newChat => '新しいチャット';

  @override
  String get groupName => 'グループ名';

  @override
  String get createGroup => 'グループを作成';

  @override
  String get groupInfo => 'グループ情報';

  @override
  String groupMembers(int count) {
    return 'メンバー ($count)';
  }

  @override
  String get addMembers => 'メンバーを追加';

  @override
  String get leaveGroup => 'グループを退出';

  @override
  String get leaveGroupConfirm => 'このグループを退出しますか？';

  @override
  String get deleteGroup => 'グループを削除';

  @override
  String get deleteGroupConfirm => 'このグループを削除しますか？この操作は元に戻せません。';

  @override
  String get groupRoleOwner => 'オーナー';

  @override
  String get groupRoleAdmin => '管理者';

  @override
  String get groupRoleMember => 'メンバー';

  @override
  String get selectParticipants => '参加者を選択';

  @override
  String selectedCount(int count) {
    return '$count 件選択済み';
  }

  @override
  String get changeRole => '役割を変更';

  @override
  String get groupCreated => 'グループが作成されました';

  @override
  String memberJoined(String name) {
    return '$name が参加しました';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name が退出しました';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name が削除されました';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name は $role になりました';
  }

  @override
  String participantsCount(int count) {
    return '$count 人の参加者';
  }

  @override
  String get enterGroupName => 'グループ名を入力';

  @override
  String get muteNotifications => '通知をミュート';

  @override
  String get unmuteNotifications => '通知のミュートを解除';

  @override
  String get muteFor1Hour => '1時間';

  @override
  String get muteFor8Hours => '8時間';

  @override
  String get muteFor2Days => '2日間';

  @override
  String get muteForever => '無期限';

  @override
  String get muted => 'ミュート中';

  @override
  String get tabTranslator => '翻訳';

  @override
  String get translatorTitle => '翻訳者';

  @override
  String get translatorSelectLanguage => '言語を選択';

  @override
  String get translatorDownloading => '言語モデルをダウンロード中...';

  @override
  String get translatorDownloadingHint => '最初のダウンロードのみインターネットが必要です';

  @override
  String get translatorTypeHint => 'テキストを入力するか、マイクをタップ';

  @override
  String get translatorListening => '聞き取り中...';

  @override
  String get translatorTapToSpeak => 'タップして話す';

  @override
  String get translatorTapToStop => 'タップして停止';

  @override
  String get translatorAutoSpeak => '自動発話';

  @override
  String get translatorCopied => 'コピーしました';

  @override
  String get translatorLangRu => 'ロシア語';

  @override
  String get translatorLangEn => '英語';

  @override
  String get translatorLangDe => 'ドイツ語';

  @override
  String get translatorLangFr => 'フランス語';

  @override
  String get translatorLangEs => 'スペイン語';

  @override
  String get translatorLangIt => 'イタリア語';

  @override
  String get translatorLangPt => 'ポルトガル語';

  @override
  String get translatorLangTr => 'トルコ語';

  @override
  String get translatorLangZh => '中国語';

  @override
  String get translatorLangJa => '日本語';

  @override
  String get translatorLangKo => '韓国語';

  @override
  String get translatorLangAr => 'アラビア語';

  @override
  String get translatorLangPl => 'ポーランド語';

  @override
  String get translatorLangSk => 'スロバキア語';

  @override
  String get translatorLangCs => 'チェコ語';

  @override
  String get translatorLangNl => 'オランダ語';

  @override
  String get translatorLangSv => 'スウェーデン語';

  @override
  String get translatorLangDa => 'デンマーク語';

  @override
  String get translatorLangNo => 'ノルウェー語';

  @override
  String get translatorLangFi => 'フィンランド語';

  @override
  String get translatorLangUk => 'ウクライナ語';

  @override
  String get translatorLangEl => 'ギリシャ語';

  @override
  String get translatorLangRo => 'ルーマニア語';

  @override
  String get translatorLangHu => 'ハンガリー語';

  @override
  String get translatorLangBg => 'ブルガリア語';

  @override
  String get translatorLangHr => 'クロアチア語';

  @override
  String get translatorLangSr => 'セルビア語';

  @override
  String get translatorLangHi => 'ヒンディー語';

  @override
  String get translatorLangTh => 'タイ語';

  @override
  String get translatorLangVi => 'ベトナム語';

  @override
  String get translatorLangId => 'インドネシア語';

  @override
  String get translatorLangMs => 'マレー語';

  @override
  String get translatorLangHe => 'ヘブライ語';

  @override
  String get translatorLangFa => 'ペルシャ語';

  @override
  String get callInProgress => '通話中';

  @override
  String get joinCall => '参加';

  @override
  String get createCallLink => '通話リンク';

  @override
  String get callLinkCopied => 'リンクをコピーしました';

  @override
  String get callLinkTitle => 'ルームリンク';

  @override
  String get connectionUnstable => '接続が不安定です — インターネットを確認してください';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get errorTimeout => '接続がタイムアウトしました。インターネット接続を確認してください。';

  @override
  String get errorNoConnection => 'インターネット接続がありません。';

  @override
  String get errorGeneral => 'エラーが発生しました。もう一度お試しください。';

  @override
  String errorWithMessage(String message) {
    return 'エラー: $message';
  }

  @override
  String get notifChannelMessages => 'メッセージ';

  @override
  String get notifChannelMessagesDesc => '新しいメッセージの通知';

  @override
  String get notifChannelMissedCalls => '不在着信';

  @override
  String get notifChannelMissedCallsDesc => '不在着信の通知';

  @override
  String get notifMissedCall => '不在着信';

  @override
  String get notifAccept => '承認';

  @override
  String get notifDecline => '拒否';

  @override
  String get notifIncomingCall => '着信中';

  @override
  String get notifIncomingCallChannel => '着信中';

  @override
  String get notifMissedCallChannel => '不在着信';

  @override
  String get notifUnknown => '不明';

  @override
  String get effectNone => '背景なし';

  @override
  String get effectBlur => 'ぼかし';

  @override
  String get effectOffice => 'オフィス';

  @override
  String get effectNature => '自然';

  @override
  String get effectGradient => 'グラデーション';

  @override
  String get effectLibrary => '図書館';

  @override
  String get effectCity => '都市';

  @override
  String get effectMinimalism => 'ミニマリズム';

  @override
  String get voiceParticipant => '参加者';

  @override
  String get voiceInvitesToRoom => 'ルームに招待しています';

  @override
  String get voiceRoom => 'ルーム';

  @override
  String get voicePasswordProtected => 'パスワード保護';

  @override
  String get voicePasswordHint => 'パスワード';

  @override
  String get voiceEnter => '入力';

  @override
  String get voiceJoinRoom => 'ルームに参加';

  @override
  String get voiceYourName => 'あなたの名前';

  @override
  String voiceInvitationSent(String name) {
    return '$nameに招待を送りました';
  }

  @override
  String get voiceNoActiveRoom => 'アクティブルームがありません';

  @override
  String get voiceCameraPermission =>
      '設定 → プライバシー → カメラ → TalerIDでカメラアクセスを許可してください';

  @override
  String get voiceOpenSettings => '開く';

  @override
  String voiceCameraError(String error) {
    return 'カメラの有効化に失敗しました: $error';
  }

  @override
  String get voiceAllAgreedRecording => '全員が同意しました。録音を開始します。';

  @override
  String get voiceNewParticipantAgreed => '新しい参加者が録音に同意しました。';

  @override
  String get voiceDeclinedRecording => '録音を拒否しました。通話を終了します。';

  @override
  String get voiceRecordingEnded => '録音が終了しました';

  @override
  String get voiceRecordingInProgress => '録音中';

  @override
  String get voiceTranscriptionRequest => '文字起こしのリクエスト';

  @override
  String get voiceRecordingRequest => '録音のリクエスト';

  @override
  String get voiceAgree => '同意する';

  @override
  String get voiceDeclineAndLeave => '拒否して退出';

  @override
  String get voiceAudioOutput => 'オーディオ出力';

  @override
  String get voiceAudioPhone => '電話';

  @override
  String get voiceAudioSpeaker => 'スピーカー';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'ヘッドフォン';

  @override
  String get voiceLinkCopied => 'リンクをコピーしました';

  @override
  String get voiceTranslateTo => '翻訳先';

  @override
  String get voiceSearchLanguage => '言語を検索...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'ルーム $name';
  }

  @override
  String get voiceVoiceCall => '音声通話';

  @override
  String get voiceOnHold => '保留中';

  @override
  String get voiceActiveCall => '通話中';

  @override
  String get voiceEndAllCalls => 'すべての通話を終了';

  @override
  String get voiceEndThisCall => 'この通話を終了';

  @override
  String get voiceCopyLink => 'リンクをコピー';

  @override
  String get voiceAddParticipant => '参加者を追加';

  @override
  String get voiceReconnecting => '再接続中...';

  @override
  String get voiceConnectionError => '接続エラー';

  @override
  String get voiceClose => '閉じる';

  @override
  String get voiceCalling => '呼び出し中...';

  @override
  String get voiceCallActive => '通話中';

  @override
  String get voiceWaiting => '待機中';

  @override
  String get voiceWaitingUpper => '待機中';

  @override
  String get voiceRec => '録音';

  @override
  String get voiceStop => '停止';

  @override
  String get voiceRecord => '録音';

  @override
  String get voiceTranslation => '翻訳';

  @override
  String get voiceAudio => 'オーディオ';

  @override
  String get voiceFlipCamera => 'カメラを反転';

  @override
  String get voiceBackground => '背景';

  @override
  String get voiceAssistantSpeakingStatus => 'アシスタントが話しています...';

  @override
  String get voiceAssistantListeningStatus => 'アシスタントが聞いています...';

  @override
  String get voiceUnmute => 'ミュート解除';

  @override
  String get voiceMic => 'マイク';

  @override
  String get voiceAssistantLabel => 'アシスタント';

  @override
  String get voiceCameraOn => 'カメラオン';

  @override
  String get voiceCameraLabel => 'カメラ';

  @override
  String get voiceEndCall => '通話終了';

  @override
  String get voiceWaitingParticipants => '参加者を待っています...';

  @override
  String get voiceYou => 'あなた';

  @override
  String get voiceAiAssistant => 'AIアシスタント';

  @override
  String get voiceVideoUnavailable => 'ビデオ利用不可';

  @override
  String get voiceSearchNickname => 'ニックネームで検索...';

  @override
  String get voiceTranscriptionWord => '文字起こし';

  @override
  String get voiceRecordingWord => '録音';

  @override
  String get voiceConnecting => '接続中...';

  @override
  String get voiceVideoBackground => 'ビデオ背景';

  @override
  String get voiceCallSettings => '通話設定';

  @override
  String get voiceEnableAI => 'AIアシスタントを有効にする';

  @override
  String get voiceAIParticipating => 'AIが会話に参加します';

  @override
  String get voiceNormalCall => 'AIなしの通常通話';

  @override
  String get voiceCallConfirm => '通話を開始しますか？';

  @override
  String get chatAlreadyInCall => 'すでに通話中です';

  @override
  String chatCallError(String error) {
    return '通話エラー: $error';
  }

  @override
  String get chatPhotoVideo => '写真 / ビデオ';

  @override
  String get chatCamera => 'カメラ';

  @override
  String get chatFile => 'ファイル';

  @override
  String get chatContact => '連絡先';

  @override
  String get chatSelectContact => '連絡先を選択';

  @override
  String get chatNoContacts => '連絡先なし';

  @override
  String get chatUser => 'ユーザー';

  @override
  String get chatFileAttachment => '📎 ファイル';

  @override
  String chatFileUploadError(String error) {
    return 'ファイルアップロードエラー: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 ボイスメッセージ';

  @override
  String get chatGroup => 'グループ';

  @override
  String get chatDialog => 'ダイアログ';

  @override
  String get chatCall => '通話';

  @override
  String get chatStartConversation => '会話を開始';

  @override
  String get chatYou => 'あなた';

  @override
  String get chatIsTyping => '入力中...';

  @override
  String chatUserIsTyping(String name) {
    return '$nameが入力中...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$namesが入力中...';
  }

  @override
  String get chatPreparingFile => 'ファイルを準備中…';

  @override
  String chatUploading(int progress) {
    return 'アップロード中… $progress%';
  }

  @override
  String get chatEdited => '編集済み';

  @override
  String get chatViaMesh => 'メッシュ経由';

  @override
  String get chatReply => '返信';

  @override
  String get chatEdit => '編集';

  @override
  String get chatCopy => 'コピー';

  @override
  String get chatCopied => 'コピー済み';

  @override
  String get chatSaveMedia => '保存';

  @override
  String get chatForward => '転送';

  @override
  String get chatSaving => '保存中...';

  @override
  String get chatSavedToGallery => 'ギャラリーに保存しました';

  @override
  String get chatNoSavePermission => '保存の権限がありません。設定を確認してください。';

  @override
  String get chatFileSaved => 'File saved';

  @override
  String get chatFileSaveError => 'ファイル保存エラー';

  @override
  String get chatDeleteMessage => 'メッセージを削除';

  @override
  String get chatDeleteForMe => '自分用に削除';

  @override
  String get chatDeleteForEveryone => '全員から削除';

  @override
  String get chatMessageForwarded => 'メッセージを転送しました';

  @override
  String get chatContactTapToOpen => '連絡先 · 開くにはタップ';

  @override
  String get chatForwardTo => '転送先...';

  @override
  String get chatSearchHint => '検索...';

  @override
  String get chatRecording => '録音中...';

  @override
  String get chatMessageHint => 'メッセージ...';

  @override
  String get chatHideKeyboard => 'キーボードを隠す';

  @override
  String get chatEditing => '編集中';

  @override
  String get chatFileDownloadError => 'ファイルダウンロードエラー';

  @override
  String get chatVoiceMessageShort => 'ボイスメッセージ';

  @override
  String get chatVideoSavedToGallery => 'ビデオをギャラリーに保存しました';

  @override
  String get chatSavingError => '保存エラー';

  @override
  String get convSetNickname => 'ニックネームを設定';

  @override
  String get convNicknameRequired =>
      'メッセンジャーを使用するにはニックネームが必要です。他のユーザーはそれであなたを見つけることができます。';

  @override
  String get convNicknameRules => '3–30文字: 英字、数字、_';

  @override
  String get convNicknameTaken => 'ニックネームは既に使用されています';

  @override
  String get convSaveError => '保存エラー';

  @override
  String get convContactsLabel => '連絡先';

  @override
  String get convDefaultUser => 'ユーザー';

  @override
  String get convNoDialogs => '会話がありません';

  @override
  String get convFindUserToChat => 'チャットを始めるユーザーを見つける';

  @override
  String get convDefaultContact => '連絡先';

  @override
  String get dashboardUser => 'ユーザー';

  @override
  String get dashboardIncomingCall => '着信';

  @override
  String get dashboardDecline => '拒否';

  @override
  String get dashboardAccept => '承諾';

  @override
  String get dashboardActiveCall => '通話中 — タップして戻る';

  @override
  String dashboardUpdateAvailable(String version) {
    return '利用可能なアップデート $version';
  }

  @override
  String get dashboardUpdate => 'アップデート';

  @override
  String get dashboardWhatsNew => '新着情報';

  @override
  String dashboardWhatsNewTitle(String version) {
    return '$version の新着情報';
  }

  @override
  String get dashboardInstalling => 'インストール中...';

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
  String get contactRequestsTitle => '連絡先';

  @override
  String get messengerContactRequestsSection => '連絡先リクエスト';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の新しいリクエスト',
      one: '1 件の新しいリクエスト',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => '検索';

  @override
  String get contactRequestsIncoming => '受信';

  @override
  String get contactRequestsSent => '送信済み';

  @override
  String get contactRequestsSearchHint => 'ニックネームまたはメール';

  @override
  String get contactRequestSent => 'リクエスト送信済み';

  @override
  String get contactRequestsNoUsers => 'ユーザーが見つかりません';

  @override
  String get contactRequestsSearchHelp => '正確なニックネームまたはメールを入力し\n検索を押してください';

  @override
  String get contactRequestsSendTooltip => 'リクエストを送信';

  @override
  String get contactRequestTitle => '連絡先リクエスト';

  @override
  String contactRequestConfirm(String name) {
    return '$name に連絡先リクエストを送信しますか？';
  }

  @override
  String get contactRequestSend => '送信';

  @override
  String get contactRequestsNoIncoming => '受信リクエストなし';

  @override
  String get contactRequestsNoSent => '送信済みリクエストなし';

  @override
  String get contactRequestStatusPending => '応答待ち';

  @override
  String get contactRequestStatusAccepted => '承諾済み';

  @override
  String get contactRequestStatusRejected => '拒否済み';

  @override
  String get userSearchTitle => 'ユーザーを探す';

  @override
  String get userSearchHint => 'ニックネーム、電話番号またはメール';

  @override
  String get userSearchHelper => '@ニックネーム、メールまたは名前を入力して検索';

  @override
  String get userSearchNoUsers => 'ユーザーが見つかりません';

  @override
  String get userProfileShareContact => '連絡先を共有';

  @override
  String get userProfileShareContactDesc => '連絡先リンクを送信';

  @override
  String get userProfileCopyLink => 'リンクをコピー';

  @override
  String get userProfileCopied => 'コピーしました';

  @override
  String get userProfileTitle => 'プロフィール';

  @override
  String get userProfileLoadError => 'プロフィール読み込みエラー';

  @override
  String get userProfileMessage => 'メッセージ';

  @override
  String get userProfileCall => '通話';

  @override
  String get userProfileRequestSent => 'リクエスト送信済み';

  @override
  String get userProfileAccept => '承認';

  @override
  String get userProfileDecline => '拒否';

  @override
  String get userProfileAddToContacts => '連絡先に追加';

  @override
  String get userProfileMediaTab => 'メディア';

  @override
  String get userProfileFilesTab => 'ファイル';

  @override
  String get userProfileLinksTab => 'リンク';

  @override
  String get userProfileRecordingsTab => '録音';

  @override
  String get userProfileSummariesTab => '要約';

  @override
  String get userProfileNoMedia => 'メディアファイルなし';

  @override
  String get userProfileNoFiles => 'ファイルなし';

  @override
  String get userProfileNoLinks => 'リンクなし';

  @override
  String get userProfileNoRecordings => '録音なし';

  @override
  String get userProfileNoSummaries => '要約なし';

  @override
  String get userProfileMeetingSummary => '会議の要約';

  @override
  String get userProfileFailedOpenChat => 'チャットを開けませんでした';

  @override
  String get sharedMediaTitle => 'メディアとファイル';

  @override
  String get sharedMediaTab => 'メディア';

  @override
  String get sharedFilesTab => 'ファイル';

  @override
  String get sharedLinksTab => 'リンク';

  @override
  String get sharedNoMedia => 'メディアファイルなし';

  @override
  String get sharedNoFiles => 'ファイルなし';

  @override
  String get sharedNoLinks => 'リンクなし';

  @override
  String get shareToChat => 'チャットに転送';

  @override
  String get shareSelectChat => 'チャットを選択';

  @override
  String get shareNoChats => 'チャットなし';

  @override
  String shareFilesCount(int count) {
    return '$count ファイル';
  }

  @override
  String get contactsTitle => '連絡先';

  @override
  String get contactsAddTooltip => '連絡先を追加';

  @override
  String get contactsSearchHint => '連絡先を検索...';

  @override
  String get contactsNotFound => '見つかりませんでした';

  @override
  String get contactsEmpty => '連絡先なし';

  @override
  String get contactsAdd => '連絡先を追加';

  @override
  String get contactsPendingConfirmation => '確認待ち';

  @override
  String get contactsMessage => 'メッセージ';

  @override
  String get contactsCall => '通話';

  @override
  String get contactsResend => 'リクエストを再送信';

  @override
  String get contactsResendTimeout => '24時間後に再試行';

  @override
  String get contactsResent => 'リクエストを再送信しました';

  @override
  String get contactsWantsToConnect => 'あなたと接続したい';

  @override
  String get contactsSearchPeople => '人を探す';

  @override
  String get notesTitle => 'メモ';

  @override
  String get notesAssistantSpeaking => 'アシスタントが話しています...';

  @override
  String get notesListening => '聞いています...';

  @override
  String get notesEmpty => 'メモなし';

  @override
  String get notesEmptyHint => 'マイクを押して音声入力\nまたは + を押して手動入力';

  @override
  String get notesDeleteConfirm => 'メモを削除しますか？';

  @override
  String get notesNew => '新しいメモ';

  @override
  String get notesEdit => '編集';

  @override
  String get notesTitleHint => 'タイトル';

  @override
  String get notesContentHint => '考えを書いてください...';

  @override
  String get calendarTitle => 'カレンダー';

  @override
  String get calendarStop => '停止';

  @override
  String get calendarVoiceInput => '音声入力';

  @override
  String get calendarNewEvent => '新しいイベント';

  @override
  String get calendarAssistantSpeaking => 'アシスタントが話しています...';

  @override
  String get calendarListening => '聞いています...';

  @override
  String calendarInvitations(int count) {
    return '招待状 ($count)';
  }

  @override
  String get calendarNoEvents => 'イベントなし';

  @override
  String get calendarDayMon => '月';

  @override
  String get calendarDayTue => '火';

  @override
  String get calendarDayWed => '水';

  @override
  String get calendarDayThu => '木';

  @override
  String get calendarDayFri => '金';

  @override
  String get calendarDaySat => '土';

  @override
  String get calendarDaySun => '日';

  @override
  String get calendarEnterRoom => '部屋に入る';

  @override
  String get calendarMeeting => '会議';

  @override
  String calendarLocationPrefix(String location) {
    return '場所: $location';
  }

  @override
  String get calendarEditEvent => '編集';

  @override
  String get calendarTitleHint => 'タイトル';

  @override
  String get calendarDescriptionHint => '説明';

  @override
  String get calendarTypeEvent => 'イベント';

  @override
  String get calendarTypeMeeting => '会議';

  @override
  String get calendarTypeReminder => 'リマインダー';

  @override
  String get calendarTypeLabel => 'タイプ';

  @override
  String get calendarMeetingLink => '会議リンク';

  @override
  String get calendarLocationHint => '場所';

  @override
  String get calendarDateLabel => '日付';

  @override
  String get calendarTimeLabel => '時間';

  @override
  String get calendarReminderLabel => 'リマインダー';

  @override
  String get calendarReminderNone => 'なし';

  @override
  String get calendarReminder15min => '15分前';

  @override
  String get calendarReminder30min => '30分前';

  @override
  String get calendarReminder1hour => '1時間前';

  @override
  String get calendarRepeatLabel => '繰り返し';

  @override
  String get calendarRepeatNone => '繰り返しなし';

  @override
  String get calendarRepeatDaily => '毎日';

  @override
  String get calendarRepeatWeekly => '毎週';

  @override
  String get calendarRepeatMonthly => '毎月';

  @override
  String get calendarRepeatYearly => '毎年';

  @override
  String get calendarParticipants => '参加者';

  @override
  String get calendarAddParticipant => '追加';

  @override
  String get calendarSearchContacts => '連絡先を検索...';

  @override
  String get calendarNoContacts => '連絡先なし';

  @override
  String get calendarStatusAccepted => '承認済み';

  @override
  String get calendarStatusDeclined => '辞退';

  @override
  String get calendarStatusMaybe => '未定';

  @override
  String get calendarStatusPending => '保留中';

  @override
  String get calendarEndTime => '終了時間';

  @override
  String get calendarYourAnswer => 'あなたの回答:';

  @override
  String get calendarOrganizer => '主催者';

  @override
  String calendarDeleteError(String error) {
    return '削除に失敗しました: $error';
  }

  @override
  String get calendarRsvpAccept => '承諾';

  @override
  String get calendarRsvpMaybe => '未定';

  @override
  String get calendarRsvpDecline => '辞退';

  @override
  String get callHistoryTitle => '通話';

  @override
  String get callHistoryTab => '通話履歴';

  @override
  String get callHistoryTempMeeting => '一時会議';

  @override
  String get callHistoryCopy => 'コピー';

  @override
  String get callHistoryLinkCopied => 'リンクをコピーしました';

  @override
  String get callHistoryShare => '共有';

  @override
  String get callHistoryEnter => '参加';

  @override
  String get callHistoryAlreadyInCall => 'すでに通話中です';

  @override
  String get callHistoryCouldNotDeterminePeer => '相手を特定できませんでした';

  @override
  String get callHistoryContacts => '連絡先';

  @override
  String get callHistoryFailedLoadRoom => 'ルームの読み込みに失敗しました';

  @override
  String get callHistoryYourRoom => 'あなたのルーム';

  @override
  String get callHistoryCreateMeeting => '会議を作成';

  @override
  String get callHistoryMeetingSummaries => '会議の要約';

  @override
  String get callHistoryMeetingRecordings => '会議の録音';

  @override
  String get callHistoryNoCalls => '通話なし';

  @override
  String get callHistoryMissed => '不在';

  @override
  String get callHistoryRecording => '録音中';

  @override
  String get callHistorySummary => '要約';

  @override
  String get callHistoryCallAgain => '再度通話';

  @override
  String callHistoryTodayTime(String time) {
    return '今日、$time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return '昨日、$time';
  }

  @override
  String get callHistoryUnknown => '不明';

  @override
  String get callHistoryDetails => '通話の詳細';

  @override
  String get callHistoryOutgoing => '発信通話';

  @override
  String get callHistoryIncoming => '着信通話';

  @override
  String callHistoryDuration(String duration) {
    return '時間: $duration';
  }

  @override
  String get callHistoryWithAI => 'AIアシスタントと';

  @override
  String get callHistoryParticipants => '参加者';

  @override
  String get callDetailYouSuffix => '（あなた）';

  @override
  String get callHistoryMeetingSummary => '会議の要約';

  @override
  String get callHistoryMoreDetails => '詳細';

  @override
  String get callHistorySummaryProcessing => '要約処理中...';

  @override
  String get callHistoryMeetingRecording => '会議の録音';

  @override
  String get callHistoryProcessing => '処理中...';

  @override
  String get callHistoryCreateTranscript => '文字起こしを作成';

  @override
  String get callHistoryNoSummaries => '要約なし';

  @override
  String get callHistoryRecordDuringCall => '通話中に「録音」を押してください';

  @override
  String callHistoryMeetingTime(String time) {
    return '会議 $time';
  }

  @override
  String get callHistoryTranscribing => '文字起こしと要約中...';

  @override
  String get callHistoryTranscriptCreated => '文字起こしが作成されました';

  @override
  String get callHistoryNoRecordings => '録音なし';

  @override
  String callHistoryRecordingDate(String date) {
    return '録音 $date';
  }

  @override
  String get callHistoryRecordingUnavailable => '録音は利用できません';

  @override
  String get callHistoryTranscriptReady => '文字起こしが準備できました';

  @override
  String get callHistoryTranscript => '文字起こし';

  @override
  String get callHistoryKeyPoints => '重要ポイント';

  @override
  String get callHistoryTasks => 'タスク';

  @override
  String callHistoryAssignedTo(String assignee) {
    return '担当者: $assignee';
  }

  @override
  String get callHistoryDecisions => '決定事項';

  @override
  String get callHistoryShowTranscript => '全文を表示';

  @override
  String get profileScanQr => 'QRをスキャン';

  @override
  String get profileMyQrCode => '私のQRコード';

  @override
  String profileAddMeShare(String userId) {
    return 'Taler IDで私を追加してください！\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'このコードを見せて追加';

  @override
  String get profileEditDesc => '名前、姓、父称、生年月日';

  @override
  String get profileAboutMe => '私について';

  @override
  String get profileAboutMeDesc => '価値観、スキル、興味など';

  @override
  String get profileNotes => 'メモ';

  @override
  String get profileNotesDesc => '考え、アイデア、メモ';

  @override
  String get profileAvatarUpdated => 'アバターが更新されました';

  @override
  String get profileNickname => 'ニックネーム';

  @override
  String get profileNotSet => '未設定';

  @override
  String get profileChangeNickname => 'ニックネームを変更';

  @override
  String get profileNicknameUpdated => 'ニックネームが更新されました';

  @override
  String get profileShareLabel => '共有';

  @override
  String get profileScanQrCode => 'QRコードをスキャン';

  @override
  String get profilePointCamera => 'カメラをQRコードに向ける';

  @override
  String get profilePhotoCamera => '写真を撮る';

  @override
  String get profilePhotoGallery => 'ギャラリーから選択';

  @override
  String get editProfilePatronymic => '父称（任意）';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => '私について';

  @override
  String get aboutMeClickToFill => 'クリックして入力';

  @override
  String get aboutMeCoreValues => '価値観';

  @override
  String get aboutMeWorldview => '世界観';

  @override
  String get aboutMeSkills => 'スキル';

  @override
  String get aboutMeInterests => '興味';

  @override
  String get aboutMeDesires => '願望';

  @override
  String get aboutMeBackground => 'プロフィール';

  @override
  String get aboutMeLikes => '好きなもの';

  @override
  String get aboutMeDislikes => '嫌いなもの';

  @override
  String get aboutMeDeleteSection => 'セクションを削除しますか？';

  @override
  String get aboutMeDeleteConfirm => 'このセクションのすべてのデータが削除されます。';

  @override
  String aboutMeConnectionError(String error) {
    return '接続エラー: $error';
  }

  @override
  String get aboutMeVisibility => '可視性';

  @override
  String get aboutMeTags => 'タグ';

  @override
  String get aboutMeAddTag => 'タグを追加...';

  @override
  String get aboutMeDescription => '説明';

  @override
  String get aboutMeDescribeLong => 'もっと教えてください...';

  @override
  String get aboutMeVisibilityEveryone => '全員';

  @override
  String get aboutMeVisibilityContacts => '連絡先';

  @override
  String get aboutMeVisibilityOnlyMe => '自分のみ';

  @override
  String get settingsProfileSubtitle => 'プロフィール';

  @override
  String get settingsWallpaper => '壁紙';

  @override
  String get settingsWallpaperDesc => 'アプリ全体の背景画像';

  @override
  String get settingsWallpaperNone => 'なし';

  @override
  String get settingsAccount => 'アカウント';

  @override
  String get settingsKycVerification => '本人確認 (KYC)';

  @override
  String get settingsOrganizations => '組織';

  @override
  String get incomingCallLabel => '着信';

  @override
  String get incomingCallDecline => '拒否';

  @override
  String get incomingCallAccept => '応答';

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
  String get meshIncomingCallLabel => '📡 メッシュ着信';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'メッシュデバイス $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => '現在の通話を終了してください';

  @override
  String get callPopupTransportTitle => '通話方法';

  @override
  String get callPopupTransportMesh => '📡 メッシュ (ピアツーピア)';

  @override
  String get callPopupTransportLk => '📞 サーバー';

  @override
  String get callPopupTransportMeshUnavailable => 'メッシュで連絡先に接続できません';

  @override
  String get meshOnboardingTitle => '📡 メッシュ通話にはアプリを開いておく必要があります';

  @override
  String get meshOnboardingBody =>
      '電話がロックされていると、メッシュ通話は約30秒後に切れることがあります（iOSの制限）。';

  @override
  String get meshOnboardingAck => '了解';

  @override
  String get meshHistoryBadge => '📡 メッシュ';

  @override
  String get meshHistoryNoChatAvailable => '連絡先がリストにありません';

  @override
  String get meshCallStatusInviting => '呼び出し中…';

  @override
  String get meshCallStatusConnecting => '接続中…';

  @override
  String get meshCallEndedUserHangup => '通話終了';

  @override
  String get meshCallEndedRemoteHangup => '相手が終了';

  @override
  String get meshCallEndedRejected => '拒否されました';

  @override
  String get meshCallEndedNoAnswer => '応答なし';

  @override
  String get meshCallEndedConnectionLost => '接続が切れました';

  @override
  String get meshCallEndedError => '接続エラー';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 メッシュ · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 メッシュ';

  @override
  String get batteryExemptionTitle => '📡 信頼性の高いメッシュ通話';

  @override
  String get batteryExemptionBody =>
      'アプリがバッテリー制限なしで動作することを許可し、Androidがバックグラウンドでメッシュを停止しないようにします。';

  @override
  String get batteryExemptionAccept => '設定を開く';

  @override
  String get batteryExemptionDismiss => '今はしない';

  @override
  String get groupCamera => 'カメラ';

  @override
  String get groupGallery => 'ギャラリー';

  @override
  String get groupAvatarUpdated => 'グループアバターが更新されました';

  @override
  String get groupNameTitle => 'グループ名';

  @override
  String get groupEnterName => '名前を入力';

  @override
  String get groupDescriptionTitle => 'グループの説明';

  @override
  String get groupEnterDescription => 'グループの説明を入力';

  @override
  String get groupChangeRoleTitle => '役割を変更';

  @override
  String get groupRemoveMemberTitle => 'メンバーを削除';

  @override
  String get groupDescription => '説明';

  @override
  String get groupAddDescription => 'グループの説明を追加';

  @override
  String get groupNoDescription => '説明なし';

  @override
  String get groupMediaAndFiles => 'メディアとファイル';

  @override
  String get groupMuteNotifications => '通知をミュート';

  @override
  String get groupMuted => 'ミュート中';

  @override
  String get groupNoResults => '結果なし';

  @override
  String get authInvalidCode => '無効なコードです。もう一度お試しください。';

  @override
  String get loginSubtitle => 'メールとパスワードを使用';

  @override
  String get emailRequired => 'メールを入力';

  @override
  String get emailInvalid => '無効なメール';

  @override
  String get passwordRequired => 'パスワードを入力';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'Talerエコシステム全体で1つのアカウント';

  @override
  String get usernameOptional => 'ユーザー名（任意）';

  @override
  String get usernameMinLength => '最低3文字';

  @override
  String get usernameMaxLength => '最大30文字';

  @override
  String get usernameInvalid => '文字、数字、_ のみ';

  @override
  String get biometricLoginReason => 'Taler IDにサインイン';

  @override
  String get docTypePassport => 'パスポート';

  @override
  String get docTypeIdCard => 'IDカード';

  @override
  String get docTypeDriverLicense => '運転免許証';

  @override
  String get docTypeResidencePermit => '居住許可証';

  @override
  String addressApartment(String number) {
    return 'アパート $number';
  }

  @override
  String get failedToUpdateProfile => 'プロフィールの更新に失敗しました';

  @override
  String get failedToStartKyb => 'KYB認証の開始に失敗しました';

  @override
  String get orgUpdated => '組織が更新されました';

  @override
  String get failedToUpdateOrg => '組織の更新に失敗しました';

  @override
  String get failedToChangeRole => '役割の変更に失敗しました';

  @override
  String get failedToRemoveMember => 'メンバーの削除に失敗しました';

  @override
  String get capabilityMessagesTitle => 'メッセージ';

  @override
  String get capabilityMessagesDesc =>
      'メッセージを確認したり、誰かに書いたりします。例：「ヴィクトルに書く：1時間後に到着します」';

  @override
  String get capabilityCallsTitle => '通話';

  @override
  String get capabilityCallsDesc => '任意の連絡先に音声で電話します。例：「ヴィクトル・ヴィクトロフに電話する」';

  @override
  String get capabilityChatTitle => 'チャット履歴';

  @override
  String get capabilityChatDesc => 'チャット履歴を分析します。例えば：「ヴィクトルと何を話しましたか？」';

  @override
  String get capabilityProfileTitle => 'プロフィール';

  @override
  String get capabilityProfileDesc => 'プロフィールを表示または更新します。例えば：「私のプロフィールを見せて」';

  @override
  String get capabilityCoachingTitle => 'コーチング';

  @override
  String get capabilityCoachingDesc =>
      'モード: ICFコーチング、心理学者、HR相談。例えば：「コーチングを始めよう」';

  @override
  String get capabilityCalendarTitle => 'カレンダー';

  @override
  String get capabilityCalendarDesc =>
      '会議をスケジュールしたり、リマインダーを設定します。例えば：「明日15:00にヴィクトルと会議をスケジュール」';

  @override
  String get capabilityNotesTitle => 'メモ';

  @override
  String get capabilityNotesDesc =>
      '考えを保存したり、最近のメモを読みます。例えば：「アイデアを書き留めて...」または「最近のメモを読む」';

  @override
  String get assistantCallConfirm => '通話をかけますか？';

  @override
  String get callNoAnswer => '応答なし';

  @override
  String get contactDelete => '連絡先を削除';

  @override
  String get contactDeleteTitle => '連絡先を削除';

  @override
  String get contactDeleteConfirm => 'よろしいですか？この連絡先は削除されます。';

  @override
  String get contactBlock => 'ブロック';

  @override
  String get contactBlockTitle => 'ユーザーをブロック';

  @override
  String get contactBlockConfirm => 'このユーザーはメッセージや通話ができなくなります。';

  @override
  String get contactUnblock => 'ブロック解除';

  @override
  String get contactBlocked => 'ブロック済み';

  @override
  String get contactYouAreBlocked => 'このユーザーにブロックされています';

  @override
  String get chatBlockedByYou => 'このユーザーをブロックしました';

  @override
  String get chatYouAreBlocked => 'このユーザーにブロックされています';

  @override
  String get chatNotContacts => 'メッセージを送るにはこのユーザーを連絡先に追加してください';

  @override
  String get contactRevokeRequest => 'リクエストを取り消す';

  @override
  String get messengerPoll => '投票';

  @override
  String get messengerCreatePoll => '投票を作成';

  @override
  String get messengerPollQuestion => '質問';

  @override
  String messengerPollOption(int number) {
    return 'オプション $number';
  }

  @override
  String get messengerPollAddOption => 'オプションを追加';

  @override
  String get messengerPollAnonymous => '匿名投票';

  @override
  String get messengerPollMultiple => '複数選択';

  @override
  String get messengerPollCreateError => '投票の作成に失敗しました';

  @override
  String get messengerPollUnavailable => '投票は利用できません';

  @override
  String get messengerPollMultipleNote => '複数選択が可能です';

  @override
  String messengerPollVotes(int count) {
    return '$count 票';
  }

  @override
  String get messengerVideoMessage => 'ビデオメッセージ';

  @override
  String get messengerVideoRecordError => 'ビデオ録画エラー';

  @override
  String get messengerVideoPlaybackError => 'ビデオを再生できませんでした';

  @override
  String get messengerGalleryAccessError => 'ギャラリーへのアクセスがありません';

  @override
  String get messengerSearchInChat => 'チャット内を検索...';

  @override
  String get messengerSaveToFavorites => 'お気に入りに保存';

  @override
  String get messengerSavedToFavorites => 'お気に入りに保存しました';

  @override
  String get messengerSearchInMessages => 'メッセージ内を検索...';

  @override
  String messengerFoundInMessages(int count) {
    return 'メッセージ内で見つかりました ($count)';
  }

  @override
  String get messengerGroupDefault => 'グループ';

  @override
  String get messengerUserDefault => 'ユーザー';

  @override
  String get messengerPin => 'ピン留め';

  @override
  String get messengerUnpin => 'ピン留め解除';

  @override
  String get messengerArchive => 'アーカイブ';

  @override
  String get messengerUnarchive => 'アーカイブ解除';

  @override
  String get messengerDeleteChat => 'チャットを削除';

  @override
  String get messengerDeleteChatTitle => 'チャットを削除しますか？';

  @override
  String messengerDeleteChatConfirm(String name) {
    return '$nameとのチャットを削除しますか？この操作は元に戻せません。';
  }

  @override
  String get messengerCreateChannel => 'チャンネルを作成';

  @override
  String get messengerChannelName => '名前';

  @override
  String get messengerChannelDescription => '説明（任意）';

  @override
  String get messengerChannelCreateError => 'チャンネルの作成に失敗しました';

  @override
  String get messengerFilterAll => 'すべて';

  @override
  String get messengerFilterUnread => '未読';

  @override
  String get messengerFilterPersonal => '個人';

  @override
  String get messengerFilterGroups => 'グループ';

  @override
  String get messengerFilterChannels => 'チャンネル';

  @override
  String get messengerArchivedSection => 'アーカイブ済み';

  @override
  String get messengerSavedSection => 'お気に入り';

  @override
  String get messengerSavedSubtitle => 'メモリに保存';

  @override
  String messengerArchiveTitle(int count) {
    return 'アーカイブ ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'アーカイブは空です';

  @override
  String messengerYouPrefix(String message) {
    return 'あなた: $message';
  }

  @override
  String get messengerMissedCall => '不在着信';

  @override
  String get messengerSavedTitle => 'お気に入り';

  @override
  String get messengerNoSavedMessages => '保存されたメッセージはありません';

  @override
  String get messengerSavedHint => 'メッセージを長押し → 「お気に入りに保存」';

  @override
  String get messengerDefaultFile => 'ファイル';

  @override
  String get messengerTopicDefault => '一般';

  @override
  String get messengerTopicNew => '新しいトピック';

  @override
  String get messengerTopicNameHint => 'トピック名';

  @override
  String get messengerTopicIcon => 'アイコン';

  @override
  String messengerTopicCount(int count) {
    return '$count トピック';
  }

  @override
  String get messengerNoTopics => 'トピックがありません';

  @override
  String get messengerNoMessages => 'メッセージなし';

  @override
  String get you => 'あなた';

  @override
  String get messengerThread => 'スレッド';

  @override
  String get messengerThreadReply => '返信';

  @override
  String get messengerThreadReplies => '返信';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => '返信なし';

  @override
  String get messengerReplyHint => 'スレッドに返信...';

  @override
  String get messengerContactName => '連絡先名';

  @override
  String messengerOriginalName(String name) {
    return '元の名前: $name';
  }

  @override
  String get messengerDisplayName => '表示名';

  @override
  String messengerShareContact(String name) {
    return 'Taler IDの連絡先: $name';
  }

  @override
  String get messengerAutoDelete => 'メッセージを自動削除';

  @override
  String get messengerAutoDeleteOff => 'オフ';

  @override
  String get messengerAutoDelete7d => '7日';

  @override
  String get messengerAutoDelete30d => '30日';

  @override
  String get messengerAutoDelete90d => '90日';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count 日';
  }

  @override
  String get messengerSettingsHeader => '設定';

  @override
  String get messengerAdminOnly => '管理者のみ投稿';

  @override
  String get messengerAdminOnlyDesc => 'メンバーは読むだけ';

  @override
  String get messengerTopics => 'トピック';

  @override
  String get messengerTopicsDesc => 'チャットをトピックに分割';

  @override
  String get aiTwinSection => 'AIボイスタイン';

  @override
  String get aiTwinEnabled => 'AIタインを有効にする';

  @override
  String get aiTwinEnabledDesc => '応答しない場合、AIタインがあなたの声で応答します';

  @override
  String get aiTwinTimeout => '応答タイムアウト';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get aiTwinPrompt => 'AIの指示';

  @override
  String get aiTwinPromptSubtitle => 'AIタインがどのように自己紹介し、何を話すべきか';

  @override
  String aiTwinPromptHint(String name) {
    return 'こんにちは、こちらは$nameのAIボイスタインです。$nameは今出られません。どなたが何の用件でお電話されたか教えてください。伝えておきます。';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'カスタムボイスクローンは近日公開予定です。現在はAIが$nameの声で話します。';
  }

  @override
  String get aiTwinDefaultName => '所有者';

  @override
  String get aiTwinPromptReset => 'リセット';

  @override
  String get callHistoryAiTwinAnswered => 'AIタインが応答';

  @override
  String get callHistoryAiTwinSummary => '通話概要';

  @override
  String get callHistoryAiTwinTranscript => '文字起こし';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return '$nameから';
  }

  @override
  String get aiTwinOfferTitle => '応答なし';

  @override
  String aiTwinOfferBody(String name) {
    return '$nameが応答しません。AIボイスツインでメッセージを残しますか？';
  }

  @override
  String get aiTwinOfferBodyUser => 'ユーザー';

  @override
  String get aiTwinOfferAccept => 'はい、メッセージを残す';

  @override
  String get aiTwinOfferKeepWaiting => '待ち続ける';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'あなたのAI代理';

  @override
  String get aiTwinHeroSubtitle => '応答できないときにあなたの声で電話に出ます。';

  @override
  String get aiTwinProfileTitle => 'AI代理';

  @override
  String get aiTwinProfileDesc => 'あなたの声で電話に出ます';

  @override
  String get aiTwinBadgeOn => 'オン';

  @override
  String get aiAnalystTitle => 'AIアナリスト';

  @override
  String get aiAnalystSubtitle => 'ファイル、タスク、分析 — Claude';

  @override
  String get channelsDiscover => 'チャンネルを探す';

  @override
  String get channelsSearchHint => 'チャンネルを検索';

  @override
  String get channelsSubscribers => '登録者';

  @override
  String get channelsSubscribe => '登録する';

  @override
  String get channelsUnsubscribe => '登録解除';

  @override
  String get channelsSubscribedLabel => '登録済み';

  @override
  String get channelsSettings => 'チャンネル設定';

  @override
  String get channelsDelete => 'チャンネルを削除';

  @override
  String get channelsDeleteConfirm => 'チャンネルを完全に削除しますか？';

  @override
  String get channelsEmpty => 'まだチャンネルがありません';

  @override
  String get channelsOpen => '開く';

  @override
  String get channelsNameLabel => '名前';

  @override
  String get channelsDescriptionLabel => '説明';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'オーナーは登録解除できません。代わりにチャンネルを削除してください。';

  @override
  String get channelsNotFoundRedirect => 'チャンネルは存在しません';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 検索',
      one: '$count 検索',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ファイル',
      one: '$count ファイル',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count コマンド',
      one: '$count コマンド',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 画像',
      one: '$count 画像',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ステップ',
      one: '$count ステップ',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get savedTitle => '保存されたメッセージ';

  @override
  String get savedSubtitle => 'あなたのプライベートクラウド';

  @override
  String get savedOpenError => '保存されたメッセージを開けませんでした';

  @override
  String get billingWalletTitle => 'ウォレット';

  @override
  String get billingBuyPackage => 'パッケージを購入';

  @override
  String get billingCurrentBalance => '現在の残高';

  @override
  String get billingPackagesTitle => 'パッケージ';

  @override
  String get billingPackagesUnavailable => 'パッケージが利用できません';

  @override
  String get billingRecentOperations => '最近の操作';

  @override
  String get billingAllOperations => 'すべての操作';

  @override
  String get billingNoOperations => '操作なし';

  @override
  String get billingOperationsTitle => '操作';

  @override
  String get billingOperationsEmptyTitle => 'まだ操作がありません';

  @override
  String get billingOperationsEmptySubtitle => 'AI機能のチャージとトップアップがここに表示されます';

  @override
  String get billingPricebookTitle => '機能の価格';

  @override
  String get billingPricebookUnavailable => '価格表が利用できません';

  @override
  String get billingAiFeaturesTitle => 'AI機能';

  @override
  String get billingInsufficientFundsTitle => '残高不足';

  @override
  String get billingInsufficientFundsSubtitle => 'この機能を使用するには残高をチャージしてください。';

  @override
  String billingRequiredLine(String required) {
    return '必要: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return '保有: $available μTAL';
  }

  @override
  String get billingTopUp => 'チャージ';

  @override
  String get billingCancel => 'キャンセル';

  @override
  String get billingRetry => '再試行';

  @override
  String billingLowBalanceWarning(String balance) {
    return '残高が少なくなっています: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'ウォレットと残高';

  @override
  String get billingSectionHeader => '請求とAI';

  @override
  String get billingFeatureVoiceAssistant => '音声アシスタント';

  @override
  String get billingFeatureWebSearch => 'アシスタントのウェブ検索';

  @override
  String get billingFeatureAiTwin => 'ボイスツイン';

  @override
  String get billingFeatureAiTwinLong => 'ボイスツイン (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'アウトバウンドボット';

  @override
  String get billingFeatureOutboundCallLong => 'アウトバウンドコールボット';

  @override
  String get billingFeatureWhisperTranscribe => '通話の文字起こし';

  @override
  String get billingFeatureMeetingSummary => 'AI通話要約';

  @override
  String get billingConfigureAiTwin => 'AIツインを設定';

  @override
  String get billingWebSearchSubtitle => '（アシスタントが使用）';

  @override
  String billingPackagePurchased(String balance) {
    return 'パッケージ購入済み: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'おすすめ';

  @override
  String get billingSessionTerminatedNoFunds => '残高がなくなりました — セッション終了';

  @override
  String get billingSessionTerminatedGeneric => 'アシスタントセッション終了';

  @override
  String billingBuyForPrice(String price) {
    return '€$priceで購入';
  }

  @override
  String get billingTxTypeTopup => 'チャージ';

  @override
  String get billingTxTypeRefund => '返金';

  @override
  String get billingTxTypeSpend => '課金';

  @override
  String get billingUnitMinute => '分';

  @override
  String get billingUnitRequest => 'リクエスト';

  @override
  String get billingUnitToken => 'トークン';

  @override
  String get billingUnitTokens1k => '1Kトークン';

  @override
  String get billingUnitCall => '通話';

  @override
  String get groupCallSelectParticipants => '参加者を選択';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => '検索';

  @override
  String get groupCallMaxReached => '最大7人の参加者';

  @override
  String get groupCallLobbyTitle => 'グループ • ロビー';

  @override
  String groupCallHostLabel(String name) {
    return 'ホスト: $name';
  }

  @override
  String get groupCallMicHint => '接続時にマイクが有効になります';

  @override
  String get groupCallCancel => 'キャンセル';

  @override
  String get groupCallNoAnswer => '誰も応答しませんでした';

  @override
  String get groupCallEndedByHost => 'ホストが通話を終了しました';

  @override
  String get groupCallAllLeft => '全員が通話を離れました';

  @override
  String get groupCallEnded => '通話が終了しました';

  @override
  String groupCallActiveTitle(int count) {
    return 'グループ • $count';
  }

  @override
  String get groupCallConnectionLost => '接続が失われました';

  @override
  String get groupCallMuteRequested => 'ホストが全員にミュートを依頼しました';

  @override
  String get groupCallUnmute => 'ミュート解除';

  @override
  String get groupCallMute => 'ミュート';

  @override
  String get groupCallMuteAll => '全員をミュート';

  @override
  String get groupCallLeave => '退出';

  @override
  String get groupCallStatusCalling => '呼び出し中…';

  @override
  String get groupCallStatusDeclined => '拒否されました';

  @override
  String get groupCallStatusTimeout => '応答なし';

  @override
  String get groupCallStatusLeft => '退出しました';

  @override
  String groupCallKickConfirm(String name) {
    return '$nameを通話から削除';
  }

  @override
  String get groupCallCancelAction => 'キャンセル';

  @override
  String get groupCallActiveBanner => '通話中';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'グループ: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'グループ: $host';
  }

  @override
  String get groupCallCreateError => '通話を作成できませんでした';

  @override
  String get groupCallJoinError => '通話に参加できませんでした';

  @override
  String get groupCallLivekitError => 'LiveKitエラー';

  @override
  String get groupCallDone => '完了';

  @override
  String get groupCallNoResults => '結果がありません';

  @override
  String get groupCallNoContacts => '連絡先がありません';

  @override
  String get meshGcContactOffline => 'このWi-Fiに接続していません';

  @override
  String get meshGcOnlineViaMesh => 'メッシュ経由でオンライン';

  @override
  String get meshGcMaxInvitees => 'グループ通話は最大4人の招待者をサポートします（合計5人）。';

  @override
  String get meshGcStart => 'グループ通話を開始';

  @override
  String get meshGcCancel => 'キャンセル';

  @override
  String get meshGcStatusCalling => '呼び出し中…';

  @override
  String get meshGcStatusJoined => '参加済み';

  @override
  String get meshGcStatusDeclined => '拒否されました';

  @override
  String get meshGcStatusNoAnswer => '応答なし';

  @override
  String get meshGcStatusConnectionFailed => '接続失敗';

  @override
  String get meshGcStatusLeft => '退出しました';

  @override
  String get meshGcTopTitle => 'メッシュ';

  @override
  String get meshGcBusyOneOnOne => '現在の通話を終了してください。';

  @override
  String get presenceOnline => 'オンライン';

  @override
  String get presenceLastSeenJustNow => 'たった今オンライン';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return '$minutes分前にオンライン';
  }

  @override
  String presenceLastSeenToday(String time) {
    return '今日 $time にオンライン';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return '昨日 $time にオンライン';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return '$date にオンライン';
  }

  @override
  String get presenceLastSeenRecently => '最近オンライン';

  @override
  String get privacySectionTitle => 'プライバシー';

  @override
  String get privacyLastSeenLabel => '最後にオンラインだった時間を誰が見れるか';

  @override
  String get privacyEveryone => '全員';

  @override
  String get privacyContacts => '連絡先のみ';

  @override
  String get privacyNobody => '誰も見れない';

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
}
