#!/bin/bash

echo "🔍 Checking cluster status..."
echo ""

echo "Nodes:"
kubectl get nodes

echo ""
echo "Cluster resources:"
kubectl top nodes 2>/dev/null || echo "⚠️  Metrics server not available"

echo ""
echo "Existing namespaces:"
kubectl get namespaces

echo ""
echo "Existing CRDs:"
kubectl get crd | grep -E "(argocd|metallb|gateway)" || echo "✓ No conflicting CRDs found"

echo ""
echo "Existing webhooks:"
kubectl get validatingwebhookconfiguration | grep -E "(argocd|metallb|gateway)" || echo "✓ No conflicting webhooks found"
kubectl get mutatingwebhookconfiguration | grep -E "(argocd|metallb|gateway)" || echo "✓ No conflicting webhooks found"

echo ""
echo "Existing helm releases:"
helm list -A