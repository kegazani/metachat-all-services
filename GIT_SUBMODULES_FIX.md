# Исправление проблемы с Git Submodules

## Проблема

Все Go-сервисы в проекте были зарегистрированы как Git submodules, но не были правильно инициализированы. Это приводило к тому, что:

1. В Git были сохранены только ссылки на коммиты (режим 160000)
2. Сами файлы не отслеживались в основном репозитории
3. При клонировании репозитория директории были пустыми
4. При попытке работать с файлами возникала ошибка "Pathspec is in submodule"

## Затронутые сервисы

- metachat-api-gateway
- metachat-chat-service
- metachat-diary-service
- metachat-event-sourcing
- metachat-match-request-service
- metachat-matching-service
- metachat-proto
- metachat-user-service

## Решение

Submodules были конвертированы в обычные директории:

1. Удалены ссылки на submodules из Git индекса
2. Удалены .git директории из подмодулей (если были)
3. Все файлы добавлены как обычные файлы в основной репозиторий
4. Добавлен `.gitignore` для исключения бинарных и отладочных файлов

## Выполненные действия

```powershell
.\fix-submodules.ps1
git add metachat-all-services/.gitignore
git rm --cached <binary-files>
git commit -m "Convert submodules to regular directories"
```

## Исключенные файлы

Следующие типы файлов теперь игнорируются:
- `__debug_bin*` - отладочные бинарники
- `*.exe` - исполняемые файлы Windows
- `main` - скомпилированные Go бинарники
- `.vscode/` - настройки VS Code (опционально)
- `vendor/` - зависимости Go
- `__pycache__/`, `*.pyc` - кэш Python

## Проверка

После коммита, файлы теперь доступны:

```bash
git ls-files metachat-all-services/metachat-api-gateway/
git ls-files metachat-all-services/metachat-user-service/
```

## Рекомендации

1. Не создавайте submodules без файла `.gitmodules`
2. Используйте Go modules для управления зависимостями между сервисами
3. Если нужна модульность, рассмотрите mono-repo подход
4. Добавьте `.gitignore` в корень каждого сервиса

## Файлы

- `fix-submodules.ps1` - скрипт для конвертации (можно удалить после коммита)
- `metachat-all-services/.gitignore` - правила игнорирования для всех сервисов

