# 受検者機能の共通親コントローラー（Issue #39、#40）
#
# 受検者（Employee）は Devise ではなく独自のセッション管理で認証する。
# ログイン状態は session[:employee_id] に Employee の id を保存して保持する。
# 受検者向けのコントローラーはすべてこのクラスを継承する。
class Examinees::BaseController < ApplicationController
  # 最後の操作からこの時間がたつと、自動的にログアウトさせる（Issue #40）。
  # 共用PCでログアウトせずに離れた場合の、なりすまし受検を防ぐため。
  # 初期パスワードのままの受検者（＝パスワード変更画面 E-4 にいる人）だけ短くする。
  SESSION_TIMEOUT = 30.minutes
  PASSWORD_CHANGE_TIMEOUT = 10.minutes

  layout "examinee"

  # CSRF トークンが一致しない場合（「戻る」ボタンで表示した古い画面から送信した場合や、
  # 画面を長時間開いたままにしてセッションが切れた場合など）は、
  # Rails のエラー画面を出さずにログイン画面へ案内する。
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_invalid_authenticity_token

  # 実行順が重要: タイムアウト → ログイン確認 → パスワード変更確認
  before_action :expire_session_if_timed_out!
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

  # 一定時間操作がなければログアウトさせ、TOP画面へ移動させる（Issue #40）。
  # 時間内であれば、最終操作時刻を今の時刻に更新する。
  def expire_session_if_timed_out!
    return unless employee_signed_in?

    if session_timed_out?
      reset_session
      redirect_to root_path, alert: "一定時間操作がなかったため、ログアウトしました。"
    else
      record_last_active_at
    end
  end

  # 最終操作時刻から、制限時間を超えているかどうか
  def session_timed_out?
    last_active_at = session[:last_active_at]
    return false if last_active_at.blank?

    Time.current.to_i - last_active_at > session_timeout.to_i
  end

  # 受検者の状態に応じた制限時間（初期パスワードのままなら10分、それ以外は30分）
  def session_timeout
    current_employee.password_change_required? ? PASSWORD_CHANGE_TIMEOUT : SESSION_TIMEOUT
  end

  # 最終操作時刻を記録する。
  # セッションは Cookie に JSON で保存されるため、Time ではなく秒の整数で保存する。
  def record_last_active_at
    session[:last_active_at] = Time.current.to_i
  end

  # CSRF トークン不一致時の処理
  def handle_invalid_authenticity_token
    redirect_to examinees_sign_in_path, alert: "画面の有効期限が切れました。お手数ですが、もう一度入力してください。"
  end
end
