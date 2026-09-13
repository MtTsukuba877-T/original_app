require "rails_helper"

RSpec.describe CompanyRegistrationForm, type: :model do
  let(:valid_attributes) do
    {
      company_name: "株式会社テスト",
      start_date: Date.new(2026, 10, 1),
      end_date: Date.new(2026, 10, 31),
      hr_name: "山田 太郎",
      hr_email: "yamada@example.com"
    }
  end

  describe "必須項目のバリデーション" do
    it "company_name が空の場合、無効になること" do
      form = CompanyRegistrationForm.new(valid_attributes.merge(company_name: ""))
      expect(form).not_to be_valid
      expect(form.errors[:company_name]).to include("can't be blank")
    end

    it "start_date が空の場合、無効になること" do
      form = CompanyRegistrationForm.new(valid_attributes.merge(start_date: nil))
      expect(form).not_to be_valid
      expect(form.errors[:start_date]).to include("can't be blank")
    end

    it "end_date が空の場合、無効になること" do
      form = CompanyRegistrationForm.new(valid_attributes.merge(end_date: nil))
      expect(form).not_to be_valid
      expect(form.errors[:end_date]).to include("can't be blank")
    end

    it "hr_name が空の場合、無効になること" do
      form = CompanyRegistrationForm.new(valid_attributes.merge(hr_name: ""))
      expect(form).not_to be_valid
      expect(form.errors[:hr_name]).to include("can't be blank")
    end

    it "hr_email が空の場合、無効になること" do
      form = CompanyRegistrationForm.new(valid_attributes.merge(hr_email: ""))
      expect(form).not_to be_valid
      expect(form.errors[:hr_email]).to include("can't be blank")
    end

    it "すべての必須項目が入力されている場合、有効になること" do
      form = CompanyRegistrationForm.new(valid_attributes)
      expect(form).to be_valid
    end
  end

  describe "#save" do
    context "有効な属性の場合" do
      it "Company / StressCheckPeriod / User が作成されること" do
        form = CompanyRegistrationForm.new(valid_attributes)
        expect {
          form.save
        }.to change(Company, :count).by(1)
          .and change(StressCheckPeriod, :count).by(1)
          .and change(User, :count).by(1)
      end

      it "招待メールが1通送信されること" do
        ActionMailer::Base.deliveries.clear
        form = CompanyRegistrationForm.new(valid_attributes)
        expect {
          form.save
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "true を返すこと" do
        form = CompanyRegistrationForm.new(valid_attributes)
        expect(form.save).to be true
      end

      it "作成された Company を form.company で参照できること" do
        form = CompanyRegistrationForm.new(valid_attributes)
        form.save
        expect(form.company).to be_a(Company)
        expect(form.company.name).to eq("株式会社テスト")
      end
    end

    context "無効な属性の場合" do
      it "false を返すこと" do
        form = CompanyRegistrationForm.new(valid_attributes.merge(company_name: ""))
        expect(form.save).to be false
      end

      it "Company / StressCheckPeriod / User いずれも作成されないこと" do
        form = CompanyRegistrationForm.new(valid_attributes.merge(company_name: ""))
        expect {
          form.save
        }.to change(Company, :count).by(0)
          .and change(StressCheckPeriod, :count).by(0)
          .and change(User, :count).by(0)
      end
    end
  end
end
