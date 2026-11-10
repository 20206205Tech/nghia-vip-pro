# Biến bí mật: không đặt default, lưu trong Doppler cùng tên
# scripts/doppler-tf-env.sh chỉ lấy những biến khai báo ở đây
variable "HOOKDECK_API_KEY" {
  type        = string
  description = "Hookdeck API Key lấy từ Project Settings"
  sensitive   = true
}

variable "TELEGRAM_BOT_TOKEN" {
  type        = string
  description = "Token bot Telegram lấy từ BotFather"
  sensitive   = true
}

variable "TELEGRAM_CHAT_ID" {
  type        = string
  description = "Chat ID cá nhân hoặc nhóm nhận thông báo"
}

# Biến không quan trọng: điền luôn default
variable "name_prefix" {
  type        = string
  description = "Tiền tố tên các resource trên Hookdeck"
  default     = "telegram-alert"
}
