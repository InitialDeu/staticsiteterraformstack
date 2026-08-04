variable "project" {
  type        = string
  description = "Project Name"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile name"
  default     = null
}

variable "region" {
  type        = string
  description = " AWS Region for S3"
  default     = "eu-south-1"
}

variable "domain_name" {
  type        = string
  description = "principal domain"
}

