provider "aws" {
  region = "us-east-1"
}

variable "name" {
  type    = string
  default = "my-bucket"
}

module "my_bucket" {
  source = "../"

  name          = var.name
  force_destroy = true
}

output "bucket" {
  value = module.my_bucket.bucket
}