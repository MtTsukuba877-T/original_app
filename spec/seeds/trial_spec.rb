require "rails_helper"

# お試し受検用の seeds（db/seeds/trial.rb）のテスト（Issue #160）。
# 本番では起動のたびに実行され、失敗するとサーバーが起動しなくなるため、壊れていないことを確かめる。
RSpec.describe "db/seeds/trial.rb" do
  # seeds の最後の puts の表示を、テストの結果に出さない
  before { allow($stdout).to receive(:puts) }

  # お試し受検用の seeds を実行する
  def run_trial_seeds
    load Rails.root.join("db/seeds/trial.rb")
  end

  it "デモンストレーション企業・お試し受検用の実施回・お試し花子さんができ、E-4 を通らない状態になること" do
    run_trial_seeds

    company = Company.find_by(name: Company::TRIAL_COMPANY_NAME)
    employee = company.employees.find_by(examinee_number: Employee::TRIAL_EXAMINEE_NUMBER)
    expect(company.stress_check_periods.in_examination_period.count).to eq(1)
    expect(employee.name).to eq("お試し花子")
    expect(employee.password_change_required?).to be(false)
  end

  it "2回実行しても、企業・実施回・受検者は1件ずつのままであること" do
    run_trial_seeds
    run_trial_seeds

    companies = Company.where(name: Company::TRIAL_COMPANY_NAME)
    expect(companies.count).to eq(1)
    expect(StressCheckPeriod.where(company: companies).count).to eq(1)
    expect(Employee.where(company: companies).count).to eq(1)
  end

  it "実行するたびに、パスワードが作り直されること" do
    run_trial_seeds
    employee = Employee.find_by(examinee_number: Employee::TRIAL_EXAMINEE_NUMBER)
    first_password_digest = employee.password_digest

    run_trial_seeds
    expect(employee.reload.password_digest).not_to eq(first_password_digest)
  end
end
