# Driver App

Мобильное приложение водителя 7Rights: рейсы, статусы, гео, фото, ПЭП, RuStore Push.

## Запуск

```bash
flutter pub get
flutter run
```

Вход — по телефону из TMS. Служебный код `1111` только в **debug**.

## Уведомления (RuStore Push)

Клиент регистрирует токен после входа (`POST /api/v1/driver/me/device`).  
Тап по пушу открывает рейс по `trip_id` из data.

Android-сборка (обязательно Project ID):

```bash
flutter build apk --release -PRUSTORE_PUSH_PROJECT_ID=your_project_id
```

В GitHub Actions тот же ID берётся из секрета `RUSTORE_PUSH_PROJECT_ID`.

Бэкенд (`prospft`):
- `RUSTORE_PUSH_PROJECT_ID`
- `RUSTORE_PUSH_SERVICE_TOKEN`
- `RUSTORE_PUSH_DEADLINE_MINUTES=60`
- cron: `driver:send-deadline-reminders` каждые 5 минут (см. `app/Console/Kernel.php`)
- на сервере должен крутиться `php artisan schedule:run` (или supervisor/cron каждую минуту)

Docs: `prospft/docs/driver-rustore-push.md`

## Структура

```
lib/
  ├── main.dart
  ├── screens/   # phone, verify, trips, details, profile
  ├── services/  # push, pep, location, maps
  └── widgets/
```
