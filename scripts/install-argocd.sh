#!/bin/bash
set -e

echo "🚀 Installing ArgoCD..."

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for ArgoCD server..."
kubectl rollout status deployment/argocd-server -n argocd

echo "✅ ArgoCD installed"
