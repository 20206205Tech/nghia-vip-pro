#!/usr/bin/env bash
# Tạo các topic Telegram còn thiếu và lưu message_thread_id vào Doppler.
#
# Doppler là nơi ghi nhớ topic nào đã tạo (Bot API không có hàm liệt kê topic):
#   - Đã có TELEGRAM_<X>_THREAD_ID trong Doppler -> bỏ qua, không tạo trùng
#   - Chưa có -> createForumTopic -> doppler secrets set TELEGRAM_<X>_THREAD_ID
# Muốn tạo lại một topic: xóa biến tương ứng trong Doppler rồi chạy lại.
#
# Cách dùng: bash scripts/infra/telegram/ensure-topics.sh
# Cần:
#   DOPPLER_TOKEN      service token đọc config (giống CI Terraform)
#   Trong Doppler:     TELEGRAM_BOT_TOKEN, TELEGRAM_HOOKDECK_CHAT_ID,
#                      DOPPLER_API_TOKEN (quyền ghi vào chính project/config đó)
#   Trên Telegram:     nhóm đã bật Topics, bot là admin có quyền "Manage topics"

set -euo pipefail

command -v doppler >/dev/null || { echo "Thiếu Doppler CLI" >&2; exit 1; }
command -v curl >/dev/null || { echo "Thiếu curl" >&2; exit 1; }

get() { doppler secrets get "$1" --plain 2>/dev/null || true; }
mask() { [ -n "${GITHUB_ACTIONS:-}" ] && [ -n "$1" ] && echo "::add-mask::$1"; return 0; }

bot_token=$(get TELEGRAM_BOT_TOKEN)
default_chat=$(get TELEGRAM_HOOKDECK_CHAT_ID)
write_token=$(get DOPPLER_API_TOKEN)
# Doppler tự có sẵn tên project/config của token đang dùng
project=$(get DOPPLER_PROJECT)
config=$(get DOPPLER_CONFIG)
mask "$bot_token"
mask "$write_token"

for v in bot_token default_chat write_token project config; do
  [ -n "${!v}" ] || { echo "Thiếu giá trị: $v (kiểm tra Doppler)" >&2; exit 1; }
done

# Chat của từng luồng: biến *_CHAT_ID riêng nếu có, không thì chat mặc định
github_chat=$(get TELEGRAM_GITHUB_CHAT_ID)
github_chat=${github_chat:-$default_chat}
alert_chat=$(get TELEGRAM_GITHUB_ALERT_CHAT_ID)
alert_chat=${alert_chat:-$github_chat}
jira_chat=$(get TELEGRAM_JIRA_CHAT_ID)
doppler_chat=$(get TELEGRAM_DOPPLER_CHAT_ID)

# Tên topic | biến lưu thread id | chat | màu icon (giá trị Telegram cho phép)
topics=(
  "🚨 Alerts|TELEGRAM_GITHUB_ALERT_THREAD_ID|$alert_chat|16478047"
  "🔐 Doppler|TELEGRAM_DOPPLER_THREAD_ID|${doppler_chat:-$default_chat}|13338331"
  "🐙 GitHub|TELEGRAM_GITHUB_THREAD_ID|$github_chat|7322096"
  "📋 Jira|TELEGRAM_JIRA_THREAD_ID|${jira_chat:-$default_chat}|9367192"
  "🪝 Webhook|TELEGRAM_HOOKDECK_THREAD_ID|$default_chat|16766590"
)

created=0
for t in "${topics[@]}"; do
  IFS='|' read -r name var chat color <<<"$t"

  existing=$(get "$var")
  if [ -n "$existing" ]; then
    echo "Đã có  $name ($var=$existing), bỏ qua"
    continue
  fi

  resp=$(curl -sS -X POST "https://api.telegram.org/bot${bot_token}/createForumTopic" \
    --data-urlencode "chat_id=${chat}" \
    --data-urlencode "name=${name}" \
    --data-urlencode "icon_color=${color}")

  # "|| true": không khớp thì để rỗng, không làm script dừng (set -e + pipefail)
  id=$(grep -o '"message_thread_id":[0-9]*' <<<"$resp" | head -1 | cut -d: -f2 || true)
  if [ -z "$id" ]; then
    desc=$(grep -o '"description":"[^"]*"' <<<"$resp" | cut -d'"' -f4 || true)
    echo "Không tạo được topic $name: ${desc:-$resp}" >&2
    case "$desc" in
      *"not a forum"*) echo "-> Bật Topics cho nhóm (Edit > Topics)" >&2 ;;
      *"not enough rights"*|*"CHAT_ADMIN_REQUIRED"*) echo "-> Cho bot làm admin với quyền Manage topics" >&2 ;;
      *"chat not found"*) echo "-> Kiểm tra chat ID và bot đã ở trong nhóm" >&2 ;;
    esac
    exit 1
  fi

  DOPPLER_TOKEN="$write_token" doppler secrets set "${var}=${id}" \
    --project "$project" --config "$config" --silent >/dev/null
  echo "Tạo   $name ($var=$id) và đã lưu vào Doppler $project/$config"
  created=$((created + 1))
done

echo "Hoàn tất: tạo mới $created topic"
