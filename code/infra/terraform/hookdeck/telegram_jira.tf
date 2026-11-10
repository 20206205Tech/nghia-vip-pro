# =============================================================================
# Telegram Jira: thông báo sự kiện Jira (issue, comment) vào Telegram
#
#   Jira webhook -> Source -> Transformation (định dạng sự kiện Jira) -> Destination Telegram dùng chung (telegram.tf)
#
# Webhook trên Jira được Terraform tạo luôn với url = hookdeck_source.telegram_jira.url,
# nên trong cùng một lần apply: tạo Source trước, rồi tạo/cập nhật webhook Jira.
# Nếu URL của Source đổi, webhook Jira cũng tự được cập nhật, không cần chạy CI/CD riêng.
#
# Xác thực chữ ký: provider Jira không hỗ trợ trường secret, nên secret được tạo trên
# giao diện Jira (webhook > Edit > Secret > Generate) rồi lưu vào Doppler JIRA_WEBHOOK_SECRET.
# Khi có biến này, Hookdeck kiểm tra header X-Hub-Signature và từ chối request không hợp lệ.
# =============================================================================

# ----- Biến (secret lưu trong Doppler cùng tên) -----

variable "JIRA_URL" {
  type        = string
  description = "Địa chỉ Jira, ví dụ https://<ten-cong-ty>.atlassian.net"
}

variable "JIRA_USER" {
  type        = string
  description = "Email tài khoản Jira (cần quyền Jira admin để quản lý webhook)"
}

variable "JIRA_API_TOKEN" {
  type        = string
  description = "API token của tài khoản Jira (id.atlassian.com > Security > API tokens)"
  sensitive   = true
}

variable "JIRA_WEBHOOK_SECRET" {
  type        = string
  description = "Secret của webhook Jira (tạo trên giao diện Jira). Bỏ trống thì Hookdeck chưa kiểm tra chữ ký"
  sensitive   = true
  default     = ""
}

variable "TELEGRAM_JIRA_THREAD_ID" {
  type        = string
  description = "Topic ID nhận thông báo Jira. Bỏ trống thì gửi vào chat chính"
  default     = ""
}

variable "telegram_jira_name" {
  type        = string
  description = "Tiền tố tên các resource của luồng Telegram Jira trên Hookdeck và Jira"
  default     = "telegram-jira"
}

variable "telegram_jira_events" {
  type        = list(string)
  description = "Các sự kiện Jira gửi về webhook"
  default = [
    "jira:issue_created",
    "jira:issue_updated",
    "jira:issue_deleted",
    "comment_created",
  ]
}

variable "telegram_jira_jql" {
  type        = string
  description = "JQL lọc issue gửi webhook, để trống là mọi issue (ví dụ: project = ABC)"
  default     = ""
}

# ----- Provider Jira -----

provider "jira" {
  url      = var.JIRA_URL
  user     = var.JIRA_USER
  password = var.JIRA_API_TOKEN
}

# ----- Resource trên Hookdeck -----

# 1. Source nhận webhook từ Jira
resource "hookdeck_source" "telegram_jira" {
  name = "${var.telegram_jira_name}-inbound"
  type = "WEBHOOK"
}

# 2. Destination: dùng chung hookdeck_destination.telegram (telegram.tf)

# 3. Transformation chuyển payload Jira thành tin nhắn Telegram dễ đọc
resource "hookdeck_transformation" "telegram_jira" {
  name = "${var.telegram_jira_name}-format"
  # Hookdeck không nhận giá trị rỗng trong env: bỏ các biến chưa cấu hình
  env = jsonencode({ for k, v in {
    TELEGRAM_CHAT_ID   = var.TELEGRAM_CHAT_ID
    TELEGRAM_THREAD_ID = var.TELEGRAM_JIRA_THREAD_ID
  } : k => v if v != "" })
  code = <<-EOT
    addHandler('transform', (request, context) => {
      const esc = (s) => String(s == null ? '' : s)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
      const cut = (s, n) => (s.length > n ? s.slice(0, n) + '…' : s);

      const b = request.body && typeof request.body === 'object' ? request.body : {};
      const event = b.webhookEvent || 'unknown';
      const issue = b.issue || {};
      const f = issue.fields || {};

      const titles = {
        'jira:issue_created': '🆕 Issue mới',
        'jira:issue_updated': '✏️ Issue được cập nhật',
        'jira:issue_deleted': '🗑️ Issue bị xóa',
        'comment_created': '💬 Bình luận mới',
        'comment_updated': '💬 Bình luận được sửa'
      };
      const lines = ['<b>' + esc(titles[event] || '🔔 ' + event) + '</b>'];

      if (issue.key) {
        const base = String(issue.self || '').split('/rest/')[0];
        const key = esc(issue.key);
        const link = base ? '<a href="' + esc(base + '/browse/' + issue.key) + '">' + key + '</a>' : key;
        lines.push(link + ': ' + esc(f.summary));
      }
      if (f.issuetype && f.issuetype.name) lines.push('Loại: ' + esc(f.issuetype.name));
      if (f.status && f.status.name) lines.push('Trạng thái: ' + esc(f.status.name));
      if (f.priority && f.priority.name) lines.push('Độ ưu tiên: ' + esc(f.priority.name));
      lines.push('Người xử lý: ' + esc(f.assignee && f.assignee.displayName ? f.assignee.displayName : 'Chưa giao'));

      const actor = (b.user && b.user.displayName) ||
        (b.comment && b.comment.author && b.comment.author.displayName) || '';
      if (actor) lines.push('Bởi: ' + esc(actor));

      // Các trường thay đổi (issue_updated), tối đa 5 dòng
      const items = (b.changelog && b.changelog.items) || [];
      items.slice(0, 5).forEach((it) => {
        lines.push('• ' + esc(it.field) + ': ' + esc(cut(String(it.fromString || '∅'), 100)) +
          ' → ' + esc(cut(String(it.toString || '∅'), 100)));
      });

      if (b.comment && b.comment.body) {
        lines.push('<i>' + esc(cut(String(b.comment.body), 1500)) + '</i>');
      }

      request.body = {
        chat_id: process.env.TELEGRAM_CHAT_ID,
        text: cut(lines.join('\n'), 4000),
        parse_mode: 'HTML',
        disable_web_page_preview: true
      };
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

# 4. Connection: chỉ nhận request có trường webhookEvent (payload của Jira)
resource "hookdeck_connection" "telegram_jira" {
  name           = "${var.telegram_jira_name}-connection"
  source_id      = hookdeck_source.telegram_jira.id
  destination_id = hookdeck_destination.telegram.id

  rules = [
    local.telegram_retry_rule,
    {
      filter_rule = {
        body = {
          json = jsonencode({ webhookEvent = { "$exist" = true } })
        }
      }
    },
    {
      transform_rule = {
        transformation_id = hookdeck_transformation.telegram_jira.id
      }
    }
  ]
}

# 5. Bật kiểm tra chữ ký Jira trên Source hiện có (không tạo lại Source, URL giữ nguyên).
#    Chỉ tạo khi đã có JIRA_WEBHOOK_SECRET trong Doppler.
resource "hookdeck_source_auth" "telegram_jira" {
  count = nonsensitive(var.JIRA_WEBHOOK_SECRET != "") ? 1 : 0

  source_id = hookdeck_source.telegram_jira.id
  auth_type = "JIRA"
  auth = jsonencode({
    webhook_secret_key = var.JIRA_WEBHOOK_SECRET
  })
}

# ----- Resource trên Jira -----

# 6. Webhook Jira trỏ về Source của Hookdeck, URL luôn đồng bộ với output
resource "jira_webhook" "telegram_jira" {
  name   = var.telegram_jira_name
  url    = hookdeck_source.telegram_jira.url
  events = var.telegram_jira_events
  jql    = var.telegram_jira_jql == "" ? null : var.telegram_jira_jql

  lifecycle {
    # Provider không biết trường secret: mỗi lần cập nhật có thể xóa secret đã đặt trên Jira.
    # Bỏ qua các trường hay lệch (Jira trả events theo thứ tự khác) để Terraform không gửi PUT.
    # Muốn đổi events/JQL: sửa trên giao diện Jira, hoặc tạm bỏ dòng tương ứng ở đây.
    ignore_changes = [name, events, jql, exclude_body]
  }
}

# ----- Output -----

output "telegram_jira_webhook_url" {
  description = "URL nhận webhook của luồng Telegram Jira (đã tự cấu hình vào Jira)"
  value       = hookdeck_source.telegram_jira.url
}
