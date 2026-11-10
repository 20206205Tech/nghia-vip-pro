# Biến dùng chung cho cả module hookdeck
# Biến riêng của từng luồng nằm trong file của luồng đó (ví dụ telegram_hookdeck.tf)
#
# Biến bí mật: không đặt default, lưu trong Doppler cùng tên
# scripts/doppler-tf-env.sh chỉ lấy những biến khai báo trong *.tf
variable "HOOKDECK_API_KEY" {
  type        = string
  description = "Hookdeck API Key lấy từ Project Settings"
  sensitive   = true
}
