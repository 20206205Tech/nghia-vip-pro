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
    # Tạo webhook GitHub (organization) trỏ về Hookdeck (xem telegram_github.tf)
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
    # Tạo webhook Doppler trỏ về Hookdeck (xem telegram_doppler.tf)
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "~> 1.23"
    }
    # Sinh secret ký webhook dùng chung giữa Hookdeck và GitHub/Doppler
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }
}

# Token lấy từ variables (scripts/infra/terraform/doppler-tf-env.sh xuất TF_VAR_*)
provider "hookdeck" {
  api_key = var.HOOKDECK_API_KEY
}
