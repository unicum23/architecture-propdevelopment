
# Управление доступом к кластеру Kubernetes через RBAC

## Обзор

Решение обеспечивает разграничение прав в кластере Kubernetes по модели RBAC. Каждая группа сотрудников получает строго определённый набор полномочий, соответствующий её функциональным обязанностям.

## Роли и полномочия

### 1. Привилегированные администраторы (`01-privileged-admins-clusterrole.yaml`)

**Группа**: `privileged-admins`

Полный контроль над всеми ресурсами кластера: управление секретами, узлами, выполнение команд внутри подов, проброс портов. Предназначена для инженеров по безопасности и ведущих DevOps-специалистов.

### 2. Наблюдатели (`02-read-only-viewers-clusterrole.yaml`)

**Группа**: `read-only-viewers`

Доступ исключительно на чтение: просмотр ресурсов, логов, событий и метрик. Секреты недоступны. Роль рассчитана на менеджеров и аналитиков, которым нужен мониторинг без возможности вносить изменения.

### 3. Операторы кластера (`03-cluster-operators-clusterrole.yaml`)

**Группа**: `cluster-operators`

Управление подами, сервисами, деплойментами, ingress, ConfigMap, Persistent Volumes и HPA. Доступны exec и port-forward для диагностики. Секреты закрыты. Роль для DevOps-инженеров, обслуживающих приложения.

### 4. Роли уровня namespace (`04-namespace-based-roles.yaml`)

Каждой команде выделен собственный namespace с индивидуальным набором прав.

| Группа | Namespace | Ключевые права |
|---|---|---|
| `development-team` | `development` | Полное управление ресурсами, просмотр секретов (без изменения), exec в подах |
| `testing-team` | `testing` | Просмотр ресурсов, создание и удаление тестовых подов, секреты недоступны |
| `production-team` | `production` | Мониторинг ресурсов, разрешено только масштабирование, секреты недоступны |
| `security-team` | `security` | Чтение секретов для аудита, просмотр всех ресурсов для контроля политик |

## Установка

### Предварительные условия

- Административный доступ к кластеру
- Настроенная система аутентификации (LDAP, AD, OIDC и т.д.)
- Группы пользователей созданы на стороне провайдера аутентификации

### Применение манифестов

```bash
# Создание namespace
kubectl create namespace development
kubectl create namespace testing
kubectl create namespace production
kubectl create namespace security

# Применение ролей
kubectl apply -f 01-privileged-admins-clusterrole.yaml
kubectl apply -f 02-read-only-viewers-clusterrole.yaml
kubectl apply -f 03-cluster-operators-clusterrole.yaml
kubectl apply -f 04-namespace-based-roles.yaml
```

### Проверка установки

```bash
kubectl get clusterroles | grep -E "privileged-admin|read-only-viewer|cluster-operator"
kubectl get clusterrolebindings | grep -E "privileged-admin|read-only-viewer|cluster-operator"
kubectl get roles -n development
kubectl get roles -n testing
kubectl get roles -n production
kubectl get roles -n security
```

## Настройка аутентификации

Провайдер аутентификации должен передавать информацию о группах пользователя в токене.

#### OIDC

```yaml
--oidc-issuer-url=https://your-oidc-provider
--oidc-client-id=kubernetes
--oidc-username-claim=email
--oidc-groups-claim=groups
```

#### LDAP

Используйте webhook-аутентификацию или промежуточный провайдер (Dex, Keycloak).

### Требуемые группы

| Группа | Назначение |
|---|---|
| `privileged-admins` | Привилегированные администраторы |
| `read-only-viewers` | Наблюдатели |
| `cluster-operators` | Операторы кластера |
| `development-team` | Разработчики |
| `testing-team` | Тестировщики |
| `production-team` | Команда продакшена |
| `security-team` | Служба безопасности |

## Проверка прав

```bash
# Привилегированный администратор
kubectl auth can-i get secrets --all-namespaces          # yes
kubectl auth can-i create pods --all-namespaces          # yes

# Наблюдатель
kubectl auth can-i get pods --all-namespaces             # yes
kubectl auth can-i get secrets --all-namespaces          # no
kubectl auth can-i create pods                           # no

# Оператор
kubectl auth can-i create deployments                    # yes
kubectl auth can-i get secrets                           # no

# Разработчик
kubectl auth can-i create pods -n development            # yes
kubectl auth can-i create pods -n production             # no
```

## Принципы безопасности

- **Минимальные привилегии** — каждой группе доступно ровно столько, сколько требуется для работы.
- **Контроль доступа к секретам** — секреты открыты только администраторам и команде безопасности.
- **Изоляция на уровне namespace** — команды ограничены своими пространствами имён.
- **Аудит** — все запросы к API-серверу журналируются; рекомендуется централизованный сбор логов.
- **Регулярный пересмотр** — периодически проверяйте актуальность ролей и удаляйте устаревшие привязки.

Дополнительно рекомендуется применять **Network Policies**, **Pod Security Standards** и назначать подам Service Account с минимальным набором прав.

## Расширение и модификация

Для добавления новой группы создайте Role/ClusterRole и соответствующий Binding, затем примените манифест командой `kubectl apply -f`. Для изменения существующей роли отредактируйте манифест и повторно примените его — изменения вступают в силу мгновенно без перезапуска компонентов.

## Диагностика

```bash
# Проверить права конкретного пользователя
kubectl auth can-i <действие> <ресурс> --as=<пользователь>

# Просмотреть привязки
kubectl get clusterrolebindings -o wide
kubectl get rolebindings -n <namespace> -o wide

# Детали роли
kubectl describe clusterrole <имя-роли>
kubectl describe role <имя-роли> -n <namespace>
```

Если группы не распознаются — проверьте конфигурацию аутентификации API-сервера и убедитесь, что токен пользователя содержит поле `groups`.

## Дополнительные ресурсы

- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#using-rbac-authorization)
- [RBAC Good Practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/)