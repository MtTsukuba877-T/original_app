require "rails_helper"

# 受検者のセッションタイムアウト（Issue #40）
RSpec.describe "Examinees::SessionTimeouts", type: :request do
  # 各テストの後に、進めた時間を元に戻す
  after { travel_back }

  context "パスワード変更済の受検者の場合（制限時間30分）" do
    let(:employee) { create(:employee, :password_changed, password: "password123") }

    before do
      post examinees_sign_in_path, params: {
        company_id: employee.company_id,
        examinee_number: employee.examinee_number,
        password: "password123"
      }
    end

    it "30分以内の操作なら、受検者トップ画面を表示できること" do
      travel 29.minutes
      get examinees_home_path
      expect(response).to have_http_status(:ok)
    end

    it "30分を超えると、TOP画面にリダイレクトし、タイムアウトのメッセージを表示すること" do
      travel 31.minutes
      get examinees_home_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("一定時間操作がなかったため、ログアウトしました。")
    end

    it "タイムアウト後は、ログアウト状態になること" do
      travel 31.minutes
      get examinees_home_path
      get examinees_home_path
      expect(response).to redirect_to(examinees_sign_in_path)
    end

    it "操作するたびに、制限時間がのびること" do
      travel 20.minutes
      get examinees_home_path
      travel 20.minutes
      get examinees_home_path
      expect(response).to have_http_status(:ok)
    end
  end

  context "初期パスワードのままの受検者の場合（制限時間10分）" do
    let(:employee) { create(:employee, password: "19900101") }

    before do
      post examinees_sign_in_path, params: {
        company_id: employee.company_id,
        examinee_number: employee.examinee_number,
        password: "19900101"
      }
    end

    it "10分以内の操作なら、パスワード変更画面を表示できること" do
      travel 9.minutes
      get edit_examinees_password_path
      expect(response).to have_http_status(:ok)
    end

    it "10分を超えると、TOP画面にリダイレクトすること" do
      travel 11.minutes
      get edit_examinees_password_path
      expect(response).to redirect_to(root_path)
    end

    it "10分を超えてから送信しても、パスワードは変更されないこと" do
      travel 11.minutes
      patch examinees_password_path, params: { employee: { password: "abc12345", password_confirmation: "abc12345" } }
      expect(response).to redirect_to(root_path)
      expect(employee.reload.password_changed_at).to be_nil
    end
  end
end
