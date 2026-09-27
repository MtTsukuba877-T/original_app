require "rails_helper"

RSpec.describe "Examinees::Sessions", type: :request do
  let(:company) { create(:company) }
  let!(:employee) { create(:employee, :password_changed, company: company, examinee_number: "EMP001", password: "password123") }

  # 正しいログイン情報（失敗パターンでは、必要な項目だけ merge で上書きする）
  let(:valid_params) do
    { company_id: company.id, examinee_number: "EMP001", password: "password123" }
  end

  describe "GET /examinees/sign_in" do
    context "未ログインの場合" do
      it "ログイン画面が表示されること" do
        get examinees_sign_in_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ストレスチェック ログイン")
      end

      it "ログアウトボタンが表示されないこと" do
        get examinees_sign_in_path
        expect(response.body).not_to include(examinees_sign_out_path)
      end
    end

    context "ログイン済の場合" do
      before { post examinees_sign_in_path, params: valid_params }

      it "受検者トップ画面にリダイレクトすること" do
        get examinees_sign_in_path
        expect(response).to redirect_to(examinees_home_path)
      end
    end
  end

  describe "POST /examinees/sign_in" do
    context "企業ID・受検者番号・パスワードがすべて正しい場合" do
      it "受検者トップ画面にリダイレクトすること" do
        post examinees_sign_in_path, params: valid_params
        expect(response).to redirect_to(examinees_home_path)
      end

      it "リダイレクト先で、ログイン完了メッセージと氏名が表示されること" do
        post examinees_sign_in_path, params: valid_params
        follow_redirect!
        expect(response.body).to include("ログインしました。")
        expect(response.body).to include("#{employee.name}さん")
      end
    end

    context "初期パスワードのままの受検者の場合" do
      let!(:initial_employee) { create(:employee, company: company, examinee_number: "EMP002", password: "19900101") }
      let(:initial_params) { valid_params.merge(examinee_number: "EMP002", password: "19900101") }

      it "パスワード変更画面にリダイレクトすること" do
        post examinees_sign_in_path, params: initial_params
        expect(response).to redirect_to(edit_examinees_password_path)
      end

      it "リダイレクト先で、ログイン完了メッセージが表示されないこと" do
        post examinees_sign_in_path, params: initial_params
        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("初回ログインのため、新しいパスワードを設定してください")
        expect(response.body).not_to include("ログインしました。")
      end
    end



    context "企業IDが存在しない場合" do
      it "ログイン画面を再表示し、エラーメッセージを表示すること" do
        post examinees_sign_in_path, params: valid_params.merge(company_id: 0)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("企業ID、受検者番号またはパスワードが正しくありません。")
      end
    end

    context "受検者番号とパスワードは正しいが、別の企業の企業IDの場合" do
      let(:other_company) { create(:company, name: "別企業") }

      it "ログインできないこと" do
        post examinees_sign_in_path, params: valid_params.merge(company_id: other_company.id)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("企業ID、受検者番号またはパスワードが正しくありません。")
      end
    end

    context "受検者番号が間違っている場合" do
      it "ログイン画面を再表示し、エラーメッセージを表示すること" do
        post examinees_sign_in_path, params: valid_params.merge(examinee_number: "EMP999")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("企業ID、受検者番号またはパスワードが正しくありません。")
      end
    end

    context "パスワードが間違っている場合" do
      it "ログイン画面を再表示し、エラーメッセージを表示すること" do
        post examinees_sign_in_path, params: valid_params.merge(password: "wrongpass")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("企業ID、受検者番号またはパスワードが正しくありません。")
      end

      it "ログイン状態にならないこと" do
        post examinees_sign_in_path, params: valid_params.merge(password: "wrongpass")
        get examinees_home_path
        expect(response).to redirect_to(examinees_sign_in_path)
      end
    end

    context "CSRF トークンが一致しない場合" do
      # テスト環境では CSRF チェックが無効になっているため、この context の間だけ有効にする
      around do |example|
        original = ActionController::Base.allow_forgery_protection
        ActionController::Base.allow_forgery_protection = true
        example.run
      ensure
        ActionController::Base.allow_forgery_protection = original
      end

      it "ログイン画面にリダイレクトし、有効期限切れのメッセージを表示すること" do
        post examinees_sign_in_path, params: valid_params
        expect(response).to redirect_to(examinees_sign_in_path)
        follow_redirect!
        expect(response.body).to include("画面の有効期限が切れました。")
      end
    end
  end

  describe "DELETE /examinees/sign_out" do
    context "ログイン済の場合" do
      before { post examinees_sign_in_path, params: valid_params }

      it "TOP画面にリダイレクトすること" do
        delete examinees_sign_out_path
        expect(response).to redirect_to(root_path)
      end

      it "リダイレクト先で、ログアウト完了メッセージが表示されること" do
        delete examinees_sign_out_path
        follow_redirect!
        expect(response.body).to include("ログアウトしました。")
      end

      it "ログアウト後は受検者トップ画面を開けないこと" do
        delete examinees_sign_out_path
        get examinees_home_path
        expect(response).to redirect_to(examinees_sign_in_path)
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトし、ログインを促すメッセージを表示すること" do
        delete examinees_sign_out_path
        expect(response).to redirect_to(examinees_sign_in_path)
        follow_redirect!
        expect(response.body).to include("ログインしてください。")
      end
    end
  end
end
