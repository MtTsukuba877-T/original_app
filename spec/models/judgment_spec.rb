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

  describe ".create_section_scores!" do
    let(:employee) { create(:employee) }
    let(:period) { create(:stress_check_period, company: employee.company) }
    let(:section_a) { create(:section) }
    let(:section_b) { create(:section) }
    # 各セクションに、逆転項目1問と、それ以外1問を用意する。
    let!(:a_reversed) { create(:question, section: section_a, reversed: true) }
    let!(:a_normal) { create(:question, section: section_a) }
    let!(:b_reversed) { create(:question, section: section_b, reversed: true) }
    let!(:b_normal) { create(:question, section: section_b) }

    # 受検者の、この実施回の回答を1件作る
    def create_response(question, raw_answer)
      create(:stress_check_response,
             employee: employee, stress_check_period: period, question: question, raw_answer: raw_answer)
    end

    # 全4問に回答する。
    # A: 逆転項目に1（→4点）、それ以外に2（→2点）で、合計6点
    # B: 逆転項目に4（→1点）、それ以外に3（→3点）で、合計4点
    def create_all_responses
      create_response(a_reversed, 1)
      create_response(a_normal, 2)
      create_response(b_reversed, 4)
      create_response(b_normal, 3)
    end

    # 保存されたセクション別スコア
    def score_of(section)
      Judgment.find_by(employee: employee, stress_check_period: period, section: section).section_score
    end

    it "セクションごとに1件ずつ保存され、逆転項目を置き換えた合計がスコアになること" do
      create_all_responses

      Judgment.create_section_scores!(employee: employee, stress_check_period: period)

      expect(Judgment.count).to eq(2)
      expect(score_of(section_a)).to eq(6)
      expect(score_of(section_b)).to eq(4)
    end

    it "回答が1問欠けていると IncompleteResponsesError が発生し、1件も保存されないこと" do
      create_response(a_reversed, 1)
      create_response(a_normal, 2)
      create_response(b_reversed, 4)

      expect {
        Judgment.create_section_scores!(employee: employee, stress_check_period: period)
      }.to raise_error(Judgment::IncompleteResponsesError)
      expect(Judgment.count).to eq(0)
    end

    it "判定方法が合計点数を使う方法（simple_sum）でない実施回では UnsupportedJudgmentMethodError が発生し、1件も保存されないこと" do
      create_all_responses
      period.update!(judgment_method: :raw_score_conversion)

      expect {
        Judgment.create_section_scores!(employee: employee, stress_check_period: period)
      }.to raise_error(Judgment::UnsupportedJudgmentMethodError)
      expect(Judgment.count).to eq(0)
    end

    it "判定済みの状態でもう一度呼ぶと ActiveRecord::RecordInvalid が発生し、件数が増えないこと" do
      create_all_responses
      Judgment.create_section_scores!(employee: employee, stress_check_period: period)

      expect {
        Judgment.create_section_scores!(employee: employee, stress_check_period: period)
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Judgment.count).to eq(2)
    end

    # 80問版の質問を A に2問足す。
    # 1問には回答がある（合計に含めると 6 → 10 になる）。もう1問には回答がない（確認の対象なら「欠けている」になる）。
    it "80問版の質問は、そろっているかの確認にも、合計にも含めないこと" do
      create_all_responses
      answered_extended_question = create(:question, section: section_a, question_type: :extended_80)
      create(:question, section: section_a, question_type: :extended_80)
      create_response(answered_extended_question, 4)

      Judgment.create_section_scores!(employee: employee, stress_check_period: period)

      expect(Judgment.count).to eq(2)
      expect(score_of(section_a)).to eq(6)
    end

    it "ほかの受検者の回答や、ほかの実施回の回答は、合計に含めないこと" do
      create_all_responses
      colleague = create(:employee, company: employee.company)
      other_period = create(:stress_check_period, company: employee.company)
      create(:stress_check_response, employee: colleague, stress_check_period: period, question: a_normal, raw_answer: 4)
      create(:stress_check_response, employee: employee, stress_check_period: other_period, question: a_normal, raw_answer: 4)

      Judgment.create_section_scores!(employee: employee, stress_check_period: period)

      expect(Judgment.count).to eq(2)
      expect(score_of(section_a)).to eq(6)
    end

    # 回答は作った順に読み込まれ、A → B の順に保存される前提。
    # B の判定を先に作っておき、B の保存を重複で失敗させる。
    # 先に保存できた A の分も取り消されることを確かめる。
    it "途中のセクションで保存に失敗すると、先に保存したセクションの分も取り消されること" do
      create_all_responses
      create(:judgment, employee: employee, stress_check_period: period, section: section_b)

      expect {
        Judgment.create_section_scores!(employee: employee, stress_check_period: period)
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Judgment.count).to eq(1)
      expect(Judgment.exists?(section: section_a)).to be(false)
    end
  end
end
