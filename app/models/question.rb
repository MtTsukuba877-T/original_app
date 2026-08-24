class Question < ApplicationRecord
  belongs_to :section
  has_many :stress_check_responses, dependent: :destroy
end
