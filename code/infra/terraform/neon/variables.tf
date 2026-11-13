# Biến bí mật: không đặt default, lưu trong Doppler cùng tên (NEON_API_KEY)
# scripts/infra/terraform/doppler-tf-env.sh chỉ lấy những biến khai báo ở đây
variable "NEON_API_KEY" {
  type        = string
  description = "API Key để xác thực với Neon"
  sensitive   = true
}

# Biến không quan trọng: điền luôn default
variable "NEON_ORGANIZATION_ID" {
  type        = string
  description = "ID của Organization trên Neon"
  default     = "org-still-feather-82034197"
}

variable "projects" {
  type        = list(string)
  description = "Danh sách tên các project Neon cần tạo"
  default = [
    "nghia-vip-pro-mot",
    "nghia-vip-pro-hai",
    "nghia-vip-pro-ba",

    "service-feedback-dev",
    "service-feedback-test",
    "service-feedback-stg",
    "service-feedback-prod",
  ]
}
