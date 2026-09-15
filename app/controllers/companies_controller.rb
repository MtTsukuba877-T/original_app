class CompaniesController < ApplicationController
  layout "admin"

  before_action :authenticate_user!
  before_action :require_system_admin

  def index
    @companies = Company.order(:id)
  end

  def new
    @form = CompanyRegistrationForm.new
  end

  def create
    @form = CompanyRegistrationForm.new(company_registration_form_params)

    if @form.save
      redirect_to company_path(@form.company), notice: "#{@form.company.name}を登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @company = Company.find(params[:id])
    @stress_check_period = @company.stress_check_periods.first
    @invited_user = @company.company_hrs.first
  end

  private

  def company_registration_form_params
    params.require(:company_registration_form).permit(
      :company_name,
      :start_date,
      :end_date,
      :hr_name,
      :hr_email
    )
  end
end
