# Create ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      "app.kubernetes.io/name" = "argocd"
    }
  }
}

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  version          = var.argocd_chart_version
  create_namespace = false

  values = [
    yamlencode({
      global = {
        domain = var.argocd_domain
      }

      server = {
        service = {
          type = var.enable_ingress ? "ClusterIP" : "LoadBalancer"
        }

        ingress = {
          enabled = var.enable_ingress
          ingressClassName = "nginx"
          hosts = var.enable_ingress ? [var.argocd_domain] : []
          tls = var.enable_ingress ? [{
            secretName = "argocd-tls"
            hosts = [var.argocd_domain]
          }] : []
        }
      }

      configs = {
        secret = {
          argocdServerAdminPassword = base64encode("admin123")  # Change this!
        }
      }

      controller = {
        replicas = 1
      }

      repoServer = {
        replicas = 1
      }

      applicationSet = {
        replicas = 1
      }

      redis = {
        enabled = true
      }

      dex = {
        enabled = true
      }

      notifications = {
        enabled = false
      }
    })
  ]

  depends_on = [kubernetes_namespace.argocd]
}

# Create initial ArgoCD Application for GitOps
resource "kubernetes_manifest" "argocd_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root-app"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repository_url
        targetRevision = var.git_repository_branch
        path           = var.git_repository_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune   = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [helm_release.argocd]
}
