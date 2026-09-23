require "rails_helper"

RSpec.describe "CompanyUsers::Employees", type: :request do
  # fixture ファイルを Rails のアップロードファイルとしてシミュレートするヘルパー
  def fixture_csv(filename)
    fixture_file_upload(filename, "text/csv")
  end

  describe "GET /company_users/employees/csv_upload" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトすること" do
        get csv_upload_company_users_employees_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "company_hr でログイン済の場合" do
      let(:company_hr) { create(:user, :company_hr) }

      before { sign_in company_hr }

      it "名簿アップロード画面が表示されること" do
        get csv_upload_company_users_employees_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("名簿アップロード")
      end

      it "テンプレートダウンロードボタンが表示されること" do
        get csv_upload_company_users_employees_path
        expect(response.body).to include("テンプレートCSVをダウンロード")
      end

      it "アップロードボタンが表示されること" do
        get csv_upload_company_users_employees_path
        expect(response.body).to include("アップロード")
      end
    end
  end

  describe "POST /company_users/employees/csv_import" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトすること" do
        post csv_import_company_users_employees_path,
             params: { employee_csv_import_form: { csv_file: fixture_csv("employees_ok.csv") } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "company_hr でログイン済の場合" do
      let(:company_hr) { create(:user, :company_hr) }

      before { sign_in company_hr }

      context "有効なCSVをアップロードした場合" do
        it "3件の Employee が作成されること" do
          expect {
            post csv_import_company_users_employees_path,
                 params: { employee_csv_import_form: { csv_file: fixture_csv("employees_ok.csv") } }
          }.to change(Employee, :count).by(3)
        end

        it "成功フラッシュメッセージが表示されること" do
          post csv_import_company_users_employees_path,
               params: { employee_csv_import_form: { csv_file: fixture_csv("employees_ok.csv") } }
          expect(response.body).to include("3件の受検者を登録しました")
        end

        it "登録された Employee がログインユーザーの企業に紐づくこと" do
          post csv_import_company_users_employees_path,
               params: { employee_csv_import_form: { csv_file: fixture_csv("employees_ok.csv") } }
          employee = Employee.find_by(examinee_number: "E001")
          expect(employee.company).to eq(company_hr.company)
        end
      end

      context "ヘッダー不一致のCSVをアップロードした場合" do
        it "422 Unprocessable Entity が返ること" do
          post csv_import_company_users_employees_path,
               params: { employee_csv_import_form: { csv_file: fixture_csv("employees_bad_header.csv") } }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "エラーメッセージが表示されること" do
          post csv_import_company_users_employees_path,
               params: { employee_csv_import_form: { csv_file: fixture_csv("employees_bad_header.csv") } }
          expect(response.body).to include("ヘッダー行が想定と異なります")
        end

        it "Employee が1件も作成されないこと" do
          expect {
            post csv_import_company_users_employees_path,
                 params: { employee_csv_import_form: { csv_file: fixture_csv("employees_bad_header.csv") } }
          }.not_to change(Employee, :count)
        end
      end

      context "一部行にエラーがあるCSVをアップロードした場合" do
        it "取り込みエラー表示が含まれること" do
          post csv_import_company_users_employees_path,
               params: { employee_csv_import_form: { csv_file: fixture_csv("employees_partial_errors.csv") } }
          expect(response.body).to include("取り込みエラー")
        end

        it "Employee が1件も作成されないこと(全件ロールバック)" do
          expect {
            post csv_import_company_users_employees_path,
                 params: { employee_csv_import_form: { csv_file: fixture_csv("employees_partial_errors.csv") } }
          }.not_to change(Employee, :count)
        end
      end
    end
  end

  describe "GET /company_users/employees/csv_template" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトすること" do
        get csv_template_company_users_employees_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "company_hr でログイン済の場合" do
      let(:company_hr) { create(:user, :company_hr) }

      before { sign_in company_hr }

      it "200 OK が返ること" do
        get csv_template_company_users_employees_path
        expect(response).to have_http_status(:ok)
      end

      it "Content-Type が text/csv であること" do
        get csv_template_company_users_employees_path
        expect(response.content_type).to include("text/csv")
      end

      it "ファイル名が employee_template.csv であること" do
        get csv_template_company_users_employees_path
        expect(response.headers["Content-Disposition"]).to include("employee_template.csv")
      end

      it "CSVの先頭にBOMが付与されていること" do
        get csv_template_company_users_employees_path
        expect(response.body.bytes[0, 3]).to eq([ 0xEF, 0xBB, 0xBF ])
      end

      it "CSVにヘッダー行が含まれること" do
        get csv_template_company_users_employees_path
        expect(response.body).to include("受検者番号,氏名,生年月日,性別,所属部署,メールアドレス")
      end

      it "CSVにサンプルデータ3行が含まれること" do
        get csv_template_company_users_employees_path
        expect(response.body).to include("サンプル太郎")
        expect(response.body).to include("サンプル花子")
        expect(response.body).to include("サンプル次郎")
      end
    end
  end
end
