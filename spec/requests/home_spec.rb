require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "未ログインの場合" do
      it "TOP画面が表示されること" do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("MVP 動作確認用トップページ")
      end
    end

    context "system_admin でログイン済の場合" do
      let(:admin) { create(:user) }

      before { sign_in admin }

      it "企業一覧画面にリダイレクトすること" do
        get root_path
        expect(response).to redirect_to(companies_path)
      end
    end

    context "company_hr でログイン済の場合" do
      let(:company_hr) { create(:user, :company_hr) }

      before { sign_in company_hr }

      it "企業担当者ダッシュボードにリダイレクトすること" do
        get root_path
        expect(response).to redirect_to(company_users_dashboard_path)
      end
    end
  end
end
