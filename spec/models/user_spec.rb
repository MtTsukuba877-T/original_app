require "rails_helper"

RSpec.describe User, type: :model do
  describe "factory" do
    it "デフォルトの factory (system_admin) が有効であること" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "trait :company_hr が有効であること" do
      user = build(:user, :company_hr)
      expect(user).to be_valid
    end
  end

  describe "validations" do
    describe "name" do
      it "nil の場合は invalid" do
        user = build(:user, name: nil)
        expect(user).to be_invalid
        expect(user.errors[:name]).to include("can't be blank")
      end

      it "50文字の場合は valid (境界値)" do
        user = build(:user, name: "あ" * 50)
        expect(user).to be_valid
      end

      it "51文字の場合は invalid (境界値超え)" do
        user = build(:user, name: "あ" * 51)
        expect(user).to be_invalid
        expect(user.errors[:name]).to include("is too long (maximum is 50 characters)")
      end
    end

    describe "role" do
      it "nil の場合は invalid" do
        user = build(:user, role: nil)
        expect(user).to be_invalid
        expect(user.errors[:role]).to include("can't be blank")
      end
    end

    describe "company (条件付きバリデーション)" do
      context "role が system_admin の場合" do
        it "company が nil であれば valid" do
          user = build(:user, role: :system_admin, company: nil)
          expect(user).to be_valid
        end

        it "company が present であれば invalid" do
          company = build(:company)
          user = build(:user, role: :system_admin, company: company)
          expect(user).to be_invalid
          expect(user.errors[:company]).to include("must be blank")
        end
      end

      context "role が company_hr の場合" do
        it "company が present であれば valid" do
          user = build(:user, :company_hr)
          expect(user).to be_valid
        end

        it "company が nil であれば invalid" do
          user = build(:user, role: :company_hr, company: nil)
          expect(user).to be_invalid
          expect(user.errors[:company]).to include("can't be blank")
        end
      end
    end

    describe "email (Devise :validatable が担当)" do
      it "nil の場合は invalid" do
        user = build(:user, email: nil)
        expect(user).to be_invalid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it "重複する場合は invalid" do
        create(:user, email: "dup@example.com")
        user = build(:user, email: "dup@example.com")
        expect(user).to be_invalid
        expect(user.errors[:email]).to include("has already been taken")
      end

      it "形式が不正な場合は invalid" do
        user = build(:user, email: "invalid-email")
        expect(user).to be_invalid
        expect(user.errors[:email]).to include("is invalid")
      end
    end

    describe "password" do
      it "nil の場合は invalid" do
        user = build(:user, password: nil)
        expect(user).to be_invalid
        expect(user.errors[:password]).to include("can't be blank")
      end

      # 長さのバリデーション (8文字以上)
      it "7文字の場合は invalid (最小8文字未満)" do
        user = build(:user, password: "abc123x")
        expect(user).to be_invalid
        expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")   # ← 英語
      end

      it "8文字の場合は valid (境界値)" do
        user = build(:user, password: "abcd1234")
        expect(user).to be_valid
      end

      # 文字種のバリデーション (半角英数字混在)
      it "英字のみの場合は invalid" do
        user = build(:user, password: "abcdefgh")
        expect(user).to be_invalid
        expect(user.errors[:password]).to include("は半角英数字混在で入力してください")
      end

      it "数字のみの場合は invalid" do
        user = build(:user, password: "12345678")
        expect(user).to be_invalid
        expect(user.errors[:password]).to include("は半角英数字混在で入力してください")
      end

      it "半角英数字混在の場合は valid" do
        user = build(:user, password: "password123")
        expect(user).to be_valid
      end
    end
  end
end
