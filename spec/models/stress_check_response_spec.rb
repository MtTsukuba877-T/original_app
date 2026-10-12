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

  describe ".save_answers!" do
    let(:employee) { create(:employee) }
    let(:period) { create(:stress_check_period, company: employee.company) }
    let!(:question1) { create(:question) }
    let!(:question2) { create(:question) }
    let(:answers) { { question1.id.to_s => 1, question2.id.to_s => 4 } }

    it "全質問の回答がそろっていれば、質問の数だけ保存され、受検者・実施回・回答の値が正しいこと" do
      StressCheckResponse.save_answers!(employee: employee, stress_check_period: period, answers: answers)

      expect(StressCheckResponse.count).to eq(2)
      expect(StressCheckResponse.find_by(question: question1))
        .to have_attributes(employee: employee, stress_check_period: period, raw_answer: 1)
      expect(StressCheckResponse.find_by(question: question2))
        .to have_attributes(employee: employee, stress_check_period: period, raw_answer: 4)
    end

    # 先に作った question1 は保存でき、question2 で失敗する。
    # 保存できた question1 の分も取り消されることを確かめる。
    it "回答が1問抜けていると ActiveRecord::RecordInvalid が発生し、1件も保存されないこと" do
      incomplete_answers = answers.except(question2.id.to_s)

      expect {
        StressCheckResponse.save_answers!(employee: employee, stress_check_period: period, answers: incomplete_answers)
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(StressCheckResponse.count).to eq(0)
    end

    it "保存済みの状態でもう一度呼ぶと ActiveRecord::RecordInvalid が発生し、件数が増えないこと" do
      StressCheckResponse.save_answers!(employee: employee, stress_check_period: period, answers: answers)

      expect {
        StressCheckResponse.save_answers!(employee: employee, stress_check_period: period, answers: answers)
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(StressCheckResponse.count).to eq(2)
    end

    it "57問版ではない質問（80問版）は、保存の対象にならないこと" do
      extended_question = create(:question, question_type: :extended_80)

      StressCheckResponse.save_answers!(employee: employee, stress_check_period: period, answers: answers)

      expect(StressCheckResponse.count).to eq(2)
      expect(StressCheckResponse.exists?(question: extended_question)).to be(false)
    end

    it "answers に存在しない質問の ID が混ざっていても、その分は保存されないこと" do
      answers_with_unknown_id = answers.merge("0" => 3)

      StressCheckResponse.save_answers!(employee: employee, stress_check_period: period, answers: answers_with_unknown_id)

      expect(StressCheckResponse.count).to eq(2)
    end
  end

  describe "#score" do
    it "逆転項目でない質問は、回答の番号がそのまま点数になること" do
      question = create(:question, reversed: false)

      expect(build(:stress_check_response, question: question, raw_answer: 1).score).to eq(1)
      expect(build(:stress_check_response, question: question, raw_answer: 4).score).to eq(4)
    end

    it "逆転項目は、1→4、2→3、3→2、4→1 に置き換えた点数になること" do
      question = create(:question, reversed: true)

      scores = (1..4).map { |raw_answer| build(:stress_check_response, question: question, raw_answer: raw_answer).score }
      expect(scores).to eq([ 4, 3, 2, 1 ])
    end

    it "score を呼んでも、保存されている回答（raw_answer）は変わらないこと" do
      response = create(:stress_check_response, question: create(:question, reversed: true), raw_answer: 1)

      expect(response.score).to eq(4)
      expect(response.reload.raw_answer).to eq(1)
    end
  end
end
