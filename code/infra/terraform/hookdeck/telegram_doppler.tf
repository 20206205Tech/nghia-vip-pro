# =============================================================================
# Telegram Doppler: thông báo khi secret trong Doppler thay đổi
#
#   Doppler webhook -> Source DOPPLER (Hookdeck kiểm tra chữ ký HMAC)
#     -> Transformation -> Telegram (topic TELEGRAM_DOPPLER_THREAD_ID)
#
# Webhook trên Doppler do Terraform tạo (mỗi project một webhook) với url = Source URL
# và secret tự sinh. Tin nhắn chỉ có TÊN secret thay đổi, không bao giờ có giá trị.
# =============================================================================

# ----- Biến (secret lưu trong Doppler cùng tên) -----

variable "DOPPLER_API_TOKEN" {
  type        = string
  description = "Doppler token có quyền ghi vào các project bên dưới để quản lý webhook (personal hoặc service account token, KHÔNG phải service token chỉ đọc)"
  sensitive   = true
}

variable "TELEGRAM_DOPPLER_THREAD_ID" {
  type        = string
  description = "Topic ID nhận thông báo Doppler. Bỏ trống thì gửi vào chat chính"
  default     = ""
}

variable "telegram_doppler_projects" {
  type        = list(string)
  description = "Các project Doppler cần theo dõi (mỗi project một webhook)"
  default     = ["nghia-vip-pro-infra"]
}

variable "telegram_doppler_configs" {
  type        = list(string)
  description = "Các config Doppler kích hoạt webhook (để trống thì webhook không gửi cho config nào)"
  default     = ["dev", "stg", "prod"]
}

variable "telegram_doppler_name" {
  type        = string
  description = "Tiền tố tên các resource của luồng Telegram Doppler"
  default     = "telegram-doppler"
}

# ----- Provider Doppler -----

provider "doppler" {
  doppler_token = var.DOPPLER_API_TOKEN
}

# ----- Secret ký webhook -----

resource "random_password" "telegram_doppler_webhook" {
  length  = 40
  special = false
}

# ----- Resource trên Hookdeck -----

# 1. Source kiểu DOPPLER: Hookdeck từ chối request sai chữ ký
resource "hookdeck_source" "telegram_doppler" {
  name = "${var.telegram_doppler_name}-inbound"
  type = "DOPPLER"
  config = jsonencode({
    auth = {
      webhook_secret_key = random_password.telegram_doppler_webhook.result
    }
  })
}

# 2. Transformation: tóm tắt thay đổi; không có thay đổi thật thì bỏ qua
resource "hookdeck_transformation" "telegram_doppler" {
  name = "${var.telegram_doppler_name}-format"
  # Hookdeck không nhận giá trị rỗng trong env: bỏ các biến chưa cấu hình
  env = jsonencode({ for k, v in {
    TELEGRAM_CHAT_ID   = var.TELEGRAM_CHAT_ID
    TELEGRAM_THREAD_ID = var.TELEGRAM_DOPPLER_THREAD_ID
  } : k => v if v != "" })
  code = <<-EOT
    addHandler('transform', (request, context) => {
      const esc = (s) => String(s == null ? '' : s)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
      const cut = (s, n) => (s.length > n ? s.slice(0, n) + '…' : s);
      const name = (o) => esc((o && o.name) || 'Unknown');

      const p = request.body && typeof request.body === 'object' ? request.body : {};
      const type = String(p.type || 'unknown');
      const sep = '━━━━━━━━━━━━━━━━━━';
      let lines = [];

      if (type === 'config.secrets.update') {
        const d = p.diff || {};
        const changes = []
          .concat((d.added || []).map((k) => '➕ ' + k))
          .concat((d.updated || []).map((k) => '✏️ ' + k))
          .concat((d.removed || []).map((k) => '🗑 ' + k));
        if (changes.length) {
          lines = [
            '🔐 <b>DOPPLER SECRETS UPDATED</b>', sep,
            '🏢 <b>Workplace:</b> <code>' + name(p.workplace) + '</code>',
            '📁 <b>Project:</b> <code>' + name(p.project) + '</code>',
            '⚙️ <b>Config:</b> <code>' + name(p.config) + '</code>',
            '🌐 <b>Environment:</b> <code>' + esc((p.config && p.config.environment) || 'Unknown') + '</code>',
            '', '<b>Thay đổi (' + changes.length + '):</b>',
            '<code>' + esc(cut(changes.join('\n'), 3000)) + '</code>'
          ];
        }
      } else {
        lines = [
          '📡 <b>DOPPLER EVENT</b>', sep,
          '🏷 <b>Type:</b> <code>' + esc(type) + '</code>',
          '📁 <b>Project:</b> <code>' + name(p.project) + '</code>',
          '🏢 <b>Workplace:</b> <code>' + name(p.workplace) + '</code>'
        ];
      }

      request.body = lines.length
        ? {
            chat_id: process.env.TELEGRAM_CHAT_ID,
            text: lines.join('\n'),
            parse_mode: 'HTML',
            disable_web_page_preview: true
          }
        : {};
      // Gửi vào topic (supergroup bật Topics) nếu có TELEGRAM_THREAD_ID
      if (request.body && request.body.chat_id && process.env.TELEGRAM_THREAD_ID) {
        request.body.message_thread_id = Number(process.env.TELEGRAM_THREAD_ID);
      }
      request.headers = request.headers || {};
      request.headers['content-type'] = 'application/json';
      return request;
    });
  EOT
}

# 3. Connection: Source -> Transformation -> (có tin nhắn) -> Telegram
resource "hookdeck_connection" "telegram_doppler" {
  name           = "${var.telegram_doppler_name}-connection"
  source_id      = hookdeck_source.telegram_doppler.id
  destination_id = hookdeck_destination.telegram.id

  rules = [
    local.telegram_retry_rule,
    {
      transform_rule = {
        transformation_id = hookdeck_transformation.telegram_doppler.id
      }
    },
    local.telegram_has_text_filter,
  ]
}

# ----- Resource trên Doppler -----

# 4. Webhook trên từng project Doppler, URL và secret luôn khớp với Hookdeck
resource "doppler_webhook" "telegram_doppler" {
  for_each = toset(var.telegram_doppler_projects)

  project = each.value
  name    = var.telegram_doppler_name
  url     = hookdeck_source.telegram_doppler.url
  secret  = random_password.telegram_doppler_webhook.result

  # Config nào thay đổi secret thì gửi thông báo
  enabled_configs = var.telegram_doppler_configs
}

# ----- Output -----

output "telegram_doppler_webhook_url" {
  description = "URL nhận webhook của luồng Telegram Doppler (đã tự cấu hình vào các project Doppler)"
  value       = hookdeck_source.telegram_doppler.url
}
