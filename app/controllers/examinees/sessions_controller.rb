# 受検者のログイン処理（Issue #39）
#
# MVP では「企業ID + 受検者番号 + パスワード」の3点で認証する。
# 受検者番号は企業内でのみ一意（company_id とのセットで unique）のため、
# 先に企業を特定してから、その企業の受検者の中から検索する。
class Examinees::SessionsController < Examinees::BaseController
  skip_before_action :authenticate_employee!, only: %i[new create]

  def new
    redirect_to examinees_home_path if employee_signed_in?
  end

  def create
    company = Company.find_by(id: params[:company_id])
    employee = company&.employees&.find_by(examinee_number: params[:examinee_number])

    if employee&.authenticate(params[:password])
      reset_session
      session[:employee_id] = employee.id
      redirect_to examinees_home_path, notice: "ログインしました。"
    else
      @login_error = "企業ID、受検者番号またはパスワードが正しくありません。ご確認ください。"
      render :new, status: :unprocessable_entity
    end
  end
end
