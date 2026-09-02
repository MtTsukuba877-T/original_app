require "rails_helper"

RSpec.describe Judgment, type: :model do
  describe "factory" do
    it "有効な factory を持つこと" do
      judgment = build(:judgment)
      expect(judgment).to be_valid
    end
  end

  describe "validations" do
    describe "section_score" do
      it "nil の場合は invalid" do
        judgment = build(:judgment, section_score: nil)
        expect(judgment).to be_invalid
        expect(judgment.errors[:section_score]).to include("can't be blank")
      end

      it "0 の場合は valid (境界値)" do
        judgment = build(:judgment, section_score: 0)
        expect(judgment).to be_valid
      end

      it "負の数の場合は invalid" do
        judgment = build(:judgment, section_score: -1)
        expect(judgment).to be_invalid
        expect(judgment.errors[:section_score]).to include("must be greater than or equal to 0")
      end

      it "小数の場合は invalid" do
        judgment = build(:judgment, section_score: 10.5)
        expect(judgment).to be_invalid
        expect(judgment.errors[:section_score]).to include("must be an integer")
      end
    end

    describe "employee_id (複合ユニーク)" do
      it "同じ employee + period + section の組み合わせで重複すると invalid" do
        employee = create(:employee)
        period = create(:stress_check_period)
        section = create(:section)
        create(:judgment,
               employee: employee, stress_check_period: period, section: section)
        judgment = build(:judgment,
                         employee: employee, stress_check_period: period, section: section)
        expect(judgment).to be_invalid
        expect(judgment.errors[:employee_id]).to include("has already been taken")
      end

      it "違う section であれば同じ employee + period でも valid" do
        employee = create(:employee)
        period = create(:stress_check_period)
        section1 = create(:section)
        section2 = create(:section)
        create(:judgment,
               employee: employee, stress_check_period: period, section: section1)
        judgment = build(:judgment,
                         employee: employee, stress_check_period: period, section: section2)
        expect(judgment).to be_valid
      end

      it "違う period であれば同じ employee + section でも valid" do
        employee = create(:employee)
        period1 = create(:stress_check_period)
        period2 = create(:stress_check_period)
        section = create(:section)
        create(:judgment,
               employee: employee, stress_check_period: period1, section: section)
        judgment = build(:judgment,
                         employee: employee, stress_check_period: period2, section: section)
        expect(judgment).to be_valid
      end

      it "違う employee であれば同じ period + section でも valid" do
        employee1 = create(:employee)
        employee2 = create(:employee)
        period = create(:stress_check_period)
        section = create(:section)
        create(:judgment,
               employee: employee1, stress_check_period: period, section: section)
        judgment = build(:judgment,
                         employee: employee2, stress_check_period: period, section: section)
        expect(judgment).to be_valid
      end
    end

    describe "belongs_to (関連の自動 presence)" do
      it "employee が nil の場合は invalid" do
        judgment = build(:judgment, employee: nil)
        expect(judgment).to be_invalid
        expect(judgment.errors[:employee]).to include("must exist")
      end

      it "stress_check_period が nil の場合は invalid" do
        judgment = build(:judgment, stress_check_period: nil)
        expect(judgment).to be_invalid
        expect(judgment.errors[:stress_check_period]).to include("must exist")
      end

      it "section が nil の場合は invalid" do
        judgment = build(:judgment, section: nil)
        expect(judgment).to be_invalid
        expect(judgment.errors[:section]).to include("must exist")
      end
    end
  end
end
