# 受検者トップ画面（Issue #39 時点では仮実装）
#
# ログイン成功後の遷移先。
# 初期パスワードのままの受検者は、BaseController の ensure_password_changed! により
# パスワード変更画面（E-4）へ移動させられる（Issue #40）。
# Issue #41 以降で受検画面への導線を追加する予定。
class Examinees::HomesController < Examinees::BaseController
  def show
  end
end
