# システム管理者(system_admin)の初期データ
#
# 環境変数 SEED_ADMIN_EMAIL、SEED_ADMIN_PASSWORD、SEED_ADMIN_NAME を使用する。
# EMAIL または PASSWORD が未設定の場合は seed をスキップする(警告のみ)。
# NAME が未設定の場合は "テスト管理者" を使用する。
#
# 設定方法:
# - 開発環境: docker-compose.yml の web サービスの environment に記述
# - 本番環境: Render Dashboard の Environment Variables に設定

admin_email = ENV["SEED_ADMIN_EMAIL"]
admin_password = ENV["SEED_ADMIN_PASSWORD"]
admin_name = ENV["SEED_ADMIN_NAME"].presence || "テスト管理者"

if admin_email.blank? || admin_password.blank?
  puts "  [users] SEED_ADMIN_EMAIL または SEED_ADMIN_PASSWORD が未設定のため、system_admin の作成をスキップします。"
else
  admin = User.find_or_initialize_by(email: admin_email)
  admin.assign_attributes(
    name: admin_name,
    role: :system_admin,
    password: admin_password,
    password_confirmation: admin_password
  )
  admin.save!
  puts "  [users] system_admin を投入しました (email: #{admin_email})"
end
