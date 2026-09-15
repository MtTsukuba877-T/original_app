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

  describe "GET /companies/new" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトすること" do
        get new_company_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "system_admin でログイン済の場合" do
      let(:admin) { create(:user) }

      before { sign_in admin }

      it "企業登録画面が表示されること" do
        get new_company_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("企業登録")
      end
    end

    context "company_hr でログイン済の場合" do
      let(:company_hr) { create(:user, :company_hr) }

      before { sign_in company_hr }

      it "root_path にリダイレクトされること" do
        get new_company_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /companies" do
    let(:admin) { create(:user) }

    before { sign_in admin }

    let(:valid_params) do
      {
        company_registration_form: {
          company_name: "株式会社テスト",
          start_date: "2026-10-01",
          end_date: "2026-10-31",
          hr_name: "山田 太郎",
          hr_email: "yamada@example.com"
        }
      }
    end

    let(:invalid_params) do
      {
        company_registration_form: {
          company_name: "",
          start_date: "",
          end_date: "",
          hr_name: "",
          hr_email: ""
        }
      }
    end

    context "有効なパラメータの場合" do
      it "作成された企業の詳細画面にリダイレクトされること" do
        post companies_path, params: valid_params
        created_company = Company.last
        expect(response).to redirect_to(company_path(created_company))
      end

      it "フラッシュメッセージが表示されること" do
        post companies_path, params: valid_params
        expect(flash[:notice]).to include("株式会社テストを登録しました")
      end
    end

    context "無効なパラメータの場合(必須項目が空)" do
      it "422 Unprocessable Entity が返ること" do
        post companies_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "エラーメッセージが表示されること" do
        post companies_path, params: invalid_params
        expect(response.body).to include("入力内容にエラーがあります")
      end
    end

    context "email が既に使用済の場合" do
      let!(:existing_user) { create(:user, :company_hr, email: "yamada@example.com") }

      it "重複エラーメッセージが表示されること" do
        post companies_path, params: valid_params
        expect(response.body).to include("はすでに使用されています")
      end
    end

    context "company_hr でログイン済の場合" do
      let(:company_hr) { create(:user, :company_hr) }

      before { sign_in company_hr }

      context "有効な params の場合" do
        it "企業が作成されないこと" do
          expect {
            post companies_path, params: valid_params
          }.not_to change(Company, :count)
        end

        it "root_path にリダイレクトされること" do
          post companies_path, params: valid_params
          expect(response).to redirect_to(root_path)
        end
      end

      context "無効な params の場合" do
        it "企業が作成されないこと" do
          expect {
            post companies_path, params: invalid_params
          }.not_to change(Company, :count)
        end

        it "root_path にリダイレクトされること" do
          post companies_path, params: invalid_params
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe "GET /companies/:id" do
    let!(:company) { Company.create!(name: "詳細テスト企業") }

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトすること" do
        get company_path(company)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "system_admin でログイン済の場合" do
      let(:admin) { create(:user) }

      before { sign_in admin }

      it "企業詳細画面が表示されること" do
        get company_path(company)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("企業詳細")
        expect(response.body).to include(company.name)
      end
    end

    context "company_hr でログイン済の場合" do
      let(:company_hr) { create(:user, :company_hr) }

      before { sign_in company_hr }

      it "root_path にリダイレクトされること" do
        get company_path(company)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
