# Запуск Flutter приложения на физическом iPhone

## Предварительные требования

1. **Mac с установленными:**
   - Xcode (последняя версия)
   - Flutter SDK
   - CocoaPods (`sudo gem install cocoapods`)

2. **Apple Developer аккаунт:**
   - Бесплатный Apple ID достаточно для разработки
   - Или платный аккаунт ($99/год) для распространения

3. **Физический iPhone:**
   - Подключен через USB кабель
   - Разблокирован
   - Настроено "Доверие этому компьютеру"

## Шаги по запуску

### 1. Подключите iPhone к Mac

- Подключите iPhone через USB кабель
- Разблокируйте iPhone
- Если появится запрос "Довериться этому компьютеру?" - нажмите "Довериться"
- Введите пароль на iPhone для подтверждения

### 2. Проверьте подключение устройства

Откройте терминал и выполните:

```bash
cd /Users/kgz/Desktop/metachat/metachat_app
flutter devices
```

Вы должны увидеть ваш iPhone в списке. Если его нет:
- Проверьте USB кабель
- Убедитесь, что iPhone разблокирован
- Попробуйте другой USB порт

### 3. Настройте Xcode проект

#### Вариант A: Через Xcode (рекомендуется для первого раза)

1. Откройте проект в Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. В Xcode:
   - Выберите проект `Runner` в левой панели
   - Выберите target `Runner`
   - Перейдите на вкладку **Signing & Capabilities**
   - Снимите галочку **Automatically manage signing** (или оставьте, если есть Apple Developer аккаунт)
   - В разделе **Team** выберите вашу команду разработчика (или "Add Account..." для добавления Apple ID)
   - Xcode автоматически создаст provisioning profile

3. В разделе **Bundle Identifier**:
   - Текущий: `com.example.metachatApp`
   - Вы можете изменить его на уникальный (например, `com.yourname.metachatApp`)
   - Bundle ID должен быть уникальным для вашего Apple ID

4. В верхней панели Xcode выберите:
   - **Device**: ваш подключенный iPhone
   - **Scheme**: Runner

#### Вариант B: Автоматическая настройка через Flutter

Если у вас настроен Apple Developer аккаунт, Flutter может настроить всё автоматически.

### 4. Установите зависимости CocoaPods

```bash
cd ios
pod install
cd ..
```

Если это первый раз, может потребоваться:
```bash
sudo gem install cocoapods
pod setup
```

### 5. Включите Developer Mode на iPhone (для iOS 16+)

**Важно:** Для iOS 16 и новее необходимо включить Developer Mode.

1. На iPhone перейдите: **Настройки → Конфиденциальность и безопасность**
2. Прокрутите вниз и найдите раздел **Режим разработчика** (Developer Mode)
3. Включите переключатель **Режим разработчика**
4. iPhone попросит перезагрузиться - нажмите **Перезагрузить**
5. После перезагрузки появится запрос на подтверждение - нажмите **Включить** и введите пароль iPhone

**Примечание:** Если вы не видите опцию "Режим разработчика", попробуйте:
- Сначала попробовать установить приложение (шаг 6), и режим появится автоматически
- Убедитесь, что iOS версия 16.0 или новее

### 6. Разрешите разработку на iPhone

1. На iPhone перейдите: **Настройки → Основные → VPN и управление устройством**
2. Найдите профиль разработчика (ваше имя или имя команды)
3. Нажмите на него и выберите **Доверять**

### 7. Запустите приложение

#### Способ 1: Через Flutter CLI (рекомендуется)

```bash
cd /Users/kgz/Desktop/metachat/metachat_app
flutter run -d <device-id>
```

Где `<device-id>` - это ID вашего iPhone из `flutter devices`.

Или просто:
```bash
flutter run
```
Flutter автоматически выберет подключенное устройство.

#### Способ 2: Через Xcode

1. Откройте `ios/Runner.xcworkspace` в Xcode
2. Выберите ваш iPhone в качестве устройства для запуска
3. Нажмите кнопку **Run** (▶️) или `Cmd + R`

### 8. Разрешите установку приложения на iPhone

При первом запуске на iPhone может появиться:
- Запрос на установку приложения - разрешите
- Предупреждение о безопасности - нажмите "Продолжить"
- Возможна необходимость ввести пароль iPhone

## Решение проблем

### Ошибка: "No code signing identities found"

**Решение:**
1. Откройте Xcode → Preferences → Accounts
2. Добавьте ваш Apple ID
3. Нажмите "Download Manual Profiles"
4. В проекте Runner → Signing & Capabilities выберите вашу команду

### Ошибка: "Failed to register bundle identifier"

**Решение:**
- Измените Bundle Identifier на уникальный (например, `com.yourname.metachatApp`)
- В Xcode: Runner → Signing & Capabilities → Bundle Identifier

### Ошибка: "Unable to install application"

**Решение:**
- Проверьте, что iPhone разблокирован
- Проверьте, что есть свободное место на iPhone
- Перезагрузите iPhone
- Проверьте, что приложение удалено с iPhone (если было установлено ранее)

### Ошибка: "Developer Disk Image not found"

**Решение:**
- Обновите Xcode до последней версии
- Убедитесь, что версия iOS на iPhone поддерживается вашей версией Xcode
- Возможно, нужно обновить iOS на iPhone

### Приложение устанавливается, но не запускается

**Решение:**
1. На iPhone: Настройки → Основные → VPN и управление устройством
2. Найдите профиль разработчика и доверьте ему
3. Перезапустите приложение

### Ошибка: "Developer Mode is not enabled" или требуется Developer Mode

**Решение:**
1. На iPhone: Настройки → Конфиденциальность и безопасность → Режим разработчика
2. Включите **Режим разработчика**
3. Перезагрузите iPhone
4. После перезагрузки подтвердите включение режима разработчика
5. Попробуйте запустить приложение снова

**Важно:** Developer Mode необходимо включать каждый раз после обновления iOS или сброса настроек.

## Проверка успешного запуска

После успешного запуска:
1. Приложение должно появиться на экране iPhone
2. В терминале вы увидите логи Flutter
3. Hot reload будет работать (сохраните файл, чтобы увидеть изменения)

## Дополнительные команды

### Просмотр подключенных устройств
```bash
flutter devices
```

### Очистка и пересборка
```bash
flutter clean
cd ios
pod deintegrate
pod install
cd ..
flutter pub get
flutter run
```

### Запуск в release режиме
```bash
flutter run --release
```

### Просмотр логов
```bash
flutter logs
```

## Полезные ссылки

- [Flutter iOS Setup](https://docs.flutter.dev/deployment/ios)
- [Xcode Signing](https://developer.apple.com/documentation/xcode/managing-your-team-s-signing-assets)
- [Troubleshooting iOS](https://docs.flutter.dev/deployment/ios#troubleshooting)

