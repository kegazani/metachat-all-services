# Инструкция по запуску мобильного приложения MetaChat

## Предварительные требования

### 1. Установка Flutter SDK

1. Скачайте Flutter SDK с официального сайта: https://docs.flutter.dev/get-started/install
2. Распакуйте архив в удобное место (например, `C:\src\flutter`)
3. Добавьте Flutter в PATH:
   - Откройте "Переменные среды" (Environment Variables)
   - Добавьте путь к `flutter\bin` в переменную PATH
4. Проверьте установку:
   ```powershell
   flutter doctor
   ```

### 2. Установка Android Studio (для Android)

1. Скачайте и установите Android Studio: https://developer.android.com/studio
2. Установите Android SDK через Android Studio
3. Настройте эмулятор Android или подключите физическое устройство

### 3. Установка Xcode (для iOS, только на macOS)

1. Установите Xcode из App Store
2. Установите CocoaPods: `sudo gem install cocoapods`

## Установка зависимостей

1. Перейдите в директорию приложения:
   ```powershell
   cd metachat_app
   ```

2. Установите зависимости Flutter:
   ```powershell
   flutter pub get
   ```

3. Для iOS (только на macOS):
   ```bash
   cd ios
   pod install
   cd ..
   ```

## Настройка API базового URL

Перед запуском убедитесь, что базовый URL API настроен правильно.

Откройте файл `lib/core/di/injection.dart` и измените `baseUrl` на адрес вашего backend сервера:

```dart
baseUrl: 'http://ВАШ_IP_АДРЕС:8080',
```

Например:
- Для локального сервера: `http://localhost:8080` (для эмулятора Android используйте `http://10.0.2.2:8080`)
- Для физического устройства: `http://192.168.1.42:8080` (IP адрес вашего компьютера в локальной сети)

## Запуск приложения

### На Android эмуляторе или устройстве

1. Убедитесь, что эмулятор запущен или устройство подключено:
   ```powershell
   flutter devices
   ```

2. Запустите приложение:
   ```powershell
   flutter run
   ```

   Или для конкретного устройства:
   ```powershell
   flutter run -d <device-id>
   ```

### На iOS симуляторе или устройстве (только на macOS)

1. Убедитесь, что симулятор запущен или устройство подключено:
   ```bash
   flutter devices
   ```

2. Запустите приложение:
   ```bash
   flutter run
   ```

   Или для конкретного устройства:
   ```bash
   flutter run -d <device-id>
   ```

## Режим разработки

### Hot Reload
Во время работы приложения нажмите `r` в терминале для hot reload (быстрая перезагрузка изменений).

### Hot Restart
Нажмите `R` для hot restart (полная перезагрузка приложения).

### Остановка
Нажмите `q` для остановки приложения.

## Сборка релизной версии

### Android APK
```powershell
flutter build apk
```

APK будет находиться в `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (для Google Play)
```powershell
flutter build appbundle
```

### iOS (только на macOS)
```bash
flutter build ios
```

## Решение проблем

### Проблема: "flutter: command not found"
- Убедитесь, что Flutter добавлен в PATH
- Перезапустите терминал

### Проблема: "No devices found"
- Для Android: запустите эмулятор через Android Studio или подключите физическое устройство с включенной отладкой по USB
- Для iOS: запустите симулятор через Xcode

### Проблема: "Failed to connect to API"
- Проверьте, что backend сервер запущен
- Убедитесь, что IP адрес в `injection.dart` правильный
- Для Android эмулятора используйте `10.0.2.2` вместо `localhost`
- Проверьте, что устройство/эмулятор имеет доступ к сети

### Проблема: "Gradle build failed" (Android)
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Проблема: "CocoaPods not found" (iOS)
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
```

## Полезные команды

```powershell
flutter doctor          # Проверка окружения
flutter devices         # Список доступных устройств
flutter clean           # Очистка build файлов
flutter pub get         # Установка зависимостей
flutter pub upgrade     # Обновление зависимостей
flutter analyze         # Проверка кода
flutter test            # Запуск тестов
```

