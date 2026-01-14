# Commands Quick Reference - Project Nebula

**Fast lookup for common commands organized by component.**

---

## Table of Contents

1. [kubectl Commands](#kubectl-commands)
2. [ArgoCD Commands](#argocd-commands)
3. [Kubernetes Inspection](#kubernetes-inspection)
4. [Troubleshooting Commands](#troubleshooting-commands)
5. [Monitoring Commands](#monitoring-commands)
6. [Git & Deployment](#git--deployment)
7. [Docker & Registry](#docker--registry)
8. [Useful Aliases](#useful-aliases)

---

## kubectl Commands

### Basic Operations

```bash
# Check cluster connection
kubectl cluster-info
kubectl version
kubectl auth can-i get pods --as=system:serviceaccount:default:default

# Get resources
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get nodes
kubectl get namespaces
kubectl get all -A  # All resources in all namespaces

# Describe resources (detailed view)
kubectl describe pod <pod-name> -n <namespace>
kubectl describe service fastapi-app-lb -n production
kubectl describe deployment fastapi-app -n production
kubectl describe node <node-name>

# Wide output (more columns)
kubectl get pods -n production -o wide
kubectl get services --all-namespaces -o wide
```

### Namespace Operations

```bash
# List namespaces
kubectl get namespaces
kubectl get ns

# Create namespace
kubectl create namespace my-app
kubectl create ns monitoring

# Delete namespace
kubectl delete namespace my-app

# Set default namespace
kubectl config set-context --current --namespace=production
kubectl config view --minify | grep namespace

# Get resources in namespace
kubectl get pods -n production
kubectl get all -n argocd
```

### Pod Operations

```bash
# List pods
kubectl get pods
kubectl get pods -n production
kubectl get pods -A  # All namespaces
kubectl get pods -n production -o wide  # Detailed
kubectl get pods -n production --sort-by=.metadata.creationTimestamp

# Get pod details
kubectl describe pod <pod-name> -n production
kubectl get pod <pod-name> -n production -o yaml
kubectl get pod <pod-name> -n production -o json

# Watch pods (live view)
kubectl get pods -n production --watch
watch kubectl get pods -n production

# Get pod by label
kubectl get pods -l app=fastapi -n production
kubectl get pods -l app=fastapi,version=v1 -n production

# Pod logs
kubectl logs <pod-name> -n production
kubectl logs <pod-name> -n production -f  # Stream
kubectl logs <pod-name> -n production --tail=50  # Last 50 lines
kubectl logs <pod-name> -n production -p  # Previous (if crashed)
kubectl logs -n production -l app=fastapi -f  # All pods with label

# Execute in pod
kubectl exec <pod-name> -n production -- ls -la
kubectl exec -it <pod-name> -n production -- /bin/bash  # Interactive
kubectl exec <pod-name> -n production -- python --version

# Port forward
kubectl port-forward pod/<pod-name> 8000:8000 -n production
kubectl port-forward svc/fastapi-app-lb 8000:80 -n production

# Delete pod
kubectl delete pod <pod-name> -n production
kubectl delete pods --all -n production

# Get resources used
kubectl top pod <pod-name> -n production
kubectl top pods -n production
kubectl top nodes
```

### Deployment Operations

```bash
# List deployments
kubectl get deployments
kubectl get deployments -n production -o wide

# Deployment details
kubectl describe deployment fastapi-app -n production
kubectl get deployment fastapi-app -n production -o yaml

# Scale deployment
kubectl scale deployment fastapi-app --replicas=5 -n production

# Edit deployment
kubectl edit deployment fastapi-app -n production

# Rollout status
kubectl rollout status deployment/fastapi-app -n production

# Rollout history
kubectl rollout history deployment/fastapi-app -n production
kubectl rollout history deployment/fastapi-app -n production --revision=1

# Rollback deployment
kubectl rollout undo deployment/fastapi-app -n production
kubectl rollout undo deployment/fastapi-app -n production --to-revision=1

# Restart deployment
kubectl rollout restart deployment/fastapi-app -n production
kubectl delete pod -l app=fastapi -n production  # Alternative
```

### Service Operations

```bash
# List services
kubectl get services
kubectl get services -n production
kubectl get svc -A  # All namespaces
kubectl get svc -o wide

# Service details
kubectl describe service fastapi-app-lb -n production
kubectl get service fastapi-app-lb -n production -o yaml

# Check endpoints
kubectl get endpoints -n production
kubectl describe endpoints fastapi-app-lb -n production

# Port forward to service
kubectl port-forward svc/fastapi-app-lb 8000:80 -n production

# Get service IP
kubectl get service fastapi-app-lb -n production -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Configuration & Secrets

```bash
# List ConfigMaps
kubectl get configmap -n production
kubectl describe configmap <name> -n production
kubectl get configmap <name> -n production -o yaml

# Create ConfigMap
kubectl create configmap my-config --from-literal=key=value -n production

# List Secrets
kubectl get secret -n production
kubectl get secret <name> -n production -o yaml

# Create Secret
kubectl create secret generic my-secret --from-literal=password=mysecret -n production

# View secret value
kubectl get secret <name> -n production -o jsonpath='{.data.password}' | base64 -d
```

### Apply & Delete

```bash
# Apply manifest
kubectl apply -f deployment.yaml
kubectl apply -f manifests/

# Apply with namespace
kubectl apply -f deployment.yaml -n production

# Dry run (test without applying)
kubectl apply -f deployment.yaml --dry-run=client
kubectl apply -f deployment.yaml --dry-run=server

# Delete resource
kubectl delete pod <pod-name> -n production
kubectl delete deployment fastapi-app -n production
kubectl delete service fastapi-app-lb -n production
kubectl delete -f deployment.yaml

# Delete all in namespace
kubectl delete all --all -n production
kubectl delete pods,services,deployments --all -n production
```

### Events & Logs

```bash
# Get events
kubectl get events -n production
kubectl get events --all-namespaces
kubectl get events -n production --sort-by='.lastTimestamp'

# Watch events
kubectl get events -n production --watch

# Watch specific resource
kubectl get pod <pod-name> -n production --watch
watch kubectl get pods -n production

# Pod logs
kubectl logs <pod-name> -n production
kubectl logs <pod-name> -n production -f  # Stream
kubectl logs <pod-name> -n production --tail=50
kubectl logs <pod-name> -n production --previous  # Previous container

# Logs from all pods with label
kubectl logs -n production -l app=fastapi -f
kubectl logs -n production -l app=fastapi --all-containers=true
```

### Patching & Editing

```bash
# Edit resource
kubectl edit deployment fastapi-app -n production
kubectl edit service fastapi-app-lb -n production

# Patch resource
kubectl patch service fastapi-app-lb -n production -p '{"spec":{"type":"LoadBalancer"}}'

# Set image
kubectl set image deployment/fastapi-app \
  fastapi=192.168.0.113:5000/fastapi-demo:v2 -n production

# Set resource limits
kubectl set resources deployment fastapi-app \
  --limits=cpu=500m,memory=1Gi \
  --requests=cpu=250m,memory=512Mi -n production
```

---

## ArgoCD Commands

### Application Management

```bash
# List applications
argocd app list
argocd app list --refresh

# Get application status
argocd app get fastapi-prod
argocd app get fastapi-prod --refresh

# Get application details (verbose)
argocd app info fastapi-prod

# Sync application
argocd app sync fastapi-prod
argocd app sync fastapi-prod --force

# Auto-sync status
argocd app set fastapi-prod --sync-policy automated
argocd app set fastapi-prod --sync-policy manual

# Watch sync progress
argocd app wait fastapi-prod
argocd app wait fastapi-prod --sync

# Delete application
argocd app delete fastapi-prod
argocd app delete fastapi-prod --cascade
```

### Repository Management

```bash
# List repositories
argocd repo list

# Add repository
argocd repo add ssh://git@192.168.0.190/root/project_nebula.git \
  --ssh-private-key-path ~/.ssh/id_rsa

# Repository details
argocd repo get ssh://git@192.168.0.190/root/project_nebula.git

# Refresh repository
argocd repo refresh

# Remove repository
argocd repo remove ssh://git@192.168.0.190/root/project_nebula.git
```

### User & Authentication

```bash
# Login to ArgoCD
argocd login 192.168.0.202 --username admin --password <password>

# Get current user
argocd account get-info

# Change password
argocd account update-password --current-password old --new-password new

# Create token
argocd account generate-token --account <username>

# List accounts
argocd account list
```

### Cluster Management

```bash
# List clusters
argocd cluster list

# Get cluster info
argocd cluster info kubernetes.default.svc

# Add cluster
argocd cluster add <context-name>

# Remove cluster
argocd cluster remove kubernetes.default.svc
```

---

## Kubernetes Inspection

### Resource Status

```bash
# Current cluster state
kubectl cluster-info
kubectl get nodes -o wide

# Namespaces
kubectl get namespaces

# All resources
kubectl get all -n production
kubectl get all -A  # All namespaces

# Pods status
kubectl get pods -n production
kubectl get pods -n production --field-selector=status.phase=Running
kubectl get pods -n production --field-selector=status.phase=Pending

# Service endpoints
kubectl get endpoints -A
kubectl describe endpoints <service-name> -n production

# Resource quotas
kubectl get resourcequota -n production
kubectl describe resourcequota <name> -n production

# Node status
kubectl get nodes
kubectl describe node <node-name>
kubectl top nodes

# Resource usage
kubectl top pods -n production
kubectl top nodes

# PVC/PV status
kubectl get pvc -n production
kubectl get pv
```

### Configuration Inspection

```bash
# Current context
kubectl config current-context

# All contexts
kubectl config get-contexts

# Set context
kubectl config use-context <context-name>

# View kubeconfig
kubectl config view

# Get API resources
kubectl api-resources

# Get API versions
kubectl api-versions

# Explain resource
kubectl explain pod
kubectl explain pod.spec
kubectl explain deployment.spec.template.spec.containers
```

---

## Troubleshooting Commands

### Pod Issues

```bash
# Describe for troubleshooting
kubectl describe pod <pod-name> -n production

# Check logs (current and previous)
kubectl logs <pod-name> -n production
kubectl logs <pod-name> -n production --previous

# Stream logs
kubectl logs <pod-name> -n production -f

# Get pod YAML
kubectl get pod <pod-name> -n production -o yaml

# Execute debug command
kubectl exec <pod-name> -n production -- /bin/sh -c "printenv"

# Restart pod
kubectl delete pod <pod-name> -n production

# Get pod events
kubectl get events -n production --field-selector involvedObject.name=<pod-name>
```

### Deployment Issues

```bash
# Check deployment status
kubectl get deployment <deployment-name> -n production
kubectl describe deployment <deployment-name> -n production

# Check replica status
kubectl get pods -n production -l app=<app-name>

# Check rollout status
kubectl rollout status deployment/<deployment-name> -n production

# Check rollout history
kubectl rollout history deployment/<deployment-name> -n production

# View deployment events
kubectl describe deployment <deployment-name> -n production | tail -30

# Rollback deployment
kubectl rollout undo deployment/<deployment-name> -n production
```

### Service Issues

```bash
# Check service
kubectl get service <service-name> -n production
kubectl describe service <service-name> -n production

# Check endpoints
kubectl get endpoints <service-name> -n production
kubectl describe endpoints <service-name> -n production

# Test from pod
kubectl run debug --image=nicolaka/netshoot -it --rm -- /bin/bash
# Inside pod: curl http://<service-name>:80

# Port forward for testing
kubectl port-forward svc/<service-name> 8000:80 -n production
# Then: curl localhost:8000

# Check DNS
kubectl run debug --image=nicolaka/netshoot -it --rm -- nslookup <service-name>.production.svc.cluster.local
```

### Resource Issues

```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Check pod resource usage
kubectl top pods -n production

# Check resource requests/limits
kubectl get pods -n production -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources}{"\n"}{end}'

# Pending pods (insufficient resources)
kubectl get pods -n production --field-selector=status.phase=Pending
kubectl describe pod <pending-pod> -n production

# Add more resources
kubectl set resources deployment <deployment-name> \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=512Mi -n production
```

### Network Issues

```bash
# Test internal connectivity
kubectl run debug --image=nicolaka/netshoot -it --rm -- /bin/bash
# Inside: curl http://fastapi-app.production.svc.cluster.local

# Check DNS
kubectl run debug --image=nicolaka/netshoot -it --rm -- \
  nslookup fastapi-app.production.svc.cluster.local

# Check service endpoints
kubectl get endpoints -n production

# Port forward for testing
kubectl port-forward pod/<pod-name> 8000:8000 -n production

# Check network policies
kubectl get networkpolicies -n production
kubectl describe networkpolicy <policy-name> -n production

# Test with curl from pod
kubectl exec -it <pod-name> -n production -- \
  curl http://prometheus-server.monitoring:9090
```

---

## Monitoring Commands

### Prometheus

```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# Query Prometheus
curl 'http://192.168.0.204:9090/api/v1/query?query=up'
curl 'http://192.168.0.204:9090/api/v1/query?query=container_memory_usage_bytes'

# Get targets
curl 'http://192.168.0.204:9090/api/v1/targets' | jq

# Get alerts
curl 'http://192.168.0.204:9090/api/v1/alerts' | jq
```

### Grafana

```bash
# Port forward to Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Get admin password
kubectl get secret grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d

# List datasources
curl -u admin:grafana http://192.168.0.205:3000/api/datasources | jq

# Get dashboards
curl -u admin:grafana http://192.168.0.205:3000/api/search | jq
```

### Metrics Collection

```bash
# Check metric scraping
kubectl logs -n monitoring -l app=prometheus -f

# Test metric endpoint
curl http://192.168.0.203/metrics

# Get specific metric
kubectl exec -it <pod-name> -n production -- \
  curl http://localhost:8000/metrics | grep http_requests
```

---

## Git & Deployment

### Git Operations

```bash
# View repository
cd /root/project_nebula
git status
git log --oneline

# Commit changes
git add src/main.py
git commit -m "Add new endpoint"

# Push changes
git push origin master

# View diff
git diff HEAD src/main.py

# Revert changes
git revert HEAD
git reset --hard HEAD~1

# Create branch
git checkout -b feature/new-feature
git push origin feature/new-feature

# Merge
git checkout master
git merge feature/new-feature
```

### ArgoCD Sync

```bash
# Manual sync
argocd app sync fastapi-prod

# Sync with force
argocd app sync fastapi-prod --force

# Watch sync
argocd app wait fastapi-prod --sync

# Enable auto-sync
argocd app set fastapi-prod --sync-policy automated

# Check sync status
argocd app get fastapi-prod | grep Sync
```

### GitLab CI/CD

```bash
# View pipeline status
# Go to: GitLab UI → Pipelines

# Trigger pipeline manually
# Go to: GitLab UI → Pipelines → Run Pipeline

# View deployment logs
# Go to: GitLab UI → Pipelines → Deploy Stage → Logs

# Check variables
# Go to: GitLab UI → Settings → CI/CD → Variables
```

---

## Docker & Registry

### Docker Commands

```bash
# Build image
docker build -t 192.168.0.113:5000/fastapi-demo:latest .
docker build -t 192.168.0.113:5000/fastapi-demo:v1.0.0 .

# Tag image
docker tag fastapi-demo:latest 192.168.0.113:5000/fastapi-demo:latest

# Push image
docker push 192.168.0.113:5000/fastapi-demo:latest

# Pull image
docker pull 192.168.0.113:5000/fastapi-demo:latest

# List images
docker images

# Remove image
docker rmi 192.168.0.113:5000/fastapi-demo:latest

# Run container
docker run -p 8000:8000 192.168.0.113:5000/fastapi-demo:latest

# View logs
docker logs <container-id>
```

### Registry Commands

```bash
# List images in registry
curl http://192.168.0.113:5000/v2/_catalog

# List image tags
curl http://192.168.0.113:5000/v2/fastapi-demo/tags/list

# Check image manifest
curl http://192.168.0.113:5000/v2/fastapi-demo/manifests/latest

# Clean up old images (if needed)
# Registry garbage collection:
docker exec registry /bin/registry garbage-collect /etc/docker/registry/config.yml
```

---

## Useful Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# kubectl shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods --all-namespaces'
alias kgs='kubectl get services'
alias kgd='kubectl get deployment'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kapi='kubectl api-resources'
alias kctx='kubectl config current-context'

# ArgoCD shortcuts
alias ag='argocd app get'
alias al='argocd app list'
alias async='argocd app sync'

# Kubernetes operations
alias kga='kubectl get all'
alias kgaa='kubectl get all -A'
alias kgn='kubectl get namespaces'
alias kdel='kubectl delete'

# Common namespace operations
alias kprod='kubectl -n production'
alias kmon='kubectl -n monitoring'
alias kargo='kubectl -n argocd'

# Useful combinations
alias kgpp='kubectl get pods -n production'
alias klpp='kubectl logs -n production -f'
alias kexpp='kubectl exec -it -n production'

# Usage examples:
# k get pods -n production
# kl pod-name -n production -f
# kex pod-name -n production -- /bin/bash
# kprod get pods
```

---

## Common Tasks

### Deploy New Version

```bash
# 1. Build and push image
docker build -t 192.168.0.113:5000/fastapi-demo:v2.0 .
docker push 192.168.0.113:5000/fastapi-demo:v2.0

# 2. Update deployment
kubectl set image deployment/fastapi-app \
  fastapi=192.168.0.113:5000/fastapi-demo:v2.0 -n production

# Or via Git (better):
# Edit manifests/deployment.yaml
# Change image version
# git commit && git push
# ArgoCD auto-syncs
```

### Scale Application

```bash
# Scale to 5 replicas
kubectl scale deployment fastapi-app --replicas=5 -n production

# Or edit deployment
kubectl edit deployment fastapi-app -n production
# Change: replicas: 5

# Verify
kubectl get pods -n production --watch
```

### Check Health

```bash
# Run status check script
./scripts/quick-status.sh

# Or manually:
kubectl get all -n production
kubectl top pods -n production
curl http://192.168.0.203/health
curl http://192.168.0.204:9090/-/healthy  # Prometheus
```

### View Logs

```bash
# Current logs
kubectl logs -n production -l app=fastapi

# Stream logs
kubectl logs -n production -l app=fastapi -f

# From specific pod
kubectl logs <pod-name> -n production -f
```

---

## Quick Links

- **Setup Guide:** `docs/SETUP_GUIDE.md`
- **Architecture Guide:** `docs/ARCHITECTURE_GUIDE.md`
- **Status Scripts:** `scripts/quick-status.sh`, `scripts/check-all-status.sh`
- **ArgoCD UI:** http://192.168.0.202
- **Grafana:** http://192.168.0.205:3000 (admin/grafana)
- **Prometheus:** http://192.168.0.204:9090

