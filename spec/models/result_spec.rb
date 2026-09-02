require "rails_helper"

RSpec.describe Result, type: :model do
  describe "factory" do
    it "有効な factory を持つこと" do
      result = build(:result)
      expect(result).to be_valid
    end
  end

  describe "validations" do
    describe "stress_level" do
      it "nil の場合は invalid" do
        result = build(:result, stress_level: nil)
        expect(result).to be_invalid
        expect(result.errors[:stress_level]).to include("can't be blank")
      end

      it "high_stress の場合は valid" do
        result = build(:result, stress_level: :high_stress)
        expect(result).to be_valid
      end

      it "low_to_moderate_stress の場合は valid" do
        result = build(:result, stress_level: :low_to_moderate_stress)
        expect(result).to be_valid
      end
    end

    describe "employee_id (複合ユニーク)" do
      it "同じ employee + period の組み合わせで重複すると invalid" do
        employee = create(:employee)
        period = create(:stress_check_period)
        create(:result, employee: employee, stress_check_period: period)
        result = build(:result, employee: employee, stress_check_period: period)
        expect(result).to be_invalid
        expect(result.errors[:employee_id]).to include("has already been taken")
      end

      it "違う period であれば同じ employee でも valid" do
        employee = create(:employee)
        period1 = create(:stress_check_period)
        period2 = create(:stress_check_period)
        create(:result, employee: employee, stress_check_period: period1)
        result = build(:result, employee: employee, stress_check_period: period2)
        expect(result).to be_valid
      end

      it "違う employee であれば同じ period でも valid" do
        employee1 = create(:employee)
        employee2 = create(:employee)
        period = create(:stress_check_period)
        create(:result, employee: employee1, stress_check_period: period)
        result = build(:result, employee: employee2, stress_check_period: period)
        expect(result).to be_valid
      end
    end

    describe "belongs_to (関連の自動 presence)" do
      it "employee が nil の場合は invalid" do
        result = build(:result, employee: nil)
        expect(result).to be_invalid
        expect(result.errors[:employee]).to include("must exist")
      end

      it "stress_check_period が nil の場合は invalid" do
        result = build(:result, stress_check_period: nil)
        expect(result).to be_invalid
        expect(result.errors[:stress_check_period]).to include("must exist")
      end
    end
  end
end
