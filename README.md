# Driver App

Мобильное приложение для водителей с функционалом управления заявками на перевозку.

## Функциональность

- Авторизация по номеру телефона
- Просмотр списка заявок
- Детальная информация о заявке
- Отметки о прибытии/убытии на погрузку/разгрузку
- Фотографирование ТТН
- Подпись документов
- Интеграция с Яндекс.Картами

## Технологии

- Flutter
- Dart
- Firebase Authentication
- Image Picker
- URL Launcher

## Установка

1. Клонируйте репозиторий:
```bash
git clone https://github.com/your-username/driver-app.git
```

2. Перейдите в директорию проекта:
```bash
cd driver-app
```

3. Установите зависимости:
```bash
flutter pub get
```

4. Запустите приложение:
```bash
flutter run
```

## Структура проекта

```
lib/
  ├── main.dart
  ├── screens/
  │   ├── phone_input_screen.dart
  │   ├── verification_screen.dart
  │   ├── requests_screen.dart
  │   ├── request_details_screen.dart
  │   ├── loading_screen.dart
  │   ├── unloading_screen.dart
  │   └── driver_profile_screen.dart
  └── widgets/
      └── ...
```

## Лицензия

MIT
