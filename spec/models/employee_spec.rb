require "rails_helper"

RSpec.describe Employee, type: :model do
  describe "factory" do
    it "有効な factory を持つこと" do
      employee = build(:employee)
      expect(employee).to be_valid
    end
  end

  describe "validations" do
    describe "examinee_number" do
      it "nil の場合は invalid" do
        employee = build(:employee, examinee_number: nil)
        expect(employee).to be_invalid
        expect(employee.errors[:examinee_number]).to include("can't be blank")
      end

      it "15文字の場合は valid (境界値)" do
        employee = build(:employee, examinee_number: "A" * 15)
        expect(employee).to be_valid
      end

      it "16文字の場合は invalid (境界値超え)" do
        employee = build(:employee, examinee_number: "A" * 16)
        expect(employee).to be_invalid
        expect(employee.errors[:examinee_number]).to include("is too long (maximum is 15 characters)")
      end

      it "同じ company 内で重複する場合は invalid" do
        company = create(:company)
        create(:employee, company: company, examinee_number: "EMP9999")
        employee = build(:employee, company: company, examinee_number: "EMP9999")
        expect(employee).to be_invalid
        expect(employee.errors[:examinee_number]).to include("has already been taken")
      end

      it "違う company であれば同じ examinee_number でも valid" do
        company1 = create(:company)
        company2 = create(:company)
        create(:employee, company: company1, examinee_number: "EMP9999")
        employee = build(:employee, company: company2, examinee_number: "EMP9999")
        expect(employee).to be_valid
      end
    end

    describe "name" do
      it "nil の場合は invalid" do
        employee = build(:employee, name: nil)
        expect(employee).to be_invalid
        expect(employee.errors[:name]).to include("can't be blank")
      end

      it "50文字の場合は valid (境界値)" do
        employee = build(:employee, name: "あ" * 50)
        expect(employee).to be_valid
      end

      it "51文字の場合は invalid (境界値超え)" do
        employee = build(:employee, name: "あ" * 51)
        expect(employee).to be_invalid
        expect(employee.errors[:name]).to include("is too long (maximum is 50 characters)")
      end
    end

    describe "date_of_birth" do
      it "nil の場合は invalid" do
        employee = build(:employee, date_of_birth: nil)
        expect(employee).to be_invalid
        expect(employee.errors[:date_of_birth]).to include("can't be blank")
      end
    end

    describe "sex" do
      it "nil の場合は invalid" do
        employee = build(:employee, sex: nil)
        expect(employee).to be_invalid
        expect(employee.errors[:sex]).to include("can't be blank")
      end
    end

    describe "department" do
      it "nil の場合は valid (任意項目)" do
        employee = build(:employee, department: nil)
        expect(employee).to be_valid
      end

      it "100文字の場合は valid (境界値)" do
        employee = build(:employee, department: "あ" * 100)
        expect(employee).to be_valid
      end

      it "101文字の場合は invalid (境界値超え)" do
        employee = build(:employee, department: "あ" * 101)
        expect(employee).to be_invalid
        expect(employee.errors[:department]).to include("is too long (maximum is 100 characters)")
      end
    end

    describe "email" do
      it "nil の場合は valid (任意項目)" do
        employee = build(:employee, email: nil)
        expect(employee).to be_valid
      end

      it "空文字の場合は valid (allow_blank)" do
        employee = build(:employee, email: "")
        expect(employee).to be_valid
      end

      it "正しい形式の場合は valid" do
        employee = build(:employee, email: "test@example.com")
        expect(employee).to be_valid
      end

      it "形式が不正な場合は invalid" do
        employee = build(:employee, email: "invalid-email")
        expect(employee).to be_invalid
        expect(employee.errors[:email]).to include("is invalid")
      end

      it "255文字を超える場合は invalid" do
        long_email = "#{'a' * 244}@example.com"  # 244 + 12 = 256文字
        employee = build(:employee, email: long_email)
        expect(employee).to be_invalid
        expect(employee.errors[:email]).to include("is too long (maximum is 255 characters)")
      end
    end

    describe "password" do
      it "8文字の場合は valid (境界値、英数字混在)" do
        employee = build(:employee, password: "abcde123")
        expect(employee).to be_valid
      end

      it "7文字の場合は invalid (境界値未満)" do
        employee = build(:employee, password: "abc1234")
        expect(employee).to be_invalid
        expect(employee.errors[:password]).to include("is too short (minimum is 8 characters)")
      end

      it "英字のみの場合は invalid (数字なし)" do
        employee = build(:employee, password: "onlyalphabet")
        expect(employee).to be_invalid
        expect(employee.errors[:password]).to include("は半角英数字混在で入力してください")
      end

      it "数字のみの場合は invalid (英字なし)" do
        employee = build(:employee, password: "12345678")
        expect(employee).to be_invalid
        expect(employee.errors[:password]).to include("は半角英数字混在で入力してください")
      end

      it "記号を含む場合は invalid" do
        employee = build(:employee, password: "abcd123!")
        expect(employee).to be_invalid
        expect(employee.errors[:password]).to include("は半角英数字混在で入力してください")
      end

      it "日本語を含む場合は invalid" do
        employee = build(:employee, password: "abc123あい")
        expect(employee).to be_invalid
        expect(employee.errors[:password]).to include("は半角英数字混在で入力してください")
      end
    end

    describe "company (belongs_to)" do
      it "company が nil の場合は invalid" do
        employee = build(:employee, company: nil)
        expect(employee).to be_invalid
        expect(employee.errors[:company]).to include("must exist")
      end
    end
  end
end
