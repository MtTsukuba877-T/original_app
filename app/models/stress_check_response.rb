class StressCheckResponse < ApplicationRecord
  belongs_to :employee
  belongs_to :stress_check_period
  belongs_to :question

  validates :raw_answer, presence: true,
                         numericality: { only_integer: true, in: 1..4 }
  validates :employee_id, uniqueness: { scope: [ :stress_check_period_id, :question_id ] }

  # 受検者が預けた回答を、57問版の全質問について1件ずつ保存する（Issue #42）。
  # トランザクションで行うので、1件でも保存できなければ、すべて取り消される（全部か0件か）。
  # 保存できなかったときは例外（ActiveRecord::RecordInvalid など）が発生する。
  #
  # answers の形: { "質問のID（文字列）" => 選んだ番号（1〜4の整数）, ... }（session[:answers] と同じ）
  # 回答が抜けている質問は raw_answer が nil になり、バリデーションで保存に失敗する。
  def self.save_answers!(employee:, stress_check_period:, answers:)
    transaction do
      Question.standard_57.each do |question|
        create!(
          employee: employee,
          stress_check_period: stress_check_period,
          question: question,
          raw_answer: answers[question.id.to_s]
        )
      end
    end
  end

  # この回答の点数（1〜4）を返す（Issue #44）。
  # 点数は、ストレスが高いほうを4点、低いほうを1点とする
  # （厚生労働省の実施マニュアルの「合計点数を使う方法」）。
  # 逆転項目（questions.reversed が true）は、回答の番号を 1→4、2→3、3→2、4→1 に置き換える。
  def score
    if question.reversed?
      5 - raw_answer
    else
      raw_answer
    end
  end
end
