# お試し受検の入口（Issue #160）
#
# トップページの「デモ用お試し受検」ボタンから呼ばれる。
# ログイン・パスワード変更を通らずに、お試し受検用の受検者（seeds で作成）としてログインした状態にし、
# 受検画面（E-5a）へ移動させる。session[:trial] が true の間は、回答・判定結果を DB に保存しない。
class Examinees::TrialsController < Examinees::BaseController
  # ログイン前に使う入口なので、受検者画面の共通の確認はすべて行わない。
  # 前の人のセッションが残っていても、create の reset_session で消してから始める。
  skip_before_action :expire_session_if_timed_out!, :authenticate_employee!, :ensure_password_changed!

  def create
    company = Company.find_by(name: Company::TRIAL_COMPANY_NAME)
    employee = company&.employees&.find_by(examinee_number: Employee::TRIAL_EXAMINEE_NUMBER)

    if employee
      reset_session
      session[:employee_id] = employee.id
      session[:trial] = true
      record_last_active_at
      redirect_to examinees_section_path("a")
    else
      redirect_to root_path, alert: "現在、お試し受検はご利用いただけません。"
    end
  end
end
