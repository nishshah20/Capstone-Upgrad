terraform {
  backend "s3" {
    bucket = "514-nish-capstone-bucket"
    key    = "514-nish-capstone/terraform.tfstate"
    region = "us-east-1"
  }
}