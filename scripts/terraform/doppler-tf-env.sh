#!/usr/bin/env bash
# Lấy từ Doppler đúng những biến mà module Terraform khai báo (variable "X" trong *.tf)
# và xuất ra dạng TF_VAR_X. Secret chỉ nằm trong Doppler, không đồng bộ sang Terraform Cloud.
#
# Cách dùng:
#   GitHub Actions : bash scripts/terraform/doppler-tf-env.sh code/infra/terraform/<module>
#                    (tự ghi vào $GITHUB_ENV và che giá trị trong log)
#   Máy local      : eval "$(bash scripts/terraform/doppler-tf-env.sh code/infra/terraform/<module>)"
#
# Yêu cầu: Doppler CLI (đã login hoặc có DOPPLER_TOKEN).
# Ngoài biến trong *.tf, script còn lấy TF_API_TOKEN để đăng nhập Terraform Cloud.

set -euo pipefail

dir="${1:?Thiếu tham số: thư mục module terraform}"

command -v doppler >/dev/null || { echo "Thiếu Doppler CLI" >&2; exit 1; }

# Kiểm tra kết nối Doppler trước, tránh lỗi im lặng khi thiếu/sai DOPPLER_TOKEN
if ! err=$(doppler secrets --only-names 2>&1 >/dev/null); then
  echo "Không kết nối được Doppler (kiểm tra secret DOPPLER_TOKEN trên GitHub hoặc 'doppler setup'):" >&2
  echo "$err" >&2
  exit 1
fi
compgen -G "$dir/*.tf" >/dev/null || { echo "Không có file .tf trong $dir" >&2; exit 1; }

# Tên các biến được khai báo trong module
names=$(sed -nE 's/^[[:space:]]*variable[[:space:]]+"([^"]+)".*/\1/p' "$dir"/*.tf | sort -u)

emit() {
  local name=$1 value=$2
  if [ -n "${GITHUB_ENV:-}" ]; then
    while IFS= read -r line; do
      [ -n "$line" ] && echo "::add-mask::$line"
    done <<<"$value"
    local delim="EOF_$RANDOM$RANDOM$RANDOM"
    { echo "$name<<$delim"; printf '%s\n' "$value"; echo "$delim"; } >>"$GITHUB_ENV"
  else
    printf 'export %s=%q\n' "$name" "$value"
  fi
}

# Chỉ hỏi Doppler đúng secret cần, không tải toàn bộ. Không có thì trả về rỗng.
get() { doppler secrets get "$1" --plain 2>/dev/null || true; }

found=() missing=()
for name in $names; do
  value=$(get "$name")
  if [ -n "$value" ]; then
    emit "TF_VAR_$name" "$value"
    found+=("$name")
  else
    missing+=("$name")
  fi
done

# Token đăng nhập Terraform Cloud (Terraform CLI tự đọc biến TF_TOKEN_app_terraform_io)
tf_token=$(get TF_API_TOKEN)
if [ -n "$tf_token" ]; then
  emit TF_TOKEN_app_terraform_io "$tf_token"
else
  echo "Cảnh báo: Doppler không có TF_API_TOKEN" >&2
fi

echo "Lấy từ Doppler: ${found[*]:-(không có)}" >&2
echo "Không có trong Doppler (dùng default nếu có): ${missing[*]:-(không có)}" >&2
