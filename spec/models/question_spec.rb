require "rails_helper"

RSpec.describe Question, type: :model do
  describe "factory" do
    it "有効な factory を持つこと" do
      question = build(:question)
      expect(question).to be_valid
    end
  end

  describe "validations" do
    describe "question_type" do
      it "nil の場合は invalid" do
        question = build(:question, question_type: nil)
        expect(question).to be_invalid
        expect(question.errors[:question_type]).to include("can't be blank")
      end
    end

    describe "question_number" do
      it "nil の場合は invalid" do
        question = build(:question, question_number: nil)
        expect(question).to be_invalid
        expect(question.errors[:question_number]).to include("can't be blank")
      end

      it "同じ question_type + section 内で重複する場合は invalid" do
        section = create(:section)
        create(:question, question_type: :standard_57, section: section, question_number: 1)
        question = build(:question, question_type: :standard_57, section: section, question_number: 1)
        expect(question).to be_invalid
        expect(question.errors[:question_number]).to include("has already been taken")
      end

      it "違う section であれば同じ question_number でも valid" do
        section1 = create(:section)
        section2 = create(:section)
        create(:question, question_type: :standard_57, section: section1, question_number: 1)
        question = build(:question, question_type: :standard_57, section: section2, question_number: 1)
        expect(question).to be_valid
      end

      it "違う question_type であれば同じ question_number でも valid" do
        section = create(:section)
        create(:question, question_type: :standard_57, section: section, question_number: 1)
        question = build(:question, question_type: :extended_80, section: section, question_number: 1)
        expect(question).to be_valid
      end

      it "0 の場合は invalid" do
        question = build(:question, question_number: 0)
        expect(question).to be_invalid
        expect(question.errors[:question_number]).to include("must be greater than 0")
      end

      it "小数の場合は invalid" do
        question = build(:question, question_number: 1.5)
        expect(question).to be_invalid
        expect(question.errors[:question_number]).to include("must be an integer")
      end
    end

    describe "content" do
      it "nil の場合は invalid" do
        question = build(:question, content: nil)
        expect(question).to be_invalid
        expect(question.errors[:content]).to include("can't be blank")
      end

      it "255文字の場合は valid (境界値)" do
        question = build(:question, content: "あ" * 255)
        expect(question).to be_valid
      end

      it "256文字の場合は invalid (境界値超え)" do
        question = build(:question, content: "あ" * 256)
        expect(question).to be_invalid
        expect(question.errors[:content]).to include("is too long (maximum is 255 characters)")
      end
    end

    describe "reversed" do
      it "nil の場合は invalid" do
        question = build(:question, reversed: nil)
        expect(question).to be_invalid
        expect(question.errors[:reversed]).to include("is not included in the list")
      end

      it "true の場合は valid" do
        question = build(:question, reversed: true)
        expect(question).to be_valid
      end

      it "false の場合は valid" do
        question = build(:question, reversed: false)
        expect(question).to be_valid
      end
    end

    describe "section (belongs_to)" do
      it "section が nil の場合は invalid" do
        question = build(:question, section: nil)
        expect(question).to be_invalid
        expect(question.errors[:section]).to include("must exist")
      end
    end
  end
end
