# K3D Infrastructure

Local Kubernetes cluster using k3d with support for Traefik ingress controller and MetalLB load balancer.

## Overview

This Terraform configuration creates a k3d cluster optimized for local development with future Traefik and MetalLB integration. The cluster is pre-configured with:

- **Kubernetes Version:** v1.31.1-k3s1
- **Architecture:** 1 server node + 2 agent nodes
- **Traefik:** Disabled by default (allows custom installation with full control)
- **Port Mappings:** 8080→80 (HTTP), 8443→443 (HTTPS), 6443→6443 (API)
- **MetalLB Support:** Pre-configured network for LoadBalancer IP assignment
- **Storage:** Docker volumes for persistence

## Prerequisites

- Docker (with Docker daemon running)
- k3d (v5.4+)
- Terraform (v1.0+)
- kubectl
- Helm (for installing Traefik & MetalLB later)

## Quick Start

### 1. Initialize Terraform

```bash
cd k3d-infrastructure
terraform init
```

### 2. Create Configuration File

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if needed (defaults are good for most cases)
```

### 3. Deploy Cluster

```bash
terraform apply
```

This will create:
- k3d cluster named `k3d-cluster`
- 1 server node
- 2 agent nodes
- Ports mapped for Traefik (8080→80, 8443→443)

### 4. Save Kubeconfig

```bash
k3d kubeconfig get k3d-cluster > ~/.kube/k3d-config
```

### 5. Verify Cluster

```bash
kubectl --kubeconfig=~/.kube/k3d-config cluster-info
kubectl --kubeconfig=~/.kube/k3d-config get nodes
```

## Configuration

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cluster_name` | string | `k3d-cluster` | Name of the k3d cluster |
| `k8s_version` | string | `v1.31.1-k3s1` | Kubernetes version |
| `agent_nodes_count` | number | `2` | Number of worker nodes |
| `enable_traefik_port_mapping` | bool | `true` | Enable Traefik port mappings |
| `traefik_http_port` | number | `8080` | Host port for HTTP (80 inside) |
| `traefik_https_port` | number | `8443` | Host port for HTTPS (443 inside) |
| `metallb_ip_pool_start` | string | `172.18.0.200` | Starting IP for MetalLB pool |
| `metallb_ip_pool_size` | number | `50` | Number of IPs in MetalLB pool |

### Example Configuration

Create `terraform.tfvars`:

```hcl
cluster_name                = "k3d-cluster"
k8s_version                 = "v1.31.1-k3s1"
agent_nodes_count           = 2
enable_traefik_port_mapping = true
traefik_http_port           = 8080
traefik_https_port          = 8443
metallb_ip_pool_start       = "172.18.0.200"
metallb_ip_pool_size        = 50
```

## Files

- **main.tf** - k3d cluster creation via local provisioners
- **variables.tf** - Configuration variables with validation
- **outputs.tf** - Cluster information and access instructions
- **terraform.tfvars.example** - Example configuration file
- **provider.tf** - Terraform and null provider setup

## Accessing the Cluster

### Via Kubeconfig

```bash
# Set kubeconfig path
export KUBECONFIG=~/.kube/k3d-config

# Or use --kubeconfig flag
kubectl --kubeconfig=~/.kube/k3d-config get pods -A
```

### Port Forwarding

Access specific services using port-forward:

```bash
# Forward to a service
kubectl --kubeconfig=~/.kube/k3d-config port-forward svc/my-service 8080:80 -n default
```

## Key Features

### ✅ Traefik Ready

- Port mappings configured (8080→80, 8443→443)
- k3s Traefik disabled
- Ready for custom Traefik installation via Helm

### ✅ MetalLB Ready

- Docker network properly configured
- IPAM settings for IP assignment
- IP pool range: 172.18.0.200-172.18.0.249

### ✅ Production-like Architecture

- Separate server and agent nodes
- Multiple worker nodes for load balancing
- Kubernetes networking fully configured

## Next Steps: Traefik & MetalLB

Your cluster is pre-configured for Traefik and MetalLB installation. To install them:

1. **Read the Setup Guide:**
   ```bash
   cat TRAEFIK_METALLB_SETUP.md
   ```

2. **Follow Installation Steps:**
   - Install MetalLB Load Balancer
   - Install Traefik Ingress Controller
   - Configure IP pools
   - Test with sample application

3. **Deploy Applications:**
   - Create Ingress resources
   - Access via LoadBalancer IPs
   - Route traffic through Traefik

See [TRAEFIK_METALLB_SETUP.md](TRAEFIK_METALLB_SETUP.md) for detailed instructions.

## Cluster Information

Get detailed cluster information:

```bash
# Cluster list
k3d cluster list

# Node details
kubectl --kubeconfig=~/.kube/k3d-config get nodes -o wide

# Network info
docker network inspect k3d-k3d-cluster

# Port mappings
docker port k3d-k3d-cluster-server-0
```

## Terraform Commands

### Apply Cluster

```bash
terraform apply
```

### Destroy Cluster

```bash
terraform destroy
```

### View Outputs

```bash
terraform output
terraform output access_instructions
```

### Plan Changes

```bash
terraform plan
```

### Get State

```bash
terraform show
```

## Troubleshooting

### Cluster Creation Fails

```bash
# Check if Docker is running
docker ps

# Check k3d version
k3d version

# View k3d logs
docker logs k3d-k3d-cluster-server-0
```

### Cannot Connect to Cluster

```bash
# Verify kubeconfig exists
ls -la ~/.kube/k3d-config

# Test kubeconfig
kubectl --kubeconfig=~/.kube/k3d-config cluster-info

# Regenerate kubeconfig
k3d kubeconfig get k3d-cluster > ~/.kube/k3d-config
chmod 600 ~/.kube/k3d-config
```

### Port Already in Use

If ports 8080 or 8443 are already in use:

```bash
# Find process using port
lsof -i :8080

# Either:
# 1. Stop the process
# 2. Or change the port in terraform.tfvars:
# traefik_http_port = 9080
# traefik_https_port = 9443
```

### Nodes Not Ready

```bash
# Check node status
kubectl --kubeconfig=~/.kube/k3d-config get nodes

# Check node events
kubectl --kubeconfig=~/.kube/k3d-config describe node k3d-k3d-cluster-agent-0

# Check kubelet logs
docker logs k3d-k3d-cluster-agent-0
```

## Performance Tuning

### Increase Nodes

```hcl
# In terraform.tfvars
agent_nodes_count = 5
```

### Adjust IP Pool for MetalLB

```hcl
metallb_ip_pool_start = "172.18.0.100"
metallb_ip_pool_size  = 100  # Creates 100 available IPs
```

### Use Different Kubernetes Version

```hcl
k8s_version = "v1.30.2-k3s1"  # Check k3s releases for available versions
```

## Cleanup

### Destroy Everything

```bash
terraform destroy

# Or manually delete the cluster
k3d cluster delete k3d-cluster
```

### Remove Kubeconfig

```bash
rm ~/.kube/k3d-config
```

### Remove Docker Network

```bash
# Networks are automatically cleaned up when cluster is deleted
# But if needed manually:
docker network rm k3d-k3d-cluster
```

## Accessing Cluster from Other Machines

To access from other machines on your network:

1. **Share Docker socket** (not recommended for security)
2. **Use kubectl proxy:**
   ```bash
   kubectl --kubeconfig=~/.kube/k3d-config proxy --address=0.0.0.0 --accept-hosts='^.*'
   ```

3. **Use Port Forward:**
   ```bash
   kubectl --kubeconfig=~/.kube/k3d-config port-forward pod/my-pod 8080:8080 --address=0.0.0.0
   ```

## Integrating with ArgoCD

To add GitOps capabilities, use the ArgoCD configuration:

```bash
cd ../argocd-for-k3d
terraform apply
```

This will deploy ArgoCD on your k3d cluster. See [`argocd-for-k3d/README.md`](../argocd-for-k3d/README.md) for details.

## Useful Commands

```bash
# Get cluster info
terraform output

# Watch pod creation
kubectl --kubeconfig=~/.kube/k3d-config get pods -w

# Check events
kubectl --kubeconfig=~/.kube/k3d-config get events -A

# View resource usage
kubectl --kubeconfig=~/.kube/k3d-config top nodes
kubectl --kubeconfig=~/.kube/k3d-config top pods

# Access cluster directly
docker exec -it k3d-k3d-cluster-server-0 bash
```

## State Management

Terraform state files are stored locally:

```bash
# Show current state
terraform show

# Backup state
cp terraform.tfstate terraform.tfstate.backup

# Import existing cluster (if manually created)
# terraform import null_resource.k3d_cluster dummy
```

## Security Notes

- k3d clusters are for **development only**
- Not suitable for production workloads
- Traefik ingress doesn't validate certificates by default
- MetalLB uses L2 mode (no BGP authentication)

## References

- [K3D Official Documentation](https://k3d.io/)
- [K3S Documentation](https://docs.k3s.io/)
- [Terraform Null Provider](https://registry.terraform.io/providers/hashicorp/null/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Support

For issues or questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review [TRAEFIK_METALLB_SETUP.md](TRAEFIK_METALLB_SETUP.md) for setup issues
3. Check k3d logs: `docker logs k3d-k3d-cluster-server-0`
4. Check Terraform state: `terraform show`

---

**Last Updated:** November 30, 2025
