#!/bin/bash

NAMESPACE=production
LABEL="app=fastapi"

echo "🚀 FASTAPI APP LIVE TIME REPORT"
echo "Namespace : $NAMESPACE"
echo "Selector  : $LABEL"
echo "==============================================="

pods=$(kubectl -n $NAMESPACE get pods -l $LABEL -o jsonpath='{.items[*].metadata.name}')

for pod in $pods; do
  echo ""
  echo "📦 Pod: $pod"

  created=$(kubectl -n $NAMESPACE get pod $pod -o jsonpath='{.metadata.creationTimestamp}')

  started=$(kubectl -n $NAMESPACE get pod $pod \
    -o jsonpath='{.status.containerStatuses[0].state.running.startedAt}' 2>/dev/null)

  ready=$(kubectl -n $NAMESPACE get pod $pod \
    -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.lastTransitionTime}{end}')

  # Convert to epoch
  created_s=$(date -d "$created" +%s)
  ready_s=$(date -d "$ready" +%s)

  live_time=$((ready_s - created_s))

  echo "🕒 Created : $created"
  echo "▶️ Started : ${started:-N/A}"
  echo "✅ Ready   : $ready"
  echo "⏱️ LIVE IN : ${live_time}s"
done

echo ""
echo "==============================================="
echo "✅ Report completed"
