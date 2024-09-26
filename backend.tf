terraform {
  backend "s3" {
    bucket  = "terraform-devops---rssc"
    key     = "state/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
