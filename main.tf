provider "aws" {
  region = var.region
}

# ACM per CloudFront DEVE stare in us-east-1
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

locals {
  apex        = var.domain_name
  bucket_name = "${var.project}-${replace(var.domain_name, ".", "-")}-site"
}





