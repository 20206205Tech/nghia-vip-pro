terraform {
  cloud {
    organization = "nghia-vip-pro"
    workspaces {
      name = "infra-hookdeck"
    }
  }

  required_providers {
    hookdeck = {
      source  = "hookdeck/hookdeck"
      version = "~> 2.4"
    }
  }
}

# Token lấy từ variables (scripts/doppler-tf-env.sh xuất TF_VAR_*)
provider "hookdeck" {
  api_key = var.HOOKDECK_API_KEY
}
