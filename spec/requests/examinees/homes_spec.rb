require "rails_helper"

RSpec.describe "Examinees::Homes", type: :request do
  describe "GET /examinees/home" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトし、ログインを促すメッセージを表示すること" do
        get examinees_home_path
        expect(response).to redirect_to(examinees_sign_in_path)
        follow_redirect!
        expect(response.body).to include("ログインしてください。")
      end
    end

    context "ログイン済の場合" do
      let(:employee) { create(:employee, :password_changed, password: "password123") }

      before do
        post examinees_sign_in_path, params: {
          company_id: employee.company_id,
          examinee_number: employee.examinee_number,
          password: "password123"
        }
      end

      it "受検者トップ画面が表示されること" do
        get examinees_home_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("#{employee.name}さん")
      end

      it "ヘッダーにログアウトボタンが表示されること" do
        get examinees_home_path
        expect(response.body).to include(%(action="#{examinees_sign_out_path}"))
        expect(response.body).to include("ログアウト")
      end

      it "ログアウトボタンに確認ポップアップが設定されていないこと" do
        get examinees_home_path
        expect(response.body).not_to include("data-turbo-confirm")
      end
    end

    context "ログイン済・初期パスワードのままの場合（Issue #40）" do
      let(:employee) { create(:employee, password: "19900101") }

      before do
        post examinees_sign_in_path, params: {
          company_id: employee.company_id,
          examinee_number: employee.examinee_number,
          password: "19900101"
        }
      end

      it "URL を直接入力しても、パスワード変更画面にリダイレクトすること" do
        get examinees_home_path
        expect(response).to redirect_to(edit_examinees_password_path)
      end
    end
  end
end
