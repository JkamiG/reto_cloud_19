terraform {
  backend "s3" {
    bucket         = "reto19-terraform-state-ACCOUNT_ID"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "reto19-terraform-locks"
    encrypt        = true
  }
}
