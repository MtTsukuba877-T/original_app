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

      it "操作メニュー画面が表示されること" do
        get company_users_dashboard_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("操作メニュー")
      end

      it "ログインユーザー名が表示されること" do
        get company_users_dashboard_path
        expect(response.body).to include(admin.name)
      end

      it "システム管理者ラベルが表示されること" do
        get company_users_dashboard_path
        expect(response.body).to include("システム管理者")
      end

      it "企業IDが表示されないこと" do
        get company_users_dashboard_path
        expect(response.body).not_to include("企業ID：")
      end

      it "3つの操作メニューボタンが表示されること" do
        get company_users_dashboard_path
        expect(response.body).to include("①受検者一覧")
        expect(response.body).to include("②受検案内一斉配信")
        expect(response.body).to include("③受検状況一覧")
      end
    end

    context "company_hr でログイン済の場合" do
      let(:company_hr) { create(:user, :company_hr) }

      before { sign_in company_hr }

      it "操作メニュー画面が表示されること" do
        get company_users_dashboard_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("操作メニュー")
      end

      it "ログインユーザー名が表示されること" do
        get company_users_dashboard_path
        expect(response.body).to include(company_hr.name)
      end

      it "所属企業名が表示されること" do
        get company_users_dashboard_path
        expect(response.body).to include(company_hr.company.name)
      end

      it "ヘッダーに所属企業の企業IDが表示されること" do
        get company_users_dashboard_path
        expect(response.body).to include("（企業ID：#{company_hr.company.id}）")
      end

      it "3つの操作メニューボタンが表示されること" do
        get company_users_dashboard_path
        expect(response.body).to include("①受検者一覧")
        expect(response.body).to include("②受検案内一斉配信")
        expect(response.body).to include("③受検状況一覧")
      end
    end
  end
end
