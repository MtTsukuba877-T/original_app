require "rails_helper"

RSpec.describe "Companies", type: :request do
  describe "GET /companies" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトすること" do
        get companies_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "system_admin でログイン済の場合" do
      let(:admin) { create(:user) }
      let!(:company) { Company.create!(name: "テスト企業A") }

      before { sign_in admin }

      it "企業一覧画面が表示されること" do
        get companies_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("企業一覧")
      end

      it "登録済の企業名が表示されること" do
        get companies_path
        expect(response.body).to include(company.name)
      end
    end

    context "company_hr でログイン済の場合" do
      let(:company_hr) { create(:user, :company_hr) }

      before { sign_in company_hr }

      it "root_path にリダイレクトされること" do
        get companies_path
        expect(response).to redirect_to(root_path)
      end

      it "権限がない旨のフラッシュメッセージが表示されること" do
        get companies_path
        expect(flash[:alert]).to eq("このページにアクセスする権限がありません。")
      end
    end
  end
end
