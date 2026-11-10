# =============================================================================
# Telegram GitHub: thông báo sự kiện GitHub (push, PR, issue, CI/CD) vào Telegram
#
#   GitHub org webhook -> Source GITHUB (Hookdeck kiểm tra chữ ký HMAC)
#     -> connection chính : Transformation -> Telegram (TELEGRAM_GITHUB_CHAT_ID)
#     -> connection alert : Transformation (chỉ CI/CD lỗi) -> Telegram (chat/topic cảnh báo, nếu khai báo)
#
# Webhook trên GitHub do Terraform tạo với url = Source URL và secret tự sinh,
# nên URL và secret luôn khớp giữa GitHub và Hookdeck.
# =============================================================================

# ----- Biến (secret lưu trong Doppler cùng tên) -----

variable "GITHUB_TOKEN" {
  type        = string
  description = "GitHub token có quyền quản lý webhook của organization (classic PAT: admin:org_hook; fine-grained: Organization webhooks read/write)"
  sensitive   = true
}

variable "TELEGRAM_GITHUB_CHAT_ID" {
  type        = string
  description = "Chat ID nhận thông báo GitHub. Bỏ trống thì dùng TELEGRAM_HOOKDECK_CHAT_ID"
  default     = ""
}

variable "TELEGRAM_GITHUB_ALERT_CHAT_ID" {
  type        = string
  description = "Chat ID nhận cảnh báo khi CI/CD lỗi. Bỏ trống thì dùng chat của luồng GitHub"
  default     = ""
}

variable "TELEGRAM_GITHUB_THREAD_ID" {
  type        = string
  description = "Topic ID nhận thông báo GitHub. Bỏ trống thì gửi vào chat chính"
  default     = ""
}

variable "TELEGRAM_GITHUB_ALERT_THREAD_ID" {
  type        = string
  description = "Topic ID nhận cảnh báo CI/CD lỗi (ví dụ topic Alerts)."
  default     = ""
}

variable "telegram_github_owner" {
  type        = string
  description = "GitHub organization gắn webhook (nhận sự kiện của mọi repo trong org)"
  default     = "20206205Tech"
}

variable "telegram_github_events" {
  type        = list(string)
  description = "Các sự kiện GitHub gửi về webhook"
  default     = ["push", "pull_request", "issues", "workflow_run"]
}

variable "telegram_github_name" {
  type        = string
  description = "Tiền tố tên các resource của luồng Telegram GitHub"
  default     = "telegram-github"
}

# ----- Provider GitHub -----

provider "github" {
  owner = var.telegram_github_owner
  token = var.GITHUB_TOKEN
}

# ----- Secret ký webhook (chỉ nằm trong Terraform state, Hookdeck và GitHub) -----

resource "random_password" "telegram_github_webhook" {
  length  = 40
  special = false
}

# ----- Resource trên Hookdeck -----

# 1. Source kiểu GITHUB: Hookdeck từ chối request sai chữ ký X-Hub-Signature-256
resource "hookdeck_source" "telegram_github" {
  name = "${var.telegram_github_name}-inbound"
  type = "GITHUB"
  config = jsonencode({
    auth = {
      webhook_secret_key = random_password.telegram_github_webhook.result
    }
  })
}

locals {
  telegram_github_chat_id = var.TELEGRAM_GITHUB_CHAT_ID != "" ? var.TELEGRAM_GITHUB_CHAT_ID : var.TELEGRAM_HOOKDECK_CHAT_ID

  # Bật connection cảnh báo khi khai báo chat hoặc topic cảnh báo
  telegram_github_alert_enabled = var.TELEGRAM_GITHUB_ALERT_CHAT_ID != "" || var.TELEGRAM_GITHUB_ALERT_THREAD_ID != ""
  telegram_github_alert_chat_id = var.TELEGRAM_GITHUB_ALERT_CHAT_ID != "" ? var.TELEGRAM_GITHUB_ALERT_CHAT_ID : local.telegram_github_chat_id

  # Code transformation dùng chung cho connection chính và connection alert.
  # ONLY_FAILED_WORKFLOW = "true": chỉ tạo tin nhắn khi CI/CD lỗi.
  # Sự kiện không hỗ trợ -> body rỗng -> bị filter sau transformation chặn lại.
  telegram_github_code = <<-EOT
    addHandler('transform', (request, context) => {
      const esc = (s) => String(s == null ? '' : s)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
      const cut = (s, n) => (s.length > n ? s.slice(0, n) + '…' : s);
      const link = (url, text) => (url ? '<a href="' + esc(url) + '">' + esc(text) + '</a>' : esc(text));
      const header = (name) => {
        const h = request.headers || {};
        const k = Object.keys(h).find((x) => x.toLowerCase() === name);
        return k ? String(h[k]) : '';
      };

      const event = header('x-github-event');
      const p = request.body && typeof request.body === 'object' ? request.body : {};
      const onlyFailed = process.env.ONLY_FAILED_WORKFLOW === 'true';
      const repo = p.repository || {};
      const repoLink = link(repo.html_url, repo.full_name || repo.name || 'Unknown');
      const sep = '━━━━━━━━━━━━━━━━━━';
      let lines = [];

      if (event === 'workflow_run' && p.workflow_run) {
        const run = p.workflow_run;
        const info = [
          '🛠 <b>Workflow:</b> <code>' + esc(run.name) + '</code>',
          '📦 <b>Repo:</b> ' + repoLink,
          '🌿 <b>Branch:</b> <code>' + esc(run.head_branch) + '</code>',
          '👤 <b>By:</b> ' + esc(run.actor && run.actor.login)
        ];
        if (p.action === 'requested' && !onlyFailed) {
          lines = ['⚙️ <b>CI/CD STARTED</b>', sep].concat(info, ['', link(run.html_url, '⏳ Xem tiến trình')]);
        } else if (p.action === 'completed') {
          const c = String(run.conclusion || 'unknown');
          const failed = ['failure', 'timed_out', 'startup_failure', 'action_required'].indexOf(c) >= 0;
          if (!onlyFailed || failed) {
            const icon = c === 'success' ? '✅' : failed ? '❌' : '⚪';
            lines = [icon + ' <b>CI/CD ' + esc(c.toUpperCase()) + '</b>', sep].concat(info, ['', link(run.html_url, '🔗 Xem log')]);
          }
        }
      } else if (!onlyFailed && event === 'pull_request' && p.pull_request) {
        const pr = p.pull_request;
        const a = p.action;
        if (['opened', 'reopened', 'closed', 'ready_for_review'].indexOf(a) >= 0) {
          const title = a === 'closed' ? (pr.merged ? '🎉 PULL REQUEST: MERGED' : '🚫 PULL REQUEST: CLOSED')
            : a === 'opened' ? '🆕 PULL REQUEST: OPENED' : '🔄 PULL REQUEST: ' + a.toUpperCase();
          lines = [
            '<b>' + esc(title) + '</b>', sep,
            '📦 <b>Repo:</b> ' + repoLink,
            '📝 <b>Title:</b> ' + link(pr.html_url, '#' + pr.number + ' ' + pr.title),
            '🌿 <b>Flow:</b> <code>' + esc(pr.head && pr.head.ref) + '</code> ➔ <code>' + esc(pr.base && pr.base.ref) + '</code>',
            '👤 <b>By:</b> ' + link(pr.user && pr.user.html_url, pr.user && pr.user.login),
            '', link(pr.html_url + '/files', '🔗 Files changed')
          ];
        }
      } else if (!onlyFailed && event === 'push' && p.ref && !p.deleted) {
        const commits = p.commits || [];
        const msg = p.head_commit && p.head_commit.message ? String(p.head_commit.message).split('\n')[0] : '';
        lines = [
          '🚀 <b>NEW PUSH</b>', sep,
          '📦 <b>Repo:</b> ' + repoLink,
          '🌿 <b>Branch:</b> <code>' + esc(String(p.ref).replace('refs/heads/', '')) + '</code>',
          '🔢 <b>Commits:</b> ' + commits.length,
          '👤 <b>Pusher:</b> <code>' + esc(p.pusher && p.pusher.name) + '</code>'
        ];
        if (msg) lines.push('', '📝 <b>Last commit:</b>', '<i>' + esc(cut(msg, 300)) + '</i>');
        lines.push('', link(p.compare, '🔗 Xem thay đổi'));
      } else if (!onlyFailed && event === 'issues' && p.issue) {
        const issue = p.issue;
        if (['opened', 'closed', 'reopened'].indexOf(p.action) >= 0) {
          lines = [
            '⚠️ <b>ISSUE: ' + esc(String(p.action).toUpperCase()) + '</b>', sep,
            '📦 <b>Repo:</b> ' + repoLink,
            '📝 <b>Title:</b> ' + link(issue.html_url, '#' + issue.number + ' ' + issue.title),
            '👤 <b>By:</b> ' + esc((p.sender && p.sender.login) || (issue.user && issue.user.login))
          ];
        }
      }

      request.body = lines.length
        ? {
            chat_id: process.env.TELEGRAM_CHAT_ID,
            text: cut(lines.join('\n'), 4000),
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

# 2. Transformation + connection chính: mọi sự kiện hỗ trợ
resource "hookdeck_transformation" "telegram_github" {
  name = "${var.telegram_github_name}-format"
  # Hookdeck không nhận giá trị rỗng trong env: bỏ các biến chưa cấu hình
  env = jsonencode({ for k, v in {
    TELEGRAM_CHAT_ID     = local.telegram_github_chat_id
    TELEGRAM_THREAD_ID   = var.TELEGRAM_GITHUB_THREAD_ID
    ONLY_FAILED_WORKFLOW = "false"
  } : k => v if v != "" })
  code = local.telegram_github_code
}

resource "hookdeck_connection" "telegram_github" {
  name           = "${var.telegram_github_name}-connection"
  source_id      = hookdeck_source.telegram_github.id
  destination_id = hookdeck_destination.telegram.id

  rules = [
    local.telegram_retry_rule,
    {
      transform_rule = {
        transformation_id = hookdeck_transformation.telegram_github.id
      }
    },
    local.telegram_has_text_filter,
  ]
}

# 3. Transformation + connection alert: chỉ CI/CD lỗi, gửi vào chat/topic cảnh báo (nếu khai báo)
resource "hookdeck_transformation" "telegram_github_alert" {
  count = local.telegram_github_alert_enabled ? 1 : 0

  name = "${var.telegram_github_name}-alert-format"
  # Hookdeck không nhận giá trị rỗng trong env: bỏ các biến chưa cấu hình
  env = jsonencode({ for k, v in {
    TELEGRAM_CHAT_ID     = local.telegram_github_alert_chat_id
    TELEGRAM_THREAD_ID   = var.TELEGRAM_GITHUB_ALERT_THREAD_ID
    ONLY_FAILED_WORKFLOW = "true"
  } : k => v if v != "" })
  code = local.telegram_github_code
}

resource "hookdeck_connection" "telegram_github_alert" {
  count = local.telegram_github_alert_enabled ? 1 : 0

  name           = "${var.telegram_github_name}-alert-connection"
  source_id      = hookdeck_source.telegram_github.id
  destination_id = hookdeck_destination.telegram.id

  rules = [
    local.telegram_retry_rule,
    {
      transform_rule = {
        transformation_id = hookdeck_transformation.telegram_github_alert[0].id
      }
    },
    local.telegram_has_text_filter,
  ]
}

# ----- Resource trên GitHub -----

# 4. Webhook cấp organization: nhận sự kiện của mọi repo trong org
resource "github_organization_webhook" "telegram_github" {
  active = true
  events = var.telegram_github_events

  configuration {
    url          = hookdeck_source.telegram_github.url
    content_type = "json"
    secret       = random_password.telegram_github_webhook.result
    insecure_ssl = false
  }
}

# ----- Output -----

output "telegram_github_webhook_url" {
  description = "URL nhận webhook của luồng Telegram GitHub (đã tự cấu hình vào GitHub organization)"
  value       = hookdeck_source.telegram_github.url
}
