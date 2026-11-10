#!/usr/bin/env bash
# Đảm bảo workspace Terraform Cloud của module tồn tại và chạy ở chế độ Local:
# plan/apply chạy trên máy CI (dùng biến lấy từ Doppler), Terraform Cloud chỉ lưu state.
#
# Đọc organization và workspace từ khối `cloud { ... }` trong *.tf của module.
#   - Workspace chưa có  -> tạo mới với execution mode Local
#   - Đang Remote/Agent  -> chuyển sang Local
#   - Đã Local           -> không làm gì
#
# Cách dùng: bash scripts/infra/terraform/tfc-ensure-local.sh code/infra/terraform/<module>
# Cần token: TF_TOKEN_app_terraform_io (scripts/infra/terraform/doppler-tf-env.sh đã xuất) hoặc TF_API_TOKEN.

set -euo pipefail

dir="${1:?Thiếu tham số: thư mục module terraform}"
token="${TF_TOKEN_app_terraform_io:-${TF_API_TOKEN:-}}"
[ -n "$token" ] || { echo "Thiếu token Terraform Cloud (TF_TOKEN_app_terraform_io hoặc TF_API_TOKEN)" >&2; exit 1; }

org=$(sed -nE 's/^[[:space:]]*organization[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$dir"/*.tf | head -1)
ws=$(awk '/workspaces[[:space:]]*\{/ { f = 1; next } f && /name[[:space:]]*=/ { print; exit }' "$dir"/*.tf |
  sed -E 's/.*"([^"]+)".*/\1/')
[ -n "$org" ] && [ -n "$ws" ] || { echo "Không đọc được organization/workspace trong $dir/*.tf" >&2; exit 1; }

api_base="https://app.terraform.io/api/v2"
resp=$(mktemp)
trap 'rm -f "$resp"' EXIT

# Gọi API, ghi body vào $resp, in ra HTTP status
api() {
  curl -sS -o "$resp" -w '%{http_code}' \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/vnd.api+json" \
    "$@"
}

fail() {
  echo "$1 (HTTP $2):" >&2
  cat "$resp" >&2
  echo >&2
  exit 1
}

local_attrs='"execution-mode":"local","setting-overwrites":{"execution-mode":true}'

status=$(api "$api_base/organizations/$org/workspaces/$ws")
case "$status" in
  200)
    mode=$(grep -o '"execution-mode":"[a-z]*"' "$resp" | head -1 | cut -d'"' -f4)
    if [ "$mode" = "local" ]; then
      echo "Workspace $org/$ws đã ở chế độ Local"
      exit 0
    fi
    status=$(api -X PATCH --data "{\"data\":{\"type\":\"workspaces\",\"attributes\":{$local_attrs}}}" \
      "$api_base/organizations/$org/workspaces/$ws")
    [ "$status" = "200" ] || fail "Không chuyển được $org/$ws sang Local" "$status"
    echo "Đã chuyển workspace $org/$ws từ ${mode:-?} sang Local"
    ;;
  404)
    status=$(api -X POST --data "{\"data\":{\"type\":\"workspaces\",\"attributes\":{\"name\":\"$ws\",$local_attrs}}}" \
      "$api_base/organizations/$org/workspaces")
    [ "$status" = "201" ] || fail "Không tạo được workspace $org/$ws" "$status"
    echo "Đã tạo workspace $org/$ws với chế độ Local"
    ;;
  *)
    fail "Không đọc được workspace $org/$ws" "$status"
    ;;
esac
