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

  describe ".stress_level_for" do
    # 厚生労働省の実施マニュアルの計算例（A 51点・B 92点・C 31点）
    it "実施マニュアルの計算例は high_stress になること" do
      expect(Result.stress_level_for(score_a: 51, score_b: 92, score_c: 31)).to eq(:high_stress)
    end

    context "基準㋐（B の合計が 77点以上）" do
      it "B がちょうど 77点なら high_stress になること" do
        expect(Result.stress_level_for(score_a: 17, score_b: 77, score_c: 9)).to eq(:high_stress)
      end

      it "B が 76点で、A と C の合算が 76点未満なら low_to_moderate_stress になること" do
        expect(Result.stress_level_for(score_a: 17, score_b: 76, score_c: 9)).to eq(:low_to_moderate_stress)
      end
    end

    context "基準㋑（A と C の合算が 76点以上、かつ B の合計が 63点以上）" do
      it "A と C の合算がちょうど 76点、B がちょうど 63点なら high_stress になること" do
        expect(Result.stress_level_for(score_a: 50, score_b: 63, score_c: 26)).to eq(:high_stress)
      end

      it "A と C の合算が 76点でも、B が 62点なら low_to_moderate_stress になること" do
        expect(Result.stress_level_for(score_a: 50, score_b: 62, score_c: 26)).to eq(:low_to_moderate_stress)
      end

      it "B が 63点でも、A と C の合算が 75点なら low_to_moderate_stress になること" do
        expect(Result.stress_level_for(score_a: 50, score_b: 63, score_c: 25)).to eq(:low_to_moderate_stress)
      end
    end
  end

  describe ".create_from_section_scores!" do
    let(:employee) { create(:employee) }
    let(:period) { create(:stress_check_period, company: employee.company) }
    # セクション A〜D。{ "a" => A のセクション, "b" => B のセクション, ... } の形
    let(:sections) { %w[a b c d].to_h { |code| [ code, create(:section, code: code) ] } }

    # 受検者と実施回を指定して、セクション別スコア（judgments）を作る。
    # scores の形: { "a" => 50, "b" => 84, ... }（セクションのコード => 点数）
    def create_scores(target_employee, target_period, scores)
      scores.each do |code, score|
        create(:judgment, employee: target_employee, stress_check_period: target_period, section: sections[code], section_score: score)
      end
    end

    # B が 84点で、基準㋐（77点以上）を満たす
    it "基準を満たすスコアのときは、high_stress の結果が1件保存されること" do
      create_scores(employee, period, { "a" => 50, "b" => 84, "c" => 27, "d" => 8 })

      Result.create_from_section_scores!(employee: employee, stress_check_period: period)

      expect(Result.count).to eq(1)
      expect(Result.first).to have_attributes(employee: employee, stress_check_period: period, stress_level: "high_stress")
    end

    # B が 61点で、基準㋐（77点以上）も基準㋑（63点以上）も満たさない
    it "基準を満たさないスコアのときは、low_to_moderate_stress の結果が1件保存されること" do
      create_scores(employee, period, { "a" => 50, "b" => 61, "c" => 27, "d" => 8 })

      Result.create_from_section_scores!(employee: employee, stress_check_period: period)

      expect(Result.count).to eq(1)
      expect(Result.first).to have_attributes(employee: employee, stress_check_period: period, stress_level: "low_to_moderate_stress")
    end

    it "D のスコアは判定に使わないこと（D のスコアがなくても判定できる）" do
      create_scores(employee, period, { "a" => 50, "b" => 84, "c" => 27 })

      Result.create_from_section_scores!(employee: employee, stress_check_period: period)

      expect(Result.first.stress_level).to eq("high_stress")
    end

    it "A・B・C のスコアがそろっていないときは例外が発生し、1件も保存されないこと" do
      create_scores(employee, period, { "a" => 50, "b" => 84, "d" => 8 })

      expect {
        Result.create_from_section_scores!(employee: employee, stress_check_period: period)
      }.to raise_error(Result::IncompleteSectionScoresError)
      expect(Result.count).to eq(0)
    end

    it "判定方法が合計点数を使う方法でない実施回では例外が発生し、1件も保存されないこと" do
      create_scores(employee, period, { "a" => 50, "b" => 84, "c" => 27, "d" => 8 })
      period.update!(judgment_method: :raw_score_conversion)

      expect {
        Result.create_from_section_scores!(employee: employee, stress_check_period: period)
      }.to raise_error(Judgment::UnsupportedJudgmentMethodError)
      expect(Result.count).to eq(0)
    end

    it "すでに判定結果があるときは例外が発生し、件数が増えないこと" do
      create_scores(employee, period, { "a" => 50, "b" => 84, "c" => 27, "d" => 8 })
      create(:result, employee: employee, stress_check_period: period)

      expect {
        Result.create_from_section_scores!(employee: employee, stress_check_period: period)
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Result.count).to eq(1)
    end

    # 自分のスコアは基準を満たさない。ほかの受検者・ほかの実施回には、基準を満たす高いスコアを作っておく。
    it "ほかの受検者のスコアや、ほかの実施回のスコアは判定に使わないこと" do
      create_scores(employee, period, { "a" => 50, "b" => 61, "c" => 27 })
      other_employee = create(:employee, company: employee.company)
      create_scores(other_employee, period, { "a" => 68, "b" => 116, "c" => 36 })
      other_period = create(:stress_check_period, company: employee.company)
      create_scores(employee, other_period, { "a" => 68, "b" => 116, "c" => 36 })

      Result.create_from_section_scores!(employee: employee, stress_check_period: period)

      expect(Result.find_by(employee: employee, stress_check_period: period).stress_level).to eq("low_to_moderate_stress")
    end
  end
end
