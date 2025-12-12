# Инструкция по настройке базы данных

## Вариант 1: Через pgAdmin (рекомендуется для Windows)

1. Откройте pgAdmin
2. Подключитесь к серверу PostgreSQL
3. Правый клик на "Databases" → "Create" → "Database"
4. Введите имя: `metachat`
5. Нажмите "Save"

## Вариант 2: Через psql (командная строка)

### Найдите psql в Windows:

Обычно находится в:
```
C:\Program Files\PostgreSQL\<версия>\bin\psql.exe
```

### Запустите:

```powershell
& "C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres
```

### Затем выполните:

```sql
CREATE DATABASE metachat;
\q
```

## Вариант 3: Используя SQL скрипт

Выполните файл `setup_database.sql`:

```powershell
& "C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres -f setup_database.sql
```

## Проверка

После создания базы данных, запустите сервис снова (F5 в VS Code).

Сервис автоматически создаст необходимые таблицы при первом запуске.

## Текущие настройки подключения

- Host: localhost
- Port: 5432
- User: postgres
- Password: postgres
- Database: metachat

Эти настройки указаны в `config/config.yaml` и в launch.json

