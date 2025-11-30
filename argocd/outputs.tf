output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_access" {
  description = "How to access ArgoCD server"
  value       = var.enable_ingress ? "https://${var.argocd_domain}" : "kubectl port-forward -n argocd svc/argocd-server 8080:443"
}

output "argocd_admin_username" {
  description = "ArgoCD admin username"
  value       = "admin"
  sensitive   = true
}

output "get_initial_password" {
  description = "Command to get initial admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "git_repository_configured" {
  description = "Git repository configured for GitOps"
  value       = var.git_repository_url
}
