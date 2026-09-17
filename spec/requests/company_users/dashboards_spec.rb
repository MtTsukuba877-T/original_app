require "rails_helper"

RSpec.describe "CompanyUsers::Dashboards", type: :request do
  describe "GET /company_users/dashboard" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトすること" do
        get company_users_dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "system_admin でログイン済の場合" do
      let(:admin) { create(:user) }

      before { sign_in admin }

      it "ダッシュボード画面が表示されること" do
        get company_users_dashboard_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("企業担当者ダッシュボード")
      end

      it "ログインユーザー名が表示されること" do
        get company_users_dashboard_path
        expect(response.body).to include(admin.name)
      end
    end

    context "company_hr でログイン済の場合" do
      let(:company_hr) { create(:user, :company_hr) }

      before { sign_in company_hr }

      it "ダッシュボード画面が表示されること" do
        get company_users_dashboard_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("企業担当者ダッシュボード")
      end

      it "ログインユーザー名が表示されること" do
        get company_users_dashboard_path
        expect(response.body).to include(company_hr.name)
      end
    end
  end
end
