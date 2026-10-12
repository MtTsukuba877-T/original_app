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

      context "自社の実施回が受検期間内で、受検済みの場合（Issue #42、#46）" do
        let(:period) do
          create(:stress_check_period, company: employee.company,
                                       start_date: Date.current - 1,
                                       end_date: Date.current + 1)
        end

        before do
          create(:stress_check_response, employee: employee, stress_check_period: period)
        end

        context "判定結果が「高ストレスではない」の場合（Issue #46）" do
          before do
            create(:result, employee: employee, stress_check_period: period, stress_level: :low_to_moderate_stress)
          end

          it "受検が完了したことと、ログアウトの案内・共用の機器の案内が表示されること" do
            get examinees_home_path
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("受検が完了しました")
            expect(response.body).to include(employee.company.name)
            expect(response.body).to include("#{employee.name}さん")
            expect(response.body).to include("ご協力ありがとうございました。")
            expect(response.body).to include("画面右上または画面下の「ログアウト」ボタンから")
            expect(response.body).to include("ログアウトしてください。")
            expect(response.body).to include("《共用のPC・スマートフォン・タブレットをお使いの方へ》")
          end

          it "ログアウトボタンがヘッダーと画面下の2か所に表示され、確認ポップアップが設定されていないこと" do
            get examinees_home_path
            assert_select %(form[action="#{examinees_sign_out_path}"]), count: 2
            expect(response.body).not_to include("onsubmit")
          end

          it "「【高ストレスではない】」が表示され、「【高ストレス】」は表示されないこと" do
            get examinees_home_path
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("判定結果：")
            expect(response.body).to include("【高ストレスではない】")
            expect(response.body).not_to include("【高ストレス】")
          end

          it "受検期間の最終日の案内が、実施回の終了日つきで表示されること" do
            last_day = period.end_date.strftime("%Y年%-m月%-d日")

            get examinees_home_path
            expect(response.body).to include("受検期間の最終日（#{last_day}）までです。")
            expect(response.body).to include("この画面を保存または印刷することをお勧めします。")
          end

          it "ほかの受検者・ほかの実施回に「高ストレス」の判定結果があっても、自分の今の実施回の結果を表示すること" do
            other_employee = create(:employee, company: employee.company)
            create(:result, employee: other_employee, stress_check_period: period, stress_level: :high_stress)
            other_period = create(:stress_check_period, company: employee.company)
            create(:result, employee: employee, stress_check_period: other_period, stress_level: :high_stress)

            get examinees_home_path
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("【高ストレスではない】")
            expect(response.body).not_to include("【高ストレス】")
          end
        end

        context "判定結果が「高ストレス」の場合（Issue #46）" do
          before do
            create(:result, employee: employee, stress_check_period: period, stress_level: :high_stress)
          end

          it "「【高ストレス】」が表示され、「【高ストレスではない】」は表示されないこと" do
            get examinees_home_path
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("判定結果：")
            expect(response.body).to include("【高ストレス】")
            expect(response.body).not_to include("【高ストレスではない】")
          end
        end

        context "判定結果がない場合（通常は起きない）（Issue #46）" do
          it "判定結果を表示できないことと問い合わせ先が表示され、完了の表示と判定結果は表示されないこと" do
            get examinees_home_path
            expect(response).to have_http_status(:ok)
            expect(response.body).to include(employee.company.name)
            expect(response.body).to include("#{employee.name}さん")
            expect(response.body).to include("判定結果を表示できません。")
            expect(response.body).to include("会社のご担当者にお問い合わせください。")
            expect(response.body).not_to include("受検が完了しました")
            expect(response.body).not_to include("判定結果：")
            assert_select %(form[action="#{examinees_sign_out_path}"]), count: 1
          end

          it "ほかの受検者・ほかの実施回の判定結果だけがある場合も、それを表示せず、判定結果を表示できない画面になること" do
            other_employee = create(:employee, company: employee.company)
            create(:result, employee: other_employee, stress_check_period: period, stress_level: :high_stress)
            other_period = create(:stress_check_period, company: employee.company)
            create(:result, employee: employee, stress_check_period: other_period, stress_level: :high_stress)

            get examinees_home_path
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("判定結果を表示できません。")
            expect(response.body).not_to include("【高ストレス】")
          end
        end
      end

      context "自社の実施回の受検期間が終わっていて、受検済みの場合（Issue #46）" do
        before do
          period = create(:stress_check_period, company: employee.company,
                                                start_date: Date.current - 10,
                                                end_date: Date.current - 1)
          create(:stress_check_response, employee: employee, stress_check_period: period)
          create(:result, employee: employee, stress_check_period: period, stress_level: :high_stress)
        end

        it "受検期間外の画面が表示され、判定結果は表示されないこと" do
          get examinees_home_path
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("現在は受検期間外のため、受検できません。")
          expect(response.body).not_to include("判定結果：")
          expect(response.body).not_to include("【高ストレス】")
        end
      end

      context "実施回がない場合（Issue #41）" do
        it "受検期間外の画面が、企業名・氏名つきで表示されること" do
          get examinees_home_path
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(employee.company.name)
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
