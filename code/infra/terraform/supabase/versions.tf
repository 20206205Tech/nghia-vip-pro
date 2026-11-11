terraform {
  cloud {
    organization = "nghia-vip-pro"
    workspaces {
      name = "infra-supabase" # Workspace riêng cho dự án này
    }
  }

  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
  }
}

# Mỗi môi trường một provider, token lấy từ variables
# (scripts/infra/terraform/doppler-tf-env.sh xuất TF_VAR_*)
provider "supabase" {
  alias        = "dev"
  access_token = var.SUPABASE_ACCESS_TOKEN_DEV
}

provider "supabase" {
  alias        = "stg"
  access_token = var.SUPABASE_ACCESS_TOKEN_STG
}

provider "supabase" {
  alias        = "prod"
  access_token = var.SUPABASE_ACCESS_TOKEN_PROD
}

provider "supabase" {
  alias        = "test"
  access_token = var.SUPABASE_ACCESS_TOKEN_TEST
}
