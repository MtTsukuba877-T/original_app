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
end
