# 受検者のログイン・ログアウト処理（Issue #39、#47、#40）
#
# MVP では「企業ID + 受検者番号 + パスワード」の3点で認証する。
# 受検者番号は企業内でのみ一意（company_id とのセットで unique）のため、
# 先に企業を特定してから、その企業の受検者の中から検索する。
class Examinees::SessionsController < Examinees::BaseController
  skip_before_action :authenticate_employee!, only: %i[new create]
  skip_before_action :ensure_password_changed!, only: %i[new create destroy]
  skip_before_action :expire_session_if_timed_out!, only: %i[create]

  def new
    redirect_to examinees_home_path if employee_signed_in?
  end

  def create
    company = Company.find_by(id: params[:company_id])
    employee = company&.employees&.find_by(examinee_number: params[:examinee_number])

    if employee&.authenticate(params[:password])
      reset_session
      session[:employee_id] = employee.id
      record_last_active_at
      # 初期パスワードのままなら、「ログインしました。」を出さずに直接 E-4 へ（Issue #40）
      if employee.password_change_required?
        redirect_to edit_examinees_password_path
      else
        redirect_to examinees_home_path, notice: "ログインしました。"
      end
    else
      @login_error = "企業ID、受検者番号またはパスワードが正しくありません。ご確認ください。"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました。"
  end
end
