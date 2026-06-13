/// Password and email rules for Firebase email accounts.
class EmailAuthPolicy {
  EmailAuthPolicy._();

  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _hasLetter = RegExp(r'[A-Za-zА-Яа-яЁё]');
  static final RegExp _hasDigit = RegExp(r'\d');

  static String passwordRequirementsHint(String lang) {
    switch (lang) {
      case 'en':
        return 'At least 8 characters, with a letter and a number';
      case 'de':
        return 'Mind. 8 Zeichen, mit Buchstabe und Zahl';
      case 'ru':
      default:
        return 'Минимум 8 символов, буква и цифра';
    }
  }

  static String? validateEmail(String raw, String lang) {
    final email = raw.trim();
    if (email.isEmpty) {
      return _msg(lang, ru: 'Введи email', en: 'Enter your email', de: 'E-Mail eingeben');
    }
    if (!_emailRegex.hasMatch(email)) {
      return _msg(lang, ru: 'Некорректный email', en: 'Invalid email address', de: 'Ungültige E-Mail');
    }
    return null;
  }

  static String? validatePassword(String raw, String lang) {
    final password = raw;
    if (password.length < minPasswordLength) {
      return _msg(
        lang,
        ru: 'Пароль: минимум $minPasswordLength символов',
        en: 'Password: at least $minPasswordLength characters',
        de: 'Passwort: mind. $minPasswordLength Zeichen',
      );
    }
    if (password.length > maxPasswordLength) {
      return _msg(lang, ru: 'Пароль слишком длинный', en: 'Password is too long', de: 'Passwort ist zu lang');
    }
    if (!_hasLetter.hasMatch(password)) {
      return _msg(
        lang,
        ru: 'Пароль должен содержать букву',
        en: 'Password must include a letter',
        de: 'Passwort braucht einen Buchstaben',
      );
    }
    if (!_hasDigit.hasMatch(password)) {
      return _msg(
        lang,
        ru: 'Пароль должен содержать цифру',
        en: 'Password must include a number',
        de: 'Passwort braucht eine Zahl',
      );
    }
    return null;
  }

  static String? validatePasswordConfirm(String password, String confirm, String lang) {
    if (password != confirm) {
      return _msg(
        lang,
        ru: 'Пароли не совпадают',
        en: 'Passwords do not match',
        de: 'Passwörter stimmen nicht überein',
      );
    }
    return null;
  }

  static String? validateDisplayName(String raw, String lang, {required bool required}) {
    final name = raw.trim();
    if (required && name.isEmpty) {
      return _msg(lang, ru: 'Введи имя аккаунта', en: 'Enter account name', de: 'Kontoname eingeben');
    }
    if (name.length > 40) {
      return _msg(lang, ru: 'Имя слишком длинное', en: 'Name is too long', de: 'Name ist zu lang');
    }
    return null;
  }

  static String friendlyFirebaseError(String code, String lang, {String? fallback}) {
    switch (code) {
      case 'invalid-email':
        return _msg(lang, ru: 'Некорректный email', en: 'Invalid email', de: 'Ungültige E-Mail');
      case 'user-disabled':
        return _msg(lang, ru: 'Аккаунт отключён', en: 'Account disabled', de: 'Konto deaktiviert');
      case 'user-not-found':
        return _msg(
          lang,
          ru: 'Аккаунт с таким email не найден',
          en: 'No account with this email',
          de: 'Kein Konto mit dieser E-Mail',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return _msg(
          lang,
          ru: 'Неверный email или пароль',
          en: 'Wrong email or password',
          de: 'Falsche E-Mail oder Passwort',
        );
      case 'email-already-in-use':
        return _msg(
          lang,
          ru: 'Этот email уже зарегистрирован',
          en: 'This email is already registered',
          de: 'Diese E-Mail ist bereits registriert',
        );
      case 'weak-password':
        return passwordRequirementsHint(lang);
      case 'too-many-requests':
        return _msg(
          lang,
          ru: 'Слишком много попыток. Подожди немного',
          en: 'Too many attempts. Try again later',
          de: 'Zu viele Versuche. Später erneut versuchen',
        );
      case 'network-request-failed':
        return _msg(
          lang,
          ru: 'Нет сети. Проверь подключение',
          en: 'Network error. Check connection',
          de: 'Netzwerkfehler. Verbindung prüfen',
        );
      default:
        return fallback ?? code;
    }
  }

  static String registrationVerificationSent(String email, String lang) {
    return _msg(
      lang,
      ru: 'Код подтверждения отправлен на $email. Введи его в приложении.',
      en: 'Verification code sent to $email. Enter it in the app.',
      de: 'Bestätigungscode an $email gesendet. In der App eingeben.',
    );
  }

  static String passwordResetSent(String email, String lang) {
    return _msg(
      lang,
      ru: 'Ссылка для сброса пароля отправлена на $email',
      en: 'Password reset link sent to $email',
      de: 'Link zum Zurücksetzen wurde an $email gesendet',
    );
  }

  static String emailNotVerifiedHint(String lang) {
    return _msg(
      lang,
      ru: 'Подтверди email — введи код из письма',
      en: 'Verify your email — enter the code from your inbox',
      de: 'Bestätige deine E-Mail — Code aus der E-Mail eingeben',
    );
  }

  static String verificationResent(String lang) {
    return _msg(
      lang,
      ru: 'Новый код отправлен на почту',
      en: 'A new code was sent to your email',
      de: 'Neuer Code wurde per E-Mail gesendet',
    );
  }

  static String verificationLinkSent(String lang) {
    return _msg(
      lang,
      ru: 'Письмо со ссылкой отправлено. Открой его и нажми ссылку, затем «Проверить»',
      en: 'Verification link sent. Open the email, tap the link, then tap Check',
      de: 'Bestätigungslink gesendet. E-Mail öffnen, Link tippen, dann Prüfen',
    );
  }

  static String checkSpamHint(String lang) {
    return _msg(
      lang,
      ru: 'Не видишь письмо? Проверь «Спам» и «Промоакции»',
      en: 'No email? Check Spam and Promotions folders',
      de: 'Keine E-Mail? Spam- und Werbeordner prüfen',
    );
  }

  static String sendingCodeHint(String lang) {
    return _msg(
      lang,
      ru: 'Отправляем код на почту…',
      en: 'Sending code to your inbox…',
      de: 'Code wird per E-Mail gesendet…',
    );
  }

  static String signInRequiredHint(String lang) {
    return _msg(
      lang,
      ru: 'Сначала войди в аккаунт',
      en: 'Sign in to your account first',
      de: 'Zuerst im Konto anmelden',
    );
  }

  static String invalidOtpHint(String lang) {
    return _msg(
      lang,
      ru: 'Введи 6-значный код из письма',
      en: 'Enter the 6-digit code from your email',
      de: 'Gib den 6-stelligen Code aus der E-Mail ein',
    );
  }

  static String? validateOtpCode(String raw, String lang) {
    final code = raw.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      return invalidOtpHint(lang);
    }
    return null;
  }

  static String emailVerificationRequired(String lang) {
    return _msg(
      lang,
      ru: 'Подтверди email, чтобы продолжить',
      en: 'Verify your email to continue',
      de: 'Bestätige deine E-Mail, um fortzufahren',
    );
  }

  static String friendlyFunctionsError(String code, String? message, String lang) {
    switch (code) {
      case 'unauthenticated':
        return signInRequiredHint(lang);
      case 'already-exists':
        return _msg(
          lang,
          ru: 'Email уже подтверждён',
          en: 'Email is already verified',
          de: 'E-Mail ist bereits bestätigt',
        );
      case 'resource-exhausted':
        return message ??
            _msg(
              lang,
              ru: 'Слишком много попыток. Подожди немного',
              en: 'Too many attempts. Try again later',
              de: 'Zu viele Versuche. Später erneut versuchen',
            );
      case 'deadline-exceeded':
        return _msg(
          lang,
          ru: 'Код истёк. Запроси новый',
          en: 'Code expired. Request a new one',
          de: 'Code abgelaufen. Neuen anfordern',
        );
      case 'not-found':
      case 'unavailable':
      case 'internal':
        if (message != null && message.isNotEmpty) return message;
        return _msg(
          lang,
          ru: 'Не удалось отправить письмо. Проверь интернет и попробуй снова',
          en: 'Could not send email. Check your connection and try again',
          de: 'E-Mail konnte nicht gesendet werden. Verbindung prüfen',
        );
      case 'invalid-argument':
        return message ?? invalidOtpHint(lang);
      case 'failed-precondition':
        return message ??
            _msg(
              lang,
              ru: 'Сервис почты не настроен. Обратись к разработчику',
              en: 'Email service is not configured. Contact support',
              de: 'E-Mail-Dienst nicht konfiguriert. Support kontaktieren',
            );
      case 'permission-denied':
        return _msg(
          lang,
          ru: 'Код не подходит к этому аккаунту',
          en: 'Code does not match this account',
          de: 'Code passt nicht zu diesem Konto',
        );
      default:
        return message ?? code;
    }
  }

  static String _msg(
    String lang, {
    required String ru,
    required String en,
    required String de,
  }) {
    switch (lang) {
      case 'en':
        return en;
      case 'de':
        return de;
      case 'ru':
      default:
        return ru;
    }
  }
}
