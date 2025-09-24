terraform {
  backend "s3" {
    bucket         = "terraform-state-djasko-com"
    key            = "k3s-argocd/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
