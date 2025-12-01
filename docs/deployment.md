# Инструкция по развертыванию и настройке MetaChat

## Требования к системе

### Аппаратные требования
- CPU: Минимум 4 ядра, рекомендуется 8+ ядер
- RAM: Минимум 8GB, рекомендуется 16GB+
- Диск: Минимум 100GB SSD, рекомендуется 200GB+ SSD

### Программные требования
- Docker 20.10+
- Docker Compose 2.0+
- Kubernetes 1.23+ (для продакшн развертывания)
- kubectl 1.23+
- Helm 3.8+ (для продакшн развертывания)
- Git 2.30+

## Локальное развертывание

### 1. Клонирование репозитория

```bash
git clone https://github.com/metachat/metachat.git
cd metachat
```

### 2. Настройка переменных окружения

Создайте файл `.env` в корне проекта на основе шаблона `.env.example`:

```bash
cp .env.example .env
```

Отредактируйте файл `.env`, указав необходимые значения:

```env
# Общие настройки
ENVIRONMENT=development
LOG_LEVEL=debug

# Настройки баз данных
EVENTSTOREDB_HOST=eventstoredb
EVENTSTOREDB_PORT=2113
EVENTSTOREDB_USER=admin
EVENTSTOREDB_PASSWORD=changeit

CASSANDRA_HOST=cassandra
CASSANDRA_PORT=9042
CASSANDRA_USER=cassandra
CASSANDRA_PASSWORD=cassandra

# Настройки Kafka
KAFKA_HOST=kafka
KAFKA_PORT=9092
KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181

# Настройки сервисов
USER_SERVICE_PORT=8080
DIARY_SERVICE_PORT=8081
MOOD_ANALYSIS_SERVICE_PORT=8082
MATCHING_SERVICE_PORT=8083

# Настройки API Gateway
API_GATEWAY_PORT=8000
API_GATEWAY_HOST=localhost

# Настройки JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=3600
```

### 3. Запуск системы с помощью Docker Compose

```bash
docker-compose up -d
```

### 4. Проверка работоспособности

Проверьте статус всех контейнеров:

```bash
docker-compose ps
```

Проверьте логи сервисов:

```bash
docker-compose logs -f user-service
docker-compose logs -f diary-service
docker-compose logs -f mood-analysis-service
docker-compose logs -f matching-service
```

### 5. Доступ к сервисам

- API Gateway: http://localhost:8000
- User Service: http://localhost:8000/users
- Diary Service: http://localhost:8000/diary
- Mood Analysis Service: http://localhost:8000/mood
- Matching Service: http://localhost:8000/matching

## Продакшн развертывание

### 1. Подготовка Kubernetes кластера

Убедитесь, что у вас есть доступ к Kubernetes кластеру и kubectl настроен:

```bash
kubectl cluster-info
kubectl get nodes
```

### 2. Установка Helm

Если Helm еще не установлен:

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

### 3. Установка Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx
```

### 4. Установка Cert-Manager (для SSL сертификатов)

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace
```

### 5. Установка Prometheus и Grafana (для мониторинга)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack
```

### 6. Развертывание баз данных

#### EventStoreDB

```bash
helm install eventstoredb ./helm/eventstoredb
```

#### Cassandra

```bash
helm install cassandra ./helm/cassandra
```

#### Kafka

```bash
helm install kafka ./helm/kafka
```

### 7. Развертывание сервисов

#### User Service

```bash
helm install user-service ./helm/user-service
```

#### Diary Service

```bash
helm install diary-service ./helm/diary-service
```

#### Mood Analysis Service

```bash
helm install mood-analysis-service ./helm/mood-analysis-service
```

#### Matching Service

```bash
helm install matching-service ./helm/matching-service
```

### 8. Развертывание API Gateway

```bash
helm install api-gateway ./helm/api-gateway
```

### 9. Настройка Ingress

```bash
kubectl apply -f k8s/ingress.yaml
```

### 10. Проверка работоспособности

Проверьте статус всех подов:

```bash
kubectl get pods
```

Проверьте статус сервисов:

```bash
kubectl get svc
```

Проверьте статус Ingress:

```bash
kubectl get ingress
```

## Настройка мониторинга

### 1. Доступ к Grafana

Получите пароль для Grafana:

```bash
kubectl get secret --namespace default prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Доступ к Grafana через Ingress:

```
http://grafana.your-domain.com
```

### 2. Настройка дашбордов

Импортируйте преднастроенные дашборды из `monitoring/grafana-dashboards/`:

1. Откройте Grafana
2. Перейдите в Dashboards -> Import
3. Загрузите JSON файлы дашбордов

### 3. Настройка алертов

Настройте алерты в Grafana для уведомления о критических событиях:

1. Перейдите в Alerting -> Notification channels
2. Создайте канал уведомлений (email, Slack, etc.)
3. Перейдите в Alerting -> Alert rules
4. Создайте правила алертов на основе метрик

## Настройка логирования

### 1. Установка EFK стека (Elasticsearch, Fluentd, Kibana)

```bash
helm repo add elastic https://helm.elastic.co
helm repo update

helm install elasticsearch elastic/elasticsearch
helm install kibana elastic/kibana
helm install fluentd fluent/fluentd
```

### 2. Настройка Fluentd

```bash
kubectl apply -f k8s/fluentd-configmap.yaml
```

### 3. Доступ к Kibana

Получите пароль для Kibana:

```bash
kubectl get secret --namespace default elasticsearch-es-elastic-user -o jsonpath="{.data.elastic}" | base64 --decode ; echo
```

Доступ к Kibana через Ingress:

```
http://kibana.your-domain.com
```

### 4. Создание индексов в Kibana

1. Откройте Kibana
2. Перейдите в Management -> Index Patterns
3. Создайте индекс patterns для логов каждого сервиса

## Обновление системы

### 1. Обновление образов

Соберите новые образы Docker:

```bash
docker-compose build
```

Или для продакшн:

```bash
docker build -t your-registry/metachat/user-service:latest ./services/user-service
docker build -t your-registry/metachat/diary-service:latest ./services/diary-service
docker build -t your-registry/metachat/mood-analysis-service:latest ./services/mood-analysis-service
docker build -t your-registry/metachat/matching-service:latest ./services/matching-service

docker push your-registry/metachat/user-service:latest
docker push your-registry/metachat/diary-service:latest
docker push your-registry/metachat/mood-analysis-service:latest
docker push your-registry/metachat/matching-service:latest
```

### 2. Обновление Helm релизов

```bash
helm upgrade user-service ./helm/user-service
helm upgrade diary-service ./helm/diary-service
helm upgrade mood-analysis-service ./helm/mood-analysis-service
helm upgrade matching-service ./helm/matching-service
helm upgrade api-gateway ./helm/api-gateway
```

## Резервное копирование и восстановление

### 1. Резервное копирование EventStoreDB

```bash
kubectl exec -it eventstoredb-0 -- /bin/bash
cd /var/lib/eventstore
tar -czvf eventstore-backup-$(date +%Y%m%d).tar.gz *
exit
kubectl cp eventstoredb-0:/var/lib/eventstore/eventstore-backup-$(date +%Y%m%d).tar.gz ./backups/
```

### 2. Резервное копирование Cassandra

```bash
kubectl exec -it cassandra-0 -- /bin/bash
nodetool snapshot
exit
kubectl cp cassandra-0:/var/lib/cassandra/data/$(ls /var/lib/cassandra/data | grep snapshot) ./backups/cassandra-backup-$(date +%Y%m%d)/
```

### 3. Восстановление EventStoreDB

```bash
kubectl cp ./backups/eventstore-backup-YYYYMMDD.tar.gz eventstoredb-0:/var/lib/eventstore/
kubectl exec -it eventstoredb-0 -- /bin/bash
cd /var/lib/eventstore
tar -xzvf eventstore-backup-YYYYMMDD.tar.gz
exit
```

### 4. Восстановление Cassandra

```bash
kubectl cp ./backups/cassandra-backup-YYYYMMDD cassandra-0:/var/lib/cassandra/data/
kubectl exec -it cassandra-0 -- /bin/bash
nodetool refresh
exit
```

## Безопасность

### 1. Настройка SSL/TLS

Используйте Cert-Manager для автоматического выпуска SSL сертификатов:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

### 2. Настройка сетевых политик

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: user-service-netpol
spec:
  podSelector:
    matchLabels:
      app: user-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-gateway
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: eventstoredb
    - podSelector:
        matchLabels:
          app: cassandra
```

### 3. Настройка RBAC

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: user-service-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: user-service-rolebinding
subjects:
- kind: ServiceAccount
  name: user-service
roleRef:
  kind: Role
  name: user-service-role
  apiGroup: rbac.authorization.k8s.io
```

## Решение проблем

### 1. Проверка логов

```bash
kubectl logs -f deployment/user-service
kubectl logs -f deployment/diary-service
kubectl logs -f deployment/mood-analysis-service
kubectl logs -f deployment/matching-service
kubectl logs -f deployment/api-gateway
```

### 2. Проверка событий

```bash
kubectl get events --sort-by='.metadata.creationTimestamp'
```

### 3. Проверка описания ресурсов

```bash
kubectl describe deployment/user-service
kubectl describe pod/user-service-xxxxxxxx-xxxxx
```

### 4. Проверка конфигурации

```bash
kubectl get configmap user-service-config -o yaml
kubectl get secret user-service-secret -o yaml
```

### 5. Перезапуск подов

```bash
kubectl rollout restart deployment/user-service
```

### 6. Откат к предыдущей версии

```bash
helm rollback user-service 1
helm rollback diary-service 1
helm rollback mood-analysis-service 1
helm rollback matching-service 1
helm rollback api-gateway 1