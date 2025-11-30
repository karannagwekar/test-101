# Infrastructure Repository

Infrastructure as Code (IaC) repository containing Terraform configurations for Kubernetes clusters and GitOps deployments.

**Author:** Karan Nagwekar

## 📁 Repository Structure

```
infrastructure-repository/
├── k3d-infrastructure/          # K3D local Kubernetes cluster
├── eks-infrastructure/          # AWS EKS cluster
├── ec2-infrastructure/          # AWS EC2 infrastructure
│
├── argocd-for-k3d/             # ArgoCD for K3D (GitOps)
├── argocd-for-eks/             # ArgoCD for EKS (GitOps)
│
├── ARGOCD_SETUP.md             # Complete ArgoCD setup guide
└── README.md                   # This file
```

## 🚀 Quick Start

### 1. Setup K3D Cluster with ArgoCD

```bash
# Deploy k3d cluster
cd k3d-infrastructure
terraform apply

# Deploy ArgoCD on k3d
cd ../argocd-for-k3d
terraform apply

# Access ArgoCD
kubectl --kubeconfig=~/.kube/k3d-config -n argocd port-forward svc/argocd-server 8080:443
# Visit: http://localhost:8080
```

### 2. Setup EKS Cluster with ArgoCD

```bash
# Deploy EKS cluster (requires AWS setup)
cd eks-infrastructure
terraform apply

# Deploy ArgoCD on EKS
cd ../argocd-for-eks
terraform apply

# Access ArgoCD
# Visit: https://argocd-eks.your-domain.com
```

## 📋 Key Features

### ✅ Segregated ArgoCD Configurations

**No more manual kubeconfig path changes!**

- **`argocd-for-k3d/`** - K3D-specific setup with hardcoded defaults
  - Kubeconfig: `~/.kube/k3d-config`
  - Service: LoadBalancer
  - Perfect for local development

- **`argocd-for-eks/`** - EKS-specific setup with production defaults
  - Kubeconfig: `~/.kube/eks-config`
  - Service: Ingress-based
  - Production-ready

### ✅ Infrastructure Automation

- **K3D Cluster**: Local Kubernetes v1.31.1 with 2 worker nodes
- **EKS Cluster**: AWS-managed Kubernetes with autoscaling
- **EC2 Infrastructure**: Supporting infrastructure on AWS

### ✅ GitOps Ready

- ArgoCD pre-configured for GitOps workflows
- Auto-generated admin passwords
- Separate configurations prevent cross-cluster confusion

## 🔧 Configuration Files

### K3D + ArgoCD

```bash
cd argocd-for-k3d
cp terraform.tfvars.example terraform.tfvars

# terraform.tfvars defaults (no changes needed):
# - kubeconfig_path = ~/.kube/k3d-config
# - cluster_type = k3d
# - enable_ingress = false
```

### EKS + ArgoCD

```bash
cd argocd-for-eks
cp terraform.tfvars.example terraform.tfvars

# Update terraform.tfvars:
# - git_repository_url = your-repo-url
# - argocd_domain = your-domain.com
# - enable_ingress = true (already set)
```

## 🔐 Getting Started

### Prerequisites

- Terraform >= 1.0
- kubectl
- Docker (for k3d)
- AWS CLI (for EKS)

### Kubeconfig Setup

```bash
# For K3D
mkdir -p ~/.kube
k3d kubeconfig get k3d-cluster > ~/.kube/k3d-config

# For EKS
aws eks update-kubeconfig --name YOUR_CLUSTER --region YOUR_REGION --kubeconfig ~/.kube/eks-config
```

## 📚 Documentation

- **[ARGOCD_SETUP.md](./ARGOCD_SETUP.md)** - Complete ArgoCD setup guide with segregation explanation
- **[argocd-for-k3d/README.md](./argocd-for-k3d/README.md)** - K3D ArgoCD deployment guide
- **[argocd-for-eks/README.md](./argocd-for-eks/README.md)** - EKS ArgoCD deployment guide

## 🎯 Common Tasks

### Access ArgoCD

**K3D:**
```bash
kubectl --kubeconfig=~/.kube/k3d-config -n argocd port-forward svc/argocd-server 8080:443
```

**EKS:**
```bash
# Get Ingress URL
kubectl --kubeconfig=~/.kube/eks-config -n argocd get ingress
```

### Get ArgoCD Admin Password

**K3D:**
```bash
kubectl --kubeconfig=~/.kube/k3d-config -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

**EKS:**
```bash
kubectl --kubeconfig=~/.kube/eks-config -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

### Destroy All

```bash
# Destroy in order
cd argocd-for-k3d && terraform destroy
cd ../argocd-for-eks && terraform destroy
cd ../k3d-infrastructure && terraform destroy
cd ../eks-infrastructure && terraform destroy
```

## 🔍 Directory Reference

| Directory | Purpose | Status |
|-----------|---------|--------|
| `k3d-infrastructure/` | Local Kubernetes cluster | ✅ Deployed |
| `eks-infrastructure/` | AWS managed Kubernetes | 📋 Ready |
| `ec2-infrastructure/` | AWS EC2 resources | 📋 Ready |
| `argocd-for-k3d/` | GitOps on k3d | ✅ Deployed |
| `argocd-for-eks/` | GitOps on EKS | 📋 Ready |

Legend: ✅ = Deployed | 📋 = Ready to deploy | ⏳ = In progress

## 💡 Best Practices

1. **Separate Kubeconfig Files**
   - Keep k3d and EKS kubeconfigs separate
   - Use `--kubeconfig` flag to specify which to use

2. **One Directory Per Cluster**
   - Don't mix k3d and EKS configs
   - Use `argocd-for-k3d/` for k3d only
   - Use `argocd-for-eks/` for EKS only

3. **Variable Management**
   - Copy `.example` files to `.tfvars`
   - Customize for your environment
   - Don't commit `.tfvars` files (add to .gitignore)

4. **State Files**
   - Keep separate state files per directory
   - Never delete `.tfstate` files directly
   - Use `terraform destroy` for cleanup

## 🆘 Troubleshooting

### Connection Refused Error
```
Error: Unable to connect to cluster
```
**Solution:** Verify kubeconfig file exists and is correct:
```bash
ls -la ~/.kube/k3d-config
kubectl --kubeconfig=~/.kube/k3d-config cluster-info
```

### Wrong Cluster Type
```
Error: cluster_type must be "eks"
```
**Solution:** You're using the wrong directory. Use `argocd-for-eks/` for EKS clusters.

### Terraform Lock Error
```
Error: Error acquiring the lock
```
**Solution:** Remove lock files:
```bash
rm -rf .terraform.lock.hcl
terraform init
```

## 📖 Further Reading

- [Terraform Documentation](https://www.terraform.io/docs)
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K3D Documentation](https://k3d.io/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)

## 📝 License

All infrastructure code is provided as-is for learning and development purposes.

---

**Last Updated:** November 30, 2025
