# ArgoCD GitOps Configuration for EKS

This directory contains Terraform configuration for deploying ArgoCD to **AWS EKS clusters only**.

For k3d clusters, use the `argocd-for-k3d` directory instead.

## Quick Start

### Prerequisites

1. **AWS EKS Cluster** - Must be already created
2. **AWS CLI** - Configured with appropriate credentials
3. **kubectl** - Installed locally
4. **Terraform** - Version 1.0 or higher

### Setup Steps

1. **Get EKS Cluster Kubeconfig:**
   ```bash
   aws eks update-kubeconfig --name YOUR_CLUSTER_NAME --region YOUR_AWS_REGION --kubeconfig ~/.kube/eks-config
   
   # Verify connection
   kubectl --kubeconfig=~/.kube/eks-config cluster-info
   ```

2. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Update terraform.tfvars:**
   ```hcl
   # Update with your EKS cluster details
   kubeconfig_path        = "~/.kube/eks-config"
   cluster_type           = "eks"
   argocd_namespace       = "argocd"
   argocd_domain          = "argocd-eks.your-domain.com"  # Update with your domain
   git_repository_url     = "https://github.com/your-org/your-gitops-repo.git"
   git_repository_branch  = "main"
   git_repository_path    = "k8s-manifests"
   enable_ingress         = true  # EKS has ingress controllers
   ```

4. **Initialize and apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Accessing ArgoCD

### Option 1: Using Port Forwarding (Development)
```bash
kubectl --kubeconfig=~/.kube/eks-config -n argocd port-forward svc/argocd-server 8080:443

# Get password
kubectl --kubeconfig=~/.kube/eks-config -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Visit: http://localhost:8080
# Username: admin
# Password: (from command above)
```

### Option 2: Using Ingress (Production)
```bash
# Get the Ingress URL
kubectl --kubeconfig=~/.kube/eks-config -n argocd get ingress

# Visit: https://argocd-eks.your-domain.com
# Username: admin
# Password: (from secret command above)
```

## Differences from K3D

| Aspect | K3D | EKS |
|--------|-----|-----|
| Kubeconfig Path | `~/.kube/k3d-config` | `~/.kube/eks-config` |
| Domain | `argocd-k3d.example.com` | `argocd-eks.example.com` |
| Ingress | Disabled by default | Enabled by default |
| Authentication | Auto-generated password | Auto-generated password |
| Service Type | LoadBalancer | ClusterIP (with Ingress) |

## Directory Structure

This is a **standalone configuration** for EKS only:
- Do NOT edit kubeconfig_path to point to k3d
- Use `argocd-for-k3d` directory for k3d deployments
- Keep separate kubeconfig files to avoid confusion

## Verifying the Deployment

```bash
# Check ArgoCD namespace and pods
kubectl --kubeconfig=~/.kube/eks-config -n argocd get pods

# Verify the server is running
kubectl --kubeconfig=~/.kube/eks-config -n argocd get svc argocd-server

# Check ingress (if enabled)
kubectl --kubeconfig=~/.kube/eks-config -n argocd get ingress
```

## Cleanup

To remove ArgoCD from your EKS cluster:

```bash
terraform destroy
```

This will remove:
- ArgoCD Helm release
- ArgoCD namespace and all resources
- Kubernetes secrets and ConfigMaps

## Notes

- This configuration is **EKS-specific** with optimized defaults
- Always keep your kubeconfig files separate for different clusters
- Store the initial admin password safely - you can change it in the UI
- For production, configure proper DNS and SSL certificates for the Ingress
