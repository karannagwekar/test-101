# ArgoCD GitOps Configuration for K3D

This directory contains Terraform configuration for deploying ArgoCD to **k3d clusters only**.

For EKS clusters, use the `argocd-for-eks` directory instead.

## Quick Start

### Prerequisites

1. **K3D Cluster** - Created with `k3d-infrastructure` Terraform
2. **kubectl** - Installed locally
3. **Terraform** - Version 1.0 or higher

### Setup Steps

1. **Get K3D Cluster Kubeconfig:**
   ```bash
   k3d kubeconfig get k3d-cluster > ~/.kube/k3d-config
   
   # Verify connection
   kubectl --kubeconfig=~/.kube/k3d-config cluster-info
   ```

2. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Update terraform.tfvars:**
   ```hcl
   # K3D-specific configuration (already set by default)
   kubeconfig_path        = "~/.kube/k3d-config"
   cluster_type           = "k3d"
   argocd_namespace       = "argocd"
   argocd_domain          = "argocd-k3d.example.com"
   git_repository_url     = "https://github.com/your-org/your-gitops-repo.git"
   git_repository_branch  = "main"
   git_repository_path    = "k8s-manifests"
   enable_ingress         = false  # K3D uses LoadBalancer
   ```

4. **Initialize and apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Accessing ArgoCD

### Using Port Forwarding (Default for K3D)
```bash
kubectl --kubeconfig=~/.kube/k3d-config -n argocd port-forward svc/argocd-server 8080:443

# Get password
kubectl --kubeconfig=~/.kube/k3d-config -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Visit: http://localhost:8080
# Username: admin
# Password: (from command above)
```

## Differences from EKS

| Aspect | K3D | EKS |
|--------|-----|-----|
| Kubeconfig Path | `~/.kube/k3d-config` | `~/.kube/eks-config` |
| Domain | `argocd-k3d.example.com` | `argocd-eks.example.com` |
| Ingress | Disabled by default | Enabled by default |
| Service Type | LoadBalancer | ClusterIP (with Ingress) |
| Setup Complexity | Simple local development | Requires AWS setup |

## Directory Structure

This is a **standalone configuration** for k3d only:
- Do NOT edit kubeconfig_path to point to EKS
- Use `argocd-for-eks` directory for EKS deployments
- Keep separate kubeconfig files to avoid confusion

## Verifying the Deployment

```bash
# Check ArgoCD namespace and pods
kubectl --kubeconfig=~/.kube/k3d-config -n argocd get pods

# Verify the server is running
kubectl --kubeconfig=~/.kube/k3d-config -n argocd get svc argocd-server

# Check the LoadBalancer external IP
kubectl --kubeconfig=~/.kube/k3d-config -n argocd get svc argocd-server -o wide
```

## Cleanup

To remove ArgoCD from your k3d cluster:

```bash
terraform destroy
```

To also destroy the k3d cluster itself:

```bash
cd ../k3d-infrastructure
terraform destroy
```

## Notes

- This configuration is **k3d-specific** with optimized defaults for local development
- Always keep your kubeconfig files separate for different clusters
- Store the initial admin password safely - you can change it in the UI
- K3D is perfect for local development and testing of GitOps workflows
