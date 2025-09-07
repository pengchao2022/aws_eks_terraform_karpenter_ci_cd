output "karpenter_release" {
  description = "Karpenter Helm release name"
  value       = helm_release.karpenter.name
}

output "karpenter_namespace" {
  description = "Karpenter namespace"
  value       = kubernetes_namespace.karpenter.metadata[0].name
}

output "provisioner_name" {
  description = "Karpenter provisioner name"
  value       = kubectl_manifest.karpenter_provisioner.name
}

output "node_template_name" {
  description = "Karpenter node template name"
  value       = kubectl_manifest.karpenter_aws_node_template.name
}