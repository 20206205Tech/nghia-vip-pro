# =============================================================================
# Telegram Hookdeck: chuyển webhook bất kỳ thành tin nhắn Telegram
#
#   Webhook -> Source -> Transformation (định dạng tin nhắn) -> Destination (Telegram sendMessage)
#
# Mỗi luồng Telegram nằm trong một file riêng. Thêm luồng mới: copy file này,
# đổi tiền tố "telegram_hookdeck" / "TELEGRAM_HOOKDECK" sang tên luồng mới.
# =============================================================================

# ----- Biến (secret lưu trong Doppler cùng tên) -----

variable "TELEGRAM_HOOKDECK_BOT_TOKEN" {
  type        = string
  description = "Token bot Telegram (BotFather) dùng cho luồng Telegram Hookdeck"
  sensitive   = true
}

variable "TELEGRAM_HOOKDECK_CHAT_ID" {
  type        = string
  description = "Chat ID cá nhân hoặc nhóm nhận thông báo của luồng Telegram Hookdeck"
}

variable "telegram_hookdeck_name" {
  type        = string
  description = "Tiền tố tên các resource của luồng Telegram Hookdeck trên Hookdeck"
  default     = "telegram-hookdeck"
}

# ----- Resource -----

# 1. Source nhận webhook gửi đến
resource "hookdeck_source" "telegram_hookdeck" {
  name = "${var.telegram_hookdeck_name}-inbound"
  type = "WEBHOOK"
}

# 2. Destination trỏ thẳng đến endpoint sendMessage của Telegram
resource "hookdeck_destination" "telegram_hookdeck" {
  name = "${var.telegram_hookdeck_name}-bot"
  type = "HTTP"
  config = jsonencode({
    url         = "https://api.telegram.org/bot${var.TELEGRAM_HOOKDECK_BOT_TOKEN}/sendMessage"
    http_method = "POST"
  })
}

# 3. Transformation định dạng lại body sang chuẩn Telegram API
#    chat_id truyền qua env, không ghép thẳng vào code
resource "hookdeck_transformation" "telegram_hookdeck" {
  name = "${var.telegram_hookdeck_name}-format"
  env = jsonencode({
    TELEGRAM_CHAT_ID = var.TELEGRAM_HOOKDECK_CHAT_ID
  })
  code = <<-EOT
    addHandler('transform', (request, context) => {
      // Escape ký tự HTML để Telegram (parse_mode HTML) không báo lỗi khi payload có < > &
      const escapeHtml = (s) =>
        s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

      let content = '';
      try {
        content = request.body !== null && typeof request.body === 'object'
          ? JSON.stringify(request.body, null, 2)
          : String(request.body == null ? '' : request.body);
      } catch (e) {
        content = 'Cannot parse payload';
      }

      if (!content.trim()) {
        content = 'Empty webhook payload received';
      }

      const text = content.length > 3500 ? content.slice(0, 3500) + '... (truncated)' : content;

      request.body = {
        chat_id: process.env.TELEGRAM_CHAT_ID,
        text: '🔔 <b>Webhook Alert</b>\n<pre>' + escapeHtml(text) + '</pre>',
        parse_mode: 'HTML'
      };

      request.headers = request.headers || {};
      request.headers['content-type'] = 'application/json';

      return request;
    });
  EOT
}

# 4. Connection liên kết Source -> Transformation -> Destination
resource "hookdeck_connection" "telegram_hookdeck" {
  name           = "${var.telegram_hookdeck_name}-connection"
  source_id      = hookdeck_source.telegram_hookdeck.id
  destination_id = hookdeck_destination.telegram_hookdeck.id

  rules = [
    {
      transform_rule = {
        transformation_id = hookdeck_transformation.telegram_hookdeck.id
      }
    }
  ]
}

# ----- Output -----

output "telegram_hookdeck_webhook_url" {
  description = "URL nhận webhook của luồng Telegram Hookdeck, cấu hình vào dịch vụ gửi webhook"
  value       = hookdeck_source.telegram_hookdeck.url
}
