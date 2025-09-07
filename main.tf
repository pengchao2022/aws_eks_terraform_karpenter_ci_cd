module "eks" {
  source = "./modules/eks"

  cluster_name    = "${var.cluster_name}-${terraform.workspace}"
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnet_ids
}

module "iam" {
  source = "./modules/iam"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
}

module "karpenter" {
  source = "./modules/karpenter"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  oidc_provider_arn      = module.eks.oidc_provider_arn
  karpenter_version      = var.karpenter_version
  karpenter_controller_iam_arn = module.iam.karpenter_controller_iam_arn
  node_instance_profile  = module.iam.karpenter_node_instance_profile
  node_count             = var.node_count
}