// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Taler ID';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get appSubtitle => 'Danh tính hệ sinh thái hợp nhất';

  @override
  String get login => 'Đăng nhập';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String get register => 'Tạo tài khoản';

  @override
  String get registerButton => 'Tạo tài khoản';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get firstName => 'Tên';

  @override
  String get lastName => 'Họ';

  @override
  String get noAccount => 'Chưa có tài khoản?';

  @override
  String get createOne => 'Tạo một tài khoản';

  @override
  String get haveAccount => 'Đã có tài khoản?';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get passwordMinLength => 'Tối thiểu 8 ký tự';

  @override
  String get invalidEmail => 'Nhập email hợp lệ';

  @override
  String get fieldRequired => 'Trường bắt buộc';

  @override
  String get twoFATitle => 'Xác thực hai yếu tố';

  @override
  String get twoFASubtitle => 'Nhập mã 6 chữ số từ ứng dụng xác thực của bạn';

  @override
  String get twoFACode => 'Mã 2FA';

  @override
  String get verify => 'Xác minh';

  @override
  String get tabProfile => 'Hồ sơ';

  @override
  String get tabKyc => 'KYC';

  @override
  String get tabOrganization => 'Tổ chức';

  @override
  String get tabSettings => 'Cài đặt';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get editProfile => 'Chỉnh sửa hồ sơ';

  @override
  String get phone => 'Điện thoại';

  @override
  String get country => 'Quốc gia';

  @override
  String get dateOfBirth => 'Ngày sinh';

  @override
  String get documents => 'Tài liệu';

  @override
  String get addDocument => 'Thêm tài liệu';

  @override
  String get noDocuments => 'Chưa tải lên tài liệu nào';

  @override
  String get save => 'Lưu';

  @override
  String get profileUpdated => 'Hồ sơ đã được cập nhật';

  @override
  String get personalData => 'Dữ liệu cá nhân';

  @override
  String get passport => 'Hộ chiếu';

  @override
  String get drivingLicense => 'Giấy phép lái xe';

  @override
  String get diploma => 'Bằng cấp';

  @override
  String get nationalId => 'CMND';

  @override
  String get certificate => 'Chứng chỉ';

  @override
  String get notSpecified => 'Chưa xác định';

  @override
  String get notSpecifiedFemale => 'Chưa xác định';

  @override
  String get documentType => 'Loại tài liệu';

  @override
  String get passportId => 'Hộ chiếu / CMND';

  @override
  String get diplomaCertificate => 'Bằng cấp / Chứng chỉ';

  @override
  String get loadError => 'Lỗi tải';

  @override
  String get verification => 'Xác minh';

  @override
  String get countryAustria => 'Áo';

  @override
  String get countryGermany => 'Đức';

  @override
  String get countryRussia => 'Nga';

  @override
  String get countryUkraine => 'Ukraine';

  @override
  String get countryKazakhstan => 'Kazakhstan';

  @override
  String get countryBelarus => 'Belarus';

  @override
  String get countryOther => 'Khác';

  @override
  String get kycTitle => 'Xác minh KYC';

  @override
  String get kycVerified => 'Đã xác minh';

  @override
  String get kycPending => 'Đang chờ';

  @override
  String get kycRejected => 'Bị từ chối';

  @override
  String get kycUnverified => 'Chưa xác minh';

  @override
  String get kycVerifiedDesc =>
      'Danh tính của bạn đã được xác minh. Bạn có quyền truy cập đầy đủ vào tất cả các tính năng của hệ sinh thái Taler.';

  @override
  String get kycPendingDesc =>
      'Tài liệu của bạn đang được xem xét. Thường mất 1-2 ngày làm việc.';

  @override
  String get kycRejectedDesc =>
      'Xác minh thất bại. Vui lòng xem lại lý do và gửi lại tài liệu của bạn.';

  @override
  String get kycUnverifiedDesc =>
      'Hoàn thành xác minh để mở khóa quyền truy cập đầy đủ vào các tính năng tài chính của hệ sinh thái Taler.';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get kycInProgress => 'In progress';

  @override
  String get kycInProgressDesc =>
      'You started verification but didn\'t finish it. Pick up right where you left off.';

  @override
  String get startVerification => 'Bắt đầu xác minh';

  @override
  String get retryVerification => 'Thử lại xác minh';

  @override
  String verifiedAt(String date) {
    return 'Đã xác minh: $date';
  }

  @override
  String get documentsSubmitted => 'Tài liệu đã gửi để xem xét';

  @override
  String get documentsSubmittedDesc =>
      'Thường mất 1-2 ngày làm việc để xem xét. Bạn sẽ nhận được thông báo đẩy với kết quả.';

  @override
  String get securityAes => 'Dữ liệu của bạn được bảo vệ bằng mã hóa AES-256';

  @override
  String get verificationTime => 'Xác minh mất 1-2 ngày làm việc';

  @override
  String get pushNotification => 'Bạn sẽ nhận được thông báo đẩy với kết quả';

  @override
  String get kycWebOnly => 'Xác minh KYC chỉ có sẵn trong ứng dụng di động.';

  @override
  String verificationError(String code) {
    return 'Lỗi xác minh: $code';
  }

  @override
  String get organizations => 'Tổ chức';

  @override
  String get noOrganizations => 'Không có tổ chức';

  @override
  String get noOrganizationsDesc => 'Tạo một tổ chức hoặc chấp nhận lời mời';

  @override
  String get createOrganization => 'Tạo tổ chức';

  @override
  String get newOrganization => 'Tổ chức mới';

  @override
  String get orgName => 'Tên *';

  @override
  String get orgDescription => 'Mô tả';

  @override
  String get orgEmail => 'Email liên hệ';

  @override
  String get orgWebsite => 'Trang web';

  @override
  String get orgLegalAddress => 'Địa chỉ pháp lý';

  @override
  String get create => 'Tạo';

  @override
  String get organization => 'Tổ chức';

  @override
  String get contacts => 'Liên hệ';

  @override
  String members(int count) {
    return 'Thành viên ($count)';
  }

  @override
  String get inviteMember => 'Mời thành viên';

  @override
  String get invite => 'Mời';

  @override
  String get sendInvite => 'Gửi lời mời';

  @override
  String inviteSent(String email) {
    return 'Đã gửi lời mời đến $email';
  }

  @override
  String get role => 'Vai trò';

  @override
  String get roleOwner => 'Chủ sở hữu';

  @override
  String get roleAdmin => 'Quản trị viên';

  @override
  String get roleOperator => 'Người vận hành';

  @override
  String get roleViewer => 'Người xem';

  @override
  String get editOrganization => 'Chỉnh sửa';

  @override
  String get editOrganizationTitle => 'Chỉnh sửa tổ chức';

  @override
  String get removeMember => 'Xóa thành viên';

  @override
  String removeMemberConfirm(String name) {
    return 'Xóa $name khỏi tổ chức?';
  }

  @override
  String get memberRemoved => 'Đã xóa thành viên';

  @override
  String get roleChanged => 'Đã thay đổi vai trò';

  @override
  String get kybVerified => 'Đã xác minh';

  @override
  String get kybPending => 'Đang chờ xử lý';

  @override
  String get kybRejected => 'Bị từ chối';

  @override
  String get kybNone => 'Chưa xác minh';

  @override
  String get kybVerification => 'Bắt đầu xác minh KYB';

  @override
  String get kybStartBusiness => 'Bắt đầu xác minh doanh nghiệp';

  @override
  String get kybStatusLabel => 'Trạng thái KYB';

  @override
  String get noKyb => 'Không có KYB';

  @override
  String get kybBusinessVerificationTitle => 'Xác minh doanh nghiệp (KYB)';

  @override
  String get kybVerifiedOrgDesc => 'Tổ chức đã được xác minh thành công.';

  @override
  String get kybPendingOrgDesc =>
      'Tài liệu đang được xem xét. Thường mất 1-3 ngày làm việc.';

  @override
  String get kybRejectedOrgDesc => 'Xác minh thất bại. Vui lòng thử lại.';

  @override
  String get kybNoneOrgDesc =>
      'Xác minh tổ chức của bạn để truy cập các tính năng doanh nghiệp.';

  @override
  String get invitePlus => '+ Mời';

  @override
  String get kybVerificationTitle => 'Xác minh KYB';

  @override
  String get kybWebOnlyBusiness =>
      'Xác minh KYB chỉ có sẵn trong ứng dụng di động.';

  @override
  String get unknownDevice => 'Thiết bị không xác định';

  @override
  String get ipUnknown => 'IP không xác định';

  @override
  String get currentSessionLabel => 'Hiện tại';

  @override
  String get endSessionAction => 'Kết thúc';

  @override
  String get deviceLoggedOut => 'Thiết bị sẽ bị đăng xuất.';

  @override
  String get acceptInvitationTitle => 'Lời mời tham gia tổ chức';

  @override
  String get acceptInvitation => 'Chấp nhận lời mời';

  @override
  String get acceptInvitationDesc =>
      'Bạn đã được mời tham gia một tổ chức trong hệ sinh thái Taler.';

  @override
  String get accept => 'Chấp nhận';

  @override
  String get reject => 'Từ chối';

  @override
  String get sessions => 'Phiên hoạt động';

  @override
  String get currentSession => 'Phiên hiện tại';

  @override
  String get deleteSession => 'Kết thúc phiên';

  @override
  String get deleteSessionConfirm => 'Kết thúc phiên này?';

  @override
  String get sessionDeleted => 'Phiên đã kết thúc';

  @override
  String get noSessions => 'Không có phiên hoạt động';

  @override
  String minutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String hoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String daysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String get justNow => 'Vừa xong';

  @override
  String get settings => 'Cài đặt';

  @override
  String get security => 'Bảo mật';

  @override
  String get biometrics => 'Sinh trắc học';

  @override
  String get biometricsDesc => 'Đăng nhập nhanh bằng Face ID hoặc vân tay';

  @override
  String get biometricsConfirm =>
      'Xác nhận sinh trắc học để bật đăng nhập nhanh';

  @override
  String get biometricsError =>
      'Không thể bật sinh trắc học. Kiểm tra cài đặt thiết bị.';

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get twoFactorAuth => 'Xác thực hai yếu tố';

  @override
  String get currentPassword => 'Mật khẩu hiện tại';

  @override
  String get newPassword => 'Mật khẩu mới';

  @override
  String get confirmNewPassword => 'Xác nhận mật khẩu mới';

  @override
  String get passwordChanged => 'Mật khẩu đã được thay đổi';

  @override
  String get wrongCurrentPassword => 'Mật khẩu hiện tại không đúng';

  @override
  String get passwordTooWeak =>
      'Mật khẩu quá yếu: ít nhất 8 ký tự, cần có chữ cái và số';

  @override
  String get passwordChangeFailed => 'Không thể thay đổi mật khẩu';

  @override
  String get notifications => 'Thông báo';

  @override
  String get permissions => 'Quyền';

  @override
  String get permissionNotifications => 'Thông báo đẩy';

  @override
  String get permissionNotificationsDesc => 'Cuộc gọi, tin nhắn, trạng thái';

  @override
  String get permissionMicrophone => 'Micro';

  @override
  String get permissionMicrophoneDesc => 'Cuộc gọi và trợ lý giọng nói';

  @override
  String get permissionCamera => 'Máy ảnh';

  @override
  String get permissionCameraDesc => 'Cuộc gọi video và xác minh';

  @override
  String get permissionLocation => 'Vị trí';

  @override
  String get permissionLocationDesc => 'Dùng để xác minh';

  @override
  String get permissionOpenSettings => 'Để thu hồi quyền, mở cài đặt hệ thống';

  @override
  String get pushKycStatus => 'Thông báo trạng thái KYC';

  @override
  String get pushKycStatusDesc => 'Kết quả xác minh';

  @override
  String get pushLogins => 'Thông báo đăng nhập';

  @override
  String get pushLoginsDesc => 'Khi đăng nhập từ thiết bị mới';

  @override
  String get account => 'Tài khoản';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSelect => 'Ngôn ngữ giao diện';

  @override
  String get exportData => 'Xuất dữ liệu (GDPR)';

  @override
  String get deleteAccount => 'Xóa tài khoản';

  @override
  String get deleteAccountConfirm => 'Xóa tài khoản?';

  @override
  String get deleteAccountDesc =>
      'Tất cả dữ liệu của bạn sẽ bị xóa (GDPR). Hành động này không thể hoàn tác.';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutConfirm => 'Đăng xuất?';

  @override
  String get logoutDesc =>
      'Bạn sẽ bị đăng xuất khỏi Taler ID trên thiết bị này.';

  @override
  String version(String version) {
    return 'Taler ID v$version';
  }

  @override
  String get pinCode => 'Mã PIN';

  @override
  String get pinCodeDesc => 'Đăng nhập nhanh với mã 4 chữ số';

  @override
  String get setupPin => 'Thiết lập PIN';

  @override
  String get enterPin => 'Nhập PIN';

  @override
  String get confirmPin => 'Xác nhận PIN';

  @override
  String get pinMismatch => 'PIN không khớp';

  @override
  String get passwordMismatch => 'Mật khẩu không khớp';

  @override
  String get pinSet => 'Thiết lập PIN thành công';

  @override
  String get enterPinToLogin => 'Nhập PIN để đăng nhập';

  @override
  String get pinIncorrect => 'PIN không đúng';

  @override
  String get removePin => 'Xóa PIN';

  @override
  String get pinRemoved => 'PIN đã được xóa';

  @override
  String get cancel => 'Hủy';

  @override
  String get delete => 'Xóa';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Thử lại';

  @override
  String get loading => 'Đang tải...';

  @override
  String get error => 'Lỗi';

  @override
  String get success => 'Thành công';

  @override
  String get noData => 'Không có dữ liệu';

  @override
  String get failedToLoad => 'Không tải được dữ liệu';

  @override
  String get failedToLoadProfile => 'Không tải được hồ sơ';

  @override
  String get failedToSave => 'Không lưu được thay đổi';

  @override
  String get failedToLoadOrgs => 'Không tải được tổ chức';

  @override
  String get failedToLoadOrg => 'Không tải được dữ liệu tổ chức';

  @override
  String get failedToCreateOrg => 'Không tạo được tổ chức';

  @override
  String get failedToInvite => 'Không gửi được lời mời';

  @override
  String get failedToAcceptInvite => 'Không chấp nhận được lời mời';

  @override
  String get failedToLoadSessions => 'Không tải được phiên';

  @override
  String get failedToDeleteSession => 'Không kết thúc được phiên';

  @override
  String get failedToLoadKyc => 'Không tải được trạng thái xác minh';

  @override
  String get failedToStartKyc => 'Không bắt đầu được xác minh';

  @override
  String get verifiedPersonalInfo => 'Dữ liệu đã xác minh';

  @override
  String get middleName => 'Tên đệm';

  @override
  String get placeOfBirth => 'Nơi sinh';

  @override
  String get nationality => 'Quốc tịch';

  @override
  String get gender => 'Giới tính';

  @override
  String get genderMale => 'Nam';

  @override
  String get genderFemale => 'Nữ';

  @override
  String get docNumber => 'Số';

  @override
  String get docIssuedDate => 'Ngày cấp';

  @override
  String get docValidUntil => 'Có hiệu lực đến';

  @override
  String get docIssuedBy => 'Cơ quan cấp';

  @override
  String get address => 'Địa chỉ';

  @override
  String get refreshData => 'Làm mới dữ liệu';

  @override
  String get failedToLoadSumsubData => 'Không tải được dữ liệu xác minh';

  @override
  String get sumsubDataLoading => 'Đang tải dữ liệu xác minh...';

  @override
  String get reviewResultGreen => 'Xác minh thành công';

  @override
  String get reviewResultRed => 'Xác minh thất bại';

  @override
  String get tabAssistant => 'Trợ lý';

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
  String get assistantConnecting => 'Đang kết nối…';

  @override
  String get assistantSpeaking => 'Đang nói…';

  @override
  String get assistantListening => 'Đang nghe…';

  @override
  String get assistantTapToStart => 'Nhấn để bắt đầu';

  @override
  String get assistantTapToTalk => 'Nhấn để nói chuyện với AI';

  @override
  String get assistantRealtimeDesc =>
      'Trợ lý phản hồi bằng giọng nói theo thời gian thực';

  @override
  String get assistantConnectingToAssistant => 'Đang kết nối với trợ lý...';

  @override
  String get assistantAiSpeaking => 'AI đang nói...';

  @override
  String get assistantAiListening => 'AI đang nghe';

  @override
  String get assistantSpeakerOn => 'Bật loa';

  @override
  String get assistantSpeaker => 'Loa';

  @override
  String get assistantEnd => 'Kết thúc';

  @override
  String get assistantUnmute => 'Bật tiếng';

  @override
  String get assistantMicrophone => 'Micro';

  @override
  String get assistantConnectionError => 'Lỗi kết nối';

  @override
  String get tabMessenger => 'Tin nhắn';

  @override
  String get tabCalls => 'Cuộc gọi';

  @override
  String get tabCalendar => 'Lịch';

  @override
  String get appearance => 'Giao diện';

  @override
  String get appearanceSelect => 'Chọn chủ đề';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get themeSystem => 'Hệ thống';

  @override
  String get onboardingTitle1 => 'Danh tính hợp nhất';

  @override
  String get onboardingDesc1 =>
      'Taler ID là hộ chiếu kỹ thuật số của bạn trong hệ sinh thái Taler. Một tài khoản cho tất cả dịch vụ.';

  @override
  String get onboardingTitle2 => 'Bảo mật dữ liệu';

  @override
  String get onboardingDesc2 =>
      'Xác minh KYC, mã hóa AES-256 và xác thực hai yếu tố bảo vệ danh tính của bạn.';

  @override
  String get onboardingTitle3 => 'Luôn được thông báo';

  @override
  String get onboardingDesc3 =>
      'Nhận thông báo về trạng thái xác minh, đăng nhập từ thiết bị mới và cuộc gọi đến.';

  @override
  String get onboardingNext => 'Tiếp theo';

  @override
  String get onboardingEnableNotifications => 'Bật thông báo';

  @override
  String get onboardingTitle4 => 'Cuộc gọi thoại';

  @override
  String get onboardingDesc4 =>
      'Cấp quyền truy cập micro cho cuộc gọi thoại và trợ lý AI. Bạn có thể thay đổi điều này sau trong cài đặt.';

  @override
  String get onboardingEnableMicrophone => 'Bật micro';

  @override
  String get onboardingStart => 'Bắt đầu';

  @override
  String get onboardingSkip => 'Bỏ qua';

  @override
  String get meshLocalNetworkPromptTitle => 'Cho phép truy cập mạng cục bộ';

  @override
  String get meshLocalNetworkPromptBody =>
      'Để tìm kiếm đồng nghiệp trên Wi-Fi (cuộc gọi nhóm ngoại tuyến), iOS yêu cầu quyền Mạng Cục Bộ. Mở Cài đặt → Quyền riêng tư & Bảo mật → Mạng Cục Bộ → Taler ID.';

  @override
  String get meshLocalNetworkPromptOpenSettings => 'Mở Cài đặt';

  @override
  String get meshLocalNetworkPromptDismiss => 'Đã hiểu';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get forgotPasswordTitle => 'Đặt lại mật khẩu';

  @override
  String get forgotPasswordSubtitle => 'Nhập email của bạn để nhận mã đặt lại';

  @override
  String resetCodeSent(String email) {
    return 'Mã đã gửi đến $email';
  }

  @override
  String get enterResetCode => 'Nhập mã';

  @override
  String get resetPasswordButton => 'Đặt lại mật khẩu';

  @override
  String get passwordResetSuccess => 'Đặt lại mật khẩu thành công';

  @override
  String get sendCode => 'Gửi mã';

  @override
  String get resendCode => 'Gửi lại mã';

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
  String get newGroup => 'Nhóm mới';

  @override
  String get newChat => 'Trò chuyện mới';

  @override
  String get groupName => 'Tên nhóm';

  @override
  String get createGroup => 'Tạo nhóm';

  @override
  String get groupInfo => 'Thông tin nhóm';

  @override
  String groupMembers(int count) {
    return 'Thành viên ($count)';
  }

  @override
  String get addMembers => 'Thêm thành viên';

  @override
  String get leaveGroup => 'Rời nhóm';

  @override
  String get leaveGroupConfirm => 'Rời nhóm này?';

  @override
  String get deleteGroup => 'Xóa nhóm';

  @override
  String get deleteGroupConfirm => 'Xóa nhóm này? Không thể hoàn tác.';

  @override
  String get groupRoleOwner => 'Chủ sở hữu';

  @override
  String get groupRoleAdmin => 'Quản trị viên';

  @override
  String get groupRoleMember => 'Thành viên';

  @override
  String get selectParticipants => 'Chọn người tham gia';

  @override
  String selectedCount(int count) {
    return '$count đã chọn';
  }

  @override
  String get changeRole => 'Thay đổi vai trò';

  @override
  String get groupCreated => 'Đã tạo nhóm';

  @override
  String memberJoined(String name) {
    return '$name đã tham gia';
  }

  @override
  String memberLeftGroup(String name) {
    return '$name đã rời';
  }

  @override
  String memberWasRemoved(String name) {
    return '$name đã bị xóa';
  }

  @override
  String roleChangedTo(String name, String role) {
    return '$name hiện là $role';
  }

  @override
  String participantsCount(int count) {
    return '$count người tham gia';
  }

  @override
  String get enterGroupName => 'Nhập tên nhóm';

  @override
  String get muteNotifications => 'Tắt thông báo';

  @override
  String get unmuteNotifications => 'Bật thông báo';

  @override
  String get muteFor1Hour => 'Trong 1 giờ';

  @override
  String get muteFor8Hours => 'Trong 8 giờ';

  @override
  String get muteFor2Days => 'Trong 2 ngày';

  @override
  String get muteForever => 'Mãi mãi';

  @override
  String get muted => 'Đã tắt';

  @override
  String get tabTranslator => 'Dịch';

  @override
  String get translatorTitle => 'Trình dịch';

  @override
  String get translatorSelectLanguage => 'Chọn ngôn ngữ';

  @override
  String get translatorDownloading => 'Đang tải xuống mô hình ngôn ngữ...';

  @override
  String get translatorDownloadingHint =>
      'Chỉ cần internet cho lần tải đầu tiên';

  @override
  String get translatorTypeHint => 'Nhập văn bản hoặc chạm vào micro';

  @override
  String get translatorListening => 'Đang nghe...';

  @override
  String get translatorTapToSpeak => 'Nhấn để nói';

  @override
  String get translatorTapToStop => 'Nhấn để dừng';

  @override
  String get translatorAutoSpeak => 'Tự động nói';

  @override
  String get translatorCopied => 'Đã sao chép';

  @override
  String get translatorLangRu => 'Tiếng Nga';

  @override
  String get translatorLangEn => 'Tiếng Anh';

  @override
  String get translatorLangDe => 'Tiếng Đức';

  @override
  String get translatorLangFr => 'Tiếng Pháp';

  @override
  String get translatorLangEs => 'Tiếng Tây Ban Nha';

  @override
  String get translatorLangIt => 'Tiếng Ý';

  @override
  String get translatorLangPt => 'Tiếng Bồ Đào Nha';

  @override
  String get translatorLangTr => 'Tiếng Thổ Nhĩ Kỳ';

  @override
  String get translatorLangZh => 'Tiếng Trung';

  @override
  String get translatorLangJa => 'Tiếng Nhật';

  @override
  String get translatorLangKo => 'Tiếng Hàn';

  @override
  String get translatorLangAr => 'Tiếng Ả Rập';

  @override
  String get translatorLangPl => 'Tiếng Ba Lan';

  @override
  String get translatorLangSk => 'Tiếng Slovakia';

  @override
  String get translatorLangCs => 'Tiếng Séc';

  @override
  String get translatorLangNl => 'Tiếng Hà Lan';

  @override
  String get translatorLangSv => 'Tiếng Thụy Điển';

  @override
  String get translatorLangDa => 'Tiếng Đan Mạch';

  @override
  String get translatorLangNo => 'Tiếng Na Uy';

  @override
  String get translatorLangFi => 'Tiếng Phần Lan';

  @override
  String get translatorLangUk => 'Tiếng Ukraina';

  @override
  String get translatorLangEl => 'Tiếng Hy Lạp';

  @override
  String get translatorLangRo => 'Tiếng Romania';

  @override
  String get translatorLangHu => 'Tiếng Hungary';

  @override
  String get translatorLangBg => 'Tiếng Bulgaria';

  @override
  String get translatorLangHr => 'Tiếng Croatia';

  @override
  String get translatorLangSr => 'Tiếng Serbia';

  @override
  String get translatorLangHi => 'Tiếng Hindi';

  @override
  String get translatorLangTh => 'Tiếng Thái';

  @override
  String get translatorLangVi => 'Tiếng Việt';

  @override
  String get translatorLangId => 'Tiếng Indonesia';

  @override
  String get translatorLangMs => 'Tiếng Mã Lai';

  @override
  String get translatorLangHe => 'Tiếng Hebrew';

  @override
  String get translatorLangFa => 'Tiếng Ba Tư';

  @override
  String get callInProgress => 'Cuộc gọi đang diễn ra';

  @override
  String get joinCall => 'Tham gia';

  @override
  String get createCallLink => 'Liên kết cuộc gọi';

  @override
  String get callLinkCopied => 'Đã sao chép liên kết';

  @override
  String get callLinkTitle => 'Liên kết phòng';

  @override
  String get connectionUnstable =>
      'Kết nối không ổn định — kiểm tra internet của bạn';

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get errorTimeout =>
      'Kết nối đã hết thời gian. Kiểm tra kết nối internet của bạn.';

  @override
  String get errorNoConnection => 'Không có kết nối internet.';

  @override
  String get errorGeneral => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String errorWithMessage(String message) {
    return 'Lỗi: $message';
  }

  @override
  String get notifChannelMessages => 'Tin nhắn';

  @override
  String get notifChannelMessagesDesc => 'Thông báo tin nhắn mới';

  @override
  String get notifChannelMissedCalls => 'Cuộc gọi nhỡ';

  @override
  String get notifChannelMissedCallsDesc => 'Thông báo cuộc gọi nhỡ';

  @override
  String get notifMissedCall => 'Cuộc gọi nhỡ';

  @override
  String get notifAccept => 'Chấp nhận';

  @override
  String get notifDecline => 'Từ chối';

  @override
  String get notifIncomingCall => 'Cuộc gọi đến';

  @override
  String get notifIncomingCallChannel => 'Cuộc gọi đến';

  @override
  String get notifMissedCallChannel => 'Cuộc gọi nhỡ';

  @override
  String get notifUnknown => 'Không xác định';

  @override
  String get effectNone => 'Không có nền';

  @override
  String get effectBlur => 'Làm mờ';

  @override
  String get effectOffice => 'Văn phòng';

  @override
  String get effectNature => 'Thiên nhiên';

  @override
  String get effectGradient => 'Chuyển màu';

  @override
  String get effectLibrary => 'Thư viện';

  @override
  String get effectCity => 'Thành phố';

  @override
  String get effectMinimalism => 'Tối giản';

  @override
  String get voiceParticipant => 'Người tham gia';

  @override
  String get voiceInvitesToRoom => 'mời bạn vào phòng';

  @override
  String get voiceRoom => 'Phòng';

  @override
  String get voicePasswordProtected => 'Được bảo vệ bằng mật khẩu';

  @override
  String get voicePasswordHint => 'Mật khẩu';

  @override
  String get voiceEnter => 'Vào';

  @override
  String get voiceJoinRoom => 'Tham gia phòng';

  @override
  String get voiceYourName => 'Tên của bạn';

  @override
  String voiceInvitationSent(String name) {
    return 'Đã gửi lời mời đến $name';
  }

  @override
  String get voiceNoActiveRoom => 'Không có phòng hoạt động';

  @override
  String get voiceCameraPermission =>
      'Cho phép truy cập camera trong Cài đặt → Quyền riêng tư → Camera → TalerID';

  @override
  String get voiceOpenSettings => 'Mở';

  @override
  String voiceCameraError(String error) {
    return 'Không thể bật camera: $error';
  }

  @override
  String get voiceAllAgreedRecording => 'Tất cả đã đồng ý. Bắt đầu ghi âm.';

  @override
  String get voiceNewParticipantAgreed =>
      'Người tham gia mới đã đồng ý ghi âm.';

  @override
  String get voiceDeclinedRecording =>
      'Bạn đã từ chối ghi âm. Rời khỏi cuộc gọi.';

  @override
  String get voiceRecordingEnded => 'Đã kết thúc ghi âm';

  @override
  String get voiceRecordingInProgress => 'Đang ghi âm';

  @override
  String get voiceTranscriptionRequest => 'Yêu cầu phiên âm';

  @override
  String get voiceRecordingRequest => 'Yêu cầu ghi âm';

  @override
  String get voiceAgree => 'Đồng ý';

  @override
  String get voiceDeclineAndLeave => 'Từ chối và rời đi';

  @override
  String get voiceAudioOutput => 'Đầu ra âm thanh';

  @override
  String get voiceAudioPhone => 'Điện thoại';

  @override
  String get voiceAudioSpeaker => 'Loa';

  @override
  String get voiceAudioBluetooth => 'Bluetooth';

  @override
  String get voiceAudioHeadphones => 'Tai nghe';

  @override
  String get voiceLinkCopied => 'Đã sao chép liên kết';

  @override
  String get voiceTranslateTo => 'Dịch sang';

  @override
  String get voiceSearchLanguage => 'Tìm kiếm ngôn ngữ...';

  @override
  String voiceRoomWithCreator(String name) {
    return 'Phòng $name';
  }

  @override
  String get voiceVoiceCall => 'Cuộc gọi thoại';

  @override
  String get voiceOnHold => 'Đang giữ';

  @override
  String get voiceActiveCall => 'Đang hoạt động';

  @override
  String get voiceEndAllCalls => 'Kết thúc tất cả cuộc gọi';

  @override
  String get voiceEndThisCall => 'Kết thúc cuộc gọi này';

  @override
  String get voiceCopyLink => 'Sao chép liên kết';

  @override
  String get voiceAddParticipant => 'Thêm người tham gia';

  @override
  String get voiceReconnecting => 'Đang kết nối lại...';

  @override
  String get voiceConnectionError => 'Lỗi kết nối';

  @override
  String get voiceClose => 'Đóng';

  @override
  String get voiceCalling => 'Đang gọi...';

  @override
  String get voiceCallActive => 'Cuộc gọi đang hoạt động';

  @override
  String get voiceWaiting => 'Đang chờ';

  @override
  String get voiceWaitingUpper => 'ĐANG CHỜ';

  @override
  String get voiceRec => 'GHI';

  @override
  String get voiceStop => 'Dừng';

  @override
  String get voiceRecord => 'Ghi âm';

  @override
  String get voiceTranslation => 'Dịch';

  @override
  String get voiceAudio => 'Âm thanh';

  @override
  String get voiceFlipCamera => 'Lật';

  @override
  String get voiceBackground => 'Nền';

  @override
  String get voiceAssistantSpeakingStatus => 'Trợ lý đang nói...';

  @override
  String get voiceAssistantListeningStatus => 'Trợ lý đang nghe...';

  @override
  String get voiceUnmute => 'Bật âm';

  @override
  String get voiceMic => 'Micro';

  @override
  String get voiceAssistantLabel => 'Trợ lý';

  @override
  String get voiceCameraOn => 'Bật camera';

  @override
  String get voiceCameraLabel => 'Camera';

  @override
  String get voiceEndCall => 'Kết thúc cuộc gọi';

  @override
  String get voiceWaitingParticipants => 'Đang chờ người tham gia...';

  @override
  String get voiceYou => 'Bạn';

  @override
  String get voiceAiAssistant => 'Trợ lý AI';

  @override
  String get voiceVideoUnavailable => 'Video không khả dụng';

  @override
  String get voiceSearchNickname => 'Tìm kiếm theo biệt danh...';

  @override
  String get voiceTranscriptionWord => 'chuyển ngữ';

  @override
  String get voiceRecordingWord => 'ghi âm';

  @override
  String get voiceConnecting => 'Đang kết nối...';

  @override
  String get voiceVideoBackground => 'Nền video';

  @override
  String get voiceCallSettings => 'Cài đặt cuộc gọi';

  @override
  String get voiceEnableAI => 'Kích hoạt trợ lý AI';

  @override
  String get voiceAIParticipating => 'AI sẽ tham gia vào cuộc trò chuyện';

  @override
  String get voiceNormalCall => 'Cuộc gọi thông thường không có AI';

  @override
  String get voiceCallConfirm => 'Thực hiện cuộc gọi?';

  @override
  String get chatAlreadyInCall => 'Đã trong cuộc gọi';

  @override
  String chatCallError(String error) {
    return 'Lỗi cuộc gọi: $error';
  }

  @override
  String get chatPhotoVideo => 'Ảnh / Video';

  @override
  String get chatCamera => 'Camera';

  @override
  String get chatFile => 'Tệp';

  @override
  String get chatContact => 'Liên hệ';

  @override
  String get chatSelectContact => 'Chọn một liên hệ';

  @override
  String get chatNoContacts => 'Không có liên hệ';

  @override
  String get chatUser => 'Người dùng';

  @override
  String get chatFileAttachment => '📎 Tệp';

  @override
  String chatFileUploadError(String error) {
    return 'Lỗi tải lên tệp: $error';
  }

  @override
  String get chatVoiceMessage => '🎤 Tin nhắn thoại';

  @override
  String get chatGroup => 'Nhóm';

  @override
  String get chatDialog => 'Hội thoại';

  @override
  String get chatCall => 'Cuộc gọi';

  @override
  String get chatStartConversation => 'Bắt đầu cuộc trò chuyện';

  @override
  String get chatYou => 'Bạn';

  @override
  String get chatIsTyping => 'đang nhập...';

  @override
  String chatUserIsTyping(String name) {
    return '$name đang nhập...';
  }

  @override
  String chatUsersAreTyping(String names) {
    return '$names đang nhập...';
  }

  @override
  String get chatPreparingFile => 'Đang chuẩn bị tệp...';

  @override
  String chatUploading(int progress) {
    return 'Đang tải lên… $progress%';
  }

  @override
  String get chatEdited => 'Đã chỉnh sửa';

  @override
  String get chatViaMesh => 'qua mesh';

  @override
  String get chatReply => 'Trả lời';

  @override
  String get chatEdit => 'Chỉnh sửa';

  @override
  String get chatCopy => 'Sao chép';

  @override
  String get chatCopied => 'Đã sao chép';

  @override
  String get chatSaveMedia => 'Lưu';

  @override
  String get chatForward => 'Chuyển tiếp';

  @override
  String get chatSaving => 'Đang lưu...';

  @override
  String get chatSavedToGallery => 'Đã lưu vào thư viện';

  @override
  String get chatNoSavePermission => 'Không có quyền lưu. Kiểm tra cài đặt.';

  @override
  String get chatFileSaved => 'File saved';

  @override
  String get chatFileSaveError => 'Lỗi lưu tệp';

  @override
  String get chatDeleteMessage => 'Xóa tin nhắn';

  @override
  String get chatDeleteForMe => 'Xóa cho tôi';

  @override
  String get chatDeleteForEveryone => 'Xóa cho mọi người';

  @override
  String get chatMessageForwarded => 'Tin nhắn đã được chuyển tiếp';

  @override
  String get chatContactTapToOpen => 'Liên hệ · chạm để mở';

  @override
  String get chatForwardTo => 'Chuyển tiếp đến...';

  @override
  String get chatSearchHint => 'Tìm kiếm...';

  @override
  String get chatRecording => 'Đang ghi âm...';

  @override
  String get chatMessageHint => 'Tin nhắn...';

  @override
  String get chatHideKeyboard => 'Ẩn bàn phím';

  @override
  String get chatEditing => 'Đang chỉnh sửa';

  @override
  String get chatFileDownloadError => 'Lỗi tải tệp';

  @override
  String get chatVoiceMessageShort => 'Tin nhắn thoại';

  @override
  String get chatVideoSavedToGallery => 'Video đã lưu vào thư viện';

  @override
  String get chatSavingError => 'Lỗi lưu';

  @override
  String get convSetNickname => 'Đặt biệt danh';

  @override
  String get convNicknameRequired =>
      'Cần có biệt danh để sử dụng trình nhắn tin. Người dùng khác có thể tìm bạn qua đó.';

  @override
  String get convNicknameRules => '3–30 ký tự: chữ cái, chữ số, _';

  @override
  String get convNicknameTaken => 'Biệt danh đã được sử dụng';

  @override
  String get convSaveError => 'Lỗi lưu';

  @override
  String get convContactsLabel => 'Danh bạ';

  @override
  String get convDefaultUser => 'Người dùng';

  @override
  String get convNoDialogs => 'Không có cuộc trò chuyện';

  @override
  String get convFindUserToChat => 'Tìm người dùng để bắt đầu trò chuyện';

  @override
  String get convDefaultContact => 'Liên hệ';

  @override
  String get dashboardUser => 'Người dùng';

  @override
  String get dashboardIncomingCall => 'Cuộc gọi đến';

  @override
  String get dashboardDecline => 'Từ chối';

  @override
  String get dashboardAccept => 'Chấp nhận';

  @override
  String get dashboardActiveCall =>
      'Cuộc gọi đang hoạt động — chạm để quay lại';

  @override
  String dashboardUpdateAvailable(String version) {
    return 'Có bản cập nhật $version';
  }

  @override
  String get dashboardUpdate => 'Cập nhật';

  @override
  String get dashboardWhatsNew => 'Có gì mới';

  @override
  String dashboardWhatsNewTitle(String version) {
    return 'Có gì mới trong $version';
  }

  @override
  String get dashboardInstalling => 'Đang cài đặt...';

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
  String get contactRequestsTitle => 'Danh bạ';

  @override
  String get messengerContactRequestsSection => 'Yêu cầu kết bạn';

  @override
  String messengerContactRequestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yêu cầu mới',
      one: '1 yêu cầu mới',
    );
    return '$_temp0';
  }

  @override
  String get contactRequestsSearch => 'Tìm kiếm';

  @override
  String get contactRequestsIncoming => 'Đến';

  @override
  String get contactRequestsSent => 'Đã gửi';

  @override
  String get contactRequestsSearchHint => 'Biệt danh hoặc email';

  @override
  String get contactRequestSent => 'Đã gửi yêu cầu';

  @override
  String get contactRequestsNoUsers => 'Không tìm thấy người dùng';

  @override
  String get contactRequestsSearchHelp =>
      'Nhập chính xác biệt danh hoặc email\nvà nhấn tìm kiếm';

  @override
  String get contactRequestsSendTooltip => 'Gửi yêu cầu';

  @override
  String get contactRequestTitle => 'Yêu cầu kết bạn';

  @override
  String contactRequestConfirm(String name) {
    return 'Gửi yêu cầu kết bạn tới $name?';
  }

  @override
  String get contactRequestSend => 'Gửi';

  @override
  String get contactRequestsNoIncoming => 'Không có yêu cầu đến';

  @override
  String get contactRequestsNoSent => 'Không có yêu cầu đã gửi';

  @override
  String get contactRequestStatusPending => 'Đang chờ phản hồi';

  @override
  String get contactRequestStatusAccepted => 'Đã chấp nhận';

  @override
  String get contactRequestStatusRejected => 'Đã từ chối';

  @override
  String get userSearchTitle => 'Tìm người dùng';

  @override
  String get userSearchHint => 'Biệt danh, số điện thoại hoặc email';

  @override
  String get userSearchHelper => 'Nhập @nickname, email hoặc tên để tìm kiếm';

  @override
  String get userSearchNoUsers => 'Không tìm thấy người dùng';

  @override
  String get userProfileShareContact => 'Chia sẻ liên hệ';

  @override
  String get userProfileShareContactDesc => 'Gửi liên kết liên hệ';

  @override
  String get userProfileCopyLink => 'Sao chép liên kết';

  @override
  String get userProfileCopied => 'Đã sao chép';

  @override
  String get userProfileTitle => 'Hồ sơ';

  @override
  String get userProfileLoadError => 'Lỗi tải hồ sơ';

  @override
  String get userProfileMessage => 'Tin nhắn';

  @override
  String get userProfileCall => 'Gọi';

  @override
  String get userProfileRequestSent => 'Yêu cầu đã gửi';

  @override
  String get userProfileAccept => 'Chấp nhận';

  @override
  String get userProfileDecline => 'Từ chối';

  @override
  String get userProfileAddToContacts => 'Thêm vào danh bạ';

  @override
  String get userProfileMediaTab => 'Phương tiện';

  @override
  String get userProfileFilesTab => 'Tệp';

  @override
  String get userProfileLinksTab => 'Liên kết';

  @override
  String get userProfileRecordingsTab => 'Ghi âm';

  @override
  String get userProfileSummariesTab => 'Tóm tắt';

  @override
  String get userProfileNoMedia => 'Không có tệp phương tiện';

  @override
  String get userProfileNoFiles => 'Không có tệp';

  @override
  String get userProfileNoLinks => 'Không có liên kết';

  @override
  String get userProfileNoRecordings => 'Không có ghi âm';

  @override
  String get userProfileNoSummaries => 'Không có tóm tắt';

  @override
  String get userProfileMeetingSummary => 'Tóm tắt cuộc họp';

  @override
  String get userProfileFailedOpenChat => 'Không mở được trò chuyện';

  @override
  String get sharedMediaTitle => 'Phương tiện và tệp';

  @override
  String get sharedMediaTab => 'Phương tiện';

  @override
  String get sharedFilesTab => 'Tệp';

  @override
  String get sharedLinksTab => 'Liên kết';

  @override
  String get sharedNoMedia => 'Không có tệp phương tiện';

  @override
  String get sharedNoFiles => 'Không có tệp';

  @override
  String get sharedNoLinks => 'Không có liên kết';

  @override
  String get shareToChat => 'Chuyển tiếp đến trò chuyện';

  @override
  String get shareSelectChat => 'Chọn trò chuyện';

  @override
  String get shareNoChats => 'Không có trò chuyện';

  @override
  String shareFilesCount(int count) {
    return '$count tệp';
  }

  @override
  String get contactsTitle => 'Danh bạ';

  @override
  String get contactsAddTooltip => 'Thêm liên hệ';

  @override
  String get contactsSearchHint => 'Tìm kiếm danh bạ...';

  @override
  String get contactsNotFound => 'Không tìm thấy';

  @override
  String get contactsEmpty => 'Không có danh bạ';

  @override
  String get contactsAdd => 'Thêm liên hệ';

  @override
  String get contactsPendingConfirmation => 'Đang chờ xác nhận';

  @override
  String get contactsMessage => 'Tin nhắn';

  @override
  String get contactsCall => 'Gọi';

  @override
  String get contactsResend => 'Gửi lại yêu cầu';

  @override
  String get contactsResendTimeout => 'Thử lại sau 24h';

  @override
  String get contactsResent => 'Yêu cầu đã được gửi lại';

  @override
  String get contactsWantsToConnect => 'Muốn kết nối với bạn';

  @override
  String get contactsSearchPeople => 'Tìm người';

  @override
  String get notesTitle => 'Ghi chú';

  @override
  String get notesAssistantSpeaking => 'Trợ lý đang nói...';

  @override
  String get notesListening => 'Đang nghe...';

  @override
  String get notesEmpty => 'Không có ghi chú';

  @override
  String get notesEmptyHint => 'Nhấn mic để nhập liệu\nhoặc + để nhập thủ công';

  @override
  String get notesDeleteConfirm => 'Xóa ghi chú?';

  @override
  String get notesNew => 'Ghi chú mới';

  @override
  String get notesEdit => 'Chỉnh sửa';

  @override
  String get notesTitleHint => 'Tiêu đề';

  @override
  String get notesContentHint => 'Viết suy nghĩ của bạn...';

  @override
  String get calendarTitle => 'Lịch';

  @override
  String get calendarStop => 'Dừng';

  @override
  String get calendarVoiceInput => 'Nhập giọng nói';

  @override
  String get calendarNewEvent => 'Sự kiện mới';

  @override
  String get calendarAssistantSpeaking => 'Trợ lý đang nói...';

  @override
  String get calendarListening => 'Đang nghe...';

  @override
  String calendarInvitations(int count) {
    return 'Lời mời ($count)';
  }

  @override
  String get calendarNoEvents => 'Không có sự kiện';

  @override
  String get calendarDayMon => 'Thứ Hai';

  @override
  String get calendarDayTue => 'Thứ Ba';

  @override
  String get calendarDayWed => 'Thứ Tư';

  @override
  String get calendarDayThu => 'Thứ Năm';

  @override
  String get calendarDayFri => 'Thứ Sáu';

  @override
  String get calendarDaySat => 'Thứ Bảy';

  @override
  String get calendarDaySun => 'Chủ Nhật';

  @override
  String get calendarEnterRoom => 'Vào phòng';

  @override
  String get calendarMeeting => 'Cuộc họp';

  @override
  String calendarLocationPrefix(String location) {
    return 'Địa điểm: $location';
  }

  @override
  String get calendarEditEvent => 'Chỉnh sửa';

  @override
  String get calendarTitleHint => 'Tiêu đề';

  @override
  String get calendarDescriptionHint => 'Mô tả';

  @override
  String get calendarTypeEvent => 'Sự kiện';

  @override
  String get calendarTypeMeeting => 'Cuộc họp';

  @override
  String get calendarTypeReminder => 'Nhắc nhở';

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
  String get calendarTypeLabel => 'Loại';

  @override
  String get calendarMeetingLink => 'Liên kết cuộc họp';

  @override
  String get calendarLocationHint => 'Địa điểm';

  @override
  String get calendarDateLabel => 'Ngày';

  @override
  String get calendarTimeLabel => 'Thời gian';

  @override
  String get calendarReminderLabel => 'Nhắc nhở';

  @override
  String get calendarReminderNone => 'Không';

  @override
  String get calendarReminder15min => '15 phút trước';

  @override
  String get calendarReminder30min => '30 phút trước';

  @override
  String get calendarReminder1hour => '1 giờ trước';

  @override
  String get calendarRepeatLabel => 'Lặp lại';

  @override
  String get calendarRepeatNone => 'Không lặp lại';

  @override
  String get calendarRepeatDaily => 'Mỗi ngày';

  @override
  String get calendarRepeatWeekly => 'Mỗi tuần';

  @override
  String get calendarRepeatMonthly => 'Mỗi tháng';

  @override
  String get calendarRepeatYearly => 'Mỗi năm';

  @override
  String get calendarParticipants => 'Người tham gia';

  @override
  String get calendarAddParticipant => 'Thêm';

  @override
  String get calendarSearchContacts => 'Tìm kiếm liên hệ...';

  @override
  String get calendarNoContacts => 'Không có liên hệ';

  @override
  String get calendarStatusAccepted => 'Đã chấp nhận';

  @override
  String get calendarStatusDeclined => 'Đã từ chối';

  @override
  String get calendarStatusMaybe => 'Có thể';

  @override
  String get calendarStatusPending => 'Đang chờ';

  @override
  String get calendarEndTime => 'Thời gian kết thúc';

  @override
  String get calendarYourAnswer => 'Câu trả lời của bạn:';

  @override
  String get calendarOrganizer => 'Người tổ chức';

  @override
  String calendarDeleteError(String error) {
    return 'Xóa thất bại: $error';
  }

  @override
  String get calendarRsvpAccept => 'Chấp nhận';

  @override
  String get calendarRsvpMaybe => 'Có thể';

  @override
  String get calendarRsvpDecline => 'Từ chối';

  @override
  String get callHistoryTitle => 'Cuộc gọi';

  @override
  String get callHistoryTab => 'Lịch sử cuộc gọi';

  @override
  String get callHistoryTempMeeting => 'Cuộc họp tạm thời';

  @override
  String get callHistoryCopy => 'Sao chép';

  @override
  String get callHistoryLinkCopied => 'Đã sao chép liên kết';

  @override
  String get callHistoryShare => 'Chia sẻ';

  @override
  String get callHistoryEnter => 'Tham gia';

  @override
  String get callHistoryAlreadyInCall => 'Đã trong cuộc gọi';

  @override
  String get callHistoryCouldNotDeterminePeer => 'Không thể xác định bên kia';

  @override
  String get callHistoryContacts => 'Danh bạ';

  @override
  String get callHistoryFailedLoadRoom => 'Không thể tải phòng của bạn';

  @override
  String get callHistoryYourRoom => 'Phòng của bạn';

  @override
  String get callHistoryCreateMeeting => 'Tạo cuộc họp';

  @override
  String get callHistoryMeetingSummaries => 'Tóm tắt cuộc họp';

  @override
  String get callHistoryMeetingRecordings => 'Ghi âm cuộc họp';

  @override
  String get callHistoryNoCalls => 'Không có cuộc gọi';

  @override
  String get callHistoryMissed => 'Bỏ lỡ';

  @override
  String get callHistoryRecording => 'Đang ghi âm';

  @override
  String get callHistorySummary => 'Tóm tắt';

  @override
  String get callHistoryCallAgain => 'Gọi lại';

  @override
  String callHistoryTodayTime(String time) {
    return 'Hôm nay, $time';
  }

  @override
  String callHistoryYesterdayTime(String time) {
    return 'Hôm qua, $time';
  }

  @override
  String get callHistoryUnknown => 'Không xác định';

  @override
  String get callHistoryDetails => 'Chi tiết cuộc gọi';

  @override
  String get callHistoryOutgoing => 'Cuộc gọi đi';

  @override
  String get callHistoryIncoming => 'Cuộc gọi đến';

  @override
  String callHistoryDuration(String duration) {
    return 'Thời lượng: $duration';
  }

  @override
  String get callHistoryWithAI => 'Với trợ lý AI';

  @override
  String get callHistoryParticipants => 'Người tham gia';

  @override
  String get callDetailYouSuffix => '(Bạn)';

  @override
  String get callHistoryMeetingSummary => 'Tóm tắt cuộc họp';

  @override
  String get callHistoryMoreDetails => 'Thêm chi tiết';

  @override
  String get callHistorySummaryProcessing => 'Đang xử lý tóm tắt...';

  @override
  String get callHistoryMeetingRecording => 'Ghi âm cuộc họp';

  @override
  String get callHistoryProcessing => 'Đang xử lý...';

  @override
  String get callHistoryCreateTranscript => 'Tạo bản ghi';

  @override
  String get callHistoryNoSummaries => 'Không có tóm tắt';

  @override
  String get callHistoryRecordDuringCall => 'Nhấn \"Ghi âm\" trong cuộc gọi';

  @override
  String callHistoryMeetingTime(String time) {
    return 'Cuộc họp $time';
  }

  @override
  String get callHistoryTranscribing => 'Đang ghi và tóm tắt...';

  @override
  String get callHistoryTranscriptCreated => 'Bản ghi đã được tạo';

  @override
  String get callHistoryNoRecordings => 'Không có ghi âm';

  @override
  String callHistoryRecordingDate(String date) {
    return 'Ghi âm $date';
  }

  @override
  String get callHistoryRecordingUnavailable => 'Ghi âm không khả dụng';

  @override
  String get callHistoryTranscriptReady => 'Bản ghi đã sẵn sàng';

  @override
  String get callHistoryTranscript => 'Bản ghi';

  @override
  String get callHistoryKeyPoints => 'Điểm chính';

  @override
  String get callHistoryTasks => 'Nhiệm vụ';

  @override
  String callHistoryAssignedTo(String assignee) {
    return 'Giao cho: $assignee';
  }

  @override
  String get callHistoryDecisions => 'Quyết định';

  @override
  String get callHistoryShowTranscript => 'Hiển thị toàn bộ bản ghi';

  @override
  String get profileScanQr => 'Quét mã QR';

  @override
  String get profileMyQrCode => 'Mã QR của tôi';

  @override
  String profileAddMeShare(String userId) {
    return 'Thêm tôi vào Taler ID!\ntalerid://user/$userId';
  }

  @override
  String get profileShowCode => 'Hiển thị mã này để thêm bạn';

  @override
  String get profileEditDesc => 'Tên, họ, tên đệm, ngày sinh';

  @override
  String get profileAboutMe => 'Về tôi';

  @override
  String get profileAboutMeDesc => 'Giá trị, kỹ năng, sở thích và hơn thế nữa';

  @override
  String get profileNotes => 'Ghi chú';

  @override
  String get profileNotesDesc => 'Suy nghĩ, ý tưởng và ghi chú';

  @override
  String get profileAvatarUpdated => 'Ảnh đại diện đã được cập nhật';

  @override
  String get profileNickname => 'Biệt danh';

  @override
  String get profileNotSet => 'Chưa thiết lập';

  @override
  String get profileChangeNickname => 'Thay đổi biệt danh';

  @override
  String get profileNicknameUpdated => 'Biệt danh đã được cập nhật';

  @override
  String get profileShareLabel => 'Chia sẻ';

  @override
  String get profileScanQrCode => 'Quét mã QR';

  @override
  String get profilePointCamera => 'Chỉ camera vào mã QR';

  @override
  String get profilePhotoCamera => 'Chụp ảnh';

  @override
  String get profilePhotoGallery => 'Chọn từ thư viện';

  @override
  String get editProfilePatronymic => 'Tên đệm (tùy chọn)';

  @override
  String get editProfileDateFormat => 'DD.MM.YYYY';

  @override
  String get aboutMeTitle => 'Về tôi';

  @override
  String get aboutMeClickToFill => 'Nhấp để điền';

  @override
  String get aboutMeCoreValues => 'Giá trị';

  @override
  String get aboutMeWorldview => 'Thế giới quan';

  @override
  String get aboutMeSkills => 'Kỹ năng';

  @override
  String get aboutMeInterests => 'Sở thích';

  @override
  String get aboutMeDesires => 'Mong muốn';

  @override
  String get aboutMeBackground => 'Hồ sơ';

  @override
  String get aboutMeLikes => 'Thích';

  @override
  String get aboutMeDislikes => 'Không thích';

  @override
  String get aboutMeDeleteSection => 'Xóa phần?';

  @override
  String get aboutMeDeleteConfirm => 'Tất cả dữ liệu trong phần này sẽ bị xóa.';

  @override
  String aboutMeConnectionError(String error) {
    return 'Lỗi kết nối: $error';
  }

  @override
  String get aboutMeVisibility => 'Khả năng hiển thị';

  @override
  String get aboutMeTags => 'Thẻ';

  @override
  String get aboutMeAddTag => 'Thêm thẻ...';

  @override
  String get aboutMeDescription => 'Mô tả';

  @override
  String get aboutMeDescribeLong => 'Hãy cho chúng tôi biết thêm...';

  @override
  String get aboutMeVisibilityEveryone => 'Mọi người';

  @override
  String get aboutMeVisibilityContacts => 'Danh bạ';

  @override
  String get aboutMeVisibilityOnlyMe => 'Chỉ mình tôi';

  @override
  String get settingsProfileSubtitle => 'Hồ sơ';

  @override
  String get settingsWallpaper => 'Hình nền';

  @override
  String get settingsWallpaperDesc => 'Hình nền cho toàn bộ ứng dụng';

  @override
  String get settingsWallpaperNone => 'Không có';

  @override
  String get settingsAccount => 'Tài khoản';

  @override
  String get settingsKycVerification => 'Xác minh danh tính (KYC)';

  @override
  String get settingsOrganizations => 'Tổ chức';

  @override
  String get incomingCallLabel => 'Cuộc gọi đến';

  @override
  String get incomingCallDecline => 'Từ chối';

  @override
  String get incomingCallAccept => 'Chấp nhận';

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
  String get meshIncomingCallLabel => '📡 Cuộc gọi mesh đến';

  @override
  String meshDeviceFallback(String hexPrefix) {
    return 'Thiết bị mesh $hexPrefix';
  }

  @override
  String get callConflictAlreadyInCall => 'Kết thúc cuộc gọi hiện tại trước';

  @override
  String get callPopupTransportTitle => 'Gọi qua';

  @override
  String get callPopupTransportMesh => '📡 Mesh (ngang hàng)';

  @override
  String get callPopupTransportLk => '📞 Máy chủ';

  @override
  String get callPopupTransportMeshUnavailable => 'Không thể liên lạc qua mesh';

  @override
  String get meshOnboardingTitle => '📡 Cuộc gọi mesh cần mở ứng dụng';

  @override
  String get meshOnboardingBody =>
      'Khi điện thoại bị khóa, cuộc gọi mesh có thể bị ngắt sau ~30 giây (hạn chế của iOS).';

  @override
  String get meshOnboardingAck => 'Hiểu rồi';

  @override
  String get meshHistoryBadge => '📡 Mesh';

  @override
  String get meshHistoryNoChatAvailable =>
      'Liên hệ không có trong danh sách của bạn';

  @override
  String get meshCallStatusInviting => 'Đang gọi…';

  @override
  String get meshCallStatusConnecting => 'Đang kết nối…';

  @override
  String get meshCallEndedUserHangup => 'Cuộc gọi kết thúc';

  @override
  String get meshCallEndedRemoteHangup => 'Đã kết thúc bởi đối tác';

  @override
  String get meshCallEndedRejected => 'Đã từ chối';

  @override
  String get meshCallEndedNoAnswer => 'Không có trả lời';

  @override
  String get meshCallEndedConnectionLost => 'Mất kết nối';

  @override
  String get meshCallEndedError => 'Lỗi kết nối';

  @override
  String meshCallTransportBadge(String transport) {
    return '📡 Mesh · $transport';
  }

  @override
  String get meshCallTransportBadgePlain => '📡 Mesh';

  @override
  String get batteryExemptionTitle => '📡 Cuộc gọi mesh đáng tin cậy';

  @override
  String get batteryExemptionBody =>
      'Cho phép ứng dụng chạy mà không bị hạn chế pin để Android không tắt mesh trong nền.';

  @override
  String get batteryExemptionAccept => 'Mở cài đặt';

  @override
  String get batteryExemptionDismiss => 'Không phải bây giờ';

  @override
  String get groupCamera => 'Máy ảnh';

  @override
  String get groupGallery => 'Thư viện';

  @override
  String get groupAvatarUpdated => 'Ảnh đại diện nhóm đã được cập nhật';

  @override
  String get groupNameTitle => 'Tên nhóm';

  @override
  String get groupEnterName => 'Nhập tên';

  @override
  String get groupDescriptionTitle => 'Mô tả nhóm';

  @override
  String get groupEnterDescription => 'Nhập mô tả nhóm';

  @override
  String get groupChangeRoleTitle => 'Thay đổi vai trò';

  @override
  String get groupRemoveMemberTitle => 'Xóa thành viên';

  @override
  String get groupDescription => 'Mô tả';

  @override
  String get groupAddDescription => 'Thêm mô tả nhóm';

  @override
  String get groupNoDescription => 'Không có mô tả';

  @override
  String get groupMediaAndFiles => 'Phương tiện và tệp';

  @override
  String get groupMuteNotifications => 'Tắt thông báo';

  @override
  String get groupMuted => 'Đã tắt';

  @override
  String get groupNoResults => 'Không có kết quả';

  @override
  String get authInvalidCode => 'Mã không hợp lệ. Thử lại.';

  @override
  String get loginSubtitle => 'Sử dụng email và mật khẩu';

  @override
  String get emailRequired => 'Nhập email';

  @override
  String get emailInvalid => 'Email không hợp lệ';

  @override
  String get passwordRequired => 'Nhập mật khẩu';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get registerSubtitle => 'Một tài khoản cho toàn bộ hệ sinh thái Taler';

  @override
  String get usernameOptional => 'Tên người dùng (tùy chọn)';

  @override
  String get usernameMinLength => 'Tối thiểu 3 ký tự';

  @override
  String get usernameMaxLength => 'Tối đa 30 ký tự';

  @override
  String get usernameInvalid => 'Chỉ chữ cái, số và _';

  @override
  String get biometricLoginReason => 'Đăng nhập vào Taler ID';

  @override
  String get docTypePassport => 'Hộ chiếu';

  @override
  String get docTypeIdCard => 'Thẻ căn cước';

  @override
  String get docTypeDriverLicense => 'Giấy phép lái xe';

  @override
  String get docTypeResidencePermit => 'Giấy phép cư trú';

  @override
  String addressApartment(String number) {
    return 'căn hộ $number';
  }

  @override
  String get failedToUpdateProfile => 'Cập nhật hồ sơ thất bại';

  @override
  String get failedToStartKyb => 'Bắt đầu xác minh KYB thất bại';

  @override
  String get orgUpdated => 'Tổ chức đã được cập nhật';

  @override
  String get failedToUpdateOrg => 'Cập nhật tổ chức thất bại';

  @override
  String get failedToChangeRole => 'Thay đổi vai trò thất bại';

  @override
  String get failedToRemoveMember => 'Xóa thành viên thất bại';

  @override
  String get capabilityMessagesTitle => 'Tin nhắn';

  @override
  String get capabilityMessagesDesc =>
      'Kiểm tra tin nhắn hoặc viết cho ai đó. Ví dụ: \"Viết cho Viktor: sẽ đến trong một giờ\"';

  @override
  String get capabilityCallsTitle => 'Cuộc gọi';

  @override
  String get capabilityCallsDesc =>
      'Gọi bất kỳ liên hệ nào bằng giọng nói. Ví dụ: \"Gọi Viktor Viktorov\"';

  @override
  String get capabilityChatTitle => 'Lịch sử trò chuyện';

  @override
  String get capabilityChatDesc =>
      'Tôi sẽ phân tích lịch sử trò chuyện. Ví dụ: \"Chúng ta đã thảo luận gì với Viktor?\"';

  @override
  String get capabilityProfileTitle => 'Hồ sơ';

  @override
  String get capabilityProfileDesc =>
      'Tôi sẽ hiển thị hoặc cập nhật hồ sơ của bạn. Ví dụ: \"Hiển thị hồ sơ của tôi\"';

  @override
  String get capabilityCoachingTitle => 'Huấn luyện';

  @override
  String get capabilityCoachingDesc =>
      'Chế độ: huấn luyện ICF, nhà tâm lý học, tư vấn nhân sự. Nói: \"Hãy huấn luyện\"';

  @override
  String get capabilityCalendarTitle => 'Lịch';

  @override
  String get capabilityCalendarDesc =>
      'Lên lịch họp hoặc đặt lời nhắc. Ví dụ: \"Lên lịch họp với Viktor vào ngày mai lúc 15:00\"';

  @override
  String get capabilityNotesTitle => 'Ghi chú';

  @override
  String get capabilityNotesDesc =>
      'Lưu ý tưởng hoặc đọc ghi chú gần đây. Ví dụ: \"Ghi lại một ý tưởng...\" hoặc \"Đọc ghi chú gần đây\"';

  @override
  String get assistantCallConfirm => 'Thực hiện cuộc gọi?';

  @override
  String get callNoAnswer => 'Không có câu trả lời';

  @override
  String get contactDelete => 'Xóa liên hệ';

  @override
  String get contactDeleteTitle => 'Xóa liên hệ';

  @override
  String get contactDeleteConfirm =>
      'Bạn có chắc không? Liên hệ này sẽ bị xóa.';

  @override
  String get contactBlock => 'Chặn';

  @override
  String get contactBlockTitle => 'Chặn người dùng';

  @override
  String get contactBlockConfirm =>
      'Người dùng này sẽ không thể nhắn tin hoặc gọi cho bạn.';

  @override
  String get contactUnblock => 'Bỏ chặn';

  @override
  String get contactBlocked => 'Đã chặn';

  @override
  String get contactYouAreBlocked => 'Người dùng này đã chặn bạn';

  @override
  String get chatBlockedByYou => 'Bạn đã chặn người dùng này';

  @override
  String get chatYouAreBlocked => 'Bạn đã bị người dùng này chặn';

  @override
  String get chatNotContacts => 'Thêm người dùng này vào danh bạ để nhắn tin';

  @override
  String get contactRevokeRequest => 'Thu hồi yêu cầu';

  @override
  String get messengerPoll => 'Khảo sát';

  @override
  String get messengerCreatePoll => 'Tạo khảo sát';

  @override
  String get messengerPollQuestion => 'Câu hỏi';

  @override
  String messengerPollOption(int number) {
    return 'Tùy chọn $number';
  }

  @override
  String get messengerPollAddOption => 'Thêm tùy chọn';

  @override
  String get messengerPollAnonymous => 'Bỏ phiếu ẩn danh';

  @override
  String get messengerPollMultiple => 'Lựa chọn nhiều';

  @override
  String get messengerPollCreateError => 'Tạo khảo sát thất bại';

  @override
  String get messengerPollUnavailable => 'Khảo sát không khả dụng';

  @override
  String get messengerPollMultipleNote => 'Bạn có thể chọn nhiều';

  @override
  String messengerPollVotes(int count) {
    return '$count phiếu bầu';
  }

  @override
  String get messengerVideoMessage => 'Tin nhắn video';

  @override
  String get messengerVideoRecordError => 'Lỗi ghi video';

  @override
  String get messengerVideoPlaybackError => 'Không thể phát video';

  @override
  String get messengerGalleryAccessError =>
      'Không có quyền truy cập vào thư viện';

  @override
  String get messengerSearchInChat => 'Tìm kiếm trong trò chuyện...';

  @override
  String get messengerSaveToFavorites => 'Lưu vào mục yêu thích';

  @override
  String get messengerSavedToFavorites => 'Đã lưu vào mục yêu thích';

  @override
  String get messengerSearchInMessages => 'Tìm kiếm trong tin nhắn...';

  @override
  String messengerFoundInMessages(int count) {
    return 'Đã tìm thấy trong tin nhắn ($count)';
  }

  @override
  String get messengerGroupDefault => 'Nhóm';

  @override
  String get messengerUserDefault => 'Người dùng';

  @override
  String get messengerPin => 'Ghim';

  @override
  String get messengerUnpin => 'Bỏ ghim';

  @override
  String get messengerArchive => 'Lưu trữ';

  @override
  String get messengerUnarchive => 'Bỏ lưu trữ';

  @override
  String get messengerDeleteChat => 'Xóa trò chuyện';

  @override
  String get messengerDeleteChatTitle => 'Xóa trò chuyện?';

  @override
  String messengerDeleteChatConfirm(String name) {
    return 'Xóa trò chuyện với $name? Không thể hoàn tác.';
  }

  @override
  String get messengerCreateChannel => 'Tạo Kênh';

  @override
  String get messengerChannelName => 'Tên';

  @override
  String get messengerChannelDescription => 'Mô tả (tùy chọn)';

  @override
  String get messengerChannelCreateError => 'Tạo kênh thất bại';

  @override
  String get messengerFilterAll => 'Tất cả';

  @override
  String get messengerFilterUnread => 'Chưa đọc';

  @override
  String get messengerFilterPersonal => 'Cá nhân';

  @override
  String get messengerFilterGroups => 'Nhóm';

  @override
  String get messengerFilterChannels => 'Kênh';

  @override
  String get messengerArchivedSection => 'Đã lưu trữ';

  @override
  String get messengerSavedSection => 'Mục yêu thích';

  @override
  String get messengerSavedSubtitle => 'Lưu vào bộ nhớ';

  @override
  String messengerArchiveTitle(int count) {
    return 'Lưu trữ ($count)';
  }

  @override
  String get messengerArchiveEmpty => 'Lưu trữ trống';

  @override
  String messengerYouPrefix(String message) {
    return 'Bạn: $message';
  }

  @override
  String get messengerMissedCall => 'Cuộc gọi nhỡ';

  @override
  String get messengerSavedTitle => 'Mục yêu thích';

  @override
  String get messengerNoSavedMessages => 'Không có tin nhắn đã lưu';

  @override
  String get messengerSavedHint =>
      'Nhấn giữ một tin nhắn → \"Lưu vào mục yêu thích\"';

  @override
  String get messengerDefaultFile => 'Tệp';

  @override
  String get messengerTopicDefault => 'Chung';

  @override
  String get messengerTopicNew => 'Chủ đề Mới';

  @override
  String get messengerTopicNameHint => 'Tên chủ đề';

  @override
  String get messengerTopicIcon => 'Biểu tượng';

  @override
  String messengerTopicCount(int count) {
    return '$count chủ đề';
  }

  @override
  String get messengerNoTopics => 'Không có chủ đề';

  @override
  String get messengerNoMessages => 'Không có tin nhắn';

  @override
  String get you => 'Bạn';

  @override
  String get messengerThread => 'Chuỗi';

  @override
  String get messengerThreadReply => 'trả lời';

  @override
  String get messengerThreadReplies => 'trả lời';

  @override
  String messengerThreadReplyCount(int count, String word) {
    return '$count $word';
  }

  @override
  String get messengerNoReplies => 'Không có trả lời';

  @override
  String get messengerReplyHint => 'Trả lời chuỗi...';

  @override
  String get messengerContactName => 'Tên liên hệ';

  @override
  String messengerOriginalName(String name) {
    return 'Tên gốc: $name';
  }

  @override
  String get messengerDisplayName => 'Tên hiển thị';

  @override
  String messengerShareContact(String name) {
    return 'Liên hệ trong Taler ID: $name';
  }

  @override
  String get messengerAutoDelete => 'Tự động xóa tin nhắn';

  @override
  String get messengerAutoDeleteOff => 'Tắt';

  @override
  String get messengerAutoDelete7d => '7 ngày';

  @override
  String get messengerAutoDelete30d => '30 ngày';

  @override
  String get messengerAutoDelete90d => '90 ngày';

  @override
  String messengerAutoDeleteDays(int count) {
    return '$count ngày';
  }

  @override
  String get messengerSettingsHeader => 'Cài đặt';

  @override
  String get messengerAdminOnly => 'Chỉ quản trị viên đăng bài';

  @override
  String get messengerAdminOnlyDesc => 'Thành viên chỉ có thể đọc';

  @override
  String get messengerTopics => 'Chủ đề';

  @override
  String get messengerTopicsDesc => 'Chia cuộc trò chuyện thành các chủ đề';

  @override
  String get aiTwinSection => 'AI Voice Twin';

  @override
  String get aiTwinEnabled => 'Kích hoạt AI Twin';

  @override
  String get aiTwinEnabledDesc =>
      'Nếu bạn không trả lời, AI twin của bạn sẽ nhận cuộc gọi bằng giọng của bạn';

  @override
  String get aiTwinTimeout => 'Thời gian chờ phản hồi';

  @override
  String aiTwinTimeoutValue(int seconds) {
    return '$seconds giây';
  }

  @override
  String get aiTwinPrompt => 'Hướng dẫn AI';

  @override
  String get aiTwinPromptSubtitle =>
      'Cách AI twin nên giới thiệu và nói về điều gì';

  @override
  String aiTwinPromptHint(String name) {
    return 'Xin chào, đây là AI voice twin của $name. $name không thể nghe máy ngay bây giờ. Cho tôi biết ai đang gọi và về vấn đề gì — tôi sẽ chuyển lời.';
  }

  @override
  String aiTwinComingSoon(String name) {
    return 'Sao chép giọng nói tùy chỉnh sắp ra mắt. Hiện tại AI nói bằng giọng của $name.';
  }

  @override
  String get aiTwinDefaultName => 'chủ sở hữu';

  @override
  String get aiTwinPromptReset => 'Đặt lại';

  @override
  String get callHistoryAiTwinAnswered => 'AI TWIN ĐÃ TRẢ LỜI';

  @override
  String get callHistoryAiTwinSummary => 'TÓM TẮT CUỘC GỌI';

  @override
  String get callHistoryAiTwinTranscript => 'BẢN GHI';

  @override
  String get callHistoryAiTwinLabel => 'AI';

  @override
  String callHistoryFromCaller(String name) {
    return 'Từ $name';
  }

  @override
  String get aiTwinOfferTitle => 'Không trả lời';

  @override
  String aiTwinOfferBody(String name) {
    return '$name không trả lời. Để lại tin nhắn với giọng nói AI của họ?';
  }

  @override
  String get aiTwinOfferBodyUser => 'Người dùng';

  @override
  String get aiTwinOfferAccept => 'Có, để lại tin nhắn';

  @override
  String get aiTwinOfferKeepWaiting => 'Tiếp tục chờ';

  @override
  String get aiTwinLabel => 'AI';

  @override
  String get aiTwinHeroTitle => 'Người đại diện AI của bạn';

  @override
  String get aiTwinHeroSubtitle =>
      'Trả lời cuộc gọi bằng giọng nói của bạn khi bạn không thể.';

  @override
  String get aiTwinProfileTitle => 'Người đại diện AI';

  @override
  String get aiTwinProfileDesc => 'Trả lời cuộc gọi bằng giọng nói của bạn';

  @override
  String get aiTwinBadgeOn => 'BẬT';

  @override
  String get aiAnalystTitle => 'Nhà phân tích AI';

  @override
  String get aiAnalystSubtitle => 'Tệp, nhiệm vụ, phân tích — Claude';

  @override
  String get channelsDiscover => 'Tìm kênh';

  @override
  String get channelsSearchHint => 'Tìm kiếm kênh';

  @override
  String get channelsSubscribers => 'người đăng ký';

  @override
  String get channelsSubscribe => 'Đăng ký';

  @override
  String get channelsUnsubscribe => 'Hủy đăng ký';

  @override
  String get channelsSubscribedLabel => 'Bạn đã đăng ký';

  @override
  String get channelsSettings => 'Cài đặt kênh';

  @override
  String get channelsDelete => 'Xóa kênh';

  @override
  String get channelsDeleteConfirm => 'Xóa kênh vĩnh viễn?';

  @override
  String get channelsEmpty => 'Chưa có kênh nào';

  @override
  String get channelsOpen => 'Mở';

  @override
  String get channelsNameLabel => 'Tên';

  @override
  String get channelsDescriptionLabel => 'Mô tả';

  @override
  String get channelsCannotUnsubscribeOwner =>
      'Chủ sở hữu không thể hủy đăng ký. Thay vào đó, hãy xóa kênh.';

  @override
  String get channelsNotFoundRedirect => 'Kênh không còn tồn tại';

  @override
  String analystSeamSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tìm kiếm',
      one: '$count tìm kiếm',
    );
    return '$_temp0';
  }

  @override
  String analystSeamFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
      one: '$count tệp',
    );
    return '$_temp0';
  }

  @override
  String analystSeamCommands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lệnh',
      one: '$count lệnh',
    );
    return '$_temp0';
  }

  @override
  String analystSeamImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hình ảnh',
      one: '$count hình ảnh',
    );
    return '$_temp0';
  }

  @override
  String analystSeamOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bước',
      one: '$count bước',
    );
    return '$_temp0';
  }

  @override
  String analystSeamDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get savedTitle => 'Tin nhắn đã lưu';

  @override
  String get savedSubtitle => 'Đám mây riêng của bạn';

  @override
  String get savedOpenError => 'Không thể mở Tin nhắn đã lưu';

  @override
  String get billingWalletTitle => 'Ví';

  @override
  String get billingBuyPackage => 'Mua gói';

  @override
  String get billingCurrentBalance => 'Số dư hiện tại';

  @override
  String get billingPackagesTitle => 'Gói';

  @override
  String get billingPackagesUnavailable => 'Gói không khả dụng';

  @override
  String get billingRecentOperations => 'Hoạt động gần đây';

  @override
  String get billingAllOperations => 'Tất cả hoạt động';

  @override
  String get billingNoOperations => 'Không có hoạt động';

  @override
  String get billingOperationsTitle => 'Hoạt động';

  @override
  String get billingOperationsEmptyTitle => 'Chưa có hoạt động';

  @override
  String get billingOperationsEmptySubtitle =>
      'Nạp tiền và phí cho các tính năng AI sẽ xuất hiện ở đây';

  @override
  String get billingPricebookTitle => 'Giá tính năng';

  @override
  String get billingPricebookUnavailable => 'Danh sách giá không khả dụng';

  @override
  String get billingAiFeaturesTitle => 'Tính năng AI';

  @override
  String get billingInsufficientFundsTitle => 'Không đủ tiền';

  @override
  String get billingInsufficientFundsSubtitle =>
      'Nạp thêm tiền để sử dụng tính năng này.';

  @override
  String billingRequiredLine(String required) {
    return 'Cần: $required μTAL';
  }

  @override
  String billingAvailableLine(String available) {
    return 'Có: $available μTAL';
  }

  @override
  String get billingTopUp => 'Nạp tiền';

  @override
  String get billingCancel => 'Hủy';

  @override
  String get billingRetry => 'Thử lại';

  @override
  String billingLowBalanceWarning(String balance) {
    return 'Số dư thấp: $balance μTAL';
  }

  @override
  String get billingWalletAndBalance => 'Ví & Số dư';

  @override
  String get billingSectionHeader => 'Thanh toán & AI';

  @override
  String get billingFeatureVoiceAssistant => 'Trợ lý giọng nói';

  @override
  String get billingFeatureWebSearch => 'Tìm kiếm web trợ lý';

  @override
  String get billingFeatureAiTwin => 'Giọng nói song sinh';

  @override
  String get billingFeatureAiTwinLong => 'Giọng nói song sinh (AI Twin)';

  @override
  String get billingFeatureOutboundCall => 'Bot gọi ra';

  @override
  String get billingFeatureOutboundCallLong => 'Bot gọi điện ra ngoài';

  @override
  String get billingFeatureWhisperTranscribe => 'Chép lại cuộc gọi';

  @override
  String get billingFeatureMeetingSummary => 'Tóm tắt cuộc gọi AI';

  @override
  String get billingConfigureAiTwin => 'Cấu hình AI twin';

  @override
  String get billingWebSearchSubtitle => '(được trợ lý sử dụng)';

  @override
  String billingPackagePurchased(String balance) {
    return 'Gói đã mua: $balance μTAL';
  }

  @override
  String get billingRecommendedBadge => 'Đề xuất';

  @override
  String get billingSessionTerminatedNoFunds => 'Hết số dư — phiên đã kết thúc';

  @override
  String get billingSessionTerminatedGeneric => 'Phiên trợ lý đã kết thúc';

  @override
  String billingBuyForPrice(String price) {
    return 'Mua với giá €$price';
  }

  @override
  String get billingTxTypeTopup => 'Nạp tiền';

  @override
  String get billingTxTypeRefund => 'Hoàn tiền';

  @override
  String get billingTxTypeSpend => 'Phí';

  @override
  String get billingUnitMinute => 'phút';

  @override
  String get billingUnitRequest => 'yêu cầu';

  @override
  String get billingUnitToken => 'token';

  @override
  String get billingUnitTokens1k => '1K token';

  @override
  String get billingUnitCall => 'cuộc gọi';

  @override
  String get groupCallSelectParticipants => 'Chọn người tham gia';

  @override
  String groupCallSelectedCount(int n) {
    return '$n/7';
  }

  @override
  String get groupCallSearch => 'Tìm kiếm';

  @override
  String get groupCallMaxReached => 'Tối đa 7 người tham gia';

  @override
  String get groupCallLobbyTitle => 'Nhóm • Sảnh chờ';

  @override
  String groupCallHostLabel(String name) {
    return 'Chủ trì: $name';
  }

  @override
  String get groupCallMicHint => 'Mic sẽ kích hoạt khi kết nối';

  @override
  String get groupCallCancel => 'Hủy';

  @override
  String get groupCallNoAnswer => 'Không ai trả lời';

  @override
  String get groupCallEndedByHost => 'Cuộc gọi kết thúc bởi chủ trì';

  @override
  String get groupCallAllLeft => 'Mọi người đã rời cuộc gọi';

  @override
  String get groupCallEnded => 'Cuộc gọi kết thúc';

  @override
  String groupCallActiveTitle(int count) {
    return 'Nhóm • $count';
  }

  @override
  String get groupCallConnectionLost => 'Mất kết nối';

  @override
  String get groupCallMuteRequested => 'Chủ trì yêu cầu mọi người tắt tiếng';

  @override
  String get groupCallUnmute => 'Bật tiếng';

  @override
  String get groupCallMute => 'Tắt tiếng';

  @override
  String get groupCallMuteAll => 'Tắt tiếng tất cả';

  @override
  String get groupCallLeave => 'Rời đi';

  @override
  String get groupCallStatusCalling => 'đang gọi…';

  @override
  String get groupCallStatusDeclined => 'từ chối';

  @override
  String get groupCallStatusTimeout => 'không trả lời';

  @override
  String get groupCallStatusLeft => 'đã rời';

  @override
  String groupCallKickConfirm(String name) {
    return 'Xóa $name khỏi cuộc gọi';
  }

  @override
  String get groupCallCancelAction => 'Hủy';

  @override
  String get groupCallActiveBanner => 'Cuộc gọi đang hoạt động';

  @override
  String groupCallBannerSummary(String host, int count) {
    return 'Nhóm: $host + $count';
  }

  @override
  String groupCallBannerSummaryAlone(String host) {
    return 'Nhóm: $host';
  }

  @override
  String get groupCallCreateError => 'Không thể tạo cuộc gọi';

  @override
  String get groupCallJoinError => 'Không thể tham gia cuộc gọi';

  @override
  String get groupCallLivekitError => 'Lỗi LiveKit';

  @override
  String get groupCallDone => 'Xong';

  @override
  String get groupCallNoResults => 'Không có kết quả';

  @override
  String get groupCallNoContacts => 'Không có liên hệ';

  @override
  String get meshGcContactOffline => 'Không có trên Wi-Fi này';

  @override
  String get meshGcOnlineViaMesh => 'Trực tuyến qua mesh';

  @override
  String get meshGcMaxInvitees =>
      'Cuộc gọi nhóm hỗ trợ tối đa 4 người được mời (tổng cộng 5 người).';

  @override
  String get meshGcStart => 'Bắt đầu cuộc gọi nhóm';

  @override
  String get meshGcCancel => 'Hủy';

  @override
  String get meshGcStatusCalling => 'Đang gọi…';

  @override
  String get meshGcStatusJoined => 'Đã tham gia';

  @override
  String get meshGcStatusDeclined => 'Đã từ chối';

  @override
  String get meshGcStatusNoAnswer => 'Không có câu trả lời';

  @override
  String get meshGcStatusConnectionFailed => 'Kết nối thất bại';

  @override
  String get meshGcStatusLeft => 'Đã rời';

  @override
  String get meshGcTopTitle => 'Mesh';

  @override
  String get meshGcBusyOneOnOne => 'Hoàn thành cuộc gọi hiện tại trước.';

  @override
  String get presenceOnline => 'trực tuyến';

  @override
  String get presenceLastSeenJustNow => 'vừa mới thấy';

  @override
  String presenceLastSeenMinutesAgo(int minutes) {
    return 'đã thấy $minutes phút trước';
  }

  @override
  String presenceLastSeenToday(String time) {
    return 'đã thấy hôm nay lúc $time';
  }

  @override
  String presenceLastSeenYesterday(String time) {
    return 'đã thấy hôm qua lúc $time';
  }

  @override
  String presenceLastSeenOnDate(String date) {
    return 'đã thấy $date';
  }

  @override
  String get presenceLastSeenRecently => 'đã thấy gần đây';

  @override
  String get privacySectionTitle => 'Quyền riêng tư';

  @override
  String get privacyLastSeenLabel =>
      'Ai có thể thấy thời gian bạn truy cập lần cuối';

  @override
  String get privacyEveryone => 'Mọi người';

  @override
  String get privacyContacts => 'Chỉ danh bạ';

  @override
  String get privacyNobody => 'Không ai';

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

  @override
  String get inviteJoinTitle => 'Invitation';

  @override
  String get inviteJoinAction => 'Join';

  @override
  String get inviteOpenChat => 'Open';

  @override
  String get inviteAlreadyMember => 'You are already a member';

  @override
  String get inviteRevoked => 'This link was revoked';

  @override
  String get inviteExpired => 'This link has expired';

  @override
  String get inviteExhausted => 'This link can no longer be used';

  @override
  String get inviteNotFound => 'This link is not valid';

  @override
  String inviteMembers(int count) {
    return 'members: $count';
  }

  @override
  String get inviteLinkTitle => 'Invite link';

  @override
  String get inviteLinkCreate => 'Create link';

  @override
  String get inviteLinkCopied => 'Link copied';

  @override
  String get inviteLinkRevoke => 'Revoke';

  @override
  String get invitePublicName => 'Public handle';

  @override
  String get invitePublicNameHint => 'e.g. talerid_news';

  @override
  String get invitePublicNameSaved => 'Public handle saved';

  @override
  String get invitePublicNameTaken => 'Handle is already taken';

  @override
  String get invitePublicNameBad =>
      '5-32 characters, starting with a letter: a-z, 0-9 and _';

  @override
  String chatViews(int count) {
    return '$count views';
  }

  @override
  String get chatReadBy => 'Read by';

  @override
  String chatReadByMore(int count) {
    return 'and $count more';
  }

  @override
  String get chatReadByNobody => 'Nobody yet';

  @override
  String get chatSendSilently => 'Send without sound';

  @override
  String get chatSendLater => 'Send later';

  @override
  String chatScheduledFor(String when) {
    return 'Will be sent $when';
  }

  @override
  String get chatSendScheduled => 'Scheduled';

  @override
  String get chatFormatBold => 'Bold';

  @override
  String get chatFormatItalic => 'Italic';

  @override
  String get chatFormatStrike => 'Strikethrough';

  @override
  String get chatFormatCode => 'Code';

  @override
  String get chatFormatSpoiler => 'Spoiler';
}
