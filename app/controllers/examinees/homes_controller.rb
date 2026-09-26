# 受検者トップ画面（Issue #39 時点では仮実装）
#
# ログイン成功後の遷移先。
# Issue #40 で password_changed_at による強制パスワード変更への分岐を、
# Issue #41 以降で受検画面への導線を追加する予定。
class Examinees::HomesController < Examinees::BaseController
  def show
  end
end
