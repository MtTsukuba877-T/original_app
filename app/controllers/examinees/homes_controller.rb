# 受検者トップ画面（振り分け係）（Issue #39、#41）
#
# ログイン後・パスワード変更後の移動先。受検者の状態を見て行き先を決める。
# - 受検期間外（実施回がない・期間が未設定の場合を含む）: この画面で受検期間外であることを表示する
# - 受検期間内: 受検画面（E-5a）へ移動する
# 受検済みの受検者を結果表示画面（E-6）へ移動させる処理は、Issue #42・#46 で追加する。
# 初期パスワードのままの受検者は、BaseController の ensure_password_changed! により
# パスワード変更画面（E-4）へ移動させられる（Issue #40）。
class Examinees::HomesController < Examinees::BaseController
  def show
    return if current_stress_check_period.nil?

    redirect_to examinees_section_path("a")
  end
end
