# 受検者トップ画面（振り分け係）（Issue #39、#41、#42、#46）
#
# ログイン後・パスワード変更後・回答の送信後の移動先。受検者の状態を見て行き先を決める。
# - 受検期間外（実施回がない・期間が未設定の場合を含む）: この画面で受検期間外であることを表示する
# - 受検期間内で受検済み・判定結果あり: 受検が完了したことと判定結果を表示する（結果表示画面 E-6・E-6'）（Issue #46）
# - 受検期間内で受検済み・判定結果なし（通常は起きない）: 判定結果を表示できないことを案内する（Issue #46）
# - 受検期間内で未受検: 受検画面（E-5a）へ移動する
# 初期パスワードのままの受検者は、BaseController の ensure_password_changed! により
# パスワード変更画面（E-4）へ移動させられる（Issue #40）。
class Examinees::HomesController < Examinees::BaseController
  def show
    return if current_stress_check_period.nil?

    if current_employee.responded_to?(current_stress_check_period)
      @stress_check_period = current_stress_check_period
      @result = current_employee.results.find_by(stress_check_period: current_stress_check_period)

      if @result
        render :completed
      else
        render :result_unavailable
      end
    else
      redirect_to examinees_section_path("a")
    end
  end
end
