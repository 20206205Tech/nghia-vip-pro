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
    # Tạo webhook trên Jira trỏ về URL của Hookdeck (xem telegram_jira.tf)
    jira = {
      source  = "fourplusone/jira"
      version = "~> 0.1.20"
    }
  }
}

# Token lấy từ variables (scripts/terraform/doppler-tf-env.sh xuất TF_VAR_*)
provider "hookdeck" {
  api_key = var.HOOKDECK_API_KEY
}
