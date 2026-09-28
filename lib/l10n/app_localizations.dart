import 'package:flutter/material.dart';

class AppLanguage extends ChangeNotifier {
  AppLanguage([this._locale = const Locale('en')]);

  Locale _locale;
  Locale get locale => _locale;

  void change(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguage> {
  const AppLanguageScope({
    super.key,
    required AppLanguage language,
    required super.child,
  }) : super(notifier: language);

  static AppLanguage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguageScope>()!.notifier!;
}

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('tr')];

  static AppLocalizations of(BuildContext context) =>
      AppLocalizations(AppLanguageScope.of(context).locale);

  String text(String key) =>
      (_values[locale.languageCode] ?? _values['en']!)[key] ??
      _values['en']![key] ??
      key;

  static const _values = <String, Map<String, String>>{
    'en': {
      'language': 'Language',
      'english': 'English',
      'turkish': 'Türkçe',
      'emailAddress': 'Email address',
      'password': 'Password',
      'welcomeBack': 'Welcome back.',
      'loginSubtitle': 'Take a breath. Make time for your practice.',
      'logIn': 'Log in',
      'loggingIn': 'Logging in…',
      'newHere': 'New to Backstreet Pilates?',
      'createAccount': 'Create an account',
      'createAccountAction': 'Create account',
      'startWithYou': 'Start with you.',
      'signupSubtitle':
          'A stronger, calmer everyday begins with one small step.',
      'yourName': 'Your name',
      'useEightCharacters': 'Use at least 8 characters.',
      'creatingAccount': 'Creating account…',
      'alreadyHaveAccount': 'Already have an account?',
      'backToLogin': 'Back to log in',
      'checkYourEmail': 'Check your email',
      'emailConfirmation':
          'We sent a confirmation link to your email address. Confirm it, then return here to log in.',
      'signOut': 'Sign out',
      'adminOverview': 'ADMIN OVERVIEW',
      'studioAtGlance': 'Your studio, at a glance.',
      'adminSubtitle': 'Keep track of the month and support your members.',
      'membershipManagement': 'MEMBERSHIP MANAGEMENT',
      'paymentsAwaitingApproval': 'Payments awaiting approval',
      'reviewCashPayments':
          'Review cash payments and activate member packages.',
      'cashRequests': 'Cash payment requests',
      'refresh': 'Refresh',
      'confirmCashPayment': 'Confirm cash payment?',
      'confirmPayment': 'Confirm payment',
      'cancel': 'Cancel',
      'membershipCreated': 'Membership for {name} was created.',
      'requestedStart': 'Requested start: {date}',
      'confirming': 'Confirming…',
      'confirmCash': 'Confirm cash payment',
      'noCashPayments': 'No cash payments are waiting.',
      'cashRequestsLoadError': 'Cash requests could not be loaded.',
      'tryAgain': 'Try again',
      'cashRequestSent': 'Cash payment request sent to the studio.',
      'cardPaymentsSoon': 'Card payments will be available soon.',
      'profile': 'Profile',
      'editProfile': 'Edit profile',
      'profileSaved': 'Profile saved.',
      'profileSavedConfirmEmail':
          'Profile saved. Confirm your new email address to finish changing it.',
      'profileLoadError': 'Profile could not be loaded.',
      'name': 'Name',
      'phoneNumber': 'Phone number',
      'dateOfBirth': 'Date of birth',
      'notProvided': 'Not provided',
      'gender': 'Gender',
      'female': 'Female',
      'male': 'Male',
      'nonBinary': 'Non-binary',
      'preferNotToSay': 'Prefer not to say',
      'saveProfile': 'Save profile',
      'saving': 'Saving…',
      'changePassword': 'Change password',
      'newPassword': 'New password',
      'confirmNewPassword': 'Confirm new password',
      'chooseNewPassword': 'Choose a new password with at least 8 characters.',
      'passwordChanged': 'Your password was changed.',
      'enterEightCharacters': 'Use at least 8 characters.',
      'passwordsDoNotMatch': 'Passwords do not match.',
      'packages': 'Packages',
      'gotIt': 'Got it',
      'explorePackages': 'Explore packages',
      'currentPackage': 'YOUR CURRENT PACKAGE',
      'nextRhythm': 'FIND YOUR NEXT RHYTHM',
      'recentPractice': 'YOUR RECENT PRACTICE',
      'noPackagesAvailable': 'No packages are available right now.',
      'cash': 'Cash',
      'creditCard': 'Credit card',
      'sendRequest': 'Send request',
      'activePackages': 'Active member packages',
      'classesRemaining': '{count} classes remaining',
      'until': 'Until {date}',
      'myPackages': 'My packages',
      'noApprovedPackages': 'No approved packages yet',
      'approvedPackagesLoadError': 'Packages could not be loaded',
      'profilePhotoLater':
          'Profile photo will be available in a future update.',
      'accountSecurity': 'ACCOUNT & SECURITY',
      'keepAccountSecure': 'Keep your account secure.',
      'member': 'Member',
      'package': 'Package',
      'paymentMethod': 'Payment method',
      'recordCashPayment': 'Record a cash payment',
      'recordPaymentGrant': 'Record payment and grant package',
      'previewOnly': 'Preview only — no package or payment has been recorded.',
    },
    'tr': {
      'language': 'Dil',
      'english': 'English',
      'turkish': 'Türkçe',
      'emailAddress': 'E-posta adresi',
      'password': 'Şifre',
      'welcomeBack': 'Tekrar hoş geldin.',
      'loginSubtitle': 'Nefes al. Pratiğine zaman ayır.',
      'logIn': 'Giriş yap',
      'loggingIn': 'Giriş yapılıyor…',
      'newHere': 'Backstreet Pilates’a yeni misin?',
      'createAccount': 'Hesap oluştur',
      'createAccountAction': 'Hesap oluştur',
      'startWithYou': 'Kendinle başla.',
      'signupSubtitle':
          'Daha güçlü ve sakin bir günlük yaşam küçük bir adımla başlar.',
      'yourName': 'Adın',
      'useEightCharacters': 'En az 8 karakter kullan.',
      'creatingAccount': 'Hesap oluşturuluyor…',
      'alreadyHaveAccount': 'Zaten hesabın var mı?',
      'backToLogin': 'Girişe dön',
      'checkYourEmail': 'E-postanı kontrol et',
      'emailConfirmation':
          'E-posta adresine bir onay bağlantısı gönderdik. Onayladıktan sonra buraya dönüp giriş yap.',
      'signOut': 'Çıkış yap',
      'adminOverview': 'YÖNETİCİ GENEL BAKIŞ',
      'studioAtGlance': 'Stüdyon, bir bakışta.',
      'adminSubtitle': 'Ayı takip et ve üyelerini destekle.',
      'membershipManagement': 'ÜYELİK YÖNETİMİ',
      'paymentsAwaitingApproval': 'Onay bekleyen ödemeler',
      'reviewCashPayments':
          'Nakit ödemeleri incele ve üye paketlerini aktifleştir.',
      'cashRequests': 'Nakit ödeme talepleri',
      'refresh': 'Yenile',
      'confirmCashPayment': 'Nakit ödeme onaylansın mı?',
      'confirmPayment': 'Ödemeyi onayla',
      'cancel': 'Vazgeç',
      'membershipCreated': '{name} için üyelik oluşturuldu.',
      'requestedStart': 'Talep edilen başlangıç: {date}',
      'confirming': 'Onaylanıyor…',
      'confirmCash': 'Nakit ödemeyi onayla',
      'noCashPayments': 'Onay bekleyen nakit ödeme yok.',
      'cashRequestsLoadError': 'Nakit ödeme talepleri yüklenemedi.',
      'tryAgain': 'Tekrar dene',
      'cashRequestSent': 'Nakit ödeme talebi stüdyoya gönderildi.',
      'cardPaymentsSoon': 'Kartla ödeme yakında kullanılabilecek.',
      'profile': 'Profil',
      'editProfile': 'Profili düzenle',
      'profileSaved': 'Profil kaydedildi.',
      'profileSavedConfirmEmail':
          'Profil kaydedildi. E-posta değişikliğini tamamlamak için yeni adresini onayla.',
      'profileLoadError': 'Profil yüklenemedi.',
      'name': 'Ad',
      'phoneNumber': 'Telefon numarası',
      'dateOfBirth': 'Doğum tarihi',
      'notProvided': 'Belirtilmedi',
      'gender': 'Cinsiyet',
      'female': 'Kadın',
      'male': 'Erkek',
      'nonBinary': 'İkili olmayan',
      'preferNotToSay': 'Belirtmek istemiyorum',
      'saveProfile': 'Profili kaydet',
      'saving': 'Kaydediliyor…',
      'changePassword': 'Şifre değiştir',
      'newPassword': 'Yeni şifre',
      'confirmNewPassword': 'Yeni şifreyi doğrula',
      'chooseNewPassword': 'En az 8 karakterden oluşan yeni bir şifre belirle.',
      'passwordChanged': 'Şifren değiştirildi.',
      'enterEightCharacters': 'En az 8 karakter kullan.',
      'passwordsDoNotMatch': 'Şifreler eşleşmiyor.',
      'packages': 'Paketler',
      'gotIt': 'Anladım',
      'explorePackages': 'Paketleri keşfet',
      'currentPackage': 'MEVCUT PAKETİN',
      'nextRhythm': 'SIRADAKİ RİTMİN',
      'recentPractice': 'SON PRATİKLERİN',
      'noPackagesAvailable': 'Şu anda paket bulunmuyor.',
      'cash': 'Nakit',
      'creditCard': 'Kredi kartı',
      'sendRequest': 'Talep gönder',
      'activePackages': 'Aktif üye paketleri',
      'classesRemaining': '{count} ders kaldı',
      'until': '{date} tarihine kadar',
      'myPackages': 'Paketlerim',
      'noApprovedPackages': 'Henüz onaylanmış paketin yok',
      'approvedPackagesLoadError': 'Paketler yüklenemedi',
      'profilePhotoLater':
          'Profil fotoğrafı gelecekteki bir güncellemede eklenecek.',
      'accountSecurity': 'HESAP VE GÜVENLİK',
      'keepAccountSecure': 'Hesabını güvende tut.',
      'member': 'Üye',
      'package': 'Paket',
      'paymentMethod': 'Ödeme yöntemi',
      'recordCashPayment': 'Nakit ödeme kaydet',
      'recordPaymentGrant': 'Ödemeyi kaydet ve paketi tanımla',
      'previewOnly': 'Önizleme — henüz paket veya ödeme kaydı oluşturulmadı.',
    },
  };
}

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final language = AppLanguageScope.of(context);
    return PopupMenuButton<Locale>(
      tooltip: strings.text('language'),
      icon: const Icon(Icons.language_outlined),
      onSelected: language.change,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: const Locale('en'),
          child: Text(strings.text('english')),
        ),
        PopupMenuItem(
          value: const Locale('tr'),
          child: Text(strings.text('turkish')),
        ),
      ],
    );
  }
}
