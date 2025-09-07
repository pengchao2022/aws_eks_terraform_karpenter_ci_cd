environment = "prod"
region = "us-east-1"
vpc_id = "vpc-prod1234567890abc"
private_subnet_ids = ["subnet-prod1234567890abc", "subnet-prod1234567890abd", "subnet-prod1234567890abe"]
cluster_name = "my-eks-cluster"
cluster_version = "1.28"
karpenter_version = "v0.32.1"
node_count = 4