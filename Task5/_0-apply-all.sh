#!/bin/bash

# Скрипт для применения всех манифестов

echo "Применение манифестов для сервисов..."

# Применяем Deployment и Service для каждого сервиса
kubectl apply -f front-end-app.yaml
kubectl apply -f back-end-api-app.yaml
kubectl apply -f admin-front-end-app.yaml
kubectl apply -f admin-back-end-api-app.yaml

echo "Ожидание готовности подов..."
kubectl wait --for=condition=ready pod -l role=front-end --timeout=60s
kubectl wait --for=condition=ready pod -l role=back-end-api --timeout=60s
kubectl wait --for=condition=ready pod -l role=admin-front-end --timeout=60s
kubectl wait --for=condition=ready pod -l role=admin-back-end-api --timeout=60s

echo "Применение сетевых политик..."
kubectl apply -f non-admin-api-allow.yaml
kubectl apply -f admin-api-allow.yaml

echo "Проверка статуса подов..."
kubectl get pods -l role=front-end
kubectl get pods -l role=back-end-api
kubectl get pods -l role=admin-front-end
kubectl get pods -l role=admin-back-end-api

echo "Проверка сетевых политик..."
kubectl get networkpolicies

echo "Готово!"

