require "rails_helper"

RSpec.describe Company, type: :model do
  describe "factory" do
    it "有効な factory を持つこと" do
      company = build(:company)
      expect(company).to be_valid
    end
  end

  describe "validations" do
    describe "name" do
      it "nil の場合は invalid" do
        company = build(:company, name: nil)
        expect(company).to be_invalid
        expect(company.errors[:name]).to include("can't be blank")
      end

      it "空文字の場合は invalid" do
        company = build(:company, name: "")
        expect(company).to be_invalid
        expect(company.errors[:name]).to include("can't be blank")
      end

      it "100文字の場合は valid (境界値)" do
        company = build(:company, name: "a" * 100)
        expect(company).to be_valid
      end

      it "101文字の場合は invalid (境界値超え)" do
        company = build(:company, name: "a" * 101)
        expect(company).to be_invalid
        expect(company.errors[:name]).to include("is too long (maximum is 100 characters)")
      end
    end
  end
end
