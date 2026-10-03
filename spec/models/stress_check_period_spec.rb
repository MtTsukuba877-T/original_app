require "rails_helper"

RSpec.describe StressCheckPeriod, type: :model do
  describe "factory" do
    it "有効な factory を持つこと" do
      period = build(:stress_check_period)
      expect(period).to be_valid
    end
  end

  describe "validations" do
    describe "name" do
      it "nil の場合は invalid" do
        period = build(:stress_check_period, name: nil)
        expect(period).to be_invalid
        expect(period.errors[:name]).to include("can't be blank")
      end

      it "30文字の場合は valid (境界値)" do
        period = build(:stress_check_period, name: "あ" * 30)
        expect(period).to be_valid
      end

      it "31文字の場合は invalid (境界値超え)" do
        period = build(:stress_check_period, name: "あ" * 31)
        expect(period).to be_invalid
        expect(period.errors[:name]).to include("is too long (maximum is 30 characters)")
      end

      it "同じ company 内で重複する場合は invalid" do
        company = create(:company)
        create(:stress_check_period, company: company, name: "2026年度")
        period = build(:stress_check_period, company: company, name: "2026年度")
        expect(period).to be_invalid
        expect(period.errors[:name]).to include("has already been taken")
      end

      it "違う company であれば同じ name でも valid" do
        company1 = create(:company)
        company2 = create(:company)
        create(:stress_check_period, company: company1, name: "2026年度")
        period = build(:stress_check_period, company: company2, name: "2026年度")
        expect(period).to be_valid
      end
    end

    describe "judgment_method" do
      it "nil の場合は invalid" do
        period = build(:stress_check_period, judgment_method: nil)
        expect(period).to be_invalid
        expect(period.errors[:judgment_method]).to include("can't be blank")
      end
    end

    describe "company (belongs_to)" do
      it "company が nil の場合は invalid" do
        period = build(:stress_check_period, company: nil)
        expect(period).to be_invalid
        expect(period.errors[:company]).to include("must exist")
      end
    end

    describe "start_date と end_date の関係 (カスタムバリデーション)" do
      it "両方 nil の場合は valid" do
        period = build(:stress_check_period, start_date: nil, end_date: nil)
        expect(period).to be_valid
      end

      it "両方 present で end_date > start_date の場合は valid" do
        period = build(:stress_check_period,
                       start_date: Date.new(2026, 4, 1),
                       end_date: Date.new(2026, 4, 30))
        expect(period).to be_valid
      end

      it "両方 present で end_date == start_date の場合は valid (境界)" do
        period = build(:stress_check_period,
                       start_date: Date.new(2026, 4, 1),
                       end_date: Date.new(2026, 4, 1))
        expect(period).to be_valid
      end

      it "両方 present で end_date < start_date の場合は invalid" do
        period = build(:stress_check_period,
                       start_date: Date.new(2026, 4, 30),
                       end_date: Date.new(2026, 4, 1))
        expect(period).to be_invalid
        expect(period.errors[:end_date]).to include("は開始日以降の日付を指定してください")
      end

      it "start_date のみ present の場合は invalid" do
        period = build(:stress_check_period, start_date: Date.new(2026, 4, 1), end_date: nil)
        expect(period).to be_invalid
        expect(period.errors[:base]).to include("開始日と終了日は両方入力するか、両方未入力にしてください")
      end

      it "end_date のみ present の場合は invalid" do
        period = build(:stress_check_period, start_date: nil, end_date: Date.new(2026, 4, 30))
        expect(period).to be_invalid
        expect(period.errors[:base]).to include("開始日と終了日は両方入力するか、両方未入力にしてください")
      end
    end
  end

  describe ".in_examination_period（Issue #41）" do
    let(:today) { Date.current }

    it "今日が期間中の実施回を含むこと" do
      period = create(:stress_check_period, start_date: today - 1, end_date: today + 1)
      expect(StressCheckPeriod.in_examination_period).to include(period)
    end

    it "今日が開始日の実施回を含むこと (境界)" do
      period = create(:stress_check_period, start_date: today, end_date: today + 1)
      expect(StressCheckPeriod.in_examination_period).to include(period)
    end

    it "今日が終了日の実施回を含むこと (境界)" do
      period = create(:stress_check_period, start_date: today - 1, end_date: today)
      expect(StressCheckPeriod.in_examination_period).to include(period)
    end

    it "開始日が明日の実施回（開始前）を含まないこと" do
      period = create(:stress_check_period, start_date: today + 1, end_date: today + 2)
      expect(StressCheckPeriod.in_examination_period).not_to include(period)
    end

    it "終了日が昨日の実施回（終了後）を含まないこと" do
      period = create(:stress_check_period, start_date: today - 2, end_date: today - 1)
      expect(StressCheckPeriod.in_examination_period).not_to include(period)
    end

    it "期間が未設定の実施回を含まないこと" do
      period = create(:stress_check_period, start_date: nil, end_date: nil)
      expect(StressCheckPeriod.in_examination_period).not_to include(period)
    end
  end
end
