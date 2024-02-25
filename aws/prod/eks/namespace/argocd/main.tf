resource "kubernetes_namespace" "example" {
  metadata {
    annotations = {
      name = "argocd"
    }

    labels = {
      mylabel = "argocd"
    }

    name = "argocd"
  }
}