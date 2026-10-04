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

      context "自社の実施回が受検期間内で、未受検の場合（Issue #41）" do
        before do
          create(:stress_check_period, company: employee.company,
                                       start_date: Date.current - 1,
                                       end_date: Date.current + 1)
        end

        it "受検画面（E-5a）にリダイレクトすること" do
          get examinees_home_path
          expect(response).to redirect_to(examinees_section_path("a"))
        end
      end

      context "自社の実施回が受検期間内で、受検済みの場合（Issue #42）" do
        before do
          period = create(:stress_check_period, company: employee.company,
                                                start_date: Date.current - 1,
                                                end_date: Date.current + 1)
          create(:stress_check_response, employee: employee, stress_check_period: period)
        end

        it "受検が完了したことを伝える画面が表示されること" do
          get examinees_home_path
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("受検が完了しました")
          expect(response.body).to include(employee.company.name)
          expect(response.body).to include("#{employee.name}さん")
          expect(response.body).to include("ご協力ありがとうございました。")
          expect(response.body).to include("画面右上の「ログアウト」ボタンから、")
          expect(response.body).to include("ログアウトしてください。")
        end

        it "ヘッダーにログアウトボタンが表示され、確認ポップアップが設定されていないこと" do
          get examinees_home_path
          expect(response.body).to include(%(action="#{examinees_sign_out_path}"))
          expect(response.body).not_to include("onsubmit")
        end
      end

      context "実施回がない場合（Issue #41）" do
        it "受検期間外の画面が表示されること" do
          get examinees_home_path
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("#{employee.name}さん")
          expect(response.body).to include("現在は受検期間外のため、受検できません。")
        end

        it "ヘッダーにログアウトボタンが表示されること" do
          get examinees_home_path
          expect(response.body).to include(%(action="#{examinees_sign_out_path}"))
          expect(response.body).to include("ログアウト")
        end

        it "ログアウトボタンに確認ポップアップが設定されていないこと" do
          get examinees_home_path
          expect(response.body).not_to include("onsubmit")
        end
      end

      context "自社の実施回の期間が未設定の場合（Issue #41）" do
        before do
          create(:stress_check_period, company: employee.company, start_date: nil, end_date: nil)
        end

        it "受検期間外の画面が表示されること" do
          get examinees_home_path
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("現在は受検期間外のため、受検できません。")
        end
      end

      context "他社の実施回だけが受検期間内の場合（Issue #41）" do
        before do
          create(:stress_check_period, start_date: Date.current - 1, end_date: Date.current + 1)
        end

        it "受検期間外の画面が表示されること（他社の受検期間で受検できないこと）" do
          get examinees_home_path
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("現在は受検期間外のため、受検できません。")
        end
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
