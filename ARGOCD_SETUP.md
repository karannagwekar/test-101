# ArgoCD Setup Guide - Segregated by Cluster Type

This guide explains how to use the segregated ArgoCD configurations for different cluster types.

## Directory Structure

```
infrastructure-repository/
├── argocd-for-k3d/          # ← K3D-specific ArgoCD configuration
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── README.md
│   ├── terraform.tfvars.example
│   └── terraform.tfvars     # Copy from .example and customize
│
├── argocd-for-eks/          # ← EKS-specific ArgoCD configuration
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── README.md
│   ├── terraform.tfvars.example
│   └── terraform.tfvars     # Copy from .example and customize
│
├── k3d-infrastructure/      # K3D cluster infrastructure
├── eks-infrastructure/      # EKS cluster infrastructure
└── ...
```

## Key Differences

### K3D Configuration (`argocd-for-k3d/`)

**Default Settings:**
- `kubeconfig_path` = `~/.kube/k3d-config` (hardcoded)
- `cluster_type` = `k3d` (enforced)
- `argocd_domain` = `argocd-k3d.example.com`
- `enable_ingress` = `false` (uses LoadBalancer)
- Service Type = `LoadBalancer`

**Why?**
- Simple local development setup
- No need to change kubeconfig path each time
- LoadBalancer is simpler for local k3d clusters
- Clearly labeled as K3D-specific

### EKS Configuration (`argocd-for-eks/`)

**Default Settings:**
- `kubeconfig_path` = `~/.kube/eks-config` (hardcoded)
- `cluster_type` = `eks` (enforced)
- `argocd_domain` = `argocd-eks.example.com`
- `enable_ingress` = `true` (uses Ingress controller)
- Service Type = `ClusterIP` with Ingress

**Why?**
- Production-ready setup
- Assumes AWS Ingress controller is available
- Domain-based access through Ingress
- Clearly labeled as EKS-specific

## Usage Workflow

### For K3D Development

```bash
cd argocd-for-k3d

# Get k3d kubeconfig
k3d kubeconfig get k3d-cluster > ~/.kube/k3d-config

# Copy and customize config (kubeconfig_path already set)
cp terraform.tfvars.example terraform.tfvars

# Deploy
terraform init
terraform plan
terraform apply

# Access
kubectl --kubeconfig=~/.kube/k3d-config -n argocd port-forward svc/argocd-server 8080:443
# Visit: http://localhost:8080
```

### For EKS Production

```bash
cd argocd-for-eks

# Get EKS kubeconfig
aws eks update-kubeconfig --name YOUR_CLUSTER --region YOUR_REGION --kubeconfig ~/.kube/eks-config

# Copy and customize config (kubeconfig_path already set)
cp terraform.tfvars.example terraform.tfvars

# Deploy
terraform init
terraform plan
terraform apply

# Access
# Visit: https://argocd-eks.your-domain.com
```

## Benefits of Segregation

✅ **No More Path Confusion**
- K3D developers always use `argocd-for-k3d/`
- EKS operators always use `argocd-for-eks/`
- Kubeconfig paths are pre-configured

✅ **Environment-Specific Defaults**
- K3D: LoadBalancer, no ingress
- EKS: Ingress-based, domain access

✅ **Clear Separation of Concerns**
- Each directory is self-contained
- Different variable defaults for each cluster type
- No cross-cluster confusion

✅ **Easy to Maintain**
- Update K3D config without affecting EKS
- Different CI/CD pipelines can target different directories
- Clear documentation for each type

## Variable Validation

Each configuration enforces its cluster type:

**K3D Configuration:**
```terraform
validation {
  condition     = var.cluster_type == "k3d"
  error_message = "This configuration is for K3D clusters only."
}
```

**EKS Configuration:**
```terraform
validation {
  condition     = var.cluster_type == "eks"
  error_message = "This configuration is for EKS clusters only."
}
```

This prevents accidental deployment to the wrong cluster!

## Kubeconfig Organization

Recommended setup:

```bash
# Create separate kubeconfig files
~/.kube/k3d-config    # K3D cluster credentials
~/.kube/eks-config    # EKS cluster credentials
~/.kube/config        # Default kubeconfig (optional)

# Use them with:
kubectl --kubeconfig=~/.kube/k3d-config ...
kubectl --kubeconfig=~/.kube/eks-config ...
```

## GitHub Actions Integration

For CI/CD pipelines, you can target specific directories:

```yaml
# Deploy to K3D
- name: Deploy ArgoCD to K3D
  run: |
    cd argocd-for-k3d
    terraform apply

# Deploy to EKS
- name: Deploy ArgoCD to EKS
  run: |
    cd argocd-for-eks
    terraform apply
```

## Troubleshooting

### Wrong Cluster Type
If you try to deploy k3d config to EKS:
```
Error: cluster_type must be "eks"
```
**Solution:** Use `argocd-for-eks/` directory instead

### Wrong Kubeconfig
If connection fails:
```
Error: Unable to connect to cluster
```
**Solution:** Ensure kubeconfig file exists:
```bash
# For K3D
k3d kubeconfig get k3d-cluster > ~/.kube/k3d-config

# For EKS
aws eks update-kubeconfig --name YOUR_CLUSTER --region YOUR_REGION --kubeconfig ~/.kube/eks-config
```

## Cleanup

### Destroy K3D ArgoCD
```bash
cd argocd-for-k3d
terraform destroy
```

### Destroy EKS ArgoCD
```bash
cd argocd-for-eks
terraform destroy
```

### Destroy Both Clusters and ArgoCD
```bash
# First destroy ArgoCD
cd argocd-for-k3d && terraform destroy
cd ../argocd-for-eks && terraform destroy

# Then destroy clusters
cd ../k3d-infrastructure && terraform destroy
cd ../eks-infrastructure && terraform destroy
```

## Summary

By segregating ArgoCD configurations by cluster type:
- ✅ No more manual kubeconfig path edits
- ✅ Prevents accidental cross-cluster deployments
- ✅ Clear, maintainable project structure
- ✅ Environment-specific optimizations
- ✅ Easy documentation and support
