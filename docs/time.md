2026_11_10_23_34_59: Khởi tạo repository
2026_11_11_00_03_25: Thêm mẫu Terraform xxxx và workflow dùng chung, lấy secret từ Doppler
2026_11_11_00_06_38: Thêm bước terraform plan cho Pull Request và comment kết quả plan
2026_11_11_00_07_11: Hoàn tác bước terraform plan vừa thêm
2026_11_11_00_09_35: In kết quả terraform plan lên Pull Request, không tạo file
2026_11_11_00_25_10: Thêm module Hookdeck chuyển webhook sang Telegram, bật Dependabot
2026_11_11_00_29_24: Ghi rõ luồng Telegram qua Hookdeck, báo lỗi khi không kết nối được Doppler
2026_11_11_00_52_10: Tự đặt workspace Terraform Cloud sang chế độ Local trước khi init
2026_11_11_00_54_07: Chuyển script Terraform vào scripts/terraform
2026_11_11_00_56_08: Dependabot nâng cấp 5 GitHub Actions
2026_11_11_01_01_45: Thêm luồng Jira → Telegram: tự tạo webhook Jira trỏ về Hookdeck
2026_11_11_01_27_16: Dùng chung bot và destination Telegram, thêm retry rule
2026_11_11_01_35_56: Thêm luồng GitHub → Telegram và Doppler → Telegram
2026_11_11_01_53_14: Hỗ trợ gửi tin vào topic Telegram (message_thread_id) cho mọi luồng
2026_11_11_02_01_22: Sửa lỗi apply: bỏ giá trị rỗng khỏi env của transformation
2026_11_11_02_10_00: Theo dõi đúng project Doppler nghia-vip-pro-infra
2026_11_11_02_25_47: Chuyển script Terraform sang scripts/infra/terraform
2026_11_11_02_33_58: Kiểm tra chữ ký webhook Jira tại Hookdeck
2026_11_11_02_41_57: Tự tạo topic Telegram còn thiếu và lưu thread id vào Doppler
2026_11_11_02_54_11: Dùng một nhóm Telegram chung qua biến TELEGRAM_CHAT_ID
2026_11_11_03_04_38: Quản lý enabled_configs của webhook Doppler trong code
2026_11_11_19_49_04: Tạo 3 project Neon bằng Terraform: nghia-vip-pro-mot, -hai, -ba
2026_11_11_19_58_11: Thêm ghi chú về thứ tự merge request (feature → dev → stg → main)
2026_11_11_20_04_36: Chạy terraform plan khi có Pull Request vào dev, stg, main
2026_11_11_20_08_13: Bỏ -no-color và bước in plan lên Pull Request, xem plan trong log CI/CD
2026_11_11_20_10_52: Bỏ quyền pull-requests: write không còn dùng
2026_11_11_20_18_12: Thêm dòng kẻ ━━━ vào thông báo Jira trên Telegram
2026_11_11_21_39_11: Thêm icon cho các dòng chi tiết thông báo Jira trên Telegram
2026_11_11_23_54_07: Thêm module Terraform Supabase cho 4 môi trường trên 2 tài khoản
2026_11_12_00_00_39: Tách biến Supabase theo từng môi trường (dev, stg, prod, test)
2026_11_12_07_25_10: Phân bổ lại tài khoản Supabase: tài khoản B cho dev, stg; tài khoản A cho prod, test
2026_11_12_23_14_08: Đổi tên các workflow Terraform thành terraform-*
2026_11_13_22_28_49: Thêm 4 project Neon cho service-feedback (dev, test, stg, prod)
