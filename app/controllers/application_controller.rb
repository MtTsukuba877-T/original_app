class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Devise の各画面(ログイン、パスワードリセット等)は admin レイアウトを使用
  layout :determine_layout

  # Devise: ログイン成功後のリダイレクト先を role 別に分岐
  def after_sign_in_path_for(resource)
    case resource.role
    when "system_admin"
      companies_path
    else
      root_path
    end
  end

  private

  # レイアウトの自動選択
  # Devise の各画面(ログイン、パスワードリセット等): admin レイアウト
  # それ以外: application レイアウト(各コントローラで個別指定も可能)
  def determine_layout
    if devise_controller?
      "admin"
    else
      "application"
    end
  end

  # システム管理者以外がアクセスした場合、TOPページへリダイレクト
  # Phase 6 で Pundit ポリシーに置き換え予定
  def require_system_admin
    return if current_user&.system_admin?

    redirect_to root_path, alert: "このページにアクセスする権限がありません。"
  end
end
