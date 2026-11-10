# =============================================================================
# Phần dùng chung cho mọi luồng Telegram (telegram_*.tf)
#
# - Một bot gửi được vào nhiều chat, nên chỉ cần một bot token và một destination.
#   Mỗi luồng chọn chat qua TELEGRAM_<LUONG>_CHAT_ID trong transformation.
# - Retry rule dùng chung: tự gửi lại khi Telegram lỗi tạm thời.
# =============================================================================

variable "TELEGRAM_BOT_TOKEN" {
  type        = string
  description = "Token bot Telegram (BotFather) dùng chung cho mọi luồng Telegram"
  sensitive   = true
}

# Destination trỏ thẳng đến endpoint sendMessage của Telegram
resource "hookdeck_destination" "telegram" {
  name = "telegram-bot"
  type = "HTTP"
  config = jsonencode({
    url         = "https://api.telegram.org/bot${var.TELEGRAM_BOT_TOKEN}/sendMessage"
    http_method = "POST"
  })
}

# Trước đây là destination riêng của luồng telegram_hookdeck: đổi tên, không tạo lại
moved {
  from = hookdeck_destination.telegram_hookdeck
  to   = hookdeck_destination.telegram
}

locals {
  # Gửi lại tối đa 5 lần, giãn cách tăng dần từ 1 phút,
  # chỉ khi Telegram quá tải (429) hoặc lỗi server (5xx)
  telegram_retry_rule = {
    retry_rule = {
      strategy              = "exponential"
      count                 = 5
      interval              = 60000
      response_status_codes = ["429", "500-599"]
    }
  }

  # Đặt SAU transform_rule: chỉ chuyển tiếp khi transformation đã tạo được tin nhắn
  # (transformation trả body rỗng cho sự kiện không cần thông báo)
  telegram_has_text_filter = {
    filter_rule = {
      body = {
        json = jsonencode({ text = { "$exist" = true } })
      }
    }
  }
}
