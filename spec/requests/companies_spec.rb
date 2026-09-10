require "rails_helper"

RSpec.describe "Companies", type: :request do
  describe "GET /companies" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトすること" do
        get companies_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済の場合" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "企業一覧画面が表示されること" do
        get companies_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("企業一覧")
      end
    end
  end
end
