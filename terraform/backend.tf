terraform {
  backend "s3" {
    bucket         = "nazmul-restauranty-tfstate"
    key            = "restauranty/eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    profile        = "nazmul"
    encrypt        = true
  }
}
