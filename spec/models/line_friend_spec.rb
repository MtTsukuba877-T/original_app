require "rails_helper"

RSpec.describe LineFriend, type: :model do
  describe "factory" do
    it "デフォルトの factory (トークン未生成、employee 未紐付け) が有効であること" do
      line_friend = build(:line_friend)
      expect(line_friend).to be_valid
    end

    it "trait :with_token が有効であること" do
      line_friend = build(:line_friend, :with_token)
      expect(line_friend).to be_valid
    end

    it "trait :linked_to_employee が有効であること" do
      line_friend = build(:line_friend, :linked_to_employee)
      expect(line_friend).to be_valid
    end

    it "trait :with_token + :linked_to_employee の組み合わせが有効であること" do
      line_friend = build(:line_friend, :with_token, :linked_to_employee)
      expect(line_friend).to be_valid
    end
  end

  describe "validations" do
    describe "line_user_id" do
      it "nil の場合は invalid" do
        line_friend = build(:line_friend, line_user_id: nil)
        expect(line_friend).to be_invalid
        expect(line_friend.errors[:line_user_id]).to include("can't be blank")
      end

      it "50文字の場合は valid (境界値)" do
        line_friend = build(:line_friend, line_user_id: "U" + "0" * 49)
        expect(line_friend).to be_valid
      end

      it "51文字の場合は invalid (境界値超え)" do
        line_friend = build(:line_friend, line_user_id: "U" + "0" * 50)
        expect(line_friend).to be_invalid
        expect(line_friend.errors[:line_user_id]).to include("is too long (maximum is 50 characters)")
      end

      it "同じ company 内で重複する場合は invalid" do
        company = create(:company)
        create(:line_friend, company: company, line_user_id: "UDUPLICATE")
        line_friend = build(:line_friend, company: company, line_user_id: "UDUPLICATE")
        expect(line_friend).to be_invalid
        expect(line_friend.errors[:line_user_id]).to include("has already been taken")
      end

      it "違う company であれば同じ line_user_id でも valid" do
        company1 = create(:company)
        company2 = create(:company)
        create(:line_friend, company: company1, line_user_id: "UDUPLICATE")
        line_friend = build(:line_friend, company: company2, line_user_id: "UDUPLICATE")
        expect(line_friend).to be_valid
      end
    end

    describe "initial_reg_token" do
      it "nil の場合は valid (任意項目)" do
        line_friend = build(:line_friend, initial_reg_token: nil)
        expect(line_friend).to be_valid
      end

      it "複数レコードが nil でも valid (allow_nil の効果)" do
        create(:line_friend, initial_reg_token: nil)
        line_friend = build(:line_friend, initial_reg_token: nil)
        expect(line_friend).to be_valid
      end

      it "重複する場合は invalid" do
        create(:line_friend, :with_token, initial_reg_token: "DUPTOKEN")
        line_friend = build(:line_friend, :with_token, initial_reg_token: "DUPTOKEN")
        expect(line_friend).to be_invalid
        expect(line_friend.errors[:initial_reg_token]).to include("has already been taken")
      end

      it "50文字の場合は valid (境界値)" do
        line_friend = build(:line_friend, :with_token, initial_reg_token: "T" * 50)
        expect(line_friend).to be_valid
      end

      it "51文字の場合は invalid (境界値超え)" do
        line_friend = build(:line_friend, :with_token, initial_reg_token: "T" * 51)
        expect(line_friend).to be_invalid
        expect(line_friend.errors[:initial_reg_token]).to include("is too long (maximum is 50 characters)")
      end
    end

    describe "token_send_count" do
      it "0 の場合は valid" do
        line_friend = build(:line_friend, token_send_count: 0)
        expect(line_friend).to be_valid
      end

      it "1 の場合は valid" do
        line_friend = build(:line_friend, token_send_count: 1)
        expect(line_friend).to be_valid
      end

      it "負の数の場合は invalid" do
        line_friend = build(:line_friend, token_send_count: -1)
        expect(line_friend).to be_invalid
        expect(line_friend.errors[:token_send_count]).to include("must be greater than or equal to 0")
      end
    end

    describe "トークン設定時の関連情報の整合性 (カスタムバリデーション)" do
      context "initial_reg_token が nil の場合" do
        it "token_generated_at と token_expires_at も nil で valid" do
          line_friend = build(:line_friend,
                              initial_reg_token: nil,
                              token_generated_at: nil,
                              token_expires_at: nil)
          expect(line_friend).to be_valid
        end
      end

      context "initial_reg_token が present の場合" do
        it "token_generated_at が nil だと invalid" do
          line_friend = build(:line_friend,
                              initial_reg_token: "SOMETOKEN",
                              token_generated_at: nil,
                              token_expires_at: Time.current + 7.days)
          expect(line_friend).to be_invalid
          expect(line_friend.errors[:token_generated_at]).to include("can't be blank")
        end

        it "token_expires_at が nil だと invalid" do
          line_friend = build(:line_friend,
                              initial_reg_token: "SOMETOKEN",
                              token_generated_at: Time.current,
                              token_expires_at: nil)
          expect(line_friend).to be_invalid
          expect(line_friend.errors[:token_expires_at]).to include("can't be blank")
        end

        it "全て present であれば valid" do
          line_friend = build(:line_friend, :with_token)
          expect(line_friend).to be_valid
        end
      end
    end

    describe "トークン有効期限の順序 (カスタムバリデーション)" do
      it "token_expires_at > token_generated_at の場合は valid" do
        now = Time.current
        line_friend = build(:line_friend, :with_token,
                            token_generated_at: now,
                            token_expires_at: now + 1.day)
        expect(line_friend).to be_valid
      end

      it "token_expires_at == token_generated_at の場合は invalid" do
        now = Time.current
        line_friend = build(:line_friend, :with_token,
                            token_generated_at: now,
                            token_expires_at: now)
        expect(line_friend).to be_invalid
        expect(line_friend.errors[:token_expires_at]).to include("はトークン発行日時より後の日時である必要があります")
      end

      it "token_expires_at < token_generated_at の場合は invalid" do
        now = Time.current
        line_friend = build(:line_friend, :with_token,
                            token_generated_at: now,
                            token_expires_at: now - 1.day)
        expect(line_friend).to be_invalid
        expect(line_friend.errors[:token_expires_at]).to include("はトークン発行日時より後の日時である必要があります")
      end

      it "両方 nil の場合は valid (順序チェック対象外)" do
        line_friend = build(:line_friend,
                            token_generated_at: nil,
                            token_expires_at: nil)
        expect(line_friend).to be_valid
      end
    end

    describe "company (belongs_to)" do
      it "company が nil の場合は invalid" do
        line_friend = build(:line_friend, company: nil)
        expect(line_friend).to be_invalid
        expect(line_friend.errors[:company]).to include("must exist")
      end
    end

    describe "employee (belongs_to, optional)" do
      it "employee が nil の場合は valid (任意)" do
        line_friend = build(:line_friend, employee: nil)
        expect(line_friend).to be_valid
      end
    end
  end
end
