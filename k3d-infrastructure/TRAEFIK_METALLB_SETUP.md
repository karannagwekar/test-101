# Traefik & MetalLB Setup Guide for K3D

This guide explains how to install and configure Traefik and MetalLB on your k3d cluster after it's been created with Terraform.

## Prerequisites

Your k3d cluster is pre-configured with:
- Traefik disabled in k3s (allows custom Traefik installation)
- Port mappings for Traefik (8080→80, 8443→443 by default)
- Docker network setup optimized for external access
- IPAM configuration for MetalLB compatibility

## Architecture Overview

```
Your Machine (macOS/Linux)
    ↓
    ├─→ localhost:8080 (HTTP) ─→ Traefik HTTP (80)
    └─→ localhost:8443 (HTTPS) ─→ Traefik HTTPS (443)
                ↓
            k3d Cluster (Docker Network: 172.18.0.0/16)
                ↓
        ┌───────────────────────┐
        │   Kubernetes          │
        │  ┌─────────────────┐  │
        │  │ Traefik Ingress │  │
        │  │  Service: LB    │  │
        │  │  IP: 172.18.0.X │  │
        │  └─────────────────┘  │
        │         ↓             │
        │  ┌─────────────────┐  │
        │  │   MetalLB       │  │
        │  │ IP Pool:        │  │
        │  │ 172.18.0.200-250│  │
        │  └─────────────────┘  │
        └───────────────────────┘
```

## Step 1: Verify Cluster Setup

First, verify your cluster is running and configured correctly:

```bash
# Check cluster status
k3d cluster list

# Verify kubeconfig
k3d kubeconfig get k3d-cluster > ~/.kube/k3d-config
kubectl --kubeconfig=~/.kube/k3d-config cluster-info

# Get cluster details (should show 1 server + 2 agents)
kubectl --kubeconfig=~/.kube/k3d-config get nodes -o wide
```

Expected output:
```
NAME                 STATUS   ROLES          
k3d-k3d-cluster-server-0   Ready    control-plane  
k3d-k3d-cluster-agent-0    Ready    <none>         
k3d-k3d-cluster-agent-1    Ready    <none>
```

## Step 2: Install MetalLB Load Balancer

MetalLB provides LoadBalancer service type support for k3d clusters.

### 2.1 Add MetalLB Helm Repository

```bash
helm repo add metallb https://metallb.github.io/metallb
helm repo update
```

### 2.2 Create Namespace and Install MetalLB

```bash
# Create metallb-system namespace
kubectl --kubeconfig=~/.kube/k3d-config create namespace metallb-system

# Install MetalLB
helm install metallb metallb/metallb \
  --namespace metallb-system \
  --kubeconfig=~/.kube/k3d-config \
  --version 0.13.10  # Use a stable version
```

### 2.3 Verify MetalLB Installation

```bash
# Check MetalLB pods
kubectl --kubeconfig=~/.kube/k3d-config get pods -n metallb-system

# Should show controller and speaker pods in Running state
```

### 2.4 Configure MetalLB IP Pool

Create an IP address pool for MetalLB:

```bash
cat <<EOF | kubectl --kubeconfig=~/.kube/k3d-config apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - 172.18.0.200-172.18.0.250

---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
EOF
```

Verify configuration:

```bash
# Check IPAddressPool
kubectl --kubeconfig=~/.kube/k3d-config get ipaddresspool -n metallb-system

# Check L2Advertisement
kubectl --kubeconfig=~/.kube/k3d-config get l2advertisement -n metallb-system
```

## Step 3: Install Traefik Ingress Controller

### 3.1 Add Traefik Helm Repository

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
```

### 3.2 Create Traefik Configuration

Create a file `traefik-values.yaml`:

```yaml
# Traefik Helm Chart Values
service:
  type: LoadBalancer
  spec:
    loadBalancerIP: "172.18.0.200"

# Entrypoints configuration
ports:
  web:
    port: 80
    exposedPort: 80
  websecure:
    port: 443
    exposedPort: 443

# Enable IngressClass
ingressClass:
  enabled: true
  isDefaultClass: true

# Traefik Dashboard (optional)
dashboard:
  enabled: true

# Logging (optional)
logs:
  general:
    level: INFO
  access:
    enabled: true
```

### 3.3 Install Traefik

```bash
# Create traefik namespace
kubectl --kubeconfig=~/.kube/k3d-config create namespace traefik

# Install Traefik
helm install traefik traefik/traefik \
  --namespace traefik \
  --kubeconfig=~/.kube/k3d-config \
  -f traefik-values.yaml \
  --version 28.0.0  # Use a stable version
```

### 3.4 Verify Traefik Installation

```bash
# Check Traefik pods
kubectl --kubeconfig=~/.kube/k3d-config get pods -n traefik

# Check Traefik service (should show EXTERNAL-IP from MetalLB pool)
kubectl --kubeconfig=~/.kube/k3d-config get svc -n traefik traefik -o wide
```

Expected output:
```
NAME      TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)
traefik   LoadBalancer   10.43.247.32   172.18.0.200     80:31567/TCP,443:31568/TCP
```

## Step 4: Test Traefik & MetalLB

### 4.1 Create a Test Application

Deploy a simple test application:

```bash
cat <<EOF | kubectl --kubeconfig=~/.kube/k3d-config apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
      - name: whoami
        image: traefik/whoami:latest
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: whoami
  namespace: default
spec:
  selector:
    app: whoami
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami-ingress
  namespace: default
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
  - host: whoami.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: whoami
            port:
              number: 80
EOF
```

### 4.2 Test Access

Add the host entry to your `/etc/hosts`:

```bash
# On macOS/Linux
echo "127.0.0.1 whoami.local" | sudo tee -a /etc/hosts
```

Access the application:

```bash
# HTTP
curl http://whoami.local:8080/

# Or use your browser
# http://whoami.local:8080/
```

Expected response showing the container ID and request details.

### 4.3 Access Traefik Dashboard

Port-forward to Traefik dashboard:

```bash
kubectl --kubeconfig=~/.kube/k3d-config -n traefik port-forward svc/traefik 9000:9000
```

Then visit: `http://localhost:9000/dashboard/`

## Step 5: Verify Everything Works

### 5.1 Check All Components

```bash
# List all namespaces
kubectl --kubeconfig=~/.kube/k3d-config get ns

# Check MetalLB status
kubectl --kubeconfig=~/.kube/k3d-config get all -n metallb-system

# Check Traefik status
kubectl --kubeconfig=~/.kube/k3d-config get all -n traefik

# Check services with external IPs
kubectl --kubeconfig=~/.kube/k3d-config get svc -A | grep LoadBalancer
```

### 5.2 Verify Ingress Routes

```bash
# List Ingress resources
kubectl --kubeconfig=~/.kube/k3d-config get ingress -A

# Describe specific ingress
kubectl --kubeconfig=~/.kube/k3d-config describe ingress whoami-ingress
```

## Advanced: External Access from Host

### For macOS/Linux: Add Network Route

To access services externally from your host machine, add a route to the Docker network:

```bash
# Get Docker bridge gateway for k3d network
GATEWAY=$(docker network inspect k3d-k3d-cluster | grep -oP '"Gateway": "\K[^"]+' | head -1)

# Add route (requires sudo)
sudo route add -net 172.18.0.0/16 $GATEWAY
```

Then you can access MetalLB services directly:

```bash
# Access via MetalLB IP
curl http://172.18.0.200/
```

### For Windows: Use Port Forwarding

Windows doesn't support direct network routing to Docker networks. Use port-forward instead:

```bash
kubectl --kubeconfig=~/.kube/k3d-config port-forward -n traefik svc/traefik 8080:80 8443:443
```

## Troubleshooting

### MetalLB Not Assigning IPs

```bash
# Check MetalLB controller logs
kubectl --kubeconfig=~/.kube/k3d-config logs -n metallb-system -l app=metallb-controller

# Check MetalLB events
kubectl --kubeconfig=~/.kube/k3d-config get events -n metallb-system
```

**Common issues:**
- IP pool not configured correctly
- L2Advertisement not created
- Speaker pods not running on all nodes

### Traefik LoadBalancer Stuck in Pending

```bash
# Check Traefik logs
kubectl --kubeconfig=~/.kube/k3d-config logs -n traefik -l app.kubernetes.io/name=traefik

# Check if MetalLB is running
kubectl --kubeconfig=~/.kube/k3d-config get pods -n metallb-system
```

### Cannot Access Services from Host

```bash
# Verify network connectivity
docker network inspect k3d-k3d-cluster

# Check if route exists (macOS/Linux)
netstat -rn | grep 172.18

# Test connectivity to k3d container
docker exec k3d-k3d-cluster-server-0 curl http://172.18.0.200/
```

### Ingress Not Routing Traffic

```bash
# Check ingress status
kubectl --kubeconfig=~/.kube/k3d-config describe ingress whoami-ingress

# Check Traefik logs for routing errors
kubectl --kubeconfig=~/.kube/k3d-config logs -n traefik -f

# Test direct service access
kubectl --kubeconfig=~/.kube/k3d-config port-forward svc/whoami 8080:80
# Then: curl localhost:8080/
```

## Cleanup (Optional)

To remove Traefik and MetalLB:

```bash
# Remove test application
kubectl --kubeconfig=~/.kube/k3d-config delete ingress whoami-ingress
kubectl --kubeconfig=~/.kube/k3d-config delete svc whoami
kubectl --kubeconfig=~/.kube/k3d-config delete deployment whoami

# Remove Traefik
helm uninstall traefik --namespace traefik --kubeconfig=~/.kube/k3d-config
kubectl --kubeconfig=~/.kube/k3d-config delete namespace traefik

# Remove MetalLB
helm uninstall metallb --namespace metallb-system --kubeconfig=~/.kube/k3d-config
kubectl --kubeconfig=~/.kube/k3d-config delete namespace metallb-system

# Remove host entry (if added)
# Edit /etc/hosts and remove whoami.local entry
```

## Next Steps

1. **Deploy Multiple Applications**
   - Create more ingress resources for different apps
   - Configure DNS with different hosts
   - Set up SSL/TLS with cert-manager

2. **Add Cert-Manager for SSL/TLS**
   ```bash
   helm repo add jetstack https://charts.jetstack.io
   helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace
   ```

3. **Configure ArgoCD with Ingress**
   - Update ArgoCD Helm values to use Ingress
   - Point argocd.local to Traefik Ingress

4. **Monitor with Prometheus & Grafana**
   - Traefik exports Prometheus metrics
   - Monitor cluster health and performance

## References

- [MetalLB Documentation](https://metallb.universe.tf/)
- [Traefik Documentation](https://doc.traefik.io/)
- [K3D Documentation](https://k3d.io/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)

---

**Last Updated:** November 30, 2025
