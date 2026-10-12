require "rails_helper"

RSpec.describe "Examinees::Passwords", type: :request do
  let(:company) { create(:company) }
  # 初期パスワード（factory の生年月日 1990年1月1日）のままの受検者
  let!(:employee) { create(:employee, company: company, examinee_number: "EMP001", password: "19900101") }

  let(:login_params) { { company_id: company.id, examinee_number: "EMP001", password: "19900101" } }

  # 正しい変更内容（失敗パターンでは、必要な項目だけ merge で上書きする）
  let(:valid_password_params) { { password: "abc12345", password_confirmation: "abc12345" } }

  describe "GET /examinees/password/edit" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトし、ログインを促すメッセージを表示すること" do
        get edit_examinees_password_path
        expect(response).to redirect_to(examinees_sign_in_path)
        follow_redirect!
        expect(response.body).to include("ログインしてください。")
      end
    end

    context "初期パスワードのままの場合" do
      before { post examinees_sign_in_path, params: login_params }

      it "パスワード変更画面が表示されること" do
        get edit_examinees_password_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("初回ログインのため、新しいパスワードを設定してください")
      end

      it "ログアウトボタンが表示されないこと" do
        get edit_examinees_password_path
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(examinees_sign_out_path)
      end
    end

    context "パスワード変更済の場合" do
      let!(:employee) { create(:employee, :password_changed, company: company, examinee_number: "EMP001", password: "abc12345") }

      before { post examinees_sign_in_path, params: login_params.merge(password: "abc12345") }

      it "受検者トップ画面にリダイレクトすること" do
        get edit_examinees_password_path
        expect(response).to redirect_to(examinees_home_path)
      end
    end
  end

  describe "PATCH /examinees/password" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトすること" do
        patch examinees_password_path, params: { employee: valid_password_params }
        expect(response).to redirect_to(examinees_sign_in_path)
      end
    end

    context "初期パスワードのままの場合" do
      before { post examinees_sign_in_path, params: login_params }

      context "正しい値の場合" do
        it "受検者トップ画面にリダイレクトし、変更完了メッセージを表示すること" do
          patch examinees_password_path, params: { employee: valid_password_params }
          expect(response).to redirect_to(examinees_home_path)
          follow_redirect!
          expect(response.body).to include("パスワードを変更しました。")
        end

        it "新しいパスワードと変更日時が保存されること" do
          patch examinees_password_path, params: { employee: valid_password_params }
          employee.reload
          expect(employee.authenticate("abc12345")).to be_truthy
          expect(employee.password_changed_at).to be_present
        end
      end

      context "空欄の場合" do
        let(:blank_params) { { password: "", password_confirmation: "" } }

        it "変更画面を再表示し、エラーメッセージを表示すること" do
          patch examinees_password_path, params: { employee: blank_params }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("パスワードを入力してください")
        end

        it "変更済みにならないこと" do
          patch examinees_password_path, params: { employee: blank_params }
          expect(employee.reload.password_changed_at).to be_nil
        end
      end

      context "8文字未満の場合" do
        it "変更画面を再表示し、エラーメッセージを表示すること" do
          patch examinees_password_path, params: { employee: valid_password_params.merge(password: "abc1", password_confirmation: "abc1") }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("パスワードは8文字以上で入力してください")
        end
      end

      context "数字のみの場合（初期パスワードと同じ形式）" do
        it "変更画面を再表示し、エラーメッセージを表示すること" do
          patch examinees_password_path, params: { employee: valid_password_params.merge(password: "12345678", password_confirmation: "12345678") }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("パスワードは半角英数字混在で入力してください")
        end
      end

      context "確認用が一致しない場合" do
        it "変更画面を再表示し、エラーメッセージを表示すること" do
          patch examinees_password_path, params: { employee: valid_password_params.merge(password_confirmation: "abc99999") }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("パスワード（確認用）とパスワードの入力が一致しません")
        end
      end
    end

    context "パスワード変更済の場合" do
      let!(:employee) { create(:employee, :password_changed, company: company, examinee_number: "EMP001", password: "abc12345") }

      before { post examinees_sign_in_path, params: login_params.merge(password: "abc12345") }

      it "受検者トップ画面にリダイレクトすること" do
        patch examinees_password_path, params: { employee: valid_password_params }
        expect(response).to redirect_to(examinees_home_path)
      end
    end
  end
end
