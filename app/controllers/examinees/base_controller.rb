# 受検者機能の共通親コントローラー（Issue #39）
#
# 受検者（Employee）は Devise ではなく独自のセッション管理で認証する。
# ログイン状態は session[:employee_id] に Employee の id を保存して保持する。
# 受検者向けのコントローラーはすべてこのクラスを継承する。
class Examinees::BaseController < ApplicationController
  layout "examinee"

  # CSRF トークンが一致しない場合（「戻る」ボタンで表示した古い画面から送信した場合や、
  # 画面を長時間開いたままにしてセッションが切れた場合など）は、
  # Rails のエラー画面を出さずにログイン画面へ案内する。
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_invalid_authenticity_token

  before_action :authenticate_employee!
  before_action :ensure_password_changed!

  helper_method :current_employee, :employee_signed_in?

  private

  # ログイン中の受検者を返す（未ログインなら nil）
  def current_employee
    return nil if session[:employee_id].blank?

    @current_employee ||= Employee.find_by(id: session[:employee_id])
  end

  # 受検者がログイン中かどうか
  def employee_signed_in?
    current_employee.present?
  end

  # 未ログインの受検者をログイン画面へ戻す
  def authenticate_employee!
    return if employee_signed_in?

    redirect_to examinees_sign_in_path, alert: "ログインしてください。"
  end

  # 初期パスワードのままの受検者を、パスワード変更画面（E-4）へ移動させる（Issue #40）。
  # 受検者画面を開くたびに確認するので、URL を直接入力しても E-4 を飛ばすことはできない。
  def ensure_password_changed!
    return unless current_employee.password_change_required?

    redirect_to edit_examinees_password_path
  end

  # CSRF トークン不一致時の処理
  def handle_invalid_authenticity_token
    redirect_to examinees_sign_in_path, alert: "画面の有効期限が切れました。お手数ですが、もう一度入力してください。"
  end
end
