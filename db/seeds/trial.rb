# お試し受検（デモ）用の企業・実施回・受検者（Issue #160）
#
# トップページの「デモ用お試し受検」から、ログインせずに受検を体験するためのデータ。
# お試し受検では、回答・セクション別スコア・判定結果を DB に保存しない。
# 本番では起動のたびに実行されるため、何度実行しても重複しない書き方にしている。
# お試し受検者のパスワードは、実行のたびにランダムに作り直す（通常のログイン画面から入れないようにするため）。

company = Company.find_or_initialize_by(name: Company::TRIAL_COMPANY_NAME)
company.save!

# 終了日をずっと先にして、いつでも受検期間内にする
period = company.stress_check_periods.find_or_initialize_by(name: "お試し受検用")
period.assign_attributes(
  start_date: Date.new(2026, 1, 1),
  end_date: Date.new(2099, 12, 31),
  judgment_method: :simple_sum
)
period.save!

# 受検者のパスワードは、変更済みの場合「英数字混在・8文字以上」のバリデーションがある。
# ランダムな英数字だけだと、まれに英字だけになって保存に失敗し、本番のサーバーが起動しなくなるため、
# 後ろに英字1つと数字1つを付けて、必ず混ざるようにする。
password = "#{SecureRandom.alphanumeric(30)}a1"

employee = company.employees.find_or_initialize_by(examinee_number: Employee::TRIAL_EXAMINEE_NUMBER)
employee.assign_attributes(
  name: "お試し花子",
  sex: :female,
  date_of_birth: Date.new(1990, 1, 1),
  password: password,
  password_changed_at: Time.current
)
employee.save!

puts "  [trial] お試し受検用の企業・実施回・受検者を投入しました"
