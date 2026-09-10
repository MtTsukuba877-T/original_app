class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Devise: ログイン成功後のリダイレクト先を role 別に分岐
  def after_sign_in_path_for(resource)
    case resource.role
    when "system_admin"
      companies_path
    else
      root_path
    end
  end
end
