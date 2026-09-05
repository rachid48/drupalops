terraform {
  backend "s3" {
    bucket         = "drupalops-tfstate-408396500844"
    key            = "drupalops/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "drupalops-tfstate-lock"
    encrypt        = true
  }
}