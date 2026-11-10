terraform {
  cloud {
    organization = "nghia-vip-pro"
    workspaces {
      name = "infra-xxxx" # Workspace riêng cho dự án này
    }
  }

  required_providers {
    # Thay bằng provider thực tế, ví dụ:
    # aiven = {
    #   source  = "aiven/aiven"
    #   version = ">= 4.0.0"
    # }
  }
}

# Khai báo provider, token lấy từ variables (scripts/infra/terraform/doppler-tf-env.sh xuất TF_VAR_*)
# provider "aiven" {
#   api_token = var.XXXX_API_TOKEN
# }
