class CompaniesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_system_admin

  def index
    @companies = Company.order(:id)
  end
end
