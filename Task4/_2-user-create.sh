#!/bin/bash

# Создание пользователя admin
echo "Создание пользователя admin..."
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -out admin.csr -subj "/CN=admin/O=privileged-admins"
openssl x509 -req -in admin.csr -CA .minikube/ca.crt -CAkey .minikube/ca.key -CAcreateserial -out admin.crt -days 365
kubectl config set-credentials admin --client-certificate=admin.crt --client-key=admin.key
kubectl config set-context admin-context --cluster=minikube --user=admin

# Создание пользователя developer
echo "Создание пользователя developer..."
openssl genrsa -out developer.key 2048
openssl req -new -key developer.key -out developer.csr -subj "/CN=developer/O=development-team"
openssl x509 -req -in developer.csr -CA .minikube/ca.crt -CAkey  .minikube/ca.key -CAcreateserial -out developer.crt -days 365
kubectl config set-credentials developer --client-certificate=developer.crt --client-key=developer.key
kubectl config set-context developer-context --cluster=minikube --user=developer