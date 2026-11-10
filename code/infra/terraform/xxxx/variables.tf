# Biến bí mật: không đặt default, lưu trong Doppler cùng tên (XXXX_API_TOKEN)
# scripts/doppler-tf-env.sh chỉ lấy những biến khai báo ở đây
variable "XXXX_API_TOKEN" {
  type        = string
  description = "Token xác thực API của xxxx"
  sensitive   = true
}

# Biến không quan trọng: điền luôn default
variable "project_name" {
  type        = string
  description = "Tên dự án"
  default     = "nghia-vip-pro"
}
