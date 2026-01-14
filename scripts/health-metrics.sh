#!/bin/bash

##############################################################################
# Infrastructure Performance & Health Metrics
# 
# Displays resource usage, performance metrics, and health indicators
# for all infrastructure components
#
# Usage: ./health-metrics.sh
##############################################################################

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}► $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
}

print_metric() {
    local label=$1
    local value=$2
    local unit=$3
    echo -e "  ${BLUE}$label:${NC} ${GREEN}$value${NC} $unit"
}

print_warning_metric() {
    local label=$1
    local value=$2
    local unit=$3
    echo -e "  ${BLUE}$label:${NC} ${YELLOW}$value${NC} $unit"
}

print_error_metric() {
    local label=$1
    local value=$2
    local unit=$3
    echo -e "  ${BLUE}$label:${NC} ${RED}$value${NC} $unit"
}

##############################################################################
# 1. NODE METRICS
##############################################################################
print_header "1. NODE RESOURCE METRICS"

echo "Allocatable Resources:"
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory --no-headers | while read node cpu mem; do
    CPU_CORES=$(echo $cpu | sed 's/m$//' | awk '{print $1/1000}')
    MEM_GB=$(echo $mem | sed 's/Ki$//' | awk '{print int($1/1024/1024)}')
    print_metric "  $node" "$CPU_CORES cores / $MEM_GB GB" ""
done

echo -e "\nRequested Resources:"
TOTAL_CPU=$(kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].resources.requests.cpu}' 2>/dev/null | tr ' ' '\n' | grep -v '^$' | sed 's/m$//' | awk '{sum+=$1/1000} END {print sum}')
TOTAL_MEM=$(kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].resources.requests.memory}' 2>/dev/null | tr ' ' '\n' | grep -v '^$' | sed 's/Mi$//' | awk '{sum+=$1} END {print int(sum/1024)}')
print_metric "Total CPU Reserved" "${TOTAL_CPU:-0}" "cores"
print_metric "Total Memory Reserved" "${TOTAL_MEM:-0}" "GB"

##############################################################################
# 2. NAMESPACE METRICS
##############################################################################
print_header "2. NAMESPACE POD DISTRIBUTION"

echo "Pod Count by Namespace:"
kubectl get ns --no-headers 2>/dev/null | awk '{print $1}' | while read ns; do
    POD_COUNT=$(kubectl get pods -n $ns --no-headers 2>/dev/null | wc -l)
    if [ $POD_COUNT -gt 0 ]; then
        RUNNING=$(kubectl get pods -n $ns --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
        READY=$(kubectl get pods -n $ns -o jsonpath='{.items[?(@.status.conditions[?(@.type=="Ready")].status=="True")]}' 2>/dev/null | grep -c "name")
        
        if [ $READY -eq $POD_COUNT ]; then
            print_metric "  $ns" "$READY/$POD_COUNT ready" ""
        else
            print_warning_metric "  $ns" "$READY/$POD_COUNT ready" ""
        fi
    fi
done

##############################################################################
# 3. ARGOCD METRICS
##############################################################################
print_header "3. ARGOCD APPLICATION METRICS"

TOTAL_APPS=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l)
SYNCED_APPS=$(kubectl get applications -n argocd -o jsonpath='{.items[?(@.status.sync.status=="Synced")]}' 2>/dev/null | grep -c '"name"' || echo 0)
HEALTHY_APPS=$(kubectl get applications -n argocd -o jsonpath='{.items[?(@.status.health.status=="Healthy")]}' 2>/dev/null | grep -c '"name"' || echo 0)

print_metric "Total Applications" "$TOTAL_APPS" ""
if [ $SYNCED_APPS -eq $TOTAL_APPS ]; then
    print_metric "Synced Applications" "$SYNCED_APPS/$TOTAL_APPS" ""
else
    print_warning_metric "Synced Applications" "$SYNCED_APPS/$TOTAL_APPS" ""
fi

if [ $HEALTHY_APPS -eq $TOTAL_APPS ]; then
    print_metric "Healthy Applications" "$HEALTHY_APPS/$TOTAL_APPS" ""
else
    print_warning_metric "Healthy Applications" "$HEALTHY_APPS/$TOTAL_APPS" ""
fi

##############################################################################
# 4. STORAGE METRICS
##############################################################################
print_header "4. STORAGE METRICS"

echo "Persistent Volume Usage:"
kubectl get pvc --all-namespaces --no-headers 2>/dev/null | while read ns name status volume capacity access time; do
    echo "  $ns/$name: $capacity allocated"
done

echo -e "\nStorage Classes:"
SC_COUNT=$(kubectl get sc --no-headers 2>/dev/null | wc -l)
print_metric "Storage Classes Available" "$SC_COUNT" ""

##############################################################################
# 5. PROMETHEUS METRICS
##############################################################################
print_header "5. PROMETHEUS HEALTH METRICS"

PROM_RUNNING=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
PROM_TOTAL=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | wc -l)

if [ $PROM_RUNNING -eq $PROM_TOTAL ]; then
    print_metric "Prometheus Instances" "$PROM_RUNNING/$PROM_TOTAL running" ""
else
    print_warning_metric "Prometheus Instances" "$PROM_RUNNING/$PROM_TOTAL running" ""
fi

# Try to get Prometheus targets info
PROM_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$PROM_POD" ]; then
    TARGETS=$(kubectl exec -n monitoring $PROM_POD -- curl -s http://localhost:9090/api/v1/targets 2>/dev/null | grep -o '"scrapePool"' | wc -l)
    if [ $TARGETS -gt 0 ]; then
        print_metric "Configured Targets" "$TARGETS" ""
    fi
fi

##############################################################################
# 6. GRAFANA METRICS
##############################################################################
print_header "6. GRAFANA HEALTH METRICS"

GRAF_RUNNING=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
GRAF_TOTAL=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | wc -l)

if [ $GRAF_RUNNING -eq $GRAF_TOTAL ]; then
    print_metric "Grafana Instances" "$GRAF_RUNNING/$GRAF_TOTAL running" ""
else
    print_warning_metric "Grafana Instances" "$GRAF_RUNNING/$GRAF_TOTAL running" ""
fi

##############################################################################
# 7. DEPLOYMENT METRICS
##############################################################################
print_header "7. DEPLOYMENT REPLICA STATUS"

echo "Deployment Replica Status:"
kubectl get deployments --all-namespaces -o wide 2>/dev/null | tail -n +2 | while read ns name ready updated available age rest; do
    if [[ "$ready" == *"/"* ]]; then
        CURRENT=$(echo $ready | cut -d'/' -f1)
        DESIRED=$(echo $ready | cut -d'/' -f2)
        
        if [ "$CURRENT" == "$DESIRED" ]; then
            print_metric "  $ns/$name" "$CURRENT/$DESIRED replicas" "ready"
        else
            print_warning_metric "  $ns/$name" "$CURRENT/$DESIRED replicas" "ready"
        fi
    fi
done

##############################################################################
# 8. EVENT METRICS (LAST 10 MINUTES)
##############################################################################
print_header "8. RECENT KUBERNETES EVENTS"

echo "Events from last 10 minutes:"
RECENT_EVENTS=$(kubectl get events --all-namespaces --sort-by='.lastTimestamp' 2>/dev/null | tail -20)

WARNING_COUNT=$(echo "$RECENT_EVENTS" | grep -i warning | wc -l)
ERROR_COUNT=$(echo "$RECENT_EVENTS" | grep -i error | wc -l)

print_metric "Warning Events" "$WARNING_COUNT" ""
print_metric "Error Events" "$ERROR_COUNT" ""

if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "\n${RED}Recent Error Events:${NC}"
    echo "$RECENT_EVENTS" | grep -i error | tail -5 | while read line; do
        echo "  $line"
    done
fi

##############################################################################
# 9. POD STATUS BREAKDOWN
##############################################################################
print_header "9. POD STATUS BREAKDOWN"

RUNNING_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
PENDING_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
FAILED_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
SUCCEEDED_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase=Succeeded --no-headers 2>/dev/null | wc -l)
UNKNOWN_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase=Unknown --no-headers 2>/dev/null | wc -l)

print_metric "Running" "$RUNNING_PODS" "pods"
[ $PENDING_PODS -gt 0 ] && print_warning_metric "Pending" "$PENDING_PODS" "pods"
[ $FAILED_PODS -gt 0 ] && print_error_metric "Failed" "$FAILED_PODS" "pods"
[ $SUCCEEDED_PODS -gt 0 ] && print_metric "Succeeded" "$SUCCEEDED_PODS" "pods"
[ $UNKNOWN_PODS -gt 0 ] && print_warning_metric "Unknown" "$UNKNOWN_PODS" "pods"

TOTAL_PODS=$((RUNNING_PODS + PENDING_PODS + FAILED_PODS + SUCCEEDED_PODS + UNKNOWN_PODS))
print_metric "Total Pods" "$TOTAL_PODS" ""

##############################################################################
# 10. HELM RELEASES STATUS
##############################################################################
print_header "10. HELM RELEASE STATUS"

DEPLOYED=$(helm list --all-namespaces 2>/dev/null | tail -n +2 | grep deployed | wc -l)
FAILED_RELEASES=$(helm list --all-namespaces 2>/dev/null | tail -n +2 | grep failed | wc -l)
PENDING_RELEASES=$(helm list --all-namespaces 2>/dev/null | tail -n +2 | grep pending | wc -l)

print_metric "Deployed Releases" "$DEPLOYED" ""
[ $FAILED_RELEASES -gt 0 ] && print_error_metric "Failed Releases" "$FAILED_RELEASES" ""
[ $PENDING_RELEASES -gt 0 ] && print_warning_metric "Pending Releases" "$PENDING_RELEASES" ""

##############################################################################
# 11. SYSTEM HEALTH SUMMARY
##############################################################################
print_header "11. SYSTEM HEALTH SUMMARY"

HEALTH_SCORE=100

# Deduct points for issues
[ $PENDING_PODS -gt 0 ] && HEALTH_SCORE=$((HEALTH_SCORE - 5))
[ $FAILED_PODS -gt 0 ] && HEALTH_SCORE=$((HEALTH_SCORE - 10))
[ $ERROR_COUNT -gt 0 ] && HEALTH_SCORE=$((HEALTH_SCORE - 5))
[ $SYNCED_APPS -ne $TOTAL_APPS ] && HEALTH_SCORE=$((HEALTH_SCORE - 10))
[ $HEALTHY_APPS -ne $TOTAL_APPS ] && HEALTH_SCORE=$((HEALTH_SCORE - 10))

if [ $HEALTH_SCORE -ge 90 ]; then
    print_metric "Overall Health Score" "$HEALTH_SCORE" "%"
    echo -e "  ${GREEN}Status: EXCELLENT${NC}"
elif [ $HEALTH_SCORE -ge 75 ]; then
    print_warning_metric "Overall Health Score" "$HEALTH_SCORE" "%"
    echo -e "  ${YELLOW}Status: GOOD (minor issues)${NC}"
else
    print_error_metric "Overall Health Score" "$HEALTH_SCORE" "%"
    echo -e "  ${RED}Status: NEEDS ATTENTION${NC}"
fi

##############################################################################
# 12. FASTAPI APPLICATION METRICS
##############################################################################
print_header "12. FASTAPI APPLICATION METRICS"

FASTAPI_RUNNING=$(kubectl get pods -n production -l app=fastapi --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
FASTAPI_TOTAL=$(kubectl get deployment -n production fastapi-app -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
FASTAPI_READY=$(kubectl get deployment -n production fastapi-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
FASTAPI_LB=$(kubectl get svc -n production fastapi-app-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

print_metric "FastAPI Replicas" "$FASTAPI_READY/$FASTAPI_TOTAL ready" ""
if [ "$FASTAPI_LB" != "pending" ] && [ -n "$FASTAPI_LB" ]; then
    print_metric "Load Balancer IP" "$FASTAPI_LB" ""
    print_metric "Access URL" "http://$FASTAPI_LB" ""
else
    print_warning_metric "Load Balancer IP" "pending assignment" ""
fi

##############################################################################
# 13. MONITORING STACK ACCESS
##############################################################################
print_header "13. MONITORING STACK ACCESS"

PROMETHEUS_LB=$(kubectl get svc -n monitoring prometheus-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
GRAFANA_LB=$(kubectl get svc -n monitoring grafana-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

echo "Prometheus:"
if [ -n "$PROMETHEUS_LB" ]; then
    print_metric "  LoadBalancer IP" "http://$PROMETHEUS_LB:9090" ""
else
    print_warning_metric "  Status" "awaiting LoadBalancer IP" ""
    print_metric "  Alternative" "kubectl port-forward -n monitoring svc/prometheus-server 9090:80" ""
fi

echo ""
echo "Grafana:"
if [ -n "$GRAFANA_LB" ]; then
    print_metric "  LoadBalancer IP" "http://$GRAFANA_LB:3000" ""
    print_metric "  Credentials" "admin / grafana" ""
else
    print_warning_metric "  Status" "awaiting LoadBalancer IP" ""
    print_metric "  Alternative" "kubectl port-forward -n monitoring svc/grafana 3000:80" ""
    print_metric "  Credentials" "admin / grafana" ""
fi

##############################################################################
# FINAL SUMMARY
##############################################################################
print_header "✓ METRICS CHECK COMPLETE"

echo -e "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "Duration: ${SECONDS}s\n"
