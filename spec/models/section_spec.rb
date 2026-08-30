require "rails_helper"

RSpec.describe Section, type: :model do
  describe "factory" do
    it "有効な factory を持つこと" do
      section = build(:section)
      expect(section).to be_valid
    end
  end

  describe "validations" do
    describe "code" do
      it "nil の場合は invalid" do
        section = build(:section, code: nil)
        expect(section).to be_invalid
        expect(section.errors[:code]).to include("can't be blank")
      end

      it "空文字の場合は invalid" do
        section = build(:section, code: "")
        expect(section).to be_invalid
        expect(section.errors[:code]).to include("can't be blank")
      end

      it "重複する場合は invalid" do
        create(:section, code: "dup_code")
        section = build(:section, code: "dup_code")
        expect(section).to be_invalid
        expect(section.errors[:code]).to include("has already been taken")
      end

      it "10文字の場合は valid (境界値)" do
        section = build(:section, code: "a" * 10)
        expect(section).to be_valid
      end

      it "11文字の場合は invalid (境界値超え)" do
        section = build(:section, code: "a" * 11)
        expect(section).to be_invalid
        expect(section.errors[:code]).to include("is too long (maximum is 10 characters)")
      end
    end

    describe "name" do
      it "nil の場合は invalid" do
        section = build(:section, name: nil)
        expect(section).to be_invalid
        expect(section.errors[:name]).to include("can't be blank")
      end

      it "50文字の場合は valid (境界値)" do
        section = build(:section, name: "あ" * 50)
        expect(section).to be_valid
      end

      it "51文字の場合は invalid (境界値超え)" do
        section = build(:section, name: "あ" * 51)
        expect(section).to be_invalid
        expect(section.errors[:name]).to include("is too long (maximum is 50 characters)")
      end
    end

    describe "intro_text" do
      it "nil の場合は invalid" do
        section = build(:section, intro_text: nil)
        expect(section).to be_invalid
        expect(section.errors[:intro_text]).to include("can't be blank")
      end
    end

    describe "display_order" do
      it "nil の場合は invalid" do
        section = build(:section, display_order: nil)
        expect(section).to be_invalid
        expect(section.errors[:display_order]).to include("can't be blank")
      end

      it "重複する場合は invalid" do
        create(:section, display_order: 99)
        section = build(:section, display_order: 99)
        expect(section).to be_invalid
        expect(section.errors[:display_order]).to include("has already been taken")
      end

      it "0 の場合は invalid" do
        section = build(:section, display_order: 0)
        expect(section).to be_invalid
        expect(section.errors[:display_order]).to include("must be greater than 0")
      end

      it "小数の場合は invalid" do
        section = build(:section, display_order: 1.5)
        expect(section).to be_invalid
        expect(section.errors[:display_order]).to include("must be an integer")
      end
    end
  end
end
