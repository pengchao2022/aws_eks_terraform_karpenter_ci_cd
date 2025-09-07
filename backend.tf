terraform {
  backend "s3" {
    bucket         = "terraformstatefile090909"
    key            = "eks-karpenter/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}