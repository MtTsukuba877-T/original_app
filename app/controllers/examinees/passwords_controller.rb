# 受検者の強制パスワード変更（Issue #40、画面 E-4）
#
# 初期パスワード（生年月日8桁）は推測されやすいため、初回ログイン時に必ず変更してもらう。
# 初期パスワードのままの受検者は、BaseController の ensure_password_changed! によって、
# どの受検者画面を開いてもこの画面へ移動させられる。
class Examinees::PasswordsController < Examinees::BaseController
  # この画面では ensure_password_changed! を実行しない。
  # 実行すると、E-4 を開くたびに E-4 へリダイレクトされ続けたり、
  # 送信しても保存前に E-4 へ戻されて、永遠に変更できなくなるため。
  skip_before_action :ensure_password_changed!
  before_action :redirect_if_password_changed

  def edit
    @employee = current_employee
  end

  def update
    @employee = current_employee
    @employee.assign_attributes(password_params)
    @employee.password_changed_at = Time.current

    if @employee.save(context: :password_change)
      redirect_to examinees_home_path, notice: "パスワードを変更しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:employee).permit(:password, :password_confirmation)
  end

  # 変更済みの受検者が E-4 を開いた場合は、仮トップ画面へ戻す（E-4 は初回専用の画面）
  def redirect_if_password_changed
    redirect_to examinees_home_path unless current_employee.password_change_required?
  end
end
