class HomeController < ApplicationController
  def index
    return unless user_signed_in?

    if current_user.system_admin?
      redirect_to companies_path
    else
      redirect_to company_users_dashboard_path
    end
  end
end
