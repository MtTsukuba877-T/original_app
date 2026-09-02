require "rails_helper"

RSpec.describe StressCheckResponse, type: :model do
  describe "factory" do
    it "有効な factory を持つこと" do
      response = build(:stress_check_response)
      expect(response).to be_valid
    end
  end

  describe "validations" do
    describe "raw_answer" do
      it "nil の場合は invalid" do
        response = build(:stress_check_response, raw_answer: nil)
        expect(response).to be_invalid
        expect(response.errors[:raw_answer]).to include("can't be blank")
      end

      it "1 の場合は valid (境界値)" do
        response = build(:stress_check_response, raw_answer: 1)
        expect(response).to be_valid
      end

      it "4 の場合は valid (境界値)" do
        response = build(:stress_check_response, raw_answer: 4)
        expect(response).to be_valid
      end

      it "0 の場合は invalid" do
        response = build(:stress_check_response, raw_answer: 0)
        expect(response).to be_invalid
        expect(response.errors[:raw_answer]).to include("must be in 1..4")
      end

      it "5 の場合は invalid" do
        response = build(:stress_check_response, raw_answer: 5)
        expect(response).to be_invalid
        expect(response.errors[:raw_answer]).to include("must be in 1..4")
      end

      it "小数の場合は invalid" do
        response = build(:stress_check_response, raw_answer: 2.5)
        expect(response).to be_invalid
        expect(response.errors[:raw_answer]).to include("must be an integer")
      end
    end

    describe "employee_id (複合ユニーク)" do
      it "同じ employee + period + question の組み合わせで重複すると invalid" do
        employee = create(:employee)
        period = create(:stress_check_period)
        question = create(:question)
        create(:stress_check_response,
               employee: employee, stress_check_period: period, question: question)
        response = build(:stress_check_response,
                         employee: employee, stress_check_period: period, question: question)
        expect(response).to be_invalid
        expect(response.errors[:employee_id]).to include("has already been taken")
      end

      it "違う question であれば同じ employee + period でも valid" do
        employee = create(:employee)
        period = create(:stress_check_period)
        question1 = create(:question)
        question2 = create(:question)
        create(:stress_check_response,
               employee: employee, stress_check_period: period, question: question1)
        response = build(:stress_check_response,
                         employee: employee, stress_check_period: period, question: question2)
        expect(response).to be_valid
      end

      it "違う period であれば同じ employee + question でも valid" do
        employee = create(:employee)
        period1 = create(:stress_check_period)
        period2 = create(:stress_check_period)
        question = create(:question)
        create(:stress_check_response,
               employee: employee, stress_check_period: period1, question: question)
        response = build(:stress_check_response,
                         employee: employee, stress_check_period: period2, question: question)
        expect(response).to be_valid
      end

      it "違う employee であれば同じ period + question でも valid" do
        employee1 = create(:employee)
        employee2 = create(:employee)
        period = create(:stress_check_period)
        question = create(:question)
        create(:stress_check_response,
               employee: employee1, stress_check_period: period, question: question)
        response = build(:stress_check_response,
                         employee: employee2, stress_check_period: period, question: question)
        expect(response).to be_valid
      end
    end

    describe "belongs_to (関連の自動 presence)" do
      it "employee が nil の場合は invalid" do
        response = build(:stress_check_response, employee: nil)
        expect(response).to be_invalid
        expect(response.errors[:employee]).to include("must exist")
      end

      it "stress_check_period が nil の場合は invalid" do
        response = build(:stress_check_response, stress_check_period: nil)
        expect(response).to be_invalid
        expect(response.errors[:stress_check_period]).to include("must exist")
      end

      it "question が nil の場合は invalid" do
        response = build(:stress_check_response, question: nil)
        expect(response).to be_invalid
        expect(response.errors[:question]).to include("must exist")
      end
    end
  end
end
