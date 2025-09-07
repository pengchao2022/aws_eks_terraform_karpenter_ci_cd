output "karpenter_node_iam_arn" {
  value = aws_iam_role.karpenter_node.arn
}

output "karpenter_controller_iam_arn" {
  value = aws_iam_role.karpenter_controller.arn
}

output "karpenter_node_instance_profile" {
  value = aws_iam_instance_profile.karpenter_node.name
}