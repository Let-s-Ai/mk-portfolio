terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-mk-portfolio"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-table-mk-portfolio"
    encrypt        = true
  }
}
