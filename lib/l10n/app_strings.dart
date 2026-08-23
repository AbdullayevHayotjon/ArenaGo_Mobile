class AppStrings {
  AppStrings(this.language);
  final String language;

  static const _values = <String, Map<String, String>>{
    'uz': {
      'welcome': 'Xush kelibsiz!',
      'loginText':
          'ArenaGo mobil ilovasiga kirish uchun ma’lumotlaringizni kiriting.',
      'phone': 'Telefon raqami',
      'password': 'Parol',
      'login': 'Kirish',
      'loggingIn': 'Kirilmoqda...',
      'invalidForm': 'Telefon raqami yoki parolni to‘g‘ri kiriting.',
      'customerOnly': 'Siz faqat ArenaGo web ilovasi orqali foydalana olasiz.',
      'networkError':
          'Serverga ulanib bo‘lmadi. Internet va server manzilini tekshiring.',
      'loginError': 'Tizimga kirishda xatolik yuz berdi.',
      'createPin': 'PIN-kod yarating',
      'createPinText': 'Ilovaga keyingi kirishlar uchun 4 xonali PIN kiriting.',
      'confirmPin': 'PIN-kodni tasdiqlang',
      'confirmPinText': 'Xuddi shu 4 ta raqamni yana bir marta kiriting.',
      'unlock': 'Xush kelibsiz',
      'unlockText': 'ArenaGo’ga kirish uchun PIN-kodingizni kiriting.',
      'pinMismatch': 'PIN-kodlar mos kelmadi. Qayta urinib ko‘ring.',
      'pinWrong': 'PIN-kod noto‘g‘ri.',
      'logout': 'Chiqish',
      'hello': 'Salom',
      'ready': 'ArenaGo mobil ilovasi ishga tayyor!',
      'readyText':
          'Keyingi API va sahifalarni shu yerdan boshlab birma-bir qo‘shamiz.',
      'secure': 'Xavfsiz kirish',
      'secureText': 'Tokenlar himoyalangan xotirada saqlanmoqda',
      'theme': 'Rejim',
      'language': 'Til',
    },
    'ru': {
      'welcome': 'Добро пожаловать!',
      'loginText': 'Введите данные для входа в мобильное приложение ArenaGo.',
      'phone': 'Номер телефона',
      'password': 'Пароль',
      'login': 'Войти',
      'loggingIn': 'Выполняется вход...',
      'invalidForm': 'Правильно введите номер телефона и пароль.',
      'customerOnly': 'Вы можете пользоваться только веб-приложением ArenaGo.',
      'networkError': 'Не удалось подключиться к серверу. Проверьте интернет и адрес сервера.',
      'loginError': 'Произошла ошибка при входе в систему.',
      'createPin': 'Создайте PIN-код',
      'createPinText': 'Введите 4-значный PIN для последующих входов.',
      'confirmPin': 'Подтвердите PIN-код',
      'confirmPinText': 'Повторно введите те же четыре цифры.',
      'unlock': 'Добро пожаловать',
      'unlockText': 'Введите PIN-код для входа в ArenaGo.',
      'pinMismatch': 'PIN-коды не совпадают. Попробуйте ещё раз.',
      'pinWrong': 'Неверный PIN-код.',
      'logout': 'Выйти',
      'hello': 'Здравствуйте',
      'ready': 'Мобильное приложение ArenaGo готово!',
      'readyText': 'Следующие API и страницы будем добавлять отсюда поэтапно.',
      'secure': 'Безопасный вход',
      'secureText': 'Токены хранятся в защищённом хранилище',
      'theme': 'Режим',
      'language': 'Язык',
    },
  };

  String t(String key) => _values[language]?[key] ?? _values['uz']![key] ?? key;
}
