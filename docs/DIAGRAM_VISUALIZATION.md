# Инструкция по визуализации диаграмм

## Онлайн инструменты

### 1. Mermaid Live Editor
Самый простой способ визуализировать диаграммы:

1. Откройте https://mermaid.live/
2. Скопируйте код диаграммы из файлов:
   - `DETAILED_FLOW_DIAGRAMS.md`
   - `FLOW_DIAGRAMS.md`
3. Вставьте в редактор
4. Нажмите "Actions" → "Download PNG" или "Download SVG"

### 2. GitHub/GitLab
Если файлы находятся в репозитории:
- GitHub автоматически отображает Mermaid диаграммы в `.md` файлах
- Просто откройте файл в браузере на GitHub

## Локальная генерация изображений

### Использование Mermaid CLI

1. **Установка:**
```bash
npm install -g @mermaid-js/mermaid-cli
```

2. **Генерация изображений:**
```bash
# Из отдельного файла с диаграммой
mmdc -i diagram.mmd -o diagram.png

# Или из Markdown файла (извлечет все диаграммы)
mmdc -i DETAILED_FLOW_DIAGRAMS.md -o output/
```

### Использование Python

1. **Установка библиотек:**
```bash
pip install mermaid
```

2. **Создание скрипта:**
```python
from mermaid import Mermaid

mermaid_code = """
graph TB
    A[Start] --> B[Process]
    B --> C[End]
"""

mermaid = Mermaid(mermaid_code)
mermaid.to_png('output.png')
```

## Рекомендуемые диаграммы для экспорта

Из файла `DETAILED_FLOW_DIAGRAMS.md`:

1. **Общая архитектура системы** - для презентаций архитектуры
2. **Flow 3: Анализ настроения (детальный)** - для объяснения AI pipeline
3. **Flow 4: Определение личности Big Five** - для объяснения расчета личности
4. **Полный цикл: От записи до рекомендаций** - для общего обзора процесса
5. **Kafka Topics и Consumer Groups** - для документации событийной архитектуры
6. **Схема базы данных** - для документации данных

## Интеграция в документацию

Диаграммы уже включены в Markdown файлы и будут автоматически отображаться в:
- GitHub
- GitLab
- VS Code (с расширением Mermaid Preview)
- Других Markdown редакторах с поддержкой Mermaid

## Альтернативные форматы

Если нужны диаграммы в других форматах:

1. **PlantUML** - можно конвертировать Mermaid в PlantUML
2. **Draw.io** - можно импортировать через Mermaid плагин
3. **Lucidchart** - поддерживает импорт Mermaid

## Автоматическая генерация

Для автоматической генерации всех диаграмм можно создать скрипт:

```bash
#!/bin/bash
# generate_diagrams.sh

# Установка зависимостей (один раз)
# npm install -g @mermaid-js/mermaid-cli

# Генерация из всех .md файлов
for file in docs/*.md; do
    if [[ $file == *"DIAGRAM"* ]] || [[ $file == *"FLOW"* ]]; then
        echo "Processing $file..."
        mmdc -i "$file" -o "docs/images/$(basename $file .md)/"
    fi
done
```


