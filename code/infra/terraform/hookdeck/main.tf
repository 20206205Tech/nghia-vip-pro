# Luồng: webhook gửi đến Source -> Transformation (định dạng tin nhắn) -> Destination (Telegram sendMessage)

# 1. Source nhận webhook gửi đến
resource "hookdeck_source" "webhook_inbound" {
  name = "${var.name_prefix}-inbound"
  type = "WEBHOOK"
}

# 2. Destination trỏ thẳng đến endpoint sendMessage của Telegram
resource "hookdeck_destination" "telegram_bot" {
  name = "${var.name_prefix}-telegram"
  type = "HTTP"
  config = jsonencode({
    url         = "https://api.telegram.org/bot${var.TELEGRAM_BOT_TOKEN}/sendMessage"
    http_method = "POST"
  })
}

# 3. Transformation định dạng lại body sang chuẩn Telegram API
#    chat_id truyền qua env, không ghép thẳng vào code
resource "hookdeck_transformation" "format_telegram" {
  name = "${var.name_prefix}-format"
  env = jsonencode({
    TELEGRAM_CHAT_ID = var.TELEGRAM_CHAT_ID
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
resource "hookdeck_connection" "telegram_forwarder" {
  name           = "${var.name_prefix}-forwarder"
  source_id      = hookdeck_source.webhook_inbound.id
  destination_id = hookdeck_destination.telegram_bot.id

  rules = [
    {
      transform_rule = {
        transformation_id = hookdeck_transformation.format_telegram.id
      }
    }
  ]
}
