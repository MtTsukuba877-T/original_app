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
      # password バリデーションは password_changed_at が present の場合のみ適用される仕様
      # （Issue #23 で変更、初期パスワード=生年月日を許容するため）。
      # そのため、バリデーションが走ることを検証するテストは password_changed_at をセットする。
      #
      # 【MVP時点の仕様範囲】
      # - モデル spec は「バリデーションの条件式が正しく機能すること」の検証に留める。
      # - 「初期パスワード=生年月日」という業務仕様の検証は、
      #   Issue #23 で作成する spec/forms/employee_csv_import_form_spec.rb で行う。
      # - 本リリース版で個別登録機能（Issue #26）が追加された際は、
      #   そのフォームオブジェクト spec に別途「手入力時の初期パス生成ロジック」の検証を追加する。

      context "password_changed_at が nil の場合（初回ログイン扱い）" do
        it "数字のみ8桁（生年月日想定）でも valid（CSV 名簿登録時の初期パスワードを許容）" do
          employee = build(:employee, password: "19800315", password_changed_at: nil)
          expect(employee).to be_valid
        end

        it "7文字（境界値未満）でも valid（バリデーションがスキップされる）" do
          employee = build(:employee, password: "abc1234", password_changed_at: nil)
          expect(employee).to be_valid
        end

        it "英字のみでも valid（バリデーションがスキップされる）" do
          employee = build(:employee, password: "onlyalphabet", password_changed_at: nil)
          expect(employee).to be_valid
        end
      end

      context "password_changed_at が present の場合（変更後の再変更）" do
        let(:changed_at) { Time.current }

        it "8文字の英数字混在の場合は valid (境界値)" do
          employee = build(:employee, password: "abcde123", password_changed_at: changed_at)
          expect(employee).to be_valid
        end

        it "7文字の場合は invalid (境界値未満)" do
          employee = build(:employee, password: "abc1234", password_changed_at: changed_at)
          expect(employee).to be_invalid
          expect(employee.errors[:password]).to include("is too short (minimum is 8 characters)")
        end

        it "英字のみの場合は invalid (数字なし)" do
          employee = build(:employee, password: "onlyalphabet", password_changed_at: changed_at)
          expect(employee).to be_invalid
          expect(employee.errors[:password]).to include("は半角英数字混在で入力してください")
        end

        it "数字のみの場合は invalid (英字なし)" do
          employee = build(:employee, password: "12345678", password_changed_at: changed_at)
          expect(employee).to be_invalid
          expect(employee.errors[:password]).to include("は半角英数字混在で入力してください")
        end

        it "記号を含む場合は invalid" do
          employee = build(:employee, password: "abcd123!", password_changed_at: changed_at)
          expect(employee).to be_invalid
          expect(employee.errors[:password]).to include("は半角英数字混在で入力してください")
        end

        it "日本語を含む場合は invalid" do
          employee = build(:employee, password: "abc123あい", password_changed_at: changed_at)
          expect(employee).to be_invalid
          expect(employee.errors[:password]).to include("は半角英数字混在で入力してください")
        end
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

  describe "#responded_to?" do
    let(:employee) { create(:employee) }
    let(:period) { create(:stress_check_period, company: employee.company, name: "2026年度前期") }

    it "その実施回の回答が1件もなければ false を返すこと" do
      expect(employee.responded_to?(period)).to be(false)
    end

    it "その実施回の回答が1件でもあれば true を返すこと" do
      create(:stress_check_response, employee: employee, stress_check_period: period)

      expect(employee.responded_to?(period)).to be(true)
    end

    it "別の実施回の回答しかなければ false を返すこと" do
      other_period = create(:stress_check_period, company: employee.company, name: "2026年度後期")
      create(:stress_check_response, employee: employee, stress_check_period: other_period)

      expect(employee.responded_to?(period)).to be(false)
    end

    it "同じ会社の別の受検者の回答しかなければ false を返すこと" do
      colleague = create(:employee, company: employee.company)
      create(:stress_check_response, employee: colleague, stress_check_period: period)

      expect(employee.responded_to?(period)).to be(false)
    end

    it "別の会社の、受検者番号が同じ受検者の回答しかなければ false を返すこと" do
      other_employee = create(:employee, examinee_number: employee.examinee_number)
      other_period = create(:stress_check_period, company: other_employee.company)
      create(:stress_check_response, employee: other_employee, stress_check_period: other_period)

      expect(other_employee.company).not_to eq(employee.company)
      expect(employee.responded_to?(period)).to be(false)
    end
  end
end
