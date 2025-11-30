# ArgoCD Gitops Configuration

This directory contains Terraform configuration for deploying ArgoCD to your Kubernetes clusters (k3d or EKS).

## Selecting Your Target Cluster

You can deploy ArgoCD to either your k3d or EKS cluster by specifying the `kubeconfig_path` variable.

### Option 1: Deploy to K3D Cluster

```bash
# Get kubeconfig for k3d cluster
k3d kubeconfig get k3d-cluster > ~/.kube/k3d-config

# Set in terraform.tfvars
kubeconfig_path = "~/.kube/k3d-config"
cluster_type    = "k3d"
```

### Option 2: Deploy to EKS Cluster

```bash
# Get kubeconfig for EKS cluster
aws eks update-kubeconfig --name your-cluster-name --region us-east-1 --kubeconfig ~/.kube/eks-config

# Set in terraform.tfvars
kubeconfig_path = "~/.kube/eks-config"
cluster_type    = "eks"
```

## Steps to Deploy ArgoCD

1. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Update terraform.tfvars:**
   - Set `kubeconfig_path` to point to your target cluster's kubeconfig
   - Set `cluster_type` to either "k3d" or "eks"
   - Update `git_repository_url` with your GitOps repository
   - Adjust other variables as needed

3. **Initialize and apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access ArgoCD:**
   ```bash
   # Get the initial admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
   
   # Port-forward to access the UI (default setup)
   kubectl port-forward -n argocd svc/argocd-server 8080:443
   
   # Then visit: https://localhost:8080
   # Username: admin
   # Password: <from above command>
   ```

## Verifying the Target Cluster

Before applying, verify you're targeting the correct cluster:

```bash
# Check current context
kubectl config current-context

# Or check with specific kubeconfig
kubectl --kubeconfig=~/.kube/k3d-config config current-context
```

## Notes

- The `kubeconfig_path` in terraform.tfvars determines which cluster will receive the ArgoCD deployment
- Keep separate kubeconfig files for each cluster to avoid confusion
- Ensure the kubeconfig has proper credentials and permissions for cluster access
