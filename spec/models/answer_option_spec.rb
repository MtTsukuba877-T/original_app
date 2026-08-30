require "rails_helper"

RSpec.describe AnswerOption, type: :model do
  describe "factory" do
    it "有効な factory を持つこと" do
      answer_option = build(:answer_option)
      expect(answer_option).to be_valid
    end
  end

  describe "validations" do
    describe "answer_number" do
      it "nil の場合は invalid" do
        answer_option = build(:answer_option, answer_number: nil)
        expect(answer_option).to be_invalid
        expect(answer_option.errors[:answer_number]).to include("can't be blank")
      end

      it "同じ section 内で重複する場合は invalid" do
        section = create(:section)
        create(:answer_option, section: section, answer_number: 1)
        answer_option = build(:answer_option, section: section, answer_number: 1)
        expect(answer_option).to be_invalid
        expect(answer_option.errors[:answer_number]).to include("has already been taken")
      end

      it "違う section 内であれば同じ answer_number でも valid" do
        section1 = create(:section)
        section2 = create(:section)
        create(:answer_option, section: section1, answer_number: 1)
        answer_option = build(:answer_option, section: section2, answer_number: 1)
        expect(answer_option).to be_valid
      end

      it "0 の場合は invalid" do
        answer_option = build(:answer_option, answer_number: 0)
        expect(answer_option).to be_invalid
        expect(answer_option.errors[:answer_number]).to include("must be in 1..4")
      end

      it "5 の場合は invalid" do
        answer_option = build(:answer_option, answer_number: 5)
        expect(answer_option).to be_invalid
        expect(answer_option.errors[:answer_number]).to include("must be in 1..4")
      end

      it "小数の場合は invalid" do
        answer_option = build(:answer_option, answer_number: 1.5)
        expect(answer_option).to be_invalid
        expect(answer_option.errors[:answer_number]).to include("must be an integer")
      end
    end

    describe "text" do
      it "nil の場合は invalid" do
        answer_option = build(:answer_option, text: nil)
        expect(answer_option).to be_invalid
        expect(answer_option.errors[:text]).to include("can't be blank")
      end

      it "50文字の場合は valid (境界値)" do
        answer_option = build(:answer_option, text: "あ" * 50)
        expect(answer_option).to be_valid
      end

      it "51文字の場合は invalid (境界値超え)" do
        answer_option = build(:answer_option, text: "あ" * 51)
        expect(answer_option).to be_invalid
        expect(answer_option.errors[:text]).to include("is too long (maximum is 50 characters)")
      end
    end

    describe "section (belongs_to)" do
      it "section が nil の場合は invalid" do
        answer_option = build(:answer_option, section: nil)
        expect(answer_option).to be_invalid
        expect(answer_option.errors[:section]).to include("must exist")
      end
    end
  end
end
