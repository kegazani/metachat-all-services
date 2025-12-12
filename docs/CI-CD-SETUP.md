# Настройка CI/CD для MetaChat

Этот документ описывает настройку автоматического CI/CD pipeline для MetaChat, который будет автоматически собирать и деплоить сервисы при каждом пуше в репозиторий.

## 🎯 Обзор

CI/CD pipeline состоит из следующих этапов:

1. **Build** - Сборка Docker образов для всех сервисов
2. **Push** - Публикация образов в Container Registry (GitHub Container Registry)
3. **Deploy** - Автоматический деплой на сервер
4. **Health Check** - Проверка работоспособности после деплоя

## 📋 Предварительные требования

### 1. GitHub Repository

Убедитесь, что ваш репозиторий находится на GitHub.

### 2. GitHub Secrets

Настройте следующие secrets в вашем GitHub репозитории:

**Settings → Secrets and variables → Actions → New repository secret**

#### Для деплоя на сервер:

- `SSH_PRIVATE_KEY` - Приватный SSH ключ для доступа к серверу
- `DEPLOY_HOST` - IP адрес или домен сервера (например: `192.168.1.100` или `deploy.example.com`)
- `DEPLOY_USER` - Пользователь для SSH подключения (например: `deploy` или `ubuntu`)
- `DEPLOY_PATH` - Путь к проекту на сервере (например: `/home/deploy/metachat`)

#### Для деплоя фронтенда (опционально):

- `FTP_SERVER` - FTP сервер для деплоя фронтенда
- `FTP_USERNAME` - FTP username
- `FTP_PASSWORD` - FTP password

### 3. Настройка сервера

#### Установка Docker и Docker Compose

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### Настройка SSH доступа

1. Создайте SSH ключ на вашем локальном компьютере (если еще нет):

```bash
ssh-keygen -t ed25519 -C "github-actions"
```

2. Скопируйте публичный ключ на сервер:

```bash
ssh-copy-id deploy@your-server-ip
```

3. Добавьте приватный ключ в GitHub Secrets как `SSH_PRIVATE_KEY`:

```bash
cat ~/.ssh/id_ed25519
# Скопируйте содержимое и добавьте в GitHub Secrets
```

#### Подготовка сервера

1. Клонируйте репозиторий на сервер:

```bash
cd /home/deploy
git clone https://github.com/your-username/metachat.git
cd metachat
```

2. Создайте директорию для логов (если используется):

```bash
mkdir -p docker/monitoring/dashboards
```

3. Убедитесь, что инфраструктура запущена:

```bash
cd docker
docker-compose -f docker-compose.infrastructure.yml up -d
```

## 🚀 Настройка CI/CD

### 1. Обновление workflow файлов

Workflow файлы уже созданы в `.github/workflows/`:

- `ci-cd.yml` - Основной pipeline для сборки и деплоя сервисов
- `build-frontend.yml` - Сборка и деплой фронтенда

### 2. Настройка Container Registry

По умолчанию используется GitHub Container Registry (ghcr.io). 

Если вы хотите использовать другой registry (Docker Hub, AWS ECR и т.д.), обновите переменные в workflow:

```yaml
env:
  REGISTRY: docker.io  # или ваш registry
  IMAGE_PREFIX: your-username/metachat
```

И обновите секреты для авторизации:

```yaml
- name: Log in to Container Registry
  uses: docker/login-action@v3
  with:
    registry: ${{ env.REGISTRY }}
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

### 3. Настройка production docker-compose

Обновите `docker/docker-compose.production.yml` с вашими настройками:

```bash
export REGISTRY=ghcr.io
export IMAGE_PREFIX=your-username/metachat
export TAG=latest
```

Или создайте `.env` файл:

```env
REGISTRY=ghcr.io
IMAGE_PREFIX=your-username/metachat
TAG=latest
```

## 🔄 Как это работает

### При пуше в main/master ветку:

1. **GitHub Actions запускает workflow**
2. **Сборка образов** - Каждый сервис собирается параллельно
3. **Публикация образов** - Образы публикуются в Container Registry
4. **Деплой на сервер** - SSH подключение к серверу и выполнение деплоя
5. **Health Check** - Проверка работоспособности сервисов

### При создании Pull Request:

1. **Сборка образов** - Образы собираются, но не публикуются
2. **Проверка** - Убедитесь, что все собирается корректно

## 📝 Использование

### Автоматический деплой

Просто сделайте push в main ветку:

```bash
git add .
git commit -m "Update services"
git push origin main
```

GitHub Actions автоматически:
- Соберет все образы
- Опубликует их в registry
- Задеплоит на сервер
- Проверит работоспособность

### Ручной запуск

Вы можете запустить workflow вручную:

1. Перейдите в **Actions** в GitHub
2. Выберите workflow **CI/CD Pipeline**
3. Нажмите **Run workflow**

### Просмотр логов деплоя

1. Перейдите в **Actions** в GitHub
2. Выберите нужный workflow run
3. Просмотрите логи каждого job

## 🔧 Настройка для разных окружений

### Development

Для development окружения создайте отдельный workflow:

```yaml
# .github/workflows/deploy-dev.yml
on:
  push:
    branches:
      - develop
```

И используйте другой набор secrets:
- `DEV_DEPLOY_HOST`
- `DEV_DEPLOY_USER`
- и т.д.

### Staging

Аналогично для staging окружения.

### Production

Production деплой должен быть только из main/master ветки с дополнительными проверками.

## 🐛 Troubleshooting

### Ошибка авторизации в Container Registry

Убедитесь, что:
- `GITHUB_TOKEN` доступен (автоматически для GitHub Container Registry)
- Для других registry добавьте соответствующие secrets

### Ошибка SSH подключения

1. Проверьте, что SSH ключ добавлен в secrets
2. Убедитесь, что публичный ключ добавлен на сервер
3. Проверьте доступность сервера: `ssh deploy@your-server-ip`

### Ошибка деплоя на сервере

1. Проверьте логи в GitHub Actions
2. Подключитесь к серверу и проверьте вручную:
   ```bash
   ssh deploy@your-server-ip
   cd /home/deploy/metachat
   docker-compose -f docker/docker-compose.production.yml ps
   ```

### Сервисы не запускаются после деплоя

1. Проверьте логи сервисов:
   ```bash
   docker-compose -f docker/docker-compose.production.yml logs
   ```

2. Убедитесь, что инфраструктура запущена:
   ```bash
   docker-compose -f docker/docker-compose.infrastructure.yml ps
   ```

3. Проверьте сеть:
   ```bash
   docker network inspect metachat_network
   ```

## 📊 Мониторинг деплоев

### GitHub Actions

Все деплои видны в разделе **Actions** вашего репозитория.

### Уведомления

Настройте уведомления в GitHub:
- Settings → Notifications → Actions

### Статус деплоя

Добавьте badge в README:

```markdown
![CI/CD](https://github.com/your-username/metachat/workflows/CI/CD%20Pipeline/badge.svg)
```

## 🔐 Безопасность

### Secrets

⚠️ **Никогда не коммитьте secrets в репозиторий!**

Все секретные данные должны быть в GitHub Secrets.

### SSH ключи

Используйте отдельный SSH ключ для CI/CD, не ваш личный ключ.

### Container Registry

Для production используйте приватные репозитории в registry.

## 📚 Дополнительные ресурсы

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Buildx](https://docs.docker.com/buildx/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

## 🎉 Готово!

После настройки каждый push в main ветку будет автоматически деплоить ваше приложение!

