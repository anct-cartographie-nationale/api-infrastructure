terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "cartographie-nationale"

    workspaces {
      prefix = "api-"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}
