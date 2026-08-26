require "rails_helper"

RSpec.describe Company, type: :model do
  describe "factory" do
    it "有効な factory を持つこと" do
      company = build(:company)
      expect(company).to be_valid
    end
  end
end
