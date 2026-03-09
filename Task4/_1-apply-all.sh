#!/bin/bash

# Скрипт для применения всех манифестов RBAC
# Использование: ./_1-_0-apply-all.sh

set -e

echo "=========================================="
echo "Применение манифестов RBAC для Kubernetes"
echo "=========================================="
echo ""

# Проверка наличия kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Ошибка: kubectl не найден. Установите kubectl и повторите попытку."
    exit 1
fi

# Проверка подключения к кластеру
if ! kubectl cluster-info &> /dev/null; then
    echo "Ошибка: Не удается подключиться к кластеру Kubernetes."
    echo "Убедитесь, что kubectl настроен правильно."
    exit 1
fi

echo "✓ Подключение к кластеру установлено"
echo ""

# Создание namespace (если не существуют)
echo "Создание namespace..."
kubectl create namespace development --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace testing --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace security --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Namespace созданы/проверены"
echo ""

# Применение манифестов
echo "Применение манифестов RBAC..."
echo ""

echo "1. Привилегированные администраторы..."
kubectl apply -f 01-privileged-admins-clusterrole.yaml
echo "✓ Применено"

echo "2. Пользователи только для просмотра..."
kubectl apply -f 02-read-only-viewers-clusterrole.yaml
echo "✓ Применено"

echo "3. Операторы кластера..."
kubectl apply -f 03-cluster-operators-clusterrole.yaml
echo "✓ Применено"

echo "4. Роли по организационной структуре..."
kubectl apply -f 04-namespace-based-roles.yaml
echo "✓ Применено"

echo ""
echo "=========================================="
echo "Применение завершено успешно!"
echo "=========================================="
echo ""

# Вывод информации о созданных ресурсах
echo "Созданные ClusterRoles:"
kubectl get clusterroles | grep -E "privileged-admin|read-only-viewer|cluster-operator" || echo "Не найдено"
echo ""

echo "Созданные ClusterRoleBindings:"
kubectl get clusterrolebindings | grep -E "privileged-admin|read-only-viewer|cluster-operator" || echo "Не найдено"
echo ""

echo "Созданные Roles в namespace:"
for ns in development testing production security; do
    echo "Namespace: $ns"
    kubectl get roles -n $ns 2>/dev/null || echo "  Нет ролей"
done

echo ""
echo "Для проверки прав доступа используйте:"
echo "  kubectl auth can-i <verb> <resource> --as=<user>"
echo ""

