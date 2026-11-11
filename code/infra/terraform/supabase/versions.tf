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

# Mỗi tài khoản Supabase một provider, token lấy từ variables
# (scripts/infra/terraform/doppler-tf-env.sh xuất TF_VAR_*)
provider "supabase" {
  alias        = "a"
  access_token = var.SUPABASE_ACCESS_TOKEN_A
}

provider "supabase" {
  alias        = "b"
  access_token = var.SUPABASE_ACCESS_TOKEN_B
}
