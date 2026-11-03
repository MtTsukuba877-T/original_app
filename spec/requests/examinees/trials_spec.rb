require "rails_helper"

RSpec.describe "Examinees::Trials", type: :request do
  describe "POST /examinees/trial" do
    context "お試し受検用の受検者がいる場合" do
      let(:trial_company) { create(:company, name: Company::TRIAL_COMPANY_NAME) }
      let!(:trial_employee) do
        create(:employee, :password_changed, company: trial_company,
                                             examinee_number: Employee::TRIAL_EXAMINEE_NUMBER)
      end

      it "受検画面（E-5a）に移動し、お試し受検用の受検者としてログインした状態になること" do
        post examinees_trial_path
        expect(response).to redirect_to(examinees_section_path("a"))
        expect(session[:employee_id]).to eq(trial_employee.id)
        expect(session[:trial]).to be(true)
      end

      it "別の受検者でログインしていても、お試し受検用の受検者に入れ替わること" do
        other_employee = create(:employee, :password_changed, password: "password123")
        post examinees_sign_in_path, params: {
          company_id: other_employee.company_id,
          examinee_number: other_employee.examinee_number,
          password: "password123"
        }
        expect(session[:employee_id]).to eq(other_employee.id)

        post examinees_trial_path
        expect(session[:employee_id]).to eq(trial_employee.id)
        expect(session[:trial]).to be(true)
      end
    end

    context "お試し受検用の受検者がいない場合" do
      it "トップページに戻って案内を表示し、ログインした状態にならないこと" do
        post examinees_trial_path
        expect(response).to redirect_to(root_path)
        expect(session[:employee_id]).to be_nil

        follow_redirect!
        expect(response.body).to include("現在、お試し受検はご利用いただけません。")
      end
    end
  end
end
