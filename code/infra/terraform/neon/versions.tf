terraform {
  cloud {
    organization = "nghia-vip-pro"
    workspaces {
      name = "infra-neon" # Workspace riêng cho dự án này
    }
  }

  required_providers {
    neon = {
      source  = "kislerdm/neon"
      version = "~> 0.6.0"
    }
  }
}

# Token lấy từ variables (scripts/infra/terraform/doppler-tf-env.sh xuất TF_VAR_*)
provider "neon" {
  api_key = var.NEON_API_KEY
}
