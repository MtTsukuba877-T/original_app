class Section < ApplicationRecord
  has_many :questions, dependent: :restrict_with_error
  has_many :answer_options, dependent: :restrict_with_error
  has_many :judgments, dependent: :destroy
end
