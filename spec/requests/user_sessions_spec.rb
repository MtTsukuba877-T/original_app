require "rails_helper"

RSpec.describe "UserSessions", type: :request do
  describe "GET /users/sign_in" do
    it "ログイン画面が表示されること" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ログイン")
    end
  end

  describe "POST /users/sign_in" do
    context "system_admin として正しい認証情報でログインした場合" do
      let(:user) { create(:user, password: "password123") }

      it "企業一覧画面にリダイレクトすること" do
        post user_session_path, params: {
          user: { email: user.email, password: "password123" }
        }
        expect(response).to redirect_to(companies_path)
      end
    end
  end
end
