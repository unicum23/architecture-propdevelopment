
# Контроль сетевого трафика в кластере Kubernetes

Данное руководство показывает, как с помощью сетевых политик Kubernetes ограничить взаимодействие между сервисами.

## Структура

В кластере запущены 4 сервиса со следующими метками:
- `front-end` — клиентская часть приложения
- `back-end-api` — серверный API
- `admin-front-end` — клиентская часть панели администратора
- `admin-back-end-api` — серверный API панели администратора

## Сетевые политики

Правила сетевых политик обеспечивают следующую логику:
- ✅ Двусторонний обмен данными между `front-end` и `back-end-api` разрешён
- ✅ Двусторонний обмен данными между `admin-front-end` и `admin-back-end-api` разрешён
- ❌ Любые другие комбинации взаимодействия между сервисами заблокированы

## Развёртывание

### Вариант 1: Применение готовых манифестов

```bash
# Применить все манифесты
chmod +x _0-apply-all.sh
./_0-apply-all.sh
```

### Вариант 2: Развёртывание вручную через kubectl run

Если требуется создать ресурсы поштучно с помощью команд `kubectl run`, как предписано в задании:

```bash
# Создание подов и сервисов
kubectl run front-end-app --image=nginx --labels role=front-end --expose --port 80
kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port 80
kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port 80
kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port 80

# Применение сетевых политик
kubectl apply -f non-admin-api-allow.yaml
kubectl apply -f admin-api-allow.yaml
```

## Применение сетевых политик
```bash
Можно запустить подготовленный скрипт _0-apply-all.sh
```

либо вручную

```bash
# Применить политику для пользовательских сервисов
kubectl apply -f non-admin-api-allow.yaml

# Применить политику для административных сервисов
kubectl apply -f admin-api-allow.yaml
```

## Тестирование трафика

Для тестирования можно выполнить проверку из уже существующих подов:

```bash
# Получить имя пода front-end
POD_NAME=$(kubectl get pod -l role=front-end -o jsonpath='{.items[0].metadata.name}')

# Проверить доступ к back-end-api (соединение должно быть успешным)
kubectl exec $POD_NAME -- wget -qO- --timeout=2 http://back-end-api-app

# Проверить доступ к admin-back-end-api (соединение должно быть отклонено)
kubectl exec $POD_NAME -- wget -qO- --timeout=2 http://admin-back-end-api-app
```

## Проверка состояния ресурсов

```bash
# Проверить статус подов
kubectl get pods -l role=front-end
kubectl get pods -l role=back-end-api
kubectl get pods -l role=admin-front-end
kubectl get pods -l role=admin-back-end-api

# Проверить сервисы
kubectl get services

# Проверить сетевые политики
kubectl get networkpolicies

# Посмотреть детали сетевой политики
kubectl describe networkpolicy non-admin-api-allow
kubectl describe networkpolicy admin-api-allow
```

## Удаление ресурсов

```bash
# Удалить все ресурсы
kubectl delete -f front-end-app.yaml
kubectl delete -f back-end-api-app.yaml
kubectl delete -f admin-front-end-app.yaml
kubectl delete -f admin-back-end-api-app.yaml
kubectl delete -f non-admin-api-allow.yaml
kubectl delete -f admin-api-allow.yaml
```